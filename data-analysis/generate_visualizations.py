import pandas as pd
import matplotlib.pyplot as plt
import seaborn as sns
import numpy as np
import os

# Set style
sns.set_style("whitegrid")
plt.rcParams['figure.figsize'] = (10, 6)
plt.rcParams['font.size'] = 10

class AdherenceVisualizer:
    def __init__(self, data_file='adherence_logs.csv'):
        self.df = pd.read_csv(data_file)
        self.output_dir = 'outputs/charts'
        os.makedirs(self.output_dir, exist_ok=True)
    
    def plot_overall_adherence(self):
        """Pie chart of overall adherence"""
        taken = len(self.df[self.df['status'] == 'taken'])
        missed = len(self.df[self.df['status'] == 'missed'])
        
        fig, ax = plt.subplots()
        colors = ['#4CAF50', '#F44336']
        ax.pie([taken, missed], labels=['Taken', 'Missed'], autopct='%1.1f%%',
               colors=colors, startangle=90)
        ax.set_title('Overall Medication Adherence', fontsize=14, fontweight='bold')
        
        plt.savefig(f'{self.output_dir}/overall_adherence.png', dpi=300, bbox_inches='tight')
        plt.close()
        print("✓ Generated: overall_adherence.png")
    
    def plot_time_of_day_adherence(self):
        """Bar chart of adherence by time of day"""
        time_mapping = {
            8: 'Morning\n(8 AM)',
            13: 'Afternoon\n(1 PM)',
            20: 'Evening\n(8 PM)'
        }
        
        adherence_by_time = []
        for hour in [8, 13, 20]:
            hour_data = self.df[self.df['hour_of_day'] == hour]
            if len(hour_data) > 0:
                rate = len(hour_data[hour_data['status'] == 'taken']) / len(hour_data) * 100
                adherence_by_time.append({'time': time_mapping[hour], 'rate': rate})
        
        df_time = pd.DataFrame(adherence_by_time)
        
        fig, ax = plt.subplots()
        bars = ax.bar(df_time['time'], df_time['rate'], color=['#FFC107', '#2196F3', '#9C27B0'])
        ax.set_ylabel('Adherence Rate (%)', fontweight='bold')
        ax.set_title('Adherence Rate by Time of Day', fontsize=14, fontweight='bold')
        ax.set_ylim(0, 100)
        
        # Add value labels on bars
        for bar in bars:
            height = bar.get_height()
            ax.text(bar.get_x() + bar.get_width()/2., height,
                   f'{height:.1f}%', ha='center', va='bottom', fontweight='bold')
        
        plt.savefig(f'{self.output_dir}/time_of_day_adherence.png', dpi=300, bbox_inches='tight')
        plt.close()
        print("✓ Generated: time_of_day_adherence.png")
    
    def plot_day_of_week_adherence(self):
        """Line chart of adherence by day of week"""
        days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun']
        adherence_rates = []
        
        for day_num in range(7):
            day_data = self.df[self.df['day_of_week'] == day_num]
            if len(day_data) > 0:
                rate = len(day_data[day_data['status'] == 'taken']) / len(day_data) * 100
                adherence_rates.append(rate)
            else:
                adherence_rates.append(0)
        
        fig, ax = plt.subplots()
        ax.plot(days, adherence_rates, marker='o', linewidth=2, markersize=8, color='#3F51B5')
        ax.fill_between(range(7), adherence_rates, alpha=0.3, color='#3F51B5')
        ax.set_ylabel('Adherence Rate (%)', fontweight='bold')
        ax.set_xlabel('Day of Week', fontweight='bold')
        ax.set_title('Adherence Rate by Day of Week', fontsize=14, fontweight='bold')
        ax.set_ylim(0, 100)
        ax.grid(True, alpha=0.3)
        
        # Highlight weekends
        ax.axvspan(4.5, 6.5, alpha=0.1, color='red', label='Weekend')
        ax.legend()
        
        plt.savefig(f'{self.output_dir}/day_of_week_adherence.png', dpi=300, bbox_inches='tight')
        plt.close()
        print("✓ Generated: day_of_week_adherence.png")
    
    def plot_user_comparison(self, top_n=10):
        """Bar chart comparing user adherence rates"""
        user_rates = []
        for user_id in self.df['user_id'].unique()[:top_n]:
            user_data = self.df[self.df['user_id'] == user_id]
            rate = len(user_data[user_data['status'] == 'taken']) / len(user_data) * 100
            user_rates.append({'user': user_id, 'rate': rate})
        
        df_users = pd.DataFrame(user_rates).sort_values('rate', ascending=False)
        
        fig, ax = plt.subplots(figsize=(12, 6))
        colors = plt.cm.viridis(np.linspace(0, 1, len(df_users)))
        bars = ax.barh(df_users['user'], df_users['rate'], color=colors)
        ax.set_xlabel('Adherence Rate (%)', fontweight='bold')
        ax.set_title('User Adherence Comparison', fontsize=14, fontweight='bold')
        ax.set_xlim(0, 100)
        
        # Add value labels
        for i, (bar, rate) in enumerate(zip(bars, df_users['rate'])):
            ax.text(rate + 1, i, f'{rate:.1f}%', va='center', fontweight='bold')
        
        plt.savefig(f'{self.output_dir}/user_comparison.png', dpi=300, bbox_inches='tight')
        plt.close()
        print("✓ Generated: user_comparison.png")
    
    def plot_weekly_trends(self):
        """Line chart of weekly adherence trends"""
        self.df['scheduled_time'] = pd.to_datetime(self.df['scheduled_time'])
        self.df['week'] = self.df['scheduled_time'].dt.isocalendar().week
        
        weekly_rates = []
        for week in sorted(self.df['week'].unique())[-8:]:  # Last 8 weeks
            week_data = self.df[self.df['week'] == week]
            rate = len(week_data[week_data['status'] == 'taken']) / len(week_data) * 100
            weekly_rates.append({'week': week, 'rate': rate})
        
        df_weekly = pd.DataFrame(weekly_rates)
        
        fig, ax = plt.subplots()
        ax.plot(df_weekly['week'], df_weekly['rate'], marker='o', linewidth=2.5, 
               markersize=10, color='#E91E63')
        ax.fill_between(df_weekly['week'], df_weekly['rate'], alpha=0.3, color='#E91E63')
        ax.set_xlabel('Week Number', fontweight='bold')
        ax.set_ylabel('Adherence Rate (%)', fontweight='bold')
        ax.set_title('Weekly Adherence Trends', fontsize=14, fontweight='bold')
        ax.set_ylim(0, 100)
        ax.grid(True, alpha=0.3)
        
        plt.savefig(f'{self.output_dir}/weekly_trends.png', dpi=300, bbox_inches='tight')
        plt.close()
        print("✓ Generated: weekly_trends.png")
    
    def generate_all_visualizations(self):
        """Generate all visualization charts"""
        print("\nGenerating visualizations...")
        print("-" * 40)
        
        self.plot_overall_adherence()
        self.plot_time_of_day_adherence()
        self.plot_day_of_week_adherence()
        self.plot_user_comparison()
        self.plot_weekly_trends()
        
        print("-" * 40)
        print(f"✓ All charts saved to {self.output_dir}/")


# Main execution
if __name__ == "__main__":
    visualizer = AdherenceVisualizer()
    visualizer.generate_all_visualizations()