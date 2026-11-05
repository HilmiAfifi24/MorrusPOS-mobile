# MorrusPOS Mobile

Aplikasi kasir Flutter untuk login, pemilihan outlet, sesi kasir, katalog, checkout, capability, dan pembaruan stok real-time.

## Menjalankan

```bash
flutter pub get
flutter run
```

URL backend dapat diatur dari halaman pengaturan aplikasi.

## Quality checks

```bash
flutter analyze --no-fatal-infos
flutter test --coverage
```

Test berada di `test/` dan mencakup auth, capability, sesi kasir, produk, tracking batch/serial, serta idempotency checkout. Repository palsu ditulis langsung dengan interface domain agar test tidak membutuhkan jaringan atau dependency mocking tambahan.
