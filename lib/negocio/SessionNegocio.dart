import '../models/database/session_dao.dart';
import '../models/session_model.dart';

class SessionNegocio{
  late SessionDao sessionDao;
  SessionNegocio(){
    sessionDao = SessionDao();
  }
  // Example method to create a session
  Future<int> createSession(SessionModelo session) async {
    return await sessionDao.createSession(session);
  }
  // Example method to read a session
  Future<SessionModelo?> getSession() async {
    return await sessionDao.getSession();
  }
  // Example method to update a session
  Future<int> updateSession(SessionModelo session) async {
    return await sessionDao.updateSession(session);
  }
  // Example method to delete a session
  Future<bool> deleteSession(int id) async {
    return await sessionDao.deleteSession(id);
  }
}