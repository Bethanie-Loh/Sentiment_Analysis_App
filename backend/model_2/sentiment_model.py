#sentiment_model.py
from vaderSentiment.vaderSentiment import SentimentIntensityAnalyzer
import nltk
from nltk.tokenize import word_tokenize
from nltk.corpus import stopwords
from nltk.stem import WordNetLemmatizer
import re
from tqdm import tqdm
from sklearn.metrics import accuracy_score, confusion_matrix
import seaborn as sns
import matplotlib.pyplot as plt

class FlexibleSentimentAnalyzer:

    def __init__(self):
        self.analyzer = SentimentIntensityAnalyzer()

        try:
            nltk.download("punkt", quiet=True)
            nltk.download("stopwords", quiet=True)
            nltk.download("wordnet", quiet=True)
        except:
            print("Note: NLTK data download failed, but model will still work")

        self.lemmatizer = WordNetLemmatizer()
        self.stop_words = set(stopwords.words("english")) - {"not", "no"}

    def preprocess_text(self, text):
        try:
            print(f"Original: {text}")
            text = str(text).lower()
            print(f"Lowercase: {text}")
            text = re.sub(r"[^a-zA-Z\s]", "", text)
            print(f"Cleaned: {text}")
            tokens = word_tokenize(text)
            tokens = [
                self.lemmatizer.lemmatize(token)
                for token in tokens
                if token not in self.stop_words
            ]
            print(f"Tokens: {tokens}")
            return " ".join(tokens)
        except Exception as e:
            print(f"Error in preprocessing: {e}")
            return str(text)

    def analyze_text(self, text):
        """Analyze sentiment of a single text"""
        raw_scores = self.analyzer.polarity_scores(text)

        # Analyze preprocessed text sentiment
        preprocessed_text = self.preprocess_text(text)
        preprocessed_scores = self.analyzer.polarity_scores(preprocessed_text)

        # Debugging: Print raw and preprocessed scores
        print("Original Text:", text)
        print("Raw Scores:", raw_scores)
        print("Preprocessed Text:", preprocessed_text)
        print("Preprocessed Scores:", preprocessed_scores)

        # Decide which scores to use (raw text or preprocessed text)
        scores = raw_scores

        # Determine sentiment category
        if scores["compound"] >= 0.05:
            sentiment = "positive"
        elif scores["compound"] <= -0.05:
            sentiment = "negative"
        else:
            sentiment = "neutral"

        return {
            "sentiment": sentiment,
            "compound_score": scores["compound"],
            "positive_score": scores["pos"],
            "negative_score": scores["neg"],
            "neutral_score": scores["neu"],
        }

    def analyze_dataframe(self, df, text_column):
        """Analyze sentiment for all texts in a dataframe"""
        if text_column not in df.columns:
            raise ValueError(
                f"Column '{text_column}' not found in dataframe. "
                f"Available columns are: {', '.join(df.columns)}"
            )

        print(f"Analyzing {len(df)} texts...")
        results = []

        for text in tqdm(df[text_column]):
            results.append(self.analyze_text(text))

        # Add results to dataframe
        df["sentiment"] = [r["sentiment"] for r in results]
        df["compound_score"] = [r["compound_score"] for r in results]
        df["positive_score"] = [r["positive_score"] for r in results]
        df["negative_score"] = [r["negative_score"] for r in results]
        df["neutral_score"] = [r["neutral_score"] for r in results]

        return df

    def evaluate_model(self, df, text_column, label_column):
        """Evaluate the model using accuracy and confusion matrix"""
        # Check if the required columns exist
        if text_column not in df.columns:
            raise ValueError(f"'{text_column}' not found in dataframe.")
        if label_column not in df.columns:
            raise ValueError(f"'{label_column}' not found in dataframe.")

        # Preprocess text and analyze sentiment
        df = self.analyze_dataframe(df, text_column)

        # Get actual and predicted sentiment
        actual = df[label_column].tolist()
        predicted = df["sentiment"].tolist()

        # Calculate accuracy
        accuracy = accuracy_score(actual, predicted)

        # Generate confusion matrix
        cm = confusion_matrix(
            actual, predicted, labels=["positive", "negative", "neutral"]
        )

        # Plot confusion matrix
        plt.figure(figsize=(8, 6))
        sns.heatmap(
            cm,
            annot=True,
            fmt="d",
            cmap="Blues",
            xticklabels=["positive", "negative", "neutral"],
            yticklabels=["positive", "negative", "neutral"],
        )
        plt.xlabel("Predicted Sentiment")
        plt.ylabel("Actual Sentiment")
        plt.title("Confusion Matrix")
        plt.show()

        print(f"Accuracy: {accuracy:.2f}")
        return accuracy, cm
