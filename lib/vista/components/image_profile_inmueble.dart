import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rentals/services/ApiService.dart';
import 'package:rentals/providers/inmueble_provider.dart';
import 'package:rentals/models/galeria_inmueble_model.dart';

class ImageProfileInmueble extends StatefulWidget {
  final String imageUrl;
  final bool isIcon;
  final List<dynamic>? galeriaInmueble;
  final int? inmuebleId;
  
  const ImageProfileInmueble({
    Key? key, 
    this.imageUrl = "", 
    this.isIcon = false,
    this.galeriaInmueble,
    this.inmuebleId,
  }) : super(key: key);

  @override
  State<ImageProfileInmueble> createState() => _ImageProfileInmuebleState();
}

class _ImageProfileInmuebleState extends State<ImageProfileInmueble> {
  // List<GaleriaInmuebleModel> _loadedGaleria = [];
  bool _isLoading = false;
  String photoPath = "";
  
  @override
  void initState() {
    super.initState();
    // If we have a property ID but no gallery images, load them
    if (widget.inmuebleId != null && widget.inmuebleId! > 0 && 
        (widget.galeriaInmueble == null || widget.galeriaInmueble!.isEmpty)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadGaleriaInmueble();
      });
    }
  }

  @override
  void dispose() {
    super.dispose();
  }
  
  Future<void> _loadGaleriaInmueble() async {
    if (widget.inmuebleId == null) return;

    if (mounted) {
      // Clear previous gallery images
      setState(() {
        _isLoading = true;
      });
    }
    
    try {
      String url = await context.read<InmuebleProvider>().getFirstImageUrl(widget.inmuebleId!);
      if (mounted) {
        setState(() {
          photoPath = url;
        });
      }
    } catch (e) {
      print('Error loading gallery images: $e');
    } finally {
      if (mounted) {
        // Clear previous gallery images
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // If we're loading images, show a loading indicator
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }
    
    // Si hemos proporcionado imágenes de galería, úselas
    if (photoPath.isNotEmpty) {
      
      final String imagePath = '${ApiService.getInstance().baseUrlImage}/$photoPath';
      print('Image path: $imagePath');
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.network(
          imagePath,
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
          errorBuilder: (context, error, stackTrace) {
            // If image fails to load, show home icon
            return const Center(
              child: Icon(Icons.home, size: 50),
            );
          },
        ),
      );
    }
    // Si se proporciona imageUrl, úsela
    else if (widget.imageUrl.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.network(
          widget.imageUrl,
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
          errorBuilder: (context, error, stackTrace) {
            // If image fails to load, show home icon
            return const Center(
              child: Icon(Icons.home, size: 50),
            );
          },
        ),
      );
    } 
    // Otherwise show home icon
    else {
      return const Center(
        child: Icon(Icons.home, size: 150),
      );
    }
  }
}