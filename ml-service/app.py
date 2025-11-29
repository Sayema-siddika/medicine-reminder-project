from flask import Flask, request, jsonify
from flask_cors import CORS
from model.predictor import AdherencePredictor
import pandas as pd
import numpy as np
import os
from datetime import datetime

app = Flask(__name__)
CORS(app)

# Initialize predictor
try:
    predictor = AdherencePredictor()
    print("✓ Model loaded successfully")
except Exception as e:
    print(f"✗ Error loading model: {e}")
    predictor = None

@app.route('/health', methods=['GET'])
def health():
    return jsonify({
        'status': 'OK',
        'model_loaded': predictor is not None
    })

@app.route('/predict', methods=['POST'])
def predict():
    """
    Predict adherence risk
    """
    if not predictor:
        return jsonify({'error': 'Model not loaded'}), 500
    
    try:
        data = request.json
        result = predictor.predict_adherence(data)
        return jsonify({
            'success': True,
            'prediction': result
        })
    except Exception as e:
        return jsonify({
            'success': False,
            'error': str(e)
        }), 400

@app.route('/suggest-times', methods=['POST'])
def suggest_times():
    """
    Suggest optimal reminder times
    """
    if not predictor:
        return jsonify({'error': 'Model not loaded'}), 500
    
    try:
        data = request.json
        num_meds = data.get('num_daily_meds', 1)
        past_rate = data.get('past_adherence_rate', 0.8)
        
        suggestions = predictor.suggest_optimal_time(num_meds, past_rate)
        
        return jsonify({
            'success': True,
            'suggested_times': suggestions
        })
    except Exception as e:
        return jsonify({
            'success': False,
            'error': str(e)
        }), 400

# ---------------------------------------------------------
# NEW: Analytics Endpoint for Real-time Charts
# ---------------------------------------------------------
@app.route('/analyze', methods=['POST'])
def analyze_data():
    """
    Analyzes user logs to return data for charts.
    Expected Input: { "logs": [ { "status": "taken", "scheduledTime": "...", "date": "..." }, ... ] }
    """
    try:
        req_data = request.json
        logs = req_data.get('logs', [])

        # 1. Handle empty data
        if not logs:
            return jsonify({
                "adherence_rate": 0,
                "total_doses": 0,
                "weekly_trend": {},
                "time_of_day_stats": {}
            })

        # 2. Convert to DataFrame
        df = pd.DataFrame(logs)

        # Ensure 'status' column exists
        if 'status' not in df.columns:
            return jsonify({"error": "Data missing 'status' field"}), 400

        # 3. Calculate Overall Adherence Rate
        total_doses = len(df)
        taken_doses = len(df[df['status'] == 'taken'])
        adherence_rate = (taken_doses / total_doses) * 100 if total_doses > 0 else 0

        # 4. Process Dates for Weekly Trend
        # Assuming incoming date format is ISO or standard string. Adjust if necessary.
        # We try to convert 'date' or 'scheduledTime' to datetime objects
        date_col = 'date' if 'date' in df.columns else 'scheduledTime'
        if date_col in df.columns:
            df[date_col] = pd.to_datetime(df[date_col], errors='coerce')
            
            # Extract Day Name (Monday, Tuesday...)
            df['day_name'] = df[date_col].dt.day_name()
            
            # Count 'taken' doses per day
            weekly_trend = df[df['status'] == 'taken']['day_name'].value_counts().to_dict()
            
            # Extract Hour for Time of Day
            df['hour'] = df[date_col].dt.hour
            
            # 5. Calculate Time of Day Patterns
            def get_time_of_day(hour):
                if 5 <= hour < 12: return 'Morning'
                elif 12 <= hour < 17: return 'Afternoon'
                elif 17 <= hour < 22: return 'Evening'
                else: return 'Night'
            
            df['time_period'] = df['hour'].apply(get_time_of_day)
            time_of_day_stats = df[df['status'] == 'taken']['time_period'].value_counts().to_dict()
        else:
            weekly_trend = {}
            time_of_day_stats = {}

        # 6. Return JSON for Flutter to render
        return jsonify({
            "adherence_rate": round(adherence_rate, 2),
            "total_doses": total_doses,
            "weekly_trend": weekly_trend,       # e.g., {"Monday": 5, "Tuesday": 3}
            "time_of_day_stats": time_of_day_stats # e.g., {"Morning": 10, "Evening": 2}
        })

    except Exception as e:
        print(f"Analytics Error: {e}")
        return jsonify({"error": str(e)}), 500

if __name__ == '__main__':
    # Use PORT environment variable for Render, default to 5000 for local
    port = int(os.environ.get('PORT', 5000))
    app.run(host='0.0.0.0', port=port)