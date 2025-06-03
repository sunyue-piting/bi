
from sqlalchemy import Column, Integer, String, Float
from database import Base

class Fund(Base):
    __tablename__ = "funds"

    id = Column(Integer, primary_key=True, index=True)
    name = Column(String, unique=True, index=True)
    inception_date = Column(String)
    fund_aum = Column(Float)
    firm_aum = Column(Float)
