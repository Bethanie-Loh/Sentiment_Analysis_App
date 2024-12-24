import numpy as np
from sklearn.model_selection import train_test_split
from sklearn.feature_extraction.text import TfidfVectorizer
from sklearn.svm import LinearSVC
from sklearn.pipeline import Pipeline
from sklearn.metrics import classification_report
import joblib
import re
import nltk
from nltk.tokenize import word_tokenize
from nltk.corpus import stopwords
from nltk.stem import WordNetLemmatizer

class SentimentAnalyzer:
    def __init__(self):
        # Download required NLTK data
        nltk.download("punkt")
        nltk.download("stopwords")
        nltk.download("wordnet")
        nltk.download("omw-1.4")

        self.lemmatizer = WordNetLemmatizer()
        self.stop_words = set(stopwords.words("english"))
        self.model = None

    def preprocess_text(self, text):
        # Convert to lowercase
        text = text.lower()

        # Remove special characters and numbers
        text = re.sub(r"[^a-zA-Z\s]", "", text)

        # Tokenization
        tokens = word_tokenize(text)

        # Remove stopwords and lemmatize
        tokens = [
            self.lemmatizer.lemmatize(token)
            for token in tokens
            if token not in self.stop_words
        ]

        return " ".join(tokens)

    def prepare_data(self, texts, labels):
        # Preprocess all texts
        processed_texts = [self.preprocess_text(text) for text in texts]

        # Create pipeline with TF-IDF and SVM
        self.model = Pipeline(
            [
                ("tfidf", TfidfVectorizer(max_features=5000, ngram_range=(1, 2))),
                ("classifier", LinearSVC(random_state=42)),
            ]
        )

        return processed_texts, labels

    def train(self, texts, labels):
        # Prepare data
        processed_texts, labels = self.prepare_data(texts, labels)

        # Split data
        X_train, X_test, y_train, y_test = train_test_split(
            processed_texts, labels, test_size=0.2, random_state=42
        )

        # Train model
        self.model.fit(X_train, y_train)

        # Evaluate model
        train_score = self.model.score(X_train, y_train)
        test_score = self.model.score(X_test, y_test)

        # Detailed evaluation
        y_pred = self.model.predict(X_test)
        report = classification_report(y_test, y_pred)

        return {
            "train_score": train_score,
            "test_score": test_score,
            "classification_report": report,
        }

    def predict(self, text):
        if self.model is None:
            raise ValueError("Model not trained yet!")

        # Preprocess input text
        processed_text = self.preprocess_text(text)

        # Make prediction
        prediction = self.model.predict([processed_text])[0]
        return prediction

    def save_model(self, path):
        if self.model is None:
            raise ValueError("No model to save!")
        joblib.dump(self.model, path)

    def load_model(self, path):
        self.model = joblib.load(path)


# Example usage and training script
if __name__ == "__main__":
    # Sample data
    texts = [
        "This product is amazing! I love it!",
        "Worst purchase ever. Don't buy this.",
        "It's okay, nothing special.",
        "Great quality and fast delivery!",
        "Disappointed with the service.",
        # Add more training examples...
    ]

    labels = ["positive", "negative", "neutral", "positive", "negative"]

    # Initialize and train model
    analyzer = SentimentAnalyzer()
    results = analyzer.train(texts, labels)

    print("Training Results:")
    print(f"Train Score: {results['train_score']:.2f}")
    print(f"Test Score: {results['test_score']:.2f}")
    print("\nClassification Report:")
    print(results["classification_report"])

    # Save model
    analyzer.save_model("sentiment_model.joblib")
