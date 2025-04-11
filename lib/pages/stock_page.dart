import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kafe_game/widgets/gradient_background.dart';

class StockPage extends StatefulWidget {
  @override
  _StockPageState createState() => _StockPageState();
}

class _StockPageState extends State<StockPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  Map<String, dynamic> fruitsRecoltes = {};
  Map<String, dynamic> grainsSeches = {};

  @override
  void initState() {
    super.initState();
    _fetchStockData();
  }

  Future<void> _fetchStockData() async {
    final user = _auth.currentUser;
    if (user == null) return;

    final joueurRef = _firestore.collection('joueurs').doc(user.uid);
    final joueurSnap = await joueurRef.get();

    setState(() {
      fruitsRecoltes =
          Map<String, dynamic>.from(joueurSnap['fruits_recoltes'] ?? {});
      grainsSeches =
          Map<String, dynamic>.from(joueurSnap['grains_seches'] ?? {});
    });
  }

  double _calculateTotal(Map<String, dynamic> items) {
    return items.values
        .fold(0.0, (sum, item) => sum + (item as num).toDouble());
  }

  @override
  Widget build(BuildContext context) {
    double totalFruits = _calculateTotal(fruitsRecoltes);
    double totalGrains = _calculateTotal(grainsSeches);

    return GradientBackground(
        child: Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        iconTheme: const IconThemeData(
          color: Colors.white,
        ),
        backgroundColor: Colors.transparent,
        title: const Text('Mon stock', style: TextStyle(color: Colors.white)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Total d\'objets',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _buildTotalCard('Fruits', totalFruits),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildTotalCard('Graines', totalGrains),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'Fruits',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white),
            ),
            const SizedBox(height: 8),
            fruitsRecoltes.isEmpty
                ? const Text(
                    'Vous n\'avez aucun fruit',
                    style: TextStyle(color: Colors.white),
                  )
                : _buildDetailList(fruitsRecoltes),
            const SizedBox(height: 16),
            const Text(
              'Graines',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white),
            ),
            const SizedBox(height: 8),
            grainsSeches.isEmpty
                ? const Text(
                    'Vous n\'avez aucune graine',
                    style: TextStyle(color: Colors.white),
                  )
                : _buildDetailList(grainsSeches),
          ],
        ),
      ),
    ));
  }

  Widget _buildTotalCard(String title, double total) {
    return Card(
      color: const Color(0xFFF59E0B),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
              '$total kg',
              style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white),
            ),
            Text(
              title,
              style: const TextStyle(fontSize: 16, color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailList(Map<String, dynamic> items) {
    return Column(
      children: items.entries.map((entry) {
        return Card(
          child: ListTile(
            title: Text(entry.key),
            trailing: Text('${entry.value} kg'),
          ),
        );
      }).toList(),
    );
  }
}
