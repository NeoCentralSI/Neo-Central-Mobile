/// App asset paths constants
/// 
/// Contains all asset paths used throughout the application.
/// Centralized asset management for easy maintenance.
abstract class AppAssets {
  AppAssets._();

  // Image Assets
  static const String _imagesPath = 'assets/images';
  
  // Logo
  static const String logo = '$_imagesPath/neocentral_logo.png';
  static const String microsoftLogo = '$_imagesPath/microsoft_logo.png';
}
