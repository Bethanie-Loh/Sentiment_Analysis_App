# main.py
from flask import Flask, request, jsonify, send_file
from model import SentimentAnalyzer
import pandas as pd
import os
from werkzeug.utils import secure_filename
import logging
from datetime import datetime

app = Flask(__name__)

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Configure upload folder
UPLOAD_FOLDER = "uploads"
RESULTS_FOLDER = "results"
ALLOWED_EXTENSIONS = {"csv"}

# Create folders if they don't exist
os.makedirs(UPLOAD_FOLDER, exist_ok=True)
os.makedirs(RESULTS_FOLDER, exist_ok=True)


def allowed_file(filename):
    return "." in filename and filename.rsplit(".", 1)[1].lower() in ALLOWED_EXTENSIONS


@app.route("/analyze", methods=["POST"])
def analyze_csv():
    try:
        # Check if file is present in request
        if "file" not in request.files:
            return jsonify({"error": "No file provided"}), 400

        file = request.files["file"]
        if file.filename == "":
            return jsonify({"error": "No file selected"}), 400

        if not allowed_file(file.filename):
            return (
                jsonify({"error": "Invalid file type. Only CSV files are allowed"}),
                400,
            )

        # Get text column name from request
        text_column = request.form.get("text_column", "comment")

        # Generate unique filename
        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        filename = secure_filename(f"{timestamp}_{file.filename}")

        # Save uploaded file
        file_path = os.path.join(UPLOAD_FOLDER, filename)
        file.save(file_path)

        # Read CSV
        df = pd.read_csv(file_path)

        # Check if text column exists
        if text_column not in df.columns:
            return (
                jsonify(
                    {
                        "error": f'Column "{text_column}" not found in CSV. Available columns: {", ".join(df.columns)}'
                    }
                ),
                400,
            )

        # Initialize analyzer and process data
        analyzer = SentimentAnalyzer()
        df = analyzer.analyze_dataframe(df, text_column)

        # Generate visualizations
        analyzer.plot_sentiment_distribution()
        analyzer.plot_confidence_histogram()
        analyzer.generate_summary_report()

        # Save results
        result_filename = f"analyzed_{filename}"
        result_path = os.path.join(RESULTS_FOLDER, result_filename)
        df.to_csv(result_path, index=False)

        # Get summary statistics
        sentiment_counts = df["sentiment"].value_counts().to_dict()
        confidence_stats = {
            "mean": float(df["confidence"].mean()),
            "median": float(df["confidence"].median()),
            "min": float(df["confidence"].min()),
            "max": float(df["confidence"].max()),
        }

        # Return results
        return (
            jsonify(
                {
                    "status": "success",
                    "message": "Analysis completed successfully",
                    "result_file": result_filename,
                    "statistics": {
                        "sentiment_counts": sentiment_counts,
                        "confidence_stats": confidence_stats,
                    },
                }
            ),
            200,
        )

    except Exception as e:
        logger.error(f"Error processing file: {str(e)}")
        return jsonify({"error": str(e)}), 500


@app.route("/download/<filename>", methods=["GET"])
def download_file(filename):
    try:
        return send_file(
            os.path.join(RESULTS_FOLDER, filename),
            as_attachment=True,
            download_name=filename,
        )
    except Exception as e:
        return jsonify({"error": f"File not found: {str(e)}"}), 404


@app.route("/visualization/<filename>", methods=["GET"])
def get_visualization(filename):
    try:
        return send_file(filename, mimetype="image/png")
    except Exception as e:
        return jsonify({"error": f"File not found: {str(e)}"}), 404


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)
