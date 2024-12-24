# main.py
from flask import Flask, request, jsonify
from sentiment_model import FlexibleSentimentAnalyzer
from flask_cors import CORS
import logging
from waitress import serve

app = Flask(__name__)
CORS(app)

analyzer = FlexibleSentimentAnalyzer()


@app.route("/test", methods=["GET"])
def test():
    return jsonify({"status": "running"})


# Set up logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)


@app.route("/analyze", methods=["POST"])
def analyze():
    print("Received request:", request.json)
    data = request.json
    if "text" not in data:
        return jsonify({"error": "Missing 'text' in request"}), 400

    text = data["text"]
    try:
        result = analyzer.analyze_text(text)
        return jsonify(result)
    except Exception as e:
        return jsonify({"error": str(e)}), 500


if __name__ == "__main__":
    logger.info("Starting Flask server...")
    try:
        # app.run(debug=True)
        serve(app)
        # serve(app, host="0.0.0.0", port=5000)

    except Exception as e:
        logger.error(f"Failed to start server: {e}")
