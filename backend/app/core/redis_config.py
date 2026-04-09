import os
from dotenv import load_dotenv
from redis.cluster import RedisCluster

# Load environment variables
load_dotenv()

# Read from .env
REDIS_HOST = os.getenv("REDIS_HOST")
REDIS_PORT = int(os.getenv("REDIS_PORT"))
REDIS_PASSWORD = os.getenv("REDIS_PASSWORD")

# Create Redis Cluster client
rc = RedisCluster(
    host=REDIS_HOST,
    port=REDIS_PORT,
    password=REDIS_PASSWORD,
    decode_responses=True
)

# Test connection
try:
    rc.set("test_key", "Hello Redis ")
    value = rc.get("test_key")
    print("Connected successfully!")
    print("Value:", value)
except Exception as e:
    print("Error:", e)