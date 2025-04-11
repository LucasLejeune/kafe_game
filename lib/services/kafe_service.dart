import 'package:cloud_firestore/cloud_firestore.dart';

class KafeService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> creerKafe(
      {required String nom,
      required int tempsPousse,
      required int productionFruit,
      required int cout,
      required Map<String, int> gato,
      required}) async {
    try {
      await _firestore.collection('kafes').add({
        'nom': nom,
        'temps_pousse': tempsPousse,
        'production_fruit': productionFruit,
        'cout': cout,
        'gato': gato,
      });
    } catch (e) {
      throw Exception('Erreur lors de la création du kafe : $e');
    }
  }
}
