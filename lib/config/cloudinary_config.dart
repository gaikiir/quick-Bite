// Cloudinary Configuration
// Replace these values with your actual Cloudinary credentials

class CloudinaryConfig {
  // Get these from your Cloudinary dashboard: https://console.cloudinary.com/
  static const String cloudName = 'dbuwnvmen'; // Your Cloudinary cloud name
  static const String uploadPreset = 'products'; // Your upload preset name
  static const String apiKey = '198826198296253'; // Your API key

  // API Secret (keep this secure - only use on server-side)
  // static const String apiSecret = 'your-api-secret';

  // Check if configuration is complete
  static bool get isConfigured =>
      cloudName != 'your-cloud-name' &&
      uploadPreset != 'your-upload-preset' &&
      apiKey != 'your-api-key';

  // Instructions for setup
  static const String setupInstructions = '''
  To set up Cloudinary image uploads:

  1. Go to https://console.cloudinary.com/ and sign up/login
  2. Get your Cloud Name from the dashboard
  3. Create an Upload Preset:
     - Go to Settings > Upload
     - Click "Add upload preset"
     - Set Mode to "Unsigned" for client-side uploads
     - Copy the preset name
  4. Get your API Key from Account Settings > API Keys
  5. Replace the placeholder values in this file

  IMPORTANT: For production apps, implement server-side uploads
  using the API Secret to keep credentials secure.
  ''';
}
