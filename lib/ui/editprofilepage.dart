import 'dart:io';

import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:image_picker/image_picker.dart';
import 'package:untitled3/const/style.dart';
import 'package:untitled3/services/auth_service.dart';
import 'package:untitled3/services/cloudinary_service.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  bool _isLoading = true;
  bool _isSaving = false;
  bool _isUploadingPhoto = false;
  String _existingPhotoUrl = '';
  File? _pickedPhoto;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final user = AuthService.currentUser;
    if (user != null) {
      final appUser = await AuthService.getUserDoc(user.uid);
      if (appUser != null) {
        _nameController.text = appUser.name;
        _phoneController.text = appUser.phone;
        _addressController.text = appUser.address;
        _existingPhotoUrl = appUser.photoUrl;
      }
    }
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _pickPhoto() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (picked == null) return;
    final user = AuthService.currentUser;
    if (user == null) return;

    setState(() {
      _pickedPhoto = File(picked.path);
      _isUploadingPhoto = true;
    });
    try {
      final url = await CloudinaryService.uploadImage(_pickedPhoto!);
      await AuthService.updateUserProfile(uid: user.uid, photoUrl: url);
      if (!mounted) return;
      setState(() => _existingPhotoUrl = url);
      Fluttertoast.showToast(msg: 'Profile photo updated');
    } catch (e) {
      Fluttertoast.showToast(msg: 'Could not upload photo: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _isUploadingPhoto = false);
    }
  }

  Future<void> _save() async {
    if (_nameController.text.trim().isEmpty) {
      Fluttertoast.showToast(msg: 'Please enter your name');
      return;
    }
    final user = AuthService.currentUser;
    if (user == null) return;

    setState(() => _isSaving = true);
    try {
      await AuthService.updateUserProfile(
        uid: user.uid,
        name: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
        address: _addressController.text.trim(),
      );
      if (!mounted) return;
      Fluttertoast.showToast(msg: 'Profile updated');
      Navigator.pop(context, true);
    } catch (e) {
      Fluttertoast.showToast(msg: 'Could not update profile: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Edit Profile')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.accent))
          : Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Stack(
                      children: [
                        CircleAvatar(
                          radius: 44,
                          backgroundColor: AppColors.card,
                          backgroundImage: _pickedPhoto != null
                              ? FileImage(_pickedPhoto!)
                              : (_existingPhotoUrl.isNotEmpty
                                  ? NetworkImage(_existingPhotoUrl)
                                  : null) as ImageProvider?,
                          child: _pickedPhoto == null && _existingPhotoUrl.isEmpty
                              ? const Icon(Icons.person, size: 48, color: AppColors.accent)
                              : null,
                        ),
                        if (_isUploadingPhoto)
                          const Positioned.fill(
                            child: CircleAvatar(
                              backgroundColor: Colors.black38,
                              child: SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2.4, color: Colors.white),
                              ),
                            ),
                          ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: SizedBox(
                            width: 32,
                            height: 32,
                            child: IconButton(
                              onPressed: _isUploadingPhoto ? null : _pickPhoto,
                              tooltip: 'Change profile photo',
                              padding: EdgeInsets.zero,
                              style: IconButton.styleFrom(
                                  backgroundColor: AppColors.accent,
                                  minimumSize: const Size(32, 32)),
                              icon: const Icon(Icons.camera_alt, size: 16, color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),
                  const Text('Full Name', style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(prefixIcon: Icon(Icons.person_outline)),
                  ),
                  const SizedBox(height: 16),
                  const Text('Phone Number', style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(prefixIcon: Icon(Icons.phone_outlined)),
                  ),
                  const SizedBox(height: 16),
                  const Text('Address', style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _addressController,
                    decoration: const InputDecoration(prefixIcon: Icon(Icons.location_on_outlined)),
                  ),
                  const SizedBox(height: 28),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _save,
                      child: _isSaving
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.4),
                            )
                          : const Text('Save Changes'),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
