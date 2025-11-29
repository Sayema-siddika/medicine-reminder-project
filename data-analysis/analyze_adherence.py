import pandas as pd
import numpy as np
from datetime import datetime, timedelta
import json

class AdherenceAnalyzer:
    def __init__(self, adherence_logs_file='adherence_logs.csv'):
        """
        Initialize with adherence logs data
        
        CSV should have columns: user_id, medication_id, scheduled_time, 
        taken_time, status, day_of_week, hour_of_day
        """
        try:
            self.df = pd.read_csv(adherence_logs_file)
            print(f"✓ Loaded {len(self.df)} records")
        except FileNotFoundError:
            print("⚠ Data file not found. Generating sample data...")
            self.df = self._generate_sample_data()
            self.df.to_csv(adherence_logs_file, index=False)
            print(f"✓ Generated {len(self.df)} sample records")
    
    def _generate_sample_data(self, n_records=500):
        """Generate sample adherence data for testing"""
        np.random.seed(42)
        data = []
        
        for i in range(n_records):
            day_of_week = np.random.randint(0, 7)
            hour = np.random.choice([8, 13, 20], p=[0.4, 0.3, 0.3])
            
            # Create realistic adherence patterns
            base_adherence = 0.75
            if day_of_week >= 5:  # Weekend
                base_adherence -= 0.15
            if hour == 8:  # Morning better
                base_adherence += 0.1
            
            status = 'taken' if np.random.random() < base_adherence else 'missed'
            
            scheduled = datetime.now() - timedelta(days=n_records-i)
            taken = scheduled + timedelta(minutes=np.random.randint(-30, 120)) if status == 'taken' else None
            
            data.append({
                'user_id': f'user_{np.random.randint(1, 11)}',
                'medication_id': f'med_{np.random.randint(1, 6)}',
                'scheduled_time': scheduled.strftime('%Y-%m-%d %H:%M:%S'),
                'taken_time': taken.strftime('%Y-%m-%d %H:%M:%S') if taken else None,
                'status': status,
                'day_of_week': day_of_week,
                'hour_of_day': hour
            })
        
        return pd.DataFrame(data)
    
    def overall_adherence_rate(self):
        """Calculate overall adherence rate"""
        total = len(self.df)
        taken = len(self.df[self.df['status'] == 'taken'])
        rate = (taken / total * 100) if total > 0 else 0
        
        return {
            'total_doses': total,
            'taken': taken,
            'missed': total - taken,
            'adherence_rate': round(rate, 2)
        }
    
    def adherence_by_time_of_day(self):
        """Analyze adherence by time of day"""
        time_groups = {
            'Morning (6-12)': self.df[self.df['hour_of_day'].between(6, 11)],
            'Afternoon (12-18)': self.df[self.df['hour_of_day'].between(12, 17)],
            'Evening (18-24)': self.df[self.df['hour_of_day'].between(18, 23)]
        }
        
        results = {}
        for time_label, group in time_groups.items():
            if len(group) > 0:
                taken = len(group[group['status'] == 'taken'])
                rate = (taken / len(group) * 100)
                results[time_label] = {
                    'total': len(group),
                    'taken': taken,
                    'rate': round(rate, 2)
                }
        
        return results
    
    def adherence_by_day_of_week(self):
        """Analyze adherence by day of week"""
        days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday']
        results = {}
        
        for day_num, day_name in enumerate(days):
            day_data = self.df[self.df['day_of_week'] == day_num]
            if len(day_data) > 0:
                taken = len(day_data[day_data['status'] == 'taken'])
                rate = (taken / len(day_data) * 100)
                results[day_name] = {
                    'total': len(day_data),
                    'taken': taken,
                    'rate': round(rate, 2)
                }
        
        return results
    
    def user_adherence_ranking(self, top_n=10):
        """Rank users by adherence rate"""
        user_stats = []
        
        for user_id in self.df['user_id'].unique():
            user_data = self.df[self.df['user_id'] == user_id]
            total = len(user_data)
            taken = len(user_data[user_data['status'] == 'taken'])
            rate = (taken / total * 100) if total > 0 else 0
            
            user_stats.append({
                'user_id': user_id,
                'total_doses': total,
                'taken': taken,
                'adherence_rate': round(rate, 2)
            })
        
        # Sort by adherence rate
        user_stats.sort(key=lambda x: x['adherence_rate'], reverse=True)
        return user_stats[:top_n]
    
    def medication_adherence_comparison(self):
        """Compare adherence rates across medications"""
        med_stats = []
        
        for med_id in self.df['medication_id'].unique():
            med_data = self.df[self.df['medication_id'] == med_id]
            total = len(med_data)
            taken = len(med_data[med_data['status'] == 'taken'])
            rate = (taken / total * 100) if total > 0 else 0
            
            med_stats.append({
                'medication_id': med_id,
                'total_doses': total,
                'taken': taken,
                'adherence_rate': round(rate, 2)
            })
        
        med_stats.sort(key=lambda x: x['adherence_rate'], reverse=True)
        return med_stats
    
    def weekly_trend_analysis(self, weeks=4):
        """Analyze adherence trends over weeks"""
        self.df['scheduled_time'] = pd.to_datetime(self.df['scheduled_time'])
        self.df['week'] = self.df['scheduled_time'].dt.isocalendar().week
        
        weekly_stats = []
        for week in self.df['week'].unique()[-weeks:]:
            week_data = self.df[self.df['week'] == week]
            total = len(week_data)
            taken = len(week_data[week_data['status'] == 'taken'])
            rate = (taken / total * 100) if total > 0 else 0
            
            weekly_stats.append({
                'week': int(week),
                'total': total,
                'taken': taken,
                'rate': round(rate, 2)
            })
        
        return weekly_stats
    
    def generate_full_report(self):
        """Generate comprehensive analysis report"""
        report = {
            'overall_adherence': self.overall_adherence_rate(),
            'by_time_of_day': self.adherence_by_time_of_day(),
            'by_day_of_week': self.adherence_by_day_of_week(),
            'top_users': self.user_adherence_ranking(5),
            'medication_comparison': self.medication_adherence_comparison(),
            'weekly_trends': self.weekly_trend_analysis()
        }
        
        return report
    
    def print_report(self):
        """Print formatted analysis report"""
        report = self.generate_full_report()
        
        print("\n" + "="*60)
        print("MEDICATION ADHERENCE ANALYSIS REPORT")
        print("="*60)
        
        print("\n1. OVERALL ADHERENCE")
        print("-" * 40)
        overall = report['overall_adherence']
        print(f"Total Doses: {overall['total_doses']}")
        print(f"Taken: {overall['taken']}")
        print(f"Missed: {overall['missed']}")
        print(f"Adherence Rate: {overall['adherence_rate']}%")
        
        print("\n2. ADHERENCE BY TIME OF DAY")
        print("-" * 40)
        for time, stats in report['by_time_of_day'].items():
            print(f"{time}: {stats['rate']}% ({stats['taken']}/{stats['total']})")
        
        print("\n3. ADHERENCE BY DAY OF WEEK")
        print("-" * 40)
        for day, stats in report['by_day_of_week'].items():
            print(f"{day}: {stats['rate']}% ({stats['taken']}/{stats['total']})")
        
        print("\n4. TOP PERFORMING USERS")
        print("-" * 40)
        for i, user in enumerate(report['top_users'], 1):
            print(f"{i}. {user['user_id']}: {user['adherence_rate']}%")
        
        print("\n5. MEDICATION COMPARISON")
        print("-" * 40)
        for med in report['medication_comparison']:
            print(f"{med['medication_id']}: {med['adherence_rate']}%")
        
        print("\n6. WEEKLY TRENDS")
        print("-" * 40)
        for week_stat in report['weekly_trends']:
            print(f"Week {week_stat['week']}: {week_stat['rate']}%")
        
        print("\n" + "="*60)
    
    def export_report_json(self, filename='analysis_report.json'):
        """Export report as JSON"""
        report = self.generate_full_report()
        with open(filename, 'w') as f:
            json.dump(report, f, indent=2)
        print(f"✓ Report exported to {filename}")


# Main execution
if __name__ == "__main__":
    # Initialize analyzer
    analyzer = AdherenceAnalyzer()
    
    # Print comprehensive report
    analyzer.print_report()
    
    # Export JSON report
    analyzer.export_report_json('outputs/analysis_report.json')