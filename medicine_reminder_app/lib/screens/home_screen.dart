import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/medication_provider.dart';
import '../services/api_service.dart';
import 'add_medication_screen.dart';
import 'analytics_screen.dart'; 

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final Set<String> _processedMedicationIds = {}; 

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      context.read<MedicationProvider>().loadMedications();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Medications'),
        actions: [
          // ✅ NEW: AI BRAIN BUTTON
          IconButton(
            icon: const Icon(Icons.lightbulb, color: Colors.orange),
            tooltip: 'Ask AI',
            onPressed: () => _askAI(context),
          ),
          IconButton(
            icon: const Icon(Icons.analytics),
            onPressed: () {
               Navigator.push(context, MaterialPageRoute(builder: (_) => const AnalyticsScreen()));
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              context.read<AuthProvider>().logout();
            },
          ),
        ],
      ),
      body: Consumer<MedicationProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.medications.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.medication_outlined, size: 80, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text('No medications added yet'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _navigateToAddMedication,
                    child: const Text('Add First Med'),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: provider.medications.length,
            itemBuilder: (context, index) {
              final med = provider.medications[index];
              final bool isProcessed = _processedMedicationIds.contains(med.id);

              return Card(
                elevation: 2,
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  leading: CircleAvatar(
                    backgroundColor: isProcessed ? Colors.grey.shade200 : Colors.blue.shade100,
                    child: Icon(
                      Icons.medication, 
                      color: isProcessed ? Colors.grey : Colors.blue
                    ),
                  ),
                  title: Text(
                    med.name, 
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      decoration: isProcessed ? TextDecoration.lineThrough : null,
                      color: isProcessed ? Colors.grey : Colors.black,
                    )
                  ),
                  subtitle: Text('${med.dosage} • ${med.times.join(", ")}'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.check_circle_outline, color: Colors.green, size: 28),
                        onPressed: isProcessed ? null : () => _logAction(med.id, 'taken'),
                      ),
                      IconButton(
                        icon: const Icon(Icons.cancel_outlined, color: Colors.redAccent, size: 28),
                        onPressed: isProcessed ? null : () => _logAction(med.id, 'missed'),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, color: Colors.grey, size: 20),
                        onPressed: () => _deleteMedication(med.id),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToAddMedication,
        child: const Icon(Icons.add),
      ),
    );
  }

  // ✅ UPDATED: Now uses REAL Adherence Stats
  Future<void> _askAI(BuildContext context) async {
    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      // 1. Get Medication Count
      final medCount = context.read<MedicationProvider>().medications.length;
      
      // 2. Get REAL Adherence Rate from Backend
      final stats = await ApiService.getAdherenceStats();
      final double adherenceRate = double.tryParse(stats['adherenceRate'].toString()) ?? 0.0;
      
      // Convert Percentage (100.0) to Decimal (1.0) for AI
      final double rateForAi = adherenceRate / 100.0;

      // 3. Call the AI API with Real Data
      final result = await ApiService.getAiPrediction(
        medsCount: medCount,
        pastAdherence: rateForAi, // Passing the real rate
      );
      
      // Close loading
      if (!mounted) return;
      Navigator.pop(context);

      final data = result['data'];
      final riskLevel = data['risk_level'];
      final score = data['risk_score'];

      // Show Result Dialog
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: Row(
            children: [
              const Icon(Icons.psychology, color: Colors.purple),
              const SizedBox(width: 10),
              const Text("AI Analysis"),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("Risk of Missing Dose:", style: TextStyle(color: Colors.grey[600])),
              Text(
                riskLevel.toString().toUpperCase(),
                style: TextStyle(
                  fontSize: 24, 
                  fontWeight: FontWeight.bold,
                  color: riskLevel == 'high' ? Colors.red : Colors.green,
                ),
              ),
              const SizedBox(height: 10),
              Text("The AI analyzed your behavior (Adherence: ${adherenceRate.toStringAsFixed(1)}%) and calculated a risk score of ${(score * 100).toStringAsFixed(1)}%."),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("Close"))
          ],
        ),
      );

    } catch (e) {
      Navigator.pop(context); // Close loading
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("AI Error: $e")));
    }
  }

  void _navigateToAddMedication() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AddMedicationScreen()),
    );
  }

  Future<void> _logAction(String id, String status) async {
    try {
      await ApiService.logAdherence(
        medicationId: id,
        scheduledTime: DateTime.now(),
        status: status,
        takenTime: DateTime.now(),
      );
      setState(() {
        _processedMedicationIds.add(id);
      });
      if (!mounted) return;
      String message = status == 'taken' ? 'Great job!' : 'Marked as missed.';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> _deleteMedication(String id) async {
    try {
      await context.read<MedicationProvider>().deleteMedication(id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Medication deleted')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }
}