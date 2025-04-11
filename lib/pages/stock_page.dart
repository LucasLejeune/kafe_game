import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
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
    final total =
        items.values.fold(0.0, (sum, item) => sum + (item as num).toDouble());
    return double.parse(total.toStringAsFixed(3));
  }

  @override
  Widget build(BuildContext context) {
    double totalFruits = _calculateTotal(fruitsRecoltes);
    double totalGrains = _calculateTotal(grainsSeches);

    return GradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          iconTheme: const IconThemeData(color: Colors.white),
          backgroundColor: Colors.transparent,
          title: const Text('Mon stock', style: TextStyle(color: Colors.white)),
        ),
        body: SingleChildScrollView(
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
                  : _buildDetailList(fruitsRecoltes, isFruit: true),
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
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
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

  Widget _buildDetailList(Map<String, dynamic> items, {bool isFruit = false}) {
    return Column(
      children: items.entries.map((entry) {
        return Card(
          child: ListTile(
            title: Text(entry.key),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('${entry.value} kg'),
                if (isFruit)
                  IconButton(
                    icon: const FaIcon(FontAwesomeIcons.fire,
                        size: 25, color: Colors.orange),
                    onPressed: () => _openSechageModal(entry.key, entry.value),
                  ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  void _openSechageModal(String kafeName, double maxPoids) {
    final TextEditingController _poidsController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Sécher $kafeName'),
          content: TextField(
            controller: _poidsController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'Poids à sécher (max $maxPoids kg)',
            ),
          ),
          actions: [
            TextButton(
              child: const Text('Annuler'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            ElevatedButton(
              child: const Text('Sécher'),
              onPressed: () async {
                final poids = double.tryParse(_poidsController.text);
                if (poids == null || poids <= 0 || poids > maxPoids) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Poids invalide')),
                  );
                  return;
                }

                Navigator.of(context).pop();
                await _secherFruit(kafeName, poids);
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _secherFruit(String kafeName, double poids) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final joueurRef = _firestore.collection('joueurs').doc(user.uid);

    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(joueurRef);
      final data = snapshot.data() as Map<String, dynamic>;

      final fruits = Map<String, dynamic>.from(data['fruits_recoltes'] ?? {});
      final grains = Map<String, dynamic>.from(data['grains_seches'] ?? {});

      final currentFruit = (fruits[kafeName] ?? 0) as double;
      final currentGrain = (grains[kafeName] ?? 0) as double;

      if (poids > currentFruit) {
        throw Exception('Poids à sécher supérieur au stock disponible.');
      }

      double fruitValue = currentFruit - poids;

      fruits[kafeName] = double.parse(fruitValue.toStringAsFixed(3));
      if (fruits[kafeName] == 0) {
        fruits.remove(kafeName);
      }

      double grainValue = (currentGrain + poids) * 0.542;

      grains[kafeName] = double.parse(grainValue.toStringAsFixed(3));

      transaction.update(joueurRef, {
        'fruits_recoltes': fruits,
        'grains_seches': grains,
      });
    });

    await _fetchStockData();
  }
}
