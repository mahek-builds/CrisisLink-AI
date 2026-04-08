from sqlalchemy import create_engine, text


DATABASE_URL = "postgresql://postgres:crisislink_@crisislink.c65uk20eedbd.us-east-1.rds.amazonaws.com:5432/crisislink"


engine = create_engine(DATABASE_URL)

try:
    with engine.connect() as connection:
        # This sends a simple 'hello' to the database
        result = connection.execute(text("SELECT 1"))
        print(" Success! The database is reachable and credentials are correct.")
except Exception as e:
    print(f"Connection failed: {e}")