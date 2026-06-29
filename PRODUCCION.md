# Preparacion para productivo

Esta app ya tiene la marca visible `EliteTrack`, pero antes de publicar debes cerrar estos puntos:

## 1. Servidor productivo

La app queda apuntando por defecto a:

```text
https://www.elitetrack.site/
```

Puedes compilar sin parametros extra:

```powershell
flutter clean
flutter pub get
flutter build apk --release
```

El APK queda en:

```text
build/app/outputs/flutter-apk/app-release.apk
```

Si quieres dejar el build totalmente explicito, usa:

```powershell
flutter build apk --release `
  --dart-define=APP_NAME=EliteTrack `
  --dart-define=SERVER_URL=https://www.elitetrack.site/ `
  --dart-define=DEEP_LINK_SCHEME=org.traccar.manager
```

Para subir a Play Store normalmente conviene generar AAB:

```powershell
flutter build appbundle --release `
  --dart-define=APP_NAME=EliteTrack `
  --dart-define=SERVER_URL=https://www.elitetrack.site/ `
  --dart-define=DEEP_LINK_SCHEME=org.traccar.manager
```

Puedes generar el APK desde Android Studio o desde Visual Studio Code. No hay problema con ninguno: ambos usan el mismo proyecto Flutter. Para un release controlado es mas claro hacerlo desde la terminal integrada de VS Code o Android Studio con `flutter build apk --release`.

## 2. Identificador de la app

Ahora el proyecto conserva el identificador original:

- Android: `org.traccar.manager`
- iOS: `org.traccar.TraccarManager`

Para publicar con marca propia deberias registrar identificadores propios, por ejemplo `com.tuempresa.elitetrack`.
Al cambiarlo tambien debes regenerar Firebase:

```powershell
flutterfire configure
```

Esto debe actualizar:

- `android/app/google-services.json`
- `ios/Runner/GoogleService-Info.plist`
- `lib/firebase_options.dart`
- `firebase.json`

## 3. Firma de Android

No publiques con claves de ejemplo. Guarda `android/key.properties` fuera del repositorio o mantenlo ignorado.
El script `tool/brand.dart` exige `KEYSTORE_PASSWORD` para evitar claves con password fija.

Si compilas sin `android/key.properties`, el APK sirve para pruebas internas, pero para publicacion formal necesitas configurar la firma release con un keystore propio.

Ejemplo de preparacion:

```powershell
$env:APP_NAME="EliteTrack"
$env:PACKAGE_ID="com.tuempresa.elitetrack"
$env:APP_VERSION="1.0.0+1"
$env:SERVER_URL="https://www.elitetrack.site/"
$env:DEEP_LINK_SCHEME="com.tuempresa.elitetrack"
$env:ICON_PATH="C:\ruta\a\icon.png"
$env:KEYSTORE_PASSWORD="cambia-este-password"
dart run tool/brand.dart
```

## 4. Checklist antes de publicar

- Verificar que `SERVER_URL` sea HTTPS y apunte al servidor productivo.
- Confirmar que Firebase use el `packageId` y bundle id definitivos.
- Ejecutar `flutter analyze`.
- Probar login, notificaciones push, descarga de reportes y enlaces OAuth/deep links.
- Compilar `flutter build appbundle --release`.
- Probar el AAB/APK en un dispositivo limpio antes de subirlo.
