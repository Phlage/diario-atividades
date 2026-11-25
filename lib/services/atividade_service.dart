import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/atividade.dart';

/// CRUD das atividades de um usuário.
abstract class AtividadeService {
  Stream<List<Atividade>> observar(String uid);
  Future<void> criar(String uid, Atividade atividade);
  Future<void> atualizar(String uid, Atividade atividade);
  Future<void> remover(String uid, String id);
}

/// Firestore: users/{uid}/atividades/{id}
class FirestoreAtividadeService implements AtividadeService {
  FirestoreAtividadeService([FirebaseFirestore? db])
      : _db = db ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> _colecao(String uid) =>
      _db.collection('users').doc(uid).collection('atividades');

  @override
  Stream<List<Atividade>> observar(String uid) =>
      _colecao(uid).orderBy('data', descending: true).snapshots().map(
            (snapshot) => snapshot.docs
                .map((doc) => Atividade.fromMap(doc.id, doc.data()))
                .toList(),
          );

  @override
  Future<void> criar(String uid, Atividade atividade) =>
      _semTravarOffline(_colecao(uid).add(_dados(uid, atividade)));

  @override
  Future<void> atualizar(String uid, Atividade atividade) => _semTravarOffline(
        _colecao(uid).doc(atividade.id).set(_dados(uid, atividade)),
      );

  @override
  Future<void> remover(String uid, String id) =>
      _semTravarOffline(_colecao(uid).doc(id).delete());

  Map<String, dynamic> _dados(String uid, Atividade atividade) => {
        ...atividade.toMap(),
        'uid': uid,
      };

  /// Sem rede, o Firestore grava no cache local na hora, mas o Future só
  /// termina quando o servidor confirma. Depois de alguns segundos seguimos
  /// em frente; a escrita é sincronizada quando a conexão voltar.
  Future<void> _semTravarOffline(Future<Object?> escrita) async {
    try {
      await escrita.timeout(const Duration(seconds: 5));
    } on TimeoutException {
      // Pendente no cache local.
    }
  }
}
