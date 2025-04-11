import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:kafe_game/pages/planter_graines_page.dart';
import '../widgets/gradient_background.dart';
import 'dart:async';
import 'dart:math';

class MesChampsPage extends StatefulWidget {
  const MesChampsPage({Key? key}) : super(key: key);

  @override
  _MesChampsPageState createState() => _MesChampsPageState();
}

class _MesChampsPageState extends State<MesChampsPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  int _devee = 0;
  List<Map<String, dynamic>> _champs = [];
  bool _isLoading = true;
  Map<int, double> _progressions = {};
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _loadPlayerData();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      _updateProgressions();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _loadPlayerData() async {
    User? user = _auth.currentUser;
    if (user != null) {
      try {
        DocumentSnapshot joueurSnapshot =
            await _firestore.collection('joueurs').doc(user.uid).get();

        if (joueurSnapshot.exists) {
          _devee = joueurSnapshot['bourse'];
          List<dynamic> champsRefs = joueurSnapshot['champs'] ?? [];

          List<Map<String, dynamic>> champsList = [];

          for (var champRef in champsRefs) {
            if (champRef is DocumentReference) {
              DocumentSnapshot champSnap = await champRef.get();
              if (champSnap.exists) {
                String specificite = champSnap['specificite'];
                String champId = champSnap.id;
                List<dynamic> plansRefs = champSnap['plans'] ?? [];
                List<Map<String, dynamic>> plans = [];

                for (var planRef in plansRefs) {
                  if (planRef is DocumentReference) {
                    DocumentSnapshot planSnap = await planRef.get();
                    if (planSnap.exists) {
                      DateTime datePlantation =
                          (planSnap['date_plantation'] as Timestamp).toDate();
                      DocumentReference kafeRef = planSnap['kafe'];
                      DocumentSnapshot kafeSnap = await kafeRef.get();
                      int tempsPousse = kafeSnap['temps_pousse'];

                      plans.add({
                        'datePlantation': datePlantation,
                        'kafe': kafeSnap,
                        'tempsPousse': tempsPousse,
                        'quantite': planSnap['quantite'],
                        'planRef': planRef
                      });
                    }
                  }
                }

                champsList.add({
                  'id': champId,
                  'specificite': specificite,
                  'plans': plans,
                });
              }
            }
          }

          setState(() {
            _champs = champsList;
            _isLoading = false;
          });
        }
      } catch (e) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur de chargement : $e')),
        );
      }
    }
  }

  void _updateProgressions() {
    final now = DateTime.now();
    final newProgressions = <int, double>{};

    for (int i = 0; i < _champs.length; i++) {
      final champ = _champs[i];
      final plans = champ['plans'] as List<Map<String, dynamic>>;
      double maxProgress = 0;

      for (var plan in plans) {
        DateTime plantedAt = plan['datePlantation'];
        int tempsPousse = plan['tempsPousse'];
        String specificite = champ['specificite'];
        if (specificite == 'Temps / 2') {
          tempsPousse = tempsPousse ~/ 2;
        }
        DateTime harvestTime = plantedAt.add(Duration(minutes: tempsPousse));

        if (now.isBefore(harvestTime)) {
          double progress = now.difference(plantedAt).inSeconds /
              Duration(minutes: tempsPousse).inSeconds;
          maxProgress = progress.clamp(0.0, 1.0);
        }
      }

      newProgressions[i] = maxProgress;
    }

    setState(() {
      _progressions = newProgressions;
    });
  }

  String _buildRemainingTime(List<Map<String, dynamic>> plans, int index) {
    if (plans.isEmpty) {
      return '';
    }

    final now = DateTime.now();
    String remainingTimeText = '';

    for (var plan in plans) {
      DateTime plantedAt = plan['datePlantation'];
      int tempsPousse = plan['tempsPousse'];
      String specificite = _champs[index]['specificite'];
      if (specificite == 'Temps / 2') {
        tempsPousse = tempsPousse ~/ 2;
      }
      DateTime harvestTime = plantedAt.add(Duration(minutes: tempsPousse));

      if (now.isBefore(harvestTime)) {
        final remainingDuration = harvestTime.difference(now);
        final minutes = remainingDuration.inMinutes;
        final seconds = remainingDuration.inSeconds % 60;
        remainingTimeText = '${minutes}m ${seconds}s';
      }
    }

    return remainingTimeText;
  }

  Widget _buildEtatTexte(List<Map<String, dynamic>> plans, int index) {
    if (plans.isEmpty) {
      return const Text("Libre",
          style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Color.fromRGBO(37, 99, 235, 100),
              fontSize: 16));
    }

    bool allReady = true;
    for (var plan in plans) {
      DateTime plantedAt = plan['datePlantation'];
      int tempsPousse = plan['tempsPousse'];
      String specificite = _champs[index]['specificite'];
      if (specificite == 'Temps / 2') {
        tempsPousse = tempsPousse ~/ 2;
      }
      DateTime now = DateTime.now();
      DateTime harvestTime = plantedAt.add(Duration(minutes: tempsPousse));

      if (now.isBefore(harvestTime)) {
        allReady = false;
        break;
      }
    }

    return Text(
      allReady ? "Prêt à récolter" : "Planté",
      style: TextStyle(
        fontWeight: FontWeight.bold,
        color:
            allReady ? const Color.fromRGBO(5, 150, 105, 100) : Colors.orange,
        fontSize: 16,
      ),
    );
  }

  void _handleHarvest(int index) async {
    final champ = _champs[index];
    final planSnapshots = champ['plans'] as List<Map<String, dynamic>>;
    final user = _auth.currentUser;

    if (user == null) return;

    final joueurRef = _firestore.collection('joueurs').doc(user.uid);
    final joueurSnap = await joueurRef.get();
    Map<String, dynamic> fruitsRecoltes =
        Map<String, dynamic>.from(joueurSnap['fruits_recoltes'] ?? {});

    try {
      final kafeSnapshots = await Future.wait(
        planSnapshots.map((planSnap) async {
          if (planSnap.isNotEmpty) {
            return planSnap['kafe'] as DocumentSnapshot;
          }
          return null;
        }).toList(),
      );

      for (int i = 0; i < planSnapshots.length; i++) {
        final planSnap = planSnapshots[i];
        final kafeSnap = kafeSnapshots[i];

        if (planSnap.isNotEmpty && kafeSnap != null && kafeSnap.exists) {
          final kafeName = kafeSnap['nom'] as String;
          num productionFruit = kafeSnap['production_fruit'] as num;
          final nbPlants = planSnap['quantite'] as int;
          final datePlantation = planSnap['datePlantation'] as DateTime;
          final tempsPousse = planSnap['tempsPousse'] as int;
          final specificite = champ['specificite'];

          if (specificite == 'Rendement X2') {
            productionFruit *= 2;
          }

          final datePlantationDateTime = datePlantation;
          final now = DateTime.now();
          final elapsedMinutes =
              now.difference(datePlantationDateTime).inMinutes;

          double penalty = 1.0;
          if (elapsedMinutes > tempsPousse * 5) {
            penalty = 0.2;
          } else if (elapsedMinutes > tempsPousse * 3) {
            penalty = 0.5;
          } else if (elapsedMinutes > tempsPousse * 2) {
            penalty = 0.8;
          }

          final totalHarvest =
              (((productionFruit * nbPlants) * penalty) * 1000).round() / 1000;

          fruitsRecoltes[kafeName] =
              (fruitsRecoltes[kafeName] ?? 0) + totalHarvest;

          final planRef = planSnap['planRef'] as DocumentReference;
          await planRef.delete();

          final champRef = _firestore.collection('champs').doc(champ['id']);

          await champRef.update({
            'plans': FieldValue.arrayRemove([planSnap['planRef']]),
          });
        }
      }

      await joueurRef.update({
        'fruits_recoltes': fruitsRecoltes,
        'bourse': FieldValue.increment(10),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Récolte effectuée avec succès')),
      );

      _loadPlayerData();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors de la récolte: $e')),
      );
    }
  }

  Widget _buildActionWide(List<Map<String, dynamic>> plans, int index) {
    if (plans.isEmpty) {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
              backgroundColor: const Color.fromRGBO(37, 99, 235, 100)),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) =>
                      PlanterGrainesPage(champId: _champs[index]['id'])),
            );
          },
          child: const Text(
            "Planter",
            style: TextStyle(color: Colors.white),
          ),
        ),
      );
    }

    bool allReady = true;

    for (var plan in plans) {
      DateTime plantedAt = plan['datePlantation'];
      int tempsPousse = plan['tempsPousse'];
      String specificite = _champs[index]['specificite'];
      if (specificite == 'Temps / 2') {
        tempsPousse = tempsPousse ~/ 2;
      }
      DateTime now = DateTime.now();
      DateTime harvestTime = plantedAt.add(Duration(minutes: tempsPousse));

      if (now.isBefore(harvestTime)) {
        allReady = false;
      }
    }

    if (allReady) {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
              backgroundColor: const Color.fromRGBO(5, 150, 105, 100)),
          onPressed: () async {
            _handleHarvest(index);
          },
          child: const Text(
            "Récolter",
            style: TextStyle(color: Colors.white),
          ),
        ),
      );
    } else {
      return SizedBox(
        width: double.infinity,
        child: Column(
          children: [
            Align(
              alignment: Alignment.topRight,
              child: Text(
                _buildRemainingTime(plans, index),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ),
            const SizedBox(height: 4),
            LinearProgressIndicator(
              value: _progressions[index] ?? 0.0,
              backgroundColor: Colors.grey[300],
              color: Colors.orange,
              minHeight: 8,
            ),
          ],
        ),
      );
    }
  }

  Future<void> _acheterChamp() async {
    if (_devee >= 15) {
      User? user = _auth.currentUser;
      if (user != null) {
        try {
          DocumentReference joueurRef =
              _firestore.collection('joueurs').doc(user.uid);

          List<String> specificites = ["Neutre", "Rendement X2", "Temps / 2"];
          final random = Random();

          String newSpecificite =
              specificites[random.nextInt(specificites.length)];
          List<Map<String, dynamic>> plans = [];

          DocumentReference nouveauChampRef =
              await _firestore.collection('champs').add({
            'specificite': newSpecificite,
            'plans': plans,
          });

          await joueurRef.update({
            'champs': FieldValue.arrayUnion([nouveauChampRef]),
            'bourse': FieldValue.increment(-15),
          });

          setState(() {
            _devee -= 15;
            _champs.add({
              'id': nouveauChampRef.id,
              'specificite': newSpecificite,
              'plans': plans,
            });
          });

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Champ acheté avec succès')),
          );
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erreur lors de l\'achat du champ: $e')),
          );
        }
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Fonds insuffisants pour acheter un champ')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return GradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          iconTheme: const IconThemeData(
            color: Colors.white,
          ),
          title:
              const Text('Mes Champs', style: TextStyle(color: Colors.white)),
          backgroundColor: Colors.transparent,
          actions: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  const Text('DeeVee: ',
                      style: TextStyle(fontSize: 18, color: Colors.white)),
                  Text(
                    '$_devee',
                    style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white),
                  ),
                ],
              ),
            ),
          ],
        ),
        body: Column(
          children: [
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _champs.isEmpty
                      ? const Center(
                          child: Text('Aucun champ trouvé',
                              style: TextStyle(color: Colors.white)))
                      : ListView.builder(
                          itemCount: _champs.length,
                          itemBuilder: (context, index) {
                            final champ = _champs[index];
                            final plans =
                                champ['plans'] as List<Map<String, dynamic>>;

                            return Container(
                              margin: const EdgeInsets.symmetric(vertical: 8.0),
                              padding: const EdgeInsets.all(16.0),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Colors.black26,
                                    blurRadius: 4,
                                    offset: Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Champ ${index + 1}',
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF92400E),
                                        ),
                                      ),
                                      _buildEtatTexte(plans, index),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    champ['specificite'] ?? '',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  _buildActionWide(plans, index),
                                ],
                              ),
                            );
                          },
                        ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromRGBO(37, 99, 235, 1),
                  minimumSize: const Size(double.infinity, 50),
                ),
                onPressed: _devee >= 15 ? _acheterChamp : null,
                child: const Text(
                  "Acheter un champ (15 Deevee)",
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
