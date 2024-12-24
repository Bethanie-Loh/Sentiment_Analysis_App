from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from typing import List
from sentiment_model import SentimentAnalyzer
import uvicorn

app = FastAPI()

# Add CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Initialize model
analyzer = SentimentAnalyzer()
try:
    analyzer.load_model("sentiment_model.joblib")
except:
    print("Warning: Could not load model")


class TextInput(BaseModel):
    text: str


class BatchInput(BaseModel):
    texts: List[str]


@app.get("/")
async def root():
    return {"status": "alive", "message": "Server is running"}


@app.get("/test")
async def test():
    return {"status": "ok"}


@app.post("/batch")
async def analyze_batch(input_data: BatchInput):
    try:
        print(f"Received batch request with {len(input_data.texts)} texts")
        results = []
        for text in input_data.texts:
            sentiment = analyzer.predict(text)
            results.append({"sentiment": sentiment})
        return results
    except Exception as e:
        print(f"Error processing batch: {str(e)}")
        raise HTTPException(status_code=500, detail=str(e))


if __name__ == "__main__":
    print("Starting server...")
    uvicorn.run(app, host="0.0.0.0", port=8000, log_level="debug")
