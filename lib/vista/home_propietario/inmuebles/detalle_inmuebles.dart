import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import '../../../models/inmueble_model.dart';
import '../../../models/galeria_inmueble_model.dart';
import '../../../providers/inmueble_provider.dart';

class DetalleInmueblesScreen extends StatefulWidget {
  final bool isEditing;
  final InmuebleModel? inmueble;

  const DetalleInmueblesScreen({
    Key? key,
    required this.isEditing,
    this.inmueble,
  }) : super(key: key);

  @override
  State<DetalleInmueblesScreen> createState() => _DetalleInmueblesScreenState();
}

class _DetalleInmueblesScreenState extends State<DetalleInmueblesScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _detalleController = TextEditingController();
  final _numHabitacionController = TextEditingController();
  final _numPisoController = TextEditingController();
  final _precioController = TextEditingController();
  bool _isOcupado = false;
  int _tipoInmuebleId = 1; // Default value
  List<XFile> _selectedImages = [];
  List<GaleriaInmuebleModel> _existingImages = [];
  bool _isLoading = false;
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    if (widget.isEditing && widget.inmueble != null) {
      _nombreController.text = widget.inmueble!.nombre;
      _detalleController.text = widget.inmueble!.detalle ?? '';
      _numHabitacionController.text = widget.inmueble!.numHabitacion;
      _numPisoController.text = widget.inmueble!.numPiso;
      _precioController.text = widget.inmueble!.precio.toString();
      _isOcupado = widget.inmueble!.isOcupado;
      _tipoInmuebleId = widget.inmueble!.tipoInmuebleId;
      
      // Load existing images
      _loadExistingImages();
    }
  }

  Future<void> _loadExistingImages() async {
    if (widget.inmueble != null) {
      setState(() {
        _isLoading = true;
      });
      
      await context.read<InmuebleProvider>().loadInmuebleGaleria(widget.inmueble!.id);
      
      setState(() {
        _existingImages = context.read<InmuebleProvider>().galeriaInmueble;
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _detalleController.dispose();
    _numHabitacionController.dispose();
    _numPisoController.dispose();
    _precioController.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    final ImagePicker picker = ImagePicker();
    final List<XFile> images = await picker.pickMultiImage();
    
    if (images.isNotEmpty) {
      setState(() {
        _selectedImages.addAll(images);
      });
    }
  }

  Future<void> _takePicture() async {
    final ImagePicker picker = ImagePicker();
    final XFile? photo = await picker.pickImage(source: ImageSource.camera);
    
    if (photo != null) {
      setState(() {
        _selectedImages.add(photo);
      });
    }
  }

  Future<File> _compressImage(XFile image) async {
    final tempDir = await getTemporaryDirectory();
    final targetPath = path.join(tempDir.path, '${DateTime.now().millisecondsSinceEpoch}.jpg');
    
    final compressedFile = await FlutterImageCompress.compressAndGetFile(
      image.path,
      targetPath,
      quality: 70, // Adjust quality to get file size below 1MB
      minWidth: 1024,
      minHeight: 1024,
    );
    
    return File(compressedFile!.path);
  }

  Future<void> _saveInmueble() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });
      
      final provider = context.read<InmuebleProvider>();
      
      // Create or update the property
      final inmueble = InmuebleModel(
        id: widget.isEditing ? widget.inmueble!.id : 0,
        userId: provider.currentUser?.id ?? 0,
        nombre: _nombreController.text,
        detalle: _detalleController.text,
        numHabitacion: _numHabitacionController.text,
        numPiso: _numPisoController.text,
        precio: double.tryParse(_precioController.text) ?? 0.0,
        isOcupado: _isOcupado,
        tipoInmuebleId: _tipoInmuebleId,
      );
      
      bool success;
      if (widget.isEditing) {
        success = await provider.updateInmueble(inmueble);
      } else {
        success = await provider.createInmueble(inmueble);
      }
      
      if (success && _selectedImages.isNotEmpty) {
        setState(() {
          _isUploading = true;
        });
        
        // Upload images
        final inmuebleId = provider.selectedInmueble?.id ?? 0;
        if (inmuebleId > 0) {
          for (var image in _selectedImages) {
            // Compress image before uploading
            final compressedImage = await _compressImage(image);
            await provider.uploadInmuebleImage(inmuebleId, compressedImage.path);
          }
        }
        
        setState(() {
          _isUploading = false;
        });
      }
      
      setState(() {
        _isLoading = false;
      });
      
      if (success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(widget.isEditing
                  ? 'Inmueble actualizado exitosamente'
                  : 'Inmueble creado exitosamente'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context);
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(provider.message ?? 'Error al guardar el inmueble'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _deleteImage(int index) async {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  Future<void> _deleteExistingImage(GaleriaInmuebleModel image) async {
    if (widget.inmueble != null) {
      setState(() {
        _isLoading = true;
      });
      
      final success = await context.read<InmuebleProvider>()
          .deleteInmuebleImage(image.id, widget.inmueble!.id);
      
      if (success) {
        setState(() {
          _existingImages.removeWhere((item) => item.id == image.id);
        });
      }
      
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final apiService = context.read<InmuebleProvider>();
    final baseUrlImage = apiService.currentUser?.photoPath ?? '';
    
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEditing ? 'Editar Inmueble' : 'Crear Inmueble'),
        actions: [
          if (!_isLoading && !_isUploading)
            IconButton(
              icon: const Icon(Icons.save),
              onPressed: _saveInmueble,
              tooltip: 'Guardar',
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Property details form
                    TextFormField(
                      controller: _nombreController,
                      decoration: const InputDecoration(
                        labelText: 'Nombre del inmueble',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Por favor ingrese un nombre';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _detalleController,
                      decoration: const InputDecoration(
                        labelText: 'Detalles',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _numHabitacionController,
                            decoration: const InputDecoration(
                              labelText: 'Número de habitaciones',
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.number,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Requerido';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            controller: _numPisoController,
                            decoration: const InputDecoration(
                              labelText: 'Número de piso',
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.number,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Requerido';
                              }
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _precioController,
                      decoration: const InputDecoration(
                        labelText: 'Precio',
                        border: OutlineInputBorder(),
                        prefixText: '\$ ',
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Por favor ingrese un precio';
                        }
                        if (double.tryParse(value) == null) {
                          return 'Por favor ingrese un número válido';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Checkbox(
                          value: _isOcupado,
                          onChanged: (value) {
                            setState(() {
                              _isOcupado = value ?? false;
                            });
                          },
                        ),
                        const Text('¿Está ocupado?'),
                      ],
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Imágenes del inmueble',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Puedes subir múltiples imágenes. Cada imagen será reducida a menos de 1MB.',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Existing images
                    if (_existingImages.isNotEmpty) ...[
                      const Text(
                        'Imágenes existentes:',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 120,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: _existingImages.length,
                          itemBuilder: (context, index) {
                            final image = _existingImages[index];
                            return Stack(
                              children: [
                                Container(
                                  margin: const EdgeInsets.only(right: 8),
                                  width: 120,
                                  height: 120,
                                  decoration: BoxDecoration(
                                    border: Border.all(color: Colors.grey),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.network(
                                      '$baseUrlImage${image.photoPath}',
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) {
                                        return const Center(
                                          child: Icon(
                                            Icons.error,
                                            color: Colors.red,
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ),
                                Positioned(
                                  top: 4,
                                  right: 12,
                                  child: GestureDetector(
                                    onTap: () => _deleteExistingImage(image),
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: const BoxDecoration(
                                        color: Colors.red,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.close,
                                        color: Colors.white,
                                        size: 16,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    
                    // Selected images
                    if (_selectedImages.isNotEmpty) ...[
                      const Text(
                        'Imágenes seleccionadas:',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 120,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: _selectedImages.length,
                          itemBuilder: (context, index) {
                            return Stack(
                              children: [
                                Container(
                                  margin: const EdgeInsets.only(right: 8),
                                  width: 120,
                                  height: 120,
                                  decoration: BoxDecoration(
                                    border: Border.all(color: Colors.grey),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.file(
                                      File(_selectedImages[index].path),
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                                Positioned(
                                  top: 4,
                                  right: 12,
                                  child: GestureDetector(
                                    onTap: () => _deleteImage(index),
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: const BoxDecoration(
                                        color: Colors.red,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.close,
                                        color: Colors.white,
                                        size: 16,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    
                    // Image selection buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ElevatedButton.icon(
                          onPressed: _isUploading ? null : _pickImages,
                          icon: const Icon(Icons.photo_library),
                          label: const Text('Galería'),
                        ),
                        const SizedBox(width: 16),
                        ElevatedButton.icon(
                          onPressed: _isUploading ? null : _takePicture,
                          icon: const Icon(Icons.camera_alt),
                          label: const Text('Cámara'),
                        ),
                      ],
                    ),
                    
                    if (_isUploading) ...[
                      const SizedBox(height: 16),
                      const Center(
                        child: Column(
                          children: [
                            CircularProgressIndicator(),
                            SizedBox(height: 8),
                            Text('Subiendo imágenes...'),
                          ],
                        ),
                      ),
                    ],
                    
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isLoading || _isUploading ? null : _saveInmueble,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                        ),
                        child: Text(
                          widget.isEditing ? 'Actualizar Inmueble' : 'Crear Inmueble',
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}