# train_model.py
import pandas as pd
from sentiment_model import SentimentAnalyzer


def train_with_csv(csv_path):
    # Load your training data
    df = pd.read_csv(csv_path)

    # Assuming your CSV has 'text' and 'sentiment' columns
    texts = df["text"].tolist()
    labels = df["sentiment"].tolist()

    # Initialize and train model
    analyzer = SentimentAnalyzer()
    results = analyzer.train(texts, labels)

    # Print results
    print("Training Results:")
    print(f"Train Score: {results['train_score']:.2f}")
    print(f"Test Score: {results['test_score']:.2f}")
    print("\nClassification Report:")
    print(results["classification_report"])

    # Save model
    analyzer.save_model("sentiment_model.joblib")


if __name__ == "__main__":
    # Replace with path to your training data
    train_with_csv("sentiment_reviews.csv")
