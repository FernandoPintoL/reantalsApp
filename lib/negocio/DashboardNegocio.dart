class DashBoardNegocio {
  // Singleton
  static final DashBoardNegocio _instance = DashBoardNegocio._internal();

  factory DashBoardNegocio() {
    return _instance;
  }

  DashBoardNegocio._internal();

  // Variables
  int _totalUsuarios = 0;
  int _totalClientes = 0;
  int _totalProveedores = 0;
  int _totalProductos = 0;

  // Getters
  int get totalUsuarios => _totalUsuarios;
  int get totalClientes => _totalClientes;
  int get totalProveedores => _totalProveedores;
  int get totalProductos => _totalProductos;

  // Setters
  set totalUsuarios(int value) {
    _totalUsuarios = value;
  }

  set totalClientes(int value) {
    _totalClientes = value;
  }

  set totalProveedores(int value) {
    _totalProveedores = value;
  }

  set totalProductos(int value) {
    _totalProductos = value;
  }
}