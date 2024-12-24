import numpy as np
from sklearn.feature_extraction.text import TfidfVectorizer
from sklearn.model_selection import train_test_split
from tensorflow.keras.models import Sequential
from tensorflow.keras.layers import Dense, Dropout, BatchNormalization
from tensorflow.keras.callbacks import EarlyStopping, ModelCheckpoint
from tensorflow.keras.optimizers import Adam
import tensorflow as tf
import json
import re
import nltk
from nltk.corpus import stopwords
from nltk.tokenize import word_tokenize
from nltk.stem import WordNetLemmatizer
import logging
from typing import List, Dict, Union
import os
from flask import Flask, send_file
from flask_cors import CORS

# Get the absolute path of the current directory
BASE_DIR = os.path.dirname(os.path.abspath(__file__))

# Create the models directory if it doesn't exist
models_dir = os.path.join(BASE_DIR, "models")
os.makedirs(models_dir, exist_ok=True)

# Define the paths
model_path = os.path.join(models_dir, "sentiment_model.tflite")
vectorizer_path = os.path.join(models_dir, "vectorizer.json")

# Initialize Flask app
app = Flask(__name__)
CORS(app)  # Enable CORS for all routes

class NumpyEncoder(json.JSONEncoder):
    def default(self, obj):
        if isinstance(obj, np.integer):
            return int(obj)
        if isinstance(obj, np.floating):
            return float(obj)
        if isinstance(obj, np.ndarray):
            return obj.tolist()
        return super().default(obj)

class SentimentAnalyzer:
    def __init__(self, max_features: int = 5000, max_length: int = 100):
        self.max_features = max_features
        self.max_length = max_length
        self.vectorizer = TfidfVectorizer(
            max_features=max_features,
            ngram_range=(1, 3),
            strip_accents="unicode",
            lowercase=True,
        )
        self.model = None
        self.label_encoder = {"positive": 2, "neutral": 1, "negative": 0}
        self.setup_logging()
        self.setup_nltk()

    def setup_logging(self):
        """Configure logging for the model."""
        logging.basicConfig(
            level=logging.INFO, format="%(asctime)s - %(levelname)s - %(message)s"
        )
        self.logger = logging.getLogger(__name__)

    def setup_nltk(self):
        """Download required NLTK resources."""
        try:
            nltk.download("punkt", quiet=True)
            nltk.download("stopwords", quiet=True)
            nltk.download("wordnet", quiet=True)
            self.stop_words = set(stopwords.words("english"))
            self.lemmatizer = WordNetLemmatizer()
        except Exception as e:
            self.logger.error(f"Error downloading NLTK resources: {str(e)}")
            raise

    def preprocess_text(self, text: str) -> str:
        try:
            # Convert to lowercase
            text = text.lower()
            # Remove special characters and numbers
            text = re.sub(r"[^a-zA-Z\s]", "", text)
            # Tokenize
            tokens = word_tokenize(text)
            # Remove stopwords and lemmatize
            tokens = [
                self.lemmatizer.lemmatize(token)
                for token in tokens
                if token not in self.stop_words
            ]
            return " ".join(tokens)
        except Exception as e:
            self.logger.error(f"Error in text preprocessing: {str(e)}")
            raise

    def build_model(self, input_dim: int) -> Sequential:
        model = Sequential(
            [
                Dense(512, activation="relu", input_dim=input_dim),
                BatchNormalization(),
                Dense(512, activation="relu"),
                Dropout(0.3),
                BatchNormalization(),
                Dense(256, activation="relu"),
                Dropout(0.2),
                BatchNormalization(),
                Dense(128, activation="relu"),
                Dropout(0.1),
                Dense(3, activation="softmax"),
            ]
        )

        model.compile(
            optimizer=Adam(learning_rate=0.001),
            loss="sparse_categorical_crossentropy",
            metrics=["accuracy"],
        )
        return model

    def train(
        self,
        texts: List[str],
        labels: List[str],
        validation_split: float = 0.2,
        epochs: int = 50,
        batch_size: int = 32,
    ) -> Dict[str, Union[float, List[float]]]:
        try:
            # Preprocess all texts
            processed_texts = [self.preprocess_text(text) for text in texts]

            # Vectorize texts
            X = self.vectorizer.fit_transform(processed_texts).toarray()
            y = np.array([self.label_encoder[label] for label in labels])

            # Split data
            X_train, X_val, y_train, y_val = train_test_split(
                X, y, test_size=validation_split, random_state=42
            )

            # Build model
            self.model = self.build_model(X.shape[1])

            # Setup callbacks
            callbacks = [
                EarlyStopping(
                    monitor="val_loss", patience=5, restore_best_weights=True
                ),
                ModelCheckpoint(
                    "best_model.keras", monitor="val_accuracy", save_best_only=True
                ),
            ]

            # Train model
            history = self.model.fit(
                X_train,
                y_train,
                validation_data=(X_val, y_val),
                epochs=epochs,
                batch_size=batch_size,
                callbacks=callbacks,
                verbose=1,
            )

            self.logger.info("Model training completed successfully")
            return history.history

        except Exception as e:
            self.logger.error(f"Error in model training: {str(e)}")
            raise

    def predict(self, texts: List[str]) -> List[str]:
        try:
            # Preprocess texts
            processed_texts = [self.preprocess_text(text) for text in texts]

            # Vectorize
            X = self.vectorizer.transform(processed_texts).toarray()

            # Predict
            predictions = self.model.predict(X)

            # Convert to labels
            label_decoder = {v: k for k, v in self.label_encoder.items()}
            return [label_decoder[pred] for pred in predictions.argmax(axis=1)]

        except Exception as e:
            self.logger.error(f"Error in prediction: {str(e)}")
            raise

    def save_model(self, model_path: str, vectorizer_path: str):
        try:
            # Create directories if they don't exist
            os.makedirs(os.path.dirname(model_path), exist_ok=True)
            os.makedirs(os.path.dirname(vectorizer_path), exist_ok=True)

            # Convert vocabulary to regular Python types
            vocabulary = {k: int(v) for k, v in self.vectorizer.vocabulary_.items()}

            # Save vectorizer
            vectorizer_data = {
                "vocabulary": vocabulary,
                "idf": self.vectorizer.idf_.tolist(),
                "max_features": self.max_features,
            }

            with open(vectorizer_path, "w") as f:
                json.dump(vectorizer_data, f, cls=NumpyEncoder)

            # Convert and save model
            converter = tf.lite.TFLiteConverter.from_keras_model(self.model)
            converter.optimizations = [tf.lite.Optimize.DEFAULT]
            tflite_model = converter.convert()

            with open(model_path, "wb") as f:
                f.write(tflite_model)

            self.logger.info("Model and vectorizer saved successfully")

        except Exception as e:
            self.logger.error(f"Error saving model: {str(e)}")
            raise

    def load_model(self, model_path: str, vectorizer_path: str):
        try:
            # Load vectorizer
            with open(vectorizer_path, "r") as f:
                vectorizer_data = json.load(f)

            self.vectorizer = TfidfVectorizer(
                max_features=vectorizer_data["max_features"],
                vocabulary=vectorizer_data["vocabulary"],
            )
            self.vectorizer.idf_ = np.array(vectorizer_data["idf"])

            # Load TFLite model
            self.interpreter = tf.lite.Interpreter(model_path=model_path)
            self.interpreter.allocate_tensors()

            self.logger.info("Model and vectorizer loaded successfully")

        except Exception as e:
            self.logger.error(f"Error loading model: {str(e)}")
            raise

