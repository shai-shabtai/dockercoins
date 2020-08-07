import logging
import os
from redis import Redis
import requests
import time

DEBUG = os.environ.get("DEBUG", "").lower().startswith("y")

#SRVRNGPORT = 80
SRVRNGPORT=os.getenv("SRVRNGPORT", default = 80)
SRVRNGNAME=os.getenv("SRVRNGNAME", default = "rng")
RNGURL="http://{}:{}/32".format(SRVRNGNAME,SRVRNGPORT)
#RNGURL="http://{}:80/32".format(SRVRNGNAME)

SRVHASHERPORT=os.getenv("SRVHASHERPORT", default = 80)
SRVHASHERNAME=os.getenv("SRVHASHERNAME", default = "hasher")
HASHERURL="http://{}:{}/".format(SRVHASHERNAME,SRVHASHERPORT)

REDISCONNECTION=os.getenv("REDISCONNECTION", default = "redis")

log = logging.getLogger(__name__)
if DEBUG:
    logging.basicConfig(level=logging.DEBUG)
else:
    logging.basicConfig(level=logging.INFO)
    logging.getLogger("requests").setLevel(logging.WARNING)


redis = Redis(REDISCONNECTION)


def get_random_bytes():
    r = requests.get(RNGURL)
    return r.content


def hash_bytes(data):
    r = requests.post(HASHERURL,
                      data=data,
                      headers={"Content-Type": "application/octet-stream"})
    hex_hash = r.text
    return hex_hash


def work_loop(interval=1):
    deadline = 0
    loops_done = 0
    while True:
        if time.time() > deadline:
            log.info("{} units of work done, updating hash counter"
                     .format(loops_done))
            redis.incrby("hashes", loops_done)
            loops_done = 0
            deadline = time.time() + interval
        work_once()
        loops_done += 1


def work_once():
    log.debug("Doing one unit of work")
    time.sleep(0.1)
    random_bytes = get_random_bytes()
    hex_hash = hash_bytes(random_bytes)
    if not hex_hash.startswith('0'):
        log.debug("No coin found")
        return
    log.info("Coin found: {}...".format(hex_hash[:8]))
    created = redis.hset("wallet", hex_hash, random_bytes)
    if not created:
        log.info("We already had that coin")


if __name__ == "__main__":
    while True:
        try:
            work_loop()
        except:
            log.exception("In work loop:")
            log.error("Waiting 10s and restarting.")
            time.sleep(10)


