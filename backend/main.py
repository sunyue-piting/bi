
from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from typing import List, Optional
from database import engine, Base, SessionLocal
import models

Base.metadata.create_all(bind=engine)

app = FastAPI()
app.add_middleware(CORSMiddleware, allow_origins=["*"], allow_credentials=True, allow_methods=["*"], allow_headers=["*"])

class FundBase(BaseModel):
    name: str
    inception_date: Optional[str]
    fund_aum: Optional[float]
    firm_aum: Optional[float]

class Fund(FundBase):
    id: int
    class Config:
        orm_mode = True

@app.get("/funds", response_model=List[Fund])
def list_funds():
    db = SessionLocal()
    funds = db.query(models.Fund).all()
    db.close()
    return funds

@app.post("/funds", response_model=Fund)
def create_fund(fund: FundBase):
    db = SessionLocal()
    db_fund = models.Fund(**fund.dict())
    db.add(db_fund)
    db.commit()
    db.refresh(db_fund)
    db.close()
    return db_fund