# Flask routes for serving model files
@app.route("/models/sentiment_model.tflite")
def serve_model():
    return send_file(model_path, mimetype="application/octet-stream")

@app.route("/models/vectorizer.json")
def serve_vectorizer():
    return send_file(vectorizer_path, mimetype="application/json")

@app.route("/health")
def health_check():
    return {"status": "ok"}, 200

if __name__ == "__main__":
    if not (os.path.exists(model_path) and os.path.exists(vectorizer_path)):
        texts = [
            "This product is amazing! I love it!",
            "Worst purchase ever. Don't buy this.",
            "It's okay, nothing special.",
            "Great quality and fast delivery!",
            "Disappointed with the service.",
            "The features are impressive but the price is too high",
            "Average performance, meets basic needs",
            "Exceptional customer support and product quality",
            "Completely useless and waste of money",
            "Decent value for the price point",
            "Outstanding performance and reliability",
            "Terrible customer service experience",
            "Just an average product, nothing more",
            "Couldn't be happier with my purchase",
            "Total disappointment in every way",
            "Neither good nor bad, just okay",
            "Best purchase I've made this year",
            "Poor quality control and design",
            "Meets expectations but doesn't exceed them",
            "Absolutely fantastic product",
        ]

        labels = [
            "positive",
            "negative",
            "neutral",
            "positive",
            "negative",
            "neutral",
            "neutral",
            "positive",
            "negative",
            "neutral",
            "positive",
            "negative",
            "neutral",
            "positive",
            "negative",
            "neutral",
            "positive",
            "negative",
            "neutral",
            "positive",
        ]

            # Initialize and train model
        analyzer = SentimentAnalyzer()
        history = analyzer.train(texts, labels)

        analyzer.save_model(model_path, vectorizer_path)

        print("Model training completed and saved")
    else:
        print("Using existing model files")

        app.run(host='0.0.0.0', port=8000, debug=True)
