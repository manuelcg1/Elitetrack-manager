class AppConfig {
  static const name = String.fromEnvironment(
    'APP_NAME',
    defaultValue: 'EliteTrack',
  );

  static const serverUrl = String.fromEnvironment(
    'SERVER_URL',
    defaultValue: 'https://www.elitetrack.site/',
  );

  static const deepLinkScheme = String.fromEnvironment(
    'DEEP_LINK_SCHEME',
    defaultValue: 'org.traccar.manager',
  );

  static Uri get serverUri {
    final uri = Uri.parse(serverUrl);
    final normalizedPath = uri.path.endsWith('/') ? uri.path : '${uri.path}/';
    return uri.replace(path: normalizedPath);
  }
}
