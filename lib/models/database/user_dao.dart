import '../user_model.dart';
import 'database.dart';

class UserDao {
  AppDatabase database = AppDatabase();
  UserDao(){
    database = AppDatabase();
  }
  Future<int> insertUserSession(UserModel user) async {
    return await database.insert(AppDatabase.tableUser, user.toMap());
  }
  Future<int> updateUserSession(UserModel user) async {
    return await database.update(AppDatabase.tableUser, user.toMap());
  }
  Future<UserModel?> getUser(int id) async {
    final Map<String, dynamic>? map = await database.queryById(AppDatabase.tableUser, id.toString());
    if (map != null) {
      return UserModel.mapToModel(map);
    }
    return null;
  }
  Future<bool> deleteUserSession(String id) async {
    return await database.delete(AppDatabase.tableUser, id);
  }
}