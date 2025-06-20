import 'package:flutter/material.dart';
class AppIconWidget extends StatelessWidget {
  const AppIconWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: 40,
      backgroundColor: Colors.white,
      child: Image.asset(
        'assets/icon/images.jpg', // Ruta del ícono en tu carpeta de assets
        width: 100, // Ajusta el tamaño según lo necesites
        height: 100,
      ),
    );
  }
}
