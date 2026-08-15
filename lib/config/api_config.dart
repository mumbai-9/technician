/// API Configuration
///
/// This file manages the API base URL for different environments.
/// Change the configuration based on where you're running the app.
library;

class ApiConfig {
  // ============================================
  // CONFIGURATION - CHANGE THIS BASED ON YOUR SETUP
  // ============================================

  /// Set this to match your current testing environment
  /// PRODUCTION: For live/client use
  /// DEMO: For demo/testing on demo server
  /// PHYSICAL_DEVICE: For local development on physical device
  /// Get the appropriate base URL based on current environment
  static const Environment currentEnvironment = Environment.production;

  static String get baseUrl {
    return 'https://integrity.fortuneitcorp.com/api';
  }

  /// Get the appropriate storage URL based on current environment
  static String get storageUrl {
    return 'https://integrity.fortuneitcorp.com/storage';
  }

  // ============================================
  // DO NOT CHANGE BELOW THIS LINE
  // ============================================

  /// Get environment name for debugging
  static String get environmentName {
    switch (currentEnvironment) {
      case Environment.emulator:
        return 'Android Emulator (Live Hostinger)';
      case Environment.physicalDevice:
        return 'Physical Device (Live Hostinger)';
      case Environment.demo:
        return 'Demo Server';
      case Environment.production:
        return 'Live Hostinger Server';
    }
  }

  /// Check if running in development mode
  static bool get isDevelopment {
    return currentEnvironment == Environment.emulator ||
        currentEnvironment == Environment.production;
  }

  /// Check if running on demo server
  static bool get isDemo {
    return currentEnvironment == Environment.demo;
  }

  /// Check if running in production
  static bool get isProduction {
    return currentEnvironment == Environment.production;
  }
}

/// Available environments
enum Environment {
  /// Android Emulator - uses 10.0.2.2 to access laptop's localhost
  emulator,

  /// Physical Device - uses laptop's WiFi IP address (for local development)
  physicalDevice,

  /// Demo Server - uses demo.wpchat.in domain
  demo,

  /// Production Server - uses live production domain
  production,
}
