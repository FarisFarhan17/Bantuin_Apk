import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:typed_data';
import '../services/firebase_service.dart';

class CampaignImage extends StatelessWidget {
  final String imageRef;
  final double? width;
  final double? height;
  final BoxFit fit;

  const CampaignImage({
    super.key,
    required this.imageRef,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
  });

  @override
  Widget build(BuildContext context) {
    if (imageRef.startsWith('http')) {
      return Image.network(
        imageRef,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (context, error, stackTrace) => _defaultImage(),
      );
    } else if (imageRef.startsWith('firestore://')) {
      return FutureBuilder<String>(
        future: FirebaseService().getImageFromBase64(imageRef),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return _loadingImage();
          } else if (snapshot.hasData && snapshot.data != null) {
            try {
              final Uint8List bytes = base64Decode(snapshot.data!);
              return Image.memory(
                bytes,
                width: width,
                height: height,
                fit: fit,
                errorBuilder: (context, error, stackTrace) => _defaultImage(),
              );
            } catch (e) {
              return _defaultImage();
            }
          } else {
            return _defaultImage();
          }
        },
      );
    } else if (imageRef.startsWith('data:image')) {
      final List<String> parts = imageRef.split(',');
      if (parts.length > 1) {
        try {
          final String base64Data = parts[1];
          final Uint8List bytes = base64Decode(base64Data);
          return Image.memory(
            bytes,
            width: width,
            height: height,
            fit: fit,
            errorBuilder: (context, error, stackTrace) => _defaultImage(),
          );
        } catch (e) {
          return _defaultImage();
        }
      }
    }
    return _defaultImage();
  }

  Widget _defaultImage() => Container(
        width: width,
        height: height,
        color: Colors.grey[300],
        child: Icon(Icons.image, size: width != null ? width! / 2 : 40, color: Colors.grey[600]),
      );

  Widget _loadingImage() => Container(
        width: width,
        height: height,
        color: Colors.grey[300],
        child: Center(child: CircularProgressIndicator()),
      );
} 