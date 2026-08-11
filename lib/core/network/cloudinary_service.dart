import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:untitled3/core/constants/cloudinary_config.dart';

/// Generic image-upload utility — used by both the seller product form
/// (features/seller/products) and profile photo upload
/// (features/profile), so it lives in core rather than under either
/// feature.
class CloudinaryService {
  static Future<String> uploadImage(File file) async {
    if (!CloudinaryConfig.isConfigured) {
      throw Exception(
          'Cloudinary is not configured yet. Set cloudName and uploadPreset in lib/core/constants/cloudinary_config.dart');
    }

    final uri = Uri.parse(
        'https://api.cloudinary.com/v1_1/${CloudinaryConfig.cloudName}/image/upload');
    final request = http.MultipartRequest('POST', uri)
      ..fields['upload_preset'] = CloudinaryConfig.uploadPreset
      ..files.add(await http.MultipartFile.fromPath('file', file.path));

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode != 200) {
      throw Exception('Cloudinary upload failed: ${response.body}');
    }

    final data = json.decode(response.body) as Map<String, dynamic>;
    return data['secure_url'] as String;
  }

  static Future<List<String>> uploadImages(List<File> files) async {
    final urls = <String>[];
    for (final file in files) {
      urls.add(await uploadImage(file));
    }
    return urls;
  }
}
