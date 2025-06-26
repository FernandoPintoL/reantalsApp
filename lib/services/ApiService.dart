import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../../models/response_model.dart';
import 'ResponseHandler.dart';
import 'UrlConfigProvider.dart';

class ApiService {
  static ApiService? _instance;
  static UrlConfigProvider? _sharedUrlConfigProvider;

  UrlConfigProvider? _urlConfigProvider;
  String _baseUrl = '';
  String _baseUrlImage = '';
  bool _isUsingProvider = false;

  // Factory method to get a shared instance with the UrlConfigProvider
  factory ApiService.getInstance() {
    if (_instance == null) {
      _instance = ApiService();
    }
    return _instance!;
  }

  // Set the shared UrlConfigProvider for all instances created with getInstance()
  static void setSharedUrlConfigProvider(UrlConfigProvider provider) {
    _sharedUrlConfigProvider = provider;
    if (_instance != null) {
      _instance!._setUrlConfigProvider(provider);
    }
  }

  // Constructor
  ApiService({UrlConfigProvider? urlConfigProvider}) {
    if (urlConfigProvider != null) {
      _setUrlConfigProvider(urlConfigProvider);
    } else if (_sharedUrlConfigProvider != null) {
      _setUrlConfigProvider(_sharedUrlConfigProvider!);
    } else {
      // Check APP_ENV to determine which URLs to use
      final appEnv = dotenv.env['APP_ENV'] ?? 'local';
      if (appEnv == 'local') {
        _baseUrl = dotenv.env['BASE_LOCAL_URL'] ?? '';
        _baseUrlImage = dotenv.env['BASE_LOCAL_URL_IMAGE'] ?? '';
      } else {
        _baseUrl = dotenv.env['BASE_PROD_URL'] ?? '';
        _baseUrlImage = dotenv.env['BASE_PROD_URL_IMAGE'] ?? '';
      }
      _isUsingProvider = false;
    }
  }

  void _setUrlConfigProvider(UrlConfigProvider provider) {
    _urlConfigProvider = provider;
    _baseUrl = _urlConfigProvider!.currentBaseUrl;
    _baseUrlImage = _urlConfigProvider!.currentBaseUrlImage;
    _urlConfigProvider!.addListener(_updateBaseUrl);
    _isUsingProvider = true;
  }

  void _updateBaseUrl() {
    if (_urlConfigProvider != null) {
      _baseUrl = _urlConfigProvider!.currentBaseUrl;
      _baseUrlImage = _urlConfigProvider!.currentBaseUrlImage;
    }
  }

  void dispose() {
    if (_isUsingProvider && _urlConfigProvider != null) {
      _urlConfigProvider!.removeListener(_updateBaseUrl);
    }
  }

  String get baseUrlImage => _baseUrlImage;

  final defaultHeaders = {'Content-Type': 'application/json'};

  Future<ResponseModel> get(String endpoint, {Map<String, String>? headers}) async {
    final url = Uri.parse('$_baseUrl$endpoint');
    print('GET request to: $url');
    try {
      final response = await http.get(url, headers: headers);
      return ResponseHandler.processResponse(response);
    } catch (e) {
      print('Error en GET: $e');
      throw Exception('Error en GET: $e');
    }
  }

  Future<ResponseModel> post(
    String endpoint,
    Map<String, dynamic> body, {
    Map<String, String>? headers,
  }) async {
    final url = Uri.parse('$_baseUrl$endpoint');
    print('POST request to: $url');
    try {
      final response = await http.post(
        url,
        headers: {...defaultHeaders, ...?headers},
        body: jsonEncode(body),
      );
      final responseBody = jsonDecode(response.body);
      print('Response: ${responseBody}');
      return ResponseHandler.processResponse(response);
    } catch (e) {
      print('Error en POST: $e');
      throw Exception('Error en POST: $e');
    }
  }

  Future<ResponseModel> put(
    String endpoint,
    Map<String, dynamic> body, {
    Map<String, String>? headers,
  }) async {
    final url = Uri.parse('$_baseUrl$endpoint');
    print('PUT request to: $url');
    final defaultHeaders = {'Content-Type': 'application/json'};
    try {
      final response = await http.put(
        url,
        headers: {...?defaultHeaders, ...?headers},
        body: jsonEncode(body),
      );
      return ResponseHandler.processResponse(response);
    } catch (e) {
      print('Error en PUT: $e');
      throw Exception('Error en PUT: $e');
    }
  }

  Future<ResponseModel> delete(
    String endpoint, {
    Map<String, String>? headers,
  }) async {
    final url = Uri.parse('$_baseUrl$endpoint');
    try {
      final response = await http.delete(url, headers: headers);
      return ResponseHandler.processResponse(response);
    } catch (e) {
      print('Error en DELETE: $e');
      throw Exception('Error en DELETE: $e');
    }
  }

  //enviar un archivo o imagen
  Future<ResponseModel> uploadFile(
    String endpoint,
    String filePath,
    int id, {
    Map<String, String>? headers,
  }) async {
    print('uploadFile: $_baseUrl$endpoint');
    final url = Uri.parse('$_baseUrl$endpoint');
    try {
      var request = http.MultipartRequest('POST', url);
      request.headers.addAll({...?defaultHeaders, ...?headers});
      request.files.add(await http.MultipartFile.fromPath('file', filePath));
      request.fields['inmueble_id'] = id.toString();
      final response = await request.send();
      print('Response: ${response.statusCode}');
      if (response.statusCode != 200) {
        throw Exception('Error en uploadFile: ${response.statusCode}');
      }
      return ResponseHandler.processResponse(
        await http.Response.fromStream(response),
      );
    } catch (e) {
      print('Error en uploadFile: $e');
      throw Exception('Error en uploadFile: $e');
    }
  }
}
