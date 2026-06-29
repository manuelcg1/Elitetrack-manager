import 'dart:io';

const _defaultAppName = 'EliteTrack';
const _defaultPackageId = 'org.traccar.manager';
const _defaultVersion = '6.0.5+71';
const _defaultUrl = 'https://www.elitetrack.site/';
const _defaultDeepLinkScheme = _defaultPackageId;

final appName = _env('APP_NAME', _defaultAppName);
final packageId = _env('PACKAGE_ID', _defaultPackageId);
final version = _env('APP_VERSION', _defaultVersion);
final url = _env('SERVER_URL', _defaultUrl);
final deepLinkScheme = _env('DEEP_LINK_SCHEME', _defaultDeepLinkScheme);
final iconPath = _env(
  'ICON_PATH',
  '${Platform.environment['USERPROFILE'] ?? Platform.environment['HOME']}/Downloads/icon.png',
);

const keystoreFilePath = 'android/android.keystore';
final keystoreAlias = _env('KEYSTORE_ALIAS', 'key');
final keystorePassword = Platform.environment['KEYSTORE_PASSWORD'];

Future<void> main() async {
  _validate();
  await _generateIcons(iconPath);
  await _updateTitle(appName);
  await _updatePackageId(packageId);
  await _updateVersion(version);
  await _updateAppConfig();
  await _updateDeepLinkScheme(deepLinkScheme);
  await _createKeystore();
  stdout.writeln('Please run `flutterfire configure` now.');
}

String _env(String name, String fallback) {
  return Platform.environment[name] ?? fallback;
}

void _validate() {
  final serverUri = Uri.tryParse(url);
  if (serverUri == null || !serverUri.isAbsolute) {
    throw ArgumentError('SERVER_URL must be an absolute URL.');
  }
  if (!File(iconPath).existsSync()) {
    throw ArgumentError('ICON_PATH does not exist: $iconPath');
  }
  if (keystorePassword == null || keystorePassword!.length < 8) {
    throw ArgumentError('KEYSTORE_PASSWORD must have at least 8 characters.');
  }
}

Future<void> _generateIcons(String icon) async {
  final dir = Directory('ios/Runner/Assets.xcassets/AppIcon.appiconset');
  dir.deleteSync(recursive: true);
  dir.createSync();

  await _deleteIfExists(
    'android/app/src/main/res/drawable/ic_launcher_foreground.xml',
  );
  await _deleteIfExists(
    'android/app/src/main/res/mipmap-anydpi-v26/ic_launcher.xml',
  );

  final f = await _writeTempYaml('flutter_launcher_icons.yaml', '''
flutter_launcher_icons:
  android: true
  ios: true
  image_path: "$icon"
  remove_alpha_ios: true
''');
  await _run('flutter', ['pub', 'run', 'flutter_launcher_icons']);
  await f.delete();

  await _replaceInFile(
    'android/app/src/main/AndroidManifest.xml',
    RegExp(
      r'\s*<meta-data\s+android:name="com\.google\.firebase\.messaging\.default_notification_icon"[\s\S]*?/>',
      multiLine: true,
    ),
    '',
  );
}

Future<void> _updateTitle(String name) async {
  await _replaceInFile(
    'android/app/src/main/AndroidManifest.xml',
    RegExp(r'android:label="[^"]*"'),
    'android:label="$name"',
  );

  await _replaceInFile(
    'ios/Runner/Info.plist',
    RegExp(r'<key>CFBundleDisplayName</key>\s*<string>.*?</string>'),
    '<key>CFBundleDisplayName</key>\n\t<string>$name</string>',
  );
}

Future<void> _updatePackageId(String id) async {
  await _replaceInFile(
    'android/app/build.gradle.kts',
    RegExp(r'namespace = ".*?"'),
    'namespace = "$id"',
  );

  await _replaceInFile(
    'android/app/build.gradle.kts',
    RegExp(r'applicationId = ".*?"'),
    'applicationId = "$id"',
  );

  await _replaceInFile(
    'ios/Runner.xcodeproj/project.pbxproj',
    RegExp(r'PRODUCT_BUNDLE_IDENTIFIER = org\.traccar\.TraccarManager;'),
    'PRODUCT_BUNDLE_IDENTIFIER = $id;',
  );
}

Future<void> _updateVersion(String version) async {
  await _replaceInFile(
    'pubspec.yaml',
    RegExp(r'^version:\s*.*$', multiLine: true),
    'version: $version',
  );
}

Future<void> _updateAppConfig() async {
  await _replaceInFileMapped(
    'lib/app_config.dart',
    RegExp(
      r"(static const name = String\.fromEnvironment\(\s*'APP_NAME',\s*)defaultValue: '[^']*',",
      multiLine: true,
    ),
    (match) => "${match[1]}defaultValue: '${_escapeDartString(appName)}',",
  );

  await _replaceInFileMapped(
    'lib/app_config.dart',
    RegExp(
      r"(static const serverUrl = String\.fromEnvironment\(\s*'SERVER_URL',\s*)defaultValue: '[^']*',",
      multiLine: true,
    ),
    (match) => "${match[1]}defaultValue: '${_escapeDartString(url)}',",
  );

  await _replaceInFileMapped(
    'lib/app_config.dart',
    RegExp(
      r"(static const deepLinkScheme = String\.fromEnvironment\(\s*'DEEP_LINK_SCHEME',\s*)defaultValue: '[^']*',",
      multiLine: true,
    ),
    (match) => "${match[1]}defaultValue: '${_escapeDartString(deepLinkScheme)}',",
  );
}

String _escapeDartString(String value) {
  return value.replaceAll('\\', '\\\\').replaceAll("'", r"\'");
}

Future<void> _updateDeepLinkScheme(String scheme) async {
  await _replaceInFile(
    'android/app/src/main/AndroidManifest.xml',
    RegExp(r'android:scheme="[^"]*"'),
    'android:scheme="$scheme"',
  );

  await _replaceInFile(
    'ios/Runner/Info.plist',
    RegExp(
      r'<key>CFBundleURLSchemes</key>\s*<array>\s*<string>.*?</string>\s*</array>',
    ),
    '<key>CFBundleURLSchemes</key>\n\t\t\t<array>\n\t\t\t\t<string>$scheme</string>\n\t\t\t</array>',
  );
}

Future<void> _createKeystore() async {
  final args = [
    '-genkeypair',
    '-v',
    '-keystore', keystoreFilePath,
    '-alias', keystoreAlias,
    '-keyalg', 'RSA',
    '-keysize', '2048',
    '-validity', '10000',
    '-storepass', keystorePassword!,
    '-keypass', keystorePassword!,
    '-dname', 'CN=Brand, OU=Dev, O=Company, L=City, S=State, C=US',
  ];
  await _run('keytool', args);

  final file = File('android/key.properties');
  final content = '''
storePassword=$keystorePassword
keyPassword=$keystorePassword
keyAlias=$keystoreAlias
storeFile=../../$keystoreFilePath
''';
  await file.writeAsString(content);

  await _replaceInFile(
    'android/app/build.gradle.kts',
    RegExp(r'val\s+keystorePropertiesFile\s*=.*'),
    'val keystorePropertiesFile = rootProject.file("key.properties")',
  );
}

Future<File> _writeTempYaml(String name, String content) async {
  final file = File(name);
  await file.writeAsString(content);
  return file;
}

Future<void> _deleteIfExists(String path) async {
  final file = File(path);
  if (await file.exists()) await file.delete();
}

Future<void> _replaceInFile(
  String path,
  RegExp pattern,
  String replacement,
) async {
  final file = File(path);
  if (!await file.exists()) return;
  final text = await file.readAsString();
  final newText = text.replaceAll(pattern, replacement);
  if (newText != text) await file.writeAsString(newText);
}

Future<void> _replaceInFileMapped(
  String path,
  RegExp pattern,
  String Function(RegExpMatch match) replace,
) async {
  final file = File(path);
  if (!await file.exists()) return;
  final text = await file.readAsString();
  final newText = text.replaceAllMapped(pattern, replace);
  if (newText != text) await file.writeAsString(newText);
}

Future<void> _run(String cmd, List<String> args) async {
  final proc = await Process.start(cmd, args);
  await stdout.addStream(proc.stdout);
  await stderr.addStream(proc.stderr);
  final code = await proc.exitCode;
  if (code != 0) throw Exception('$cmd ${args.join(" ")} failed ($code)');
}
