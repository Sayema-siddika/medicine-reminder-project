import json
from analyze_adherence import AdherenceAnalyzer

# Generate comprehensive data for mobile app dashboard
analyzer = AdherenceAnalyzer()
report = analyzer.generate_full_report()

# Create simplified dashboard data
dashboard_data = {
    'summary': {
        'adherence_rate': report['overall_adherence']['adherence_rate'],
        'total_doses': report['overall_adherence']['total_doses'],
        'streak_days': 7  # Calculate this from consecutive days
    },
    'weekly_progress': [
        {'day': 'Mon', 'rate': report['by_day_of_week'].get('Monday', {}).get('rate', 0)},
        {'day': 'Tue', 'rate': report['by_day_of_week'].get('Tuesday', {}).get('rate', 0)},
        {'day': 'Wed', 'rate': report['by_day_of_week'].get('Wednesday', {}).get('rate', 0)},
        {'day': 'Thu', 'rate': report['by_day_of_week'].get('Thursday', {}).get('rate', 0)},
        {'day': 'Fri', 'rate': report['by_day_of_week'].get('Friday', {}).get('rate', 0)},
        {'day': 'Sat', 'rate': report['by_day_of_week'].get('Saturday', {}).get('rate', 0)},
        {'day': 'Sun', 'rate': report['by_day_of_week'].get('Sunday', {}).get('rate', 0)}
    ],
    'best_time': max(report['by_time_of_day'].items(), key=lambda x: x[1]['rate'])[0]
}

# Save for use in mobile app
with open('outputs/dashboard_data.json', 'w') as f:
    json.dump(dashboard_data, f, indent=2)

print("✓ Dashboard data exported")
print(json.dumps(dashboard_data, indent=2))