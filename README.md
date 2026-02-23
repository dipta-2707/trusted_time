# Trusted Time Service

A **tamper-resistant trusted time service** for Flutter and Dart apps.

This package provides a secure and reliable time source that **does not depend on the device clock**, making it ideal for security-sensitive use cases like OTP expiry, payments, token validation, and anti-cheat systems.

---

## ✨ Features

- Fetches **trusted UTC time** from HTTPS servers
- Anchors to **native monotonic uptime** via FFI
- Calculates **trusted current time** without relying on device clock
- Supports **custom timezone offsets**
- Manual **trusted anchor injection** for server-provided time
- Safe **fallback to system time** if initialization fails
- Ready-to-use on **Android and iOS**
- Secure and **tamper-resistant** design

---

## 📦 Installation

Add this to your `pubspec.yaml`:

```yaml
dependencies:
  trusted_time_service: latest
```

Then run:

```bash
flutter pub get
```

---

## 🔧 Platform Setup

This package uses native uptime through FFI and is **ready to use out of the box**.

### Android
✅ Fully supported. No additional setup required.

### iOS
✅ Fully supported. No additional setup required.

Simply add the package and start using it.


---

## 🧪 Basic Usage

### Initialize once at app startup

```dart
import 'package:trusted_time_service/trusted_time_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await TrustedTimeService().initialize(
    defaultOffsetHours: 6, // Example timezone
  );

  runApp(const MyApp());
}
```

---

### Get trusted current time

```dart
final now = TrustedTimeService().now();
print(now);
```

---

### Get trusted UTC

```dart
final utc = TrustedTimeService().nowUtc();
```

---

### Provide custom offset

```dart
final local = TrustedTimeService().now(
  offsetHours: 6,
);
```

---

## 🧪 Advanced Usage

### Use server-provided trusted time

If you already have a trusted time source (for example, your own backend or secure server), you can directly use that time as the anchor instead of calling the default HTTPS provider.

```dart
await TrustedTimeService().initialize(
  trustedAnchorUtc: serverTime,
);
```

---

### Reset trusted time

```dart
TrustedTimeService().reset();
```

Useful when:

* User logs out
* Security refresh is needed

---

## 📊 Comparison

| Feature          | System Time | Trusted Time |
| ---------------- | ----------- | ------------ |
| Tamper resistant | ❌           | ✅            |
| Timezone safe    | ❌           | ✅            |
| Monotonic        | ❌           | ✅            |
| Secure           | ❌           | ✅            |


---

## 🌟 Contributors

We appreciate everyone who contributes to making this package better ❤️

<p align="left"> <a href="https://github.com/ishafiul/" target="_blank" rel="noreferrer"> <img src="https://avatars.githubusercontent.com/u/45520613?v=4" alt="ishafiul" width="50" height="50"/> </a> </p>


---

## 🤝 Welcome to Contribute

We warmly welcome developers from all experience levels to contribute ❤️

You can help by:

* Fixing bugs
* Improving performance
* Adding features
* Writing documentation
* Creating examples
* Improving platform support

Even small contributions make a big difference.

If you are new to open source, this is a great project to start!

---

## 📬 Support

If you find this package useful:

* ⭐ Star the repository
* Share it with the community
* Open issues for suggestions

---

## 📄 License

MIT License
