import 'dart:io';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

class CompressImage{
   // Comprimir imagen para que pese menos de 1MB
  static Future<File> comprimirImagen(File file) async {
    // Obtener el tamaño original del archivo en bytes
    final int originalSize = await file.length();
    // Si ya es menor a 1MB (1,048,576 bytes), devolver el archivo original
    if (originalSize < 1048576) {
      return file;
    }
    try {
      // Calcular la calidad de compresión basada en el tamaño original
      // Cuanto más grande sea el archivo, menor será la calidad para lograr una mayor compresión
      int quality = 90;
      if (originalSize > 5 * 1048576) { // > 5MB
        quality = 60;
      } else if (originalSize > 3 * 1048576) { // > 3MB
        quality = 70;
      } else if (originalSize > 2 * 1048576) { // > 2MB
        quality = 80;
      }

      // Crear un directorio temporal para guardar la imagen comprimida
      final tempDir = await getTemporaryDirectory();
      final targetPath = path.join(tempDir.path, '${DateTime.now().millisecondsSinceEpoch}.jpg');

      // Comprimir la imagen
      final result = await FlutterImageCompress.compressAndGetFile(
        file.absolute.path,
        targetPath,
        quality: quality,
        format: CompressFormat.jpeg,
      );

      if (result == null) {
        // Si la compresión falla, devolver el archivo original
        return file;
      }

      // Convertir XFile a File
      final compressedFile = File(result.path);

      // Verificar si el archivo comprimido es menor a 1MB
      final compressedSize = await compressedFile.length();
      if (compressedSize >= 1048576) {
        // Si sigue siendo mayor a 1MB, intentar con una calidad menor
        int newQuality = quality - 10;
        if (newQuality < 10) newQuality = 10; // No bajar de 10% de calidad

        // Crear un nuevo path para la imagen recomprimida
        final newTargetPath = path.join(tempDir.path, '${DateTime.now().millisecondsSinceEpoch}_recomp.jpg');

        final recompressedResult = await FlutterImageCompress.compressAndGetFile(
          compressedFile.absolute.path,
          newTargetPath,
          quality: newQuality,
          format: CompressFormat.jpeg,
        );

        if (recompressedResult == null) {
          return compressedFile; // Si falla la recompresión, usar la primera compresión
        }

        return File(recompressedResult.path);
      }

      return compressedFile;
    } catch (e) {
      print('Error al comprimir imagen: $e');
      // En caso de error, devolver el archivo original
      return file;
    }
  }
}