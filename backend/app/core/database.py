from sqlalchemy import create_engine, Column, Integer, String
from sqlalchemy.orm import declarative_base, sessionmaker
import os
from dotenv import load_dotenv

# Load .env
load_dotenv()

DATABASE_URL = os.getenv("DATABASE_URL")

# Create engine
engine = create_engine(
    DATABASE_URL,
    pool_pre_ping=True
)

# Session
SessionLocal = sessionmaker(
    autocommit=False,
    autoflush=False,
    bind=engine
)

# Base
Base = declarative_base()


# ------------------ MODEL ------------------
class User(Base):
    __tablename__ = "users"

    id = Column(Integer, primary_key=True, index=True)
    name = Column(String)
    email = Column(String)


# ------------------ CREATE TABLE ------------------
Base.metadata.create_all(bind=engine)


# ------------------ DB DEPENDENCY ------------------
def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()


# ------------------ TEST RUN ------------------
if __name__ == "__main__":
    db = SessionLocal()

    # Insert test user
    new_user = User(name="Hirdesh", email="hirdesh@example.com")
    db.add(new_user)
    db.commit()

    # Fetch users
    users = db.query(User).all()
    for user in users:
        print(user.id, user.name, user.email)

    db.close()
