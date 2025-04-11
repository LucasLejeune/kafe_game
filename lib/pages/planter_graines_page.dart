import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kafe_game/pages/mes_champs_page.dart';
import '../widgets/gradient_background.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PlanterGrainesPage extends StatefulWidget {
  final String champId;

  const PlanterGrainesPage({Key? key, required this.champId}) : super(key: key);

  @override
  _PlanterGrainesPageState createState() => _PlanterGrainesPageState();
}

class _PlanterGrainesPageState extends State<PlanterGrainesPage> {
  final _formKey = GlobalKey<FormState>();
  String? _selectedKafeId;
  int _nombrePlants = 1;
  late String _selectedChampId;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<Map<String, dynamic>> _cafesDisponibles = [];

  @override
  void initState() {
    super.initState();
    _selectedChampId = widget.champId;
    _fetchCafesDisponibles();
  }

  Future<void> _fetchCafesDisponibles() async {
    try {
      QuerySnapshot querySnapshot =
          await FirebaseFirestore.instance.collection('kafes').get();
      setState(() {
        _cafesDisponibles = querySnapshot.docs.map((doc) {
          return {
            'id': doc.id,
            'nom': doc['nom'],
            'cout': doc['cout'],
            'temps_pousse': doc['temps_pousse'],
            'production_fruits': doc['production_fruit'],
          };
        }).toList();
      });
    } catch (e) {
      print("Erreur lors de la récupération des types de café : $e");
    }
  }

  Map<String, dynamic>? get _kafeSelectionne {
    return _cafesDisponibles.firstWhere((kafe) => kafe['id'] == _selectedKafeId,
        orElse: () => {});
  }

  Future<void> _planterGraines() async {
    final user = _auth.currentUser;
    if (user == null) return;

    if (_formKey.currentState!.validate()) {
      try {
        DocumentReference kafeRef =
            FirebaseFirestore.instance.collection('kafes').doc(_selectedKafeId);

        DocumentSnapshot kafeSnap = await kafeRef.get();

        DocumentReference nouveauPlanRef =
            await FirebaseFirestore.instance.collection('plans_de_kafe').add({
          'kafe': kafeRef,
          'quantite': _nombrePlants,
          'date_plantation': Timestamp.now(),
        });

        DocumentReference champRef = FirebaseFirestore.instance
            .collection('champs')
            .doc(_selectedChampId);
        await champRef.update({
          'plans': FieldValue.arrayUnion([nouveauPlanRef])
        });

        final joueurRef = _firestore.collection('joueurs').doc(user.uid);
        final joueurSnap = await joueurRef.get();
        final cout = kafeSnap['cout'] * _nombrePlants;
        await joueurRef.update({
          'bourse': FieldValue.increment(-cout),
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Graines plantées avec succès')),
        );

        _formKey.currentState!.reset();
        setState(() {
          _selectedKafeId = null;
          _nombrePlants = 1;
        });
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const MesChampsPage()),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Erreur lors de la plantation des graines: $e')),
        );
      }
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
          backgroundColor: Colors.transparent,
          title: const Text(
            'Planter des Graines',
            style: TextStyle(color: Colors.white),
          ),
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: _cafesDisponibles.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Type de Kafé',
                        style: TextStyle(color: Colors.white),
                      ),
                      Container(
                        padding: const EdgeInsets.all(16.0),
                        margin: const EdgeInsets.only(bottom: 16.0),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        child: Column(
                          children: [
                            DropdownButtonFormField<String>(
                              value: _selectedKafeId,
                              decoration: const InputDecoration(
                                labelText: 'Sélectionnez un type de café',
                                border: OutlineInputBorder(),
                              ),
                              items: _cafesDisponibles.map((kafe) {
                                return DropdownMenuItem<String>(
                                  value: kafe['id'],
                                  child: Text(kafe['nom']),
                                );
                              }).toList(),
                              onChanged: (value) {
                                setState(() {
                                  _selectedKafeId = value;
                                });
                              },
                              validator: (value) => value == null
                                  ? 'Veuillez sélectionner un type de café'
                                  : null,
                              alignment: Alignment.centerLeft,
                            ),
                            if (_kafeSelectionne!.isNotEmpty)
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  SizedBox(
                                    width: double.infinity,
                                    child: Text(
                                      'Coût: ${_kafeSelectionne!['cout']}',
                                      style:
                                          const TextStyle(color: Colors.black),
                                      textAlign: TextAlign.left,
                                    ),
                                  ),
                                  SizedBox(
                                    width: double.infinity,
                                    child: Text(
                                      'Temps de pousse: ${_kafeSelectionne!['temps_pousse']} minutes',
                                      style:
                                          const TextStyle(color: Colors.black),
                                      textAlign: TextAlign.left,
                                    ),
                                  ),
                                  SizedBox(
                                    width: double.infinity,
                                    child: Text(
                                      'Production de fruits: ${_kafeSelectionne!['production_fruits']}',
                                      style:
                                          const TextStyle(color: Colors.black),
                                      textAlign: TextAlign.left,
                                    ),
                                  ),
                                ],
                              )
                            else
                              const Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  SizedBox(
                                    width: double.infinity,
                                    child: Text(
                                      'Sélectionner un type de Kafé',
                                      style: TextStyle(color: Colors.black),
                                    ),
                                  ),
                                ],
                              )
                          ],
                        ),
                      ),
                      const Text(
                        'Nombre de plants',
                        style: TextStyle(color: Colors.white),
                      ),
                      Container(
                        padding: const EdgeInsets.all(16.0),
                        margin: const EdgeInsets.only(bottom: 16.0),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.remove),
                                  onPressed: () {
                                    setState(() {
                                      if (_nombrePlants > 1) {
                                        _nombrePlants--;
                                      }
                                    });
                                  },
                                ),
                                Text(
                                  '$_nombrePlants',
                                  style: const TextStyle(fontSize: 24),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.add),
                                  onPressed: () {
                                    setState(() {
                                      if (_nombrePlants < 4) {
                                        _nombrePlants++;
                                      }
                                    });
                                  },
                                ),
                              ],
                            ),
                            const SizedBox(height: 8.0),
                            const Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Minimum: 1',
                                  style: TextStyle(color: Colors.black),
                                ),
                                Text(
                                  'Maximum: 4',
                                  style: TextStyle(color: Colors.black),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      Container(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFF59E0B),
                          ),
                          onPressed: _planterGraines,
                          child: const Text(
                            'Planter',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
        ),
      ),
    );
  }
}
