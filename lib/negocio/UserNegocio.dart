import 'package:rentals/models/database/user_dao.dart';
import 'package:rentals/models/response_model.dart';
import '../models/user_model.dart';
import '../services/ApiService.dart';

class UserNegocio {
  UserDao _userDao;
  ApiService apiService = ApiService.getInstance();
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