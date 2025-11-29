import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/api_service.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  bool _isLoading = true;
  Map<String, dynamic>? _stats;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    try {
      final data = await ApiService.getAdherenceStats();
      if (mounted) {
        setState(() {
          _stats = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Progress')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(child: Text('Error: $_errorMessage'))
              : _buildContent(),
    );
  }

  Widget _buildContent() {
    if (_stats == null) return const Center(child: Text("No data available"));

    // Parse values safely
    final double rate = double.tryParse(_stats!['adherenceRate'].toString()) ?? 0.0;
    final int taken = _stats!['taken'] ?? 0;
    final int skipped = _stats!['skipped'] ?? 0;
    final int missed = _stats!['missed'] ?? 0;
    final int total = _stats!['total'] ?? 1; // avoid divide by zero

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          // 1. Large Percentage Card
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  const Text("Overall Adherence", style: TextStyle(fontSize: 18, color: Colors.grey)),
                  const SizedBox(height: 10),
                  Text(
                    "${rate.toStringAsFixed(1)}%",
                    style: TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      color: _getColorForRate(rate),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // 2. Pie Chart Section
          SizedBox(
            height: 200,
            child: PieChart(
              PieChartData(
                sections: [
                  PieChartSectionData(
                    value: taken.toDouble(),
                    title: 'Taken',
                    color: Colors.green,
                    radius: 50,
                    titleStyle: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  PieChartSectionData(
                    value: missed.toDouble(),
                    title: 'Missed',
                    color: Colors.red,
                    radius: 50,
                    titleStyle: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  PieChartSectionData(
                    value: skipped.toDouble(),
                    title: 'Skip',
                    color: Colors.orange,
                    radius: 50,
                    titleStyle: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ],
                centerSpaceRadius: 40,
                sectionsSpace: 2,
              ),
            ),
          ),
          const SizedBox(height: 24),

          // 3. Detailed Stats List
          _buildStatRow('Total Doses Scheduled', total.toString(), Icons.calendar_today, Colors.blue),
          _buildStatRow('Taken', taken.toString(), Icons.check_circle, Colors.green),
          _buildStatRow('Missed', missed.toString(), Icons.cancel, Colors.red),
          _buildStatRow('Skipped', skipped.toString(), Icons.skip_next, Colors.orange),
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, String value, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 16),
          Text(label, style: const TextStyle(fontSize: 16)),
          const Spacer(),
          Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Color _getColorForRate(double rate) {
    if (rate >= 80) return Colors.green;
    if (rate >= 50) return Colors.orange;
    return Colors.red;
  }
}