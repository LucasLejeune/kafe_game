import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kafe_game/pages/mes_champs_page.dart';
import 'auth/login_page.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../widgets/gradient_background.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String _nom = '';
  String _prenom = '';
  String _email = '';
  int _devee = 0;
  int _grains = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPlayerData();
  }

  Future<void> _loadPlayerData() async {
    User? user = _auth.currentUser;
    if (user != null) {
      try {
        DocumentSnapshot snapshot =
            await _firestore.collection('joueurs').doc(user.uid).get();

        if (snapshot.exists) {
          setState(() {
            _nom = snapshot['nom'] ?? 'Nom non disponible';
            _prenom = snapshot['prenom'] ?? 'Prénom non disponible';
            _email = snapshot['email'] ?? 'Email non disponible';
            _devee = snapshot['bourse'] ?? 0;
            _grains = snapshot['grains_d_or'] ?? 0;
            _isLoading = false;
          });
        }
      } catch (e) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors du chargement des données : $e')),
        );
      }
    } else {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content:
                Text('Vous devez être connecté pour accéder à cette page')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return GradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text(
            'Accueil',
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: Colors.transparent,
          actions: [
            IconButton(
              icon: const Icon(
                Icons.logout,
                color: Colors.white,
              ),
              onPressed: () {
                FirebaseAuth.instance.signOut();
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginPage()),
                );
              },
            ),
          ],
        ),
        body: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: [
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : Container(
                      margin: const EdgeInsets.all(8),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color.fromARGB(255, 255, 255, 255),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                            color: const Color.fromARGB(255, 255, 255, 255)),
                      ),
                      child: Row(
                        children: [
                          const CircleAvatar(
                            radius: 30,
                            backgroundColor: Color.fromARGB(255, 255, 255, 255),
                            child: Icon(Icons.person,
                                size: 30, color: Color.fromARGB(255, 0, 0, 0)),
                          ),
                          const SizedBox(width: 16),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '$_prenom $_nom',
                                style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black),
                              ),
                              Row(
                                children: [
                                  const FaIcon(
                                    FontAwesomeIcons.sackDollar,
                                    size: 18,
                                    color: Color.fromRGBO(245, 158, 11, 100),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '$_devee DeeVee',
                                    style: const TextStyle(
                                        fontSize: 16, color: Colors.black),
                                  ),
                                ],
                              ),
                              Row(
                                children: [
                                  const FaIcon(
                                    FontAwesomeIcons.wheatAwn,
                                    size: 18,
                                    color: Color.fromRGBO(217, 119, 6, 100),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '$_grains Grains d\'or',
                                    style: const TextStyle(
                                        fontSize: 16, color: Colors.black),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
              Expanded(
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) =>
                                          const MesChampsPage()),
                                );
                              },
                              child: Container(
                                margin: const EdgeInsets.all(4),
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  border: Border.all(color: Colors.white),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    FaIcon(FontAwesomeIcons.seedling,
                                        size: 25, color: Colors.green),
                                    SizedBox(height: 8),
                                    Text('Champs',
                                        style: TextStyle(
                                            fontSize: 18, color: Colors.black)),
                                  ],
                                ),
                              )),
                        ),
                        Expanded(
                          child: Container(
                            margin: const EdgeInsets.all(4),
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              border: Border.all(color: Colors.white),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                FaIcon(FontAwesomeIcons.box,
                                    size: 25,
                                    color: Color.fromRGBO(37, 99, 235, 100)),
                                SizedBox(height: 8),
                                Text('Stock',
                                    style: TextStyle(
                                        fontSize: 18, color: Colors.black)),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            margin: const EdgeInsets.all(4),
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              border: Border.all(color: Colors.white),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                FaIcon(FontAwesomeIcons.bowlRice,
                                    size: 25,
                                    color: Color.fromRGBO(124, 58, 237, 100)),
                                SizedBox(height: 8),
                                Text('Assemblage',
                                    style: TextStyle(
                                        fontSize: 18, color: Colors.black)),
                              ],
                            ),
                          ),
                        ),
                        Expanded(
                          child: Container(
                            margin: const EdgeInsets.all(4),
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              border: Border.all(color: Colors.white),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                FaIcon(FontAwesomeIcons.trophy,
                                    size: 25,
                                    color: Color.fromRGBO(217, 119, 6, 100)),
                                SizedBox(height: 8),
                                Text('CMTM',
                                    style: TextStyle(
                                        fontSize: 18, color: Colors.black)),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
