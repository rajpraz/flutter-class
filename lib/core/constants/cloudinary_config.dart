/// Fill these in with your Cloudinary account's cloud name and an
/// *unsigned* upload preset (Cloudinary console → Settings → Upload →
/// Upload presets → Add upload preset → Signing Mode: Unsigned).
class CloudinaryConfig {
  static const String cloudName = 'YOUR_CLOUD_NAME';
  static const String uploadPreset = 'YOUR_UPLOAD_PRESET';

  static bool get isConfigured =>
      cloudName != 'YOUR_CLOUD_NAME' && uploadPreset != 'YOUR_UPLOAD_PRESET';
}
