import pandas as pd
import numpy as np
from sklearn.model_selection import train_test_split
from sklearn.ensemble import RandomForestClassifier
from sklearn.metrics import accuracy_score, classification_report, confusion_matrix
import joblib
import os

def train_adherence_model():
    print("Loading data...")
    # Load the data
    df = pd.read_csv('data/sample_data.csv')
    
    # Features and target
    feature_columns = [
        'hour_of_day',
        'day_of_week',
        'num_daily_meds',
        'past_adherence_rate',
        'hours_since_last_dose',
        'is_weekend',
        'is_morning',
        'is_evening'
    ]
    
    X = df[feature_columns]
    y = df['adherent']
    
    print(f"\nDataset shape: {X.shape}")
    print(f"Adherent: {y.sum()} ({y.mean():.2%})")
    print(f"Non-adherent: {len(y) - y.sum()} ({1 - y.mean():.2%})")
    
    # Split the data (80% for training, 20% for testing)
    X_train, X_test, y_train, y_test = train_test_split(
        X, y, test_size=0.2, random_state=42, stratify=y
    )
    
    print(f"\nTraining set: {X_train.shape[0]} samples")
    print(f"Test set: {X_test.shape[0]} samples")
    
    # Train Random Forest model
    print("\nTraining Random Forest model...")
    model = RandomForestClassifier(
        n_estimators=100,
        max_depth=10,
        min_samples_split=5,
        random_state=42,
        n_jobs=-1
    )
    
    model.fit(X_train, y_train)
    
    # Evaluate
    print("\n=== Model Evaluation ===")
    y_pred_train = model.predict(X_train)
    y_pred_test = model.predict(X_test)
    
    train_accuracy = accuracy_score(y_train, y_pred_train)
    test_accuracy = accuracy_score(y_test, y_pred_test)
    
    print(f"Training Accuracy: {train_accuracy:.4f}")
    print(f"Test Accuracy: {test_accuracy:.4f}")
    
    print("\n=== Classification Report ===")
    print(classification_report(y_test, y_pred_test, 
                                target_names=['Non-adherent', 'Adherent']))
    
    # Feature importance
    print("\n=== Feature Importance ===")
    feature_importance = pd.DataFrame({
        'feature': feature_columns,
        'importance': model.feature_importances_
    }).sort_values('importance', ascending=False)
    
    print(feature_importance)
    
    # Save the model
    os.makedirs('data', exist_ok=True)
    joblib.dump(model, 'data/trained_model.pkl')
    print("\n✓ Model saved to data/trained_model.pkl")
    
    # Save feature columns for later use
    joblib.dump(feature_columns, 'data/feature_columns.pkl')
    print("✓ Feature columns saved")
    
    return model

if __name__ == "__main__":
    model = train_adherence_model()