import joblib
import numpy as np
from datetime import datetime

class AdherencePredictor:
    def __init__(self, model_path='data/trained_model.pkl'):
        self.model = joblib.load(model_path)
        self.feature_columns = joblib.load('data/feature_columns.pkl')
    
    def prepare_features(self, data):
        """
        Prepare features from input data
        
        Expected input format:
        {
            'hour_of_day': int (0-23),
            'day_of_week': int (0-6),
            'num_daily_meds': int,
            'past_adherence_rate': float (0-1),
            'hours_since_last_dose': int
        }
        """
        hour = data.get('hour_of_day', datetime.now().hour)
        day = data.get('day_of_week', datetime.now().weekday())
        
        features = {
            'hour_of_day': hour,
            'day_of_week': day,
            'num_daily_meds': data.get('num_daily_meds', 1),
            'past_adherence_rate': data.get('past_adherence_rate', 0.8),
            'hours_since_last_dose': data.get('hours_since_last_dose', 8),
            'is_weekend': 1 if day >= 5 else 0,
            'is_morning': 1 if 6 <= hour < 12 else 0,
            'is_evening': 1 if 18 <= hour < 23 else 0
        }
        
        # Create feature array in correct order
        feature_array = np.array([[features[col] for col in self.feature_columns]])
        return feature_array
    
    def predict_adherence(self, data):
        """
        Predict adherence probability
        
        Returns:
        {
            'will_adhere': bool,
            'adherence_probability': float,
            'risk_level': str,
            'risk_score': float
        }
        """
        features = self.prepare_features(data)
        
        # Get prediction and probability
        prediction = self.model.predict(features)[0]
        probability = self.model.predict_proba(features)[0]
        
        adherence_prob = probability[1]  # Probability of adherence
        risk_score = 1 - adherence_prob  # Risk of non-adherence
        
        # Determine risk level
        if risk_score < 0.3:
            risk_level = 'low'
        elif risk_score < 0.6:
            risk_level = 'medium'
        else:
            risk_level = 'high'
        
        return {
            'will_adhere': bool(prediction),
            'adherence_probability': round(float(adherence_prob), 3),
            'risk_level': risk_level,
            'risk_score': round(float(risk_score), 3)
        }
    
    def suggest_optimal_time(self, num_daily_meds, past_adherence_rate):
        """
        Suggest optimal reminder times based on adherence patterns
        """
        # Test different times of day
        hours_to_test = [7, 8, 9, 13, 14, 19, 20, 21]
        suggestions = []
        
        for hour in hours_to_test:
            data = {
                'hour_of_day': hour,
                'day_of_week': 2,  # Mid-week
                'num_daily_meds': num_daily_meds,
                'past_adherence_rate': past_adherence_rate,
                'hours_since_last_dose': 8
            }
            
            result = self.predict_adherence(data)
            suggestions.append({
                'time': f"{hour:02d}:00",
                'adherence_probability': result['adherence_probability']
            })
        
        # Sort by probability
        suggestions.sort(key=lambda x: x['adherence_probability'], reverse=True)
        
        return suggestions[:3]  # Return top 3