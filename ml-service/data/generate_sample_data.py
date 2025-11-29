import pandas as pd
import numpy as np
from datetime import datetime, timedelta
import random

# Set random seed for reproducibility
np.random.seed(42)

# Generate sample data
num_samples = 1000
data = []

for i in range(num_samples):
    # Features
    hour_of_day = random.randint(6, 23)
    day_of_week = random.randint(0, 6)  # 0=Monday, 6=Sunday
    num_daily_meds = random.randint(1, 5)
    past_adherence_rate = round(random.uniform(0.3, 1.0), 2)
    hours_since_last_dose = random.randint(0, 24)
    is_weekend = 1 if day_of_week >= 5 else 0
    is_morning = 1 if 6 <= hour_of_day < 12 else 0
    is_evening = 1 if 18 <= hour_of_day < 23 else 0
    
    # Create adherence pattern based on realistic scenarios
    adherence_score = 0
    
    # Morning meds have better adherence
    if is_morning:
        adherence_score += 0.3
    
    # Weekends have lower adherence
    if is_weekend:
        adherence_score -= 0.2
    
    # Past adherence is strong predictor
    adherence_score += past_adherence_rate * 0.5
    
    # Too many meds reduces adherence
    if num_daily_meds > 3:
        adherence_score -= 0.15
    
    # Long time since last dose
    if hours_since_last_dose > 12:
        adherence_score -= 0.1
    
    # Add some randomness
    adherence_score += random.uniform(-0.2, 0.2)
    
    # Determine if adherent (1) or not (0)
    adherent = 1 if adherence_score > 0.5 else 0
    
    data.append({
        'hour_of_day': hour_of_day,
        'day_of_week': day_of_week,
        'num_daily_meds': num_daily_meds,
        'past_adherence_rate': past_adherence_rate,
        'hours_since_last_dose': hours_since_last_dose,
        'is_weekend': is_weekend,
        'is_morning': is_morning,
        'is_evening': is_evening,
        'adherent': adherent
    })

# Create DataFrame
df = pd.DataFrame(data)

# Save to CSV
df.to_csv('data/sample_data.csv', index=False)
print(f"Generated {num_samples} samples")
print(f"Adherence rate: {df['adherent'].mean():.2%}")
print("\nSample data:")
print(df.head(10))