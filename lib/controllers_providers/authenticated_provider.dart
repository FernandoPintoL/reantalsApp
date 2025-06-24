import 'package:flutter/material.dart';
import '../../models/response_model.dart';
import '../../models/user_model.dart';
import '../../negocio/AuthenticatedNegocio.dart';
import '../vista/components/message_widget.dart';
import '../vista/interfaces/authenticated_screen_state.dart';
import 'user_global_provider.dart';

class AuthenticatedProvider extends ChangeNotifier{
  late AuthenticatedNegocio authenticatedNegocio;
  late AuthenticatedScreenState authenticatedScreenState;
  UserModel? userActual; // Usuario actual de la sesión

  late GlobalKey formKey;
  late TextEditingController emailController;
  late TextEditingController usernickController;
  late TextEditingController passwordController;
  late TextEditingController confirmPasswordController;

  late GlobalKey formCreateKey;
  late TextEditingController numIdController;
  late TextEditingController nameController;
  late TextEditingController phoneController;
  late TextEditingController direccionController;

  late FocusNode emailFocusNode;
  late FocusNode usernickFocusNode;
  late FocusNode passwordFocusNode;
  late FocusNode confirmPasswordFocusNode;
  late FocusNode numIdFocusNode;
  late FocusNode nameFocusNode;
  late FocusNode phoneFocusNode;
  late FocusNode direccionFocusNode;

  late bool _isLoading;
  late bool _isPasswordVisible;
  late bool _isPasswordRepeatedVisible;
  late bool _isSuccess;
  late String? _message;
  late bool _isPropietario;
  MessageType _messageType = MessageType.info;


  // Global user provider instance
  final UserGlobalProvider _userGlobalProvider = UserGlobalProvider();

  AuthenticatedProvider() {
    authenticatedNegocio = AuthenticatedNegocio();

    formKey = GlobalKey<FormState>();
    formCreateKey = GlobalKey<FormState>();

    emailController = TextEditingController();
    usernickController = TextEditingController();
    numIdController = TextEditingController();
    passwordController = TextEditingController();
    nameController = TextEditingController();
    confirmPasswordController = TextEditingController();
    phoneController = TextEditingController();
    direccionController = TextEditingController();

    emailFocusNode = FocusNode();
    usernickFocusNode = FocusNode();
    passwordFocusNode = FocusNode();
    confirmPasswordFocusNode = FocusNode();
    numIdFocusNode = FocusNode();
    nameFocusNode = FocusNode();
    phoneFocusNode = FocusNode();
    direccionFocusNode = FocusNode();

    _isLoading = false;
    _isPasswordVisible = false;
    _message = null;
    _isSuccess = false;
    _isPasswordRepeatedVisible = false;
    _isPropietario = false;
    _messageType = MessageType.info;

    loadUserSession();
  }

  Future<void> login(AuthenticatedScreenState screen) async {
    try{
      isLoading = true;
      authenticatedScreenState = screen;
      ResponseModel responseModel = await authenticatedNegocio.login(emailController.text, passwordController.text);
      print('Response model en provider: ${responseModel.data}');
      if (responseModel.statusCode == 200) {
        message = responseModel.message;
        print('Response model en provider: ${responseModel.data}');
        userActual = UserModel.mapToModel(responseModel.data);

        // Update global user state
        _userGlobalProvider.updateUser(userActual);

        messageType = responseModel.isSuccess ? MessageType.success : MessageType.error;
        isSuccess = responseModel.isSuccess;
        message = responseModel.isSuccess ? responseModel.message : ('${responseModel.message}\n${responseModel.messageError}').toString();
        isLoading = false;
        print('Usuario actual: ${userActual!.tipoUsuario}');
        if(userActual!.tipoUsuario == 'propietario') {
          print("moviendo a dashboard propietario");
          authenticatedScreenState.navigateToHomePropietario();
        } else {
          print("moviendo a dashboard cliente");
          authenticatedScreenState.navigateToHomeCliente();
        }
      } else {
        messageType = MessageType.error;
        isLoading = false;
        isSuccess = false;
        message = ('${responseModel.message}\n${responseModel.messageError}').toString();
      }
    } catch (e) {
      messageType = MessageType.error;
      isLoading = false;
      isSuccess = false;
      message = 'Error al iniciar sesión: $e';
    }
  }

  Future<void> createUser(AuthenticatedScreenState screen) async {
    isLoading = true;
    authenticatedScreenState = screen;
    userActual = UserModel(
      email: emailController.text,
      usernick: usernickController.text,
      name: nameController.text,
      numId: numIdController.text,
      telefono: phoneController.text,
      direccion: direccionController.text,
      tipoUsuario: isPropietario ? 'propietario' : 'cliente',
      tipoCliente: isPropietario ? 'particular' : 'normal',
    );
    if (userActual == null) {
      isLoading = false;
      message = 'Error al crear el usuario';
      return;
    }
    ResponseModel responseModel = await authenticatedNegocio.createUser(userActual!, passwordController.text, confirmPasswordController.text);
    print('Response model en provider: ${responseModel.data}');
    if (responseModel.statusCode == 200) {
      message = responseModel.message;
      print('Response model en provider: ${responseModel.data}');
      userActual = UserModel.mapToModel(responseModel.data);
      if(userActual == null) {
        messageType = MessageType.error;
        isSuccess = false;
        isLoading = false;
        message = 'Error al obtener el usuario';
        return;
      }

      // Update global user state
      _userGlobalProvider.updateUser(userActual);

      messageType = MessageType.success;
      isSuccess = true;
      isLoading = false;
      print('Usuario actual: ${userActual!.tipoUsuario}');
      if(userActual!.tipoUsuario == 'propietario') {
        print("moviendo a dashboard propietario");
        authenticatedScreenState.navigateToHomePropietario();
      } else {
        print("moviendo a dashboard cliente");
        authenticatedScreenState.navigateToHomeCliente();
      }
    } else {
      messageType = MessageType.error;
      isLoading = false;
      isSuccess = false;
      message = ('${responseModel.message}\n${responseModel.messageError}').toString();
    }
    messageType = MessageType.error;
    isLoading = false;
    isSuccess = false;
  }

  Future<void> loadUserSession() async {
    userActual = await getUserSession();
    // Update global user state
    _userGlobalProvider.updateUser(userActual);
  }

  Future<UserModel?> getUserSession() async {
    try{
      isLoading = true;
      UserModel? userAct = await authenticatedNegocio.getUserSession();
      if (userAct != null) {
        messageType = MessageType.success;
        message = 'Existe un usuario autenticado';
        isSuccess = true;
        print('Usuario actual: ${userAct.tipoUsuario}');
      } else {
        messageType = MessageType.info;
        isSuccess = false;
        message = 'Iniciar sesión para continuar';
      }
      isLoading = false;
      return userAct;
    } catch (e) {
      message = 'Error al obtener la sesión del usuario: $e';
      return null;
    }
  }

  Future<bool> logout() async {
    isLoading = true;
    ResponseModel responseModel = await authenticatedNegocio.logout(userActual!.id);
    if (responseModel.statusCode == 200) {
      message = responseModel.message;
      userActual = null; // Limpiar el usuario actual

      // Clear global user state
      _userGlobalProvider.clearUser();

      messageType = MessageType.success;
      isSuccess = true;
      isLoading = false;
    } else {
      messageType = MessageType.error;
      isLoading = false;
      isSuccess = false;
      message = ('${responseModel.message}\n${responseModel.messageError}').toString();
    }
    return isSuccess;
  }

  String? get message => _message;
  set message(String? value) {
    _message = value;
    notifyListeners();
  }
  bool get isSuccess => _isSuccess;
  set isSuccess(bool value) {
    _isSuccess = value;
    notifyListeners();
  }
  bool get isPasswordVisible => _isPasswordVisible;
  set isPasswordVisible(bool value) {
    _isPasswordVisible = value;
    notifyListeners();
  }
  bool get isLoading => _isLoading;
  set isLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
  bool get isPasswordRepeatedVisible => _isPasswordRepeatedVisible;
  set isPasswordRepeatedVisible(bool value) {
    _isPasswordRepeatedVisible = value;
    notifyListeners();
  }
  bool get isPropietario => _isPropietario;
  set isPropietario(bool value) {
    _isPropietario = value;
    notifyListeners();
  }
  MessageType get messageType => _messageType;
  set messageType(MessageType value) {
    _messageType = value;
    notifyListeners();
  }
}
