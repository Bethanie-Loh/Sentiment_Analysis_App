from transformers import pipeline
import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
import seaborn as sns


class SentimentAnalyzer:
    def __init__(self):
        self.analyzer = pipeline(
            "sentiment-analysis",
            model="nlptown/bert-base-multilingual-uncased-sentiment",
        )
        self.results = None

    def analyze_text(self, text):
        """Analyze a single piece of text using 5-star rating system"""
        try:
            result = self.analyzer(text[:512])[0]
            # Model returns labels like '1 star', '2 stars', etc.
            rating = int(result["label"].split()[0])
            confidence = result["score"]

            # Convert 5-star rating to sentiment categories
            if rating >= 4:
                sentiment = "POSITIVE"
                score = 1.0
            elif rating <= 2:
                sentiment = "NEGATIVE"
                score = -1.0
            else:
                sentiment = "NEUTRAL"
                score = 0.0

            return {
                "sentiment": sentiment,
                "rating": rating,
                "confidence": confidence,
                "score": score,
            }
        except Exception as e:
            print(f"Error analyzing text: {e}")
            return {
                "sentiment": "NEUTRAL",
                "rating": 3,
                "confidence": 0.5,
                "score": 0.0,
            }

    def analyze_dataframe(self, df, text_column):
        """Analyze all texts in a dataframe column"""
        print("Analyzing sentiments...")
        results = []
        for text in df[text_column]:
            if pd.isna(text):
                results.append(
                    {
                        "sentiment": "NEUTRAL",
                        "rating": 3,
                        "confidence": 0.5,
                        "score": 0.0,
                    }
                )
            else:
                results.append(self.analyze_text(str(text)))

        self.results = results

        df["sentiment"] = [r["sentiment"] for r in results]
        df["rating"] = [r["rating"] for r in results]
        df["confidence"] = [r["confidence"] for r in results]
        df["sentiment_score"] = [r["score"] for r in results]

        return df

    def plot_sentiment_distribution(self):
        """Plot the distribution of sentiments and ratings"""
        if not self.results:
            print("No results to plot. Please analyze data first.")
            return

        # Create figure with two subplots
        fig, (ax1, ax2) = plt.subplots(1, 2, figsize=(15, 6))

        # Plot sentiment categories
        sentiments = [r["sentiment"] for r in self.results]
        colors = {"POSITIVE": "green", "NEUTRAL": "gray", "NEGATIVE": "red"}
        sns.countplot(x=sentiments, palette=colors, ax=ax1)
        ax1.set_title("Distribution of Sentiments")
        ax1.set_xlabel("Sentiment")
        ax1.set_ylabel("Count")

        # Plot star ratings
        ratings = [r["rating"] for r in self.results]
        sns.countplot(x=ratings, ax=ax2, color="blue")
        ax2.set_title("Distribution of Star Ratings")
        ax2.set_xlabel("Stars")
        ax2.set_ylabel("Count")

        plt.tight_layout()
        plt.savefig("sentiment_distribution.png")
        plt.close()

    def plot_confidence_histogram(self):
        """Plot histogram of confidence scores by sentiment"""
        if not self.results:
            print("No results to plot. Please analyze data first.")
            return

        confidences = [r["confidence"] for r in self.results]
        sentiments = [r["sentiment"] for r in self.results]

        plt.figure(figsize=(10, 6))
        colors = {"POSITIVE": "green", "NEUTRAL": "gray", "NEGATIVE": "red"}

        for sentiment in ["POSITIVE", "NEUTRAL", "NEGATIVE"]:
            sentiment_confidences = [
                conf for conf, sent in zip(confidences, sentiments) if sent == sentiment
            ]
            if sentiment_confidences:
                plt.hist(
                    sentiment_confidences,
                    bins=20,
                    alpha=0.5,
                    label=sentiment,
                    color=colors[sentiment],
                )

        plt.title("Distribution of Confidence Scores by Sentiment")
        plt.xlabel("Confidence Score")
        plt.ylabel("Frequency")
        plt.legend()
        plt.tight_layout()
        plt.savefig("confidence_distribution.png")
        plt.close()

    def generate_summary_report(self):
        """Generate a summary report of the analysis"""
        if not self.results:
            print("No results to summarize. Please analyze data first.")
            return

        sentiments = [r["sentiment"] for r in self.results]
        ratings = [r["rating"] for r in self.results]
        confidences = [r["confidence"] for r in self.results]

        total = len(self.results)
        positive_count = sentiments.count("POSITIVE")
        neutral_count = sentiments.count("NEUTRAL")
        negative_count = sentiments.count("NEGATIVE")

        report = f"""
Sentiment Analysis Summary Report
-------------------------------
Total texts analyzed: {total}
Positive sentiments: {positive_count} ({(positive_count/total)*100:.1f}%)
Neutral sentiments: {neutral_count} ({(neutral_count/total)*100:.1f}%)
Negative sentiments: {negative_count} ({(negative_count/total)*100:.1f}%)

Rating Distribution:
1 star: {ratings.count(1)} ({(ratings.count(1)/total)*100:.1f}%)
2 stars: {ratings.count(2)} ({(ratings.count(2)/total)*100:.1f}%)
3 stars: {ratings.count(3)} ({(ratings.count(3)/total)*100:.1f}%)
4 stars: {ratings.count(4)} ({(ratings.count(4)/total)*100:.1f}%)
5 stars: {ratings.count(5)} ({(ratings.count(5)/total)*100:.1f}%)

Average rating: {np.mean(ratings):.2f}

Confidence Scores:
Average confidence: {np.mean(confidences):.3f}
Median confidence: {np.median(confidences):.3f}
Min confidence: {min(confidences):.3f}
Max confidence: {max(confidences):.3f}
        """

        with open("sentiment_analysis_report.txt", "w") as f:
            f.write(report)

        print(report)
