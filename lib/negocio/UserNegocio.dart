import 'package:rentals/models/database/user_dao.dart';
import '../models/user_model.dart';

class UserNegocio {
  UserDao _userDao;
  //constructor
  UserNegocio() : _userDao = UserDao();

  //insert user
  Future<int> insertUser(UserModel user) async {
    return await _userDao.insertUserSession(user);
  }
  //update user
  Future<int> updateUser(UserModel user) async {
    return await _userDao.updateUserSession(user);
  }
  //get user
  Future<UserModel?> getUser(int id) async {
    return await _userDao.getUser(id);
  }

  //delete user session
  Future<bool> deleteUser(String id) async {
    return await _userDao.deleteUserSession(id);
  }
}