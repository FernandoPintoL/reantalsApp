import 'package:rentals/models/session_model.dart';

import 'database.dart';

class SessionDao{
  late AppDatabase database;
  SessionDao(){
    database = AppDatabase();
  }
  // Example method to create a session
  Future<int> createSession(SessionModelo session) async {
    return await database.insert(AppDatabase.tableSession, session.toMap());
  }
  // Example method to read a session
  Future<SessionModelo?> getSession() async {
    final List<Map<String, dynamic>> maps = await database.query(
      AppDatabase.tableSession, null, null);
    if (maps.isNotEmpty) {
      return SessionModelo.mapToModel(maps.first);
    }
    return null;
  }
  // Example method to update a session
  Future<int> updateSession(SessionModelo session) async {
    return await database.update(AppDatabase.tableSession, session.toMap());
  }
  // Example method to delete a session
  Future<bool> deleteSession(int id) async {
    return await database.delete(AppDatabase.tableSession, id.toString());
  }
}