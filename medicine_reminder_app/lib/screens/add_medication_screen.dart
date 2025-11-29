import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/medication.dart';
import '../providers/medication_provider.dart';
import '../services/api_service.dart'; // Need this to talk to AI

class AddMedicationScreen extends StatefulWidget {
  const AddMedicationScreen({super.key});

  @override
  State<AddMedicationScreen> createState() => _AddMedicationScreenState();
}

class _AddMedicationScreenState extends State<AddMedicationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _dosageController = TextEditingController();
  final _notesController = TextEditingController();
  
  String _frequency = 'daily';
  final List<TimeOfDay> _selectedTimes = [const TimeOfDay(hour: 8, minute: 0)];
  bool _isSuggesting = false; // Loading state for AI

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Medication')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Medicine Name', border: OutlineInputBorder()),
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _dosageController,
                decoration: const InputDecoration(labelText: 'Dosage (e.g., 500mg)', border: OutlineInputBorder()),
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _frequency,
                decoration: const InputDecoration(labelText: 'Frequency', border: OutlineInputBorder()),
                items: ['daily', 'weekly', 'twice_daily'].map((f) {
                  return DropdownMenuItem(value: f, child: Text(f.toUpperCase()));
                }).toList(),
                onChanged: (v) => setState(() => _frequency = v!),
              ),
              const SizedBox(height: 24),
              
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Reminder Times', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  
                  // ✅ AI SUGGESTION BUTTON
                  TextButton.icon(
                    onPressed: _isSuggesting ? null : _getAiSuggestion,
                    icon: _isSuggesting 
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.auto_awesome, color: Colors.purple),
                    label: Text(_isSuggesting ? "Thinking..." : "Suggest Best Time"),
                  ),
                ],
              ),
              
              ..._selectedTimes.asMap().entries.map((entry) {
                int idx = entry.key;
                TimeOfDay time = entry.value;
                return ListTile(
                  title: Text(time.format(context)),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () {
                      setState(() => _selectedTimes.removeAt(idx));
                    },
                  ),
                  onTap: () async {
                    final newTime = await showTimePicker(context: context, initialTime: time);
                    if (newTime != null) {
                      setState(() => _selectedTimes[idx] = newTime);
                    }
                  },
                );
              }),
              TextButton.icon(
                icon: const Icon(Icons.add_alarm),
                label: const Text('Add Another Time'),
                onPressed: () async {
                  final newTime = await showTimePicker(
                    context: context, 
                    initialTime: const TimeOfDay(hour: 12, minute: 0)
                  );
                  if (newTime != null) {
                    setState(() => _selectedTimes.add(newTime));
                  }
                },
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _saveMedication,
                child: const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text('Save Medication'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ✅ FUNCTION TO CALL AI
  Future<void> _getAiSuggestion() async {
    setState(() => _isSuggesting = true);

    try {
      // 1. Get user stats
      final stats = await ApiService.getAdherenceStats();
      final double adherenceRate = double.tryParse(stats['adherenceRate'].toString()) ?? 0.0;
      final int currentMeds = context.read<MedicationProvider>().medications.length;

      // 2. Call Python AI
      final suggestedTime = await ApiService.getOptimalTime(
        medsCount: currentMeds, 
        pastAdherence: adherenceRate / 100.0
      );

      if (!mounted) return;

      // 3. Apply suggestion
      final parts = suggestedTime.split(':');
      final hour = int.parse(parts[0]);
      final minute = int.parse(parts[1]);

      setState(() {
        _selectedTimes.clear();
        _selectedTimes.add(TimeOfDay(hour: hour, minute: minute));
        _isSuggesting = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("✨ AI suggests $suggestedTime based on your history!"),
          backgroundColor: Colors.purple,
        ),
      );

    } catch (e) {
      setState(() => _isSuggesting = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("AI Error: $e")));
    }
  }

  Future<void> _saveMedication() async {
    if (_formKey.currentState!.validate() && _selectedTimes.isNotEmpty) {
      List<String> formattedTimes = _selectedTimes.map((t) {
        final hour = t.hour.toString().padLeft(2, '0');
        final minute = t.minute.toString().padLeft(2, '0');
        return '$hour:$minute';
      }).toList();

      final newMed = Medication(
        id: '', 
        userId: '', 
        name: _nameController.text,
        dosage: _dosageController.text,
        frequency: _frequency,
        times: formattedTimes,
        startDate: DateTime.now(),
        notes: _notesController.text,
      );

      try {
        await context.read<MedicationProvider>().addMedication(newMed);
        if (!mounted) return;
        Navigator.pop(context); 
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }
}