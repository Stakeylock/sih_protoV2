# SIH Proto V2

[![Flutter](https://img.shields.io/badge/Flutter-3.24.0-blue)](https://flutter.dev)
[![Node.js](https://img.shields.io/badge/Node.js-18.x-green)](https://nodejs.org)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

## Overview

SIH Proto V2 is a prototype application built for the Smart India Hackathon (SIH) focusing on Decentralized Identity (DID) issuance and verification using Flutter for the mobile frontend and Node.js for the backend issuer service. The app allows users to request and manage DIDs securely, with a focus on privacy-preserving identity solutions.

This repository contains:
- **Flutter App**: Cross-platform mobile app (Android/iOS) for user interaction, located in the `sih_proto` directory.
- **DID Issuer Backend**: Node.js server handling DID creation, issuance, and API endpoints, located in the `did-key-issuer` directory.

## Repository Structure
- `did-key-issuer/`: Backend Node.js application (JS version of TS files)
  - Contains server code, package.json, and related dependencies.
- `sih_proto/`: Frontend Flutter application
  - Basic digital ID generation app.
  - Standard Flutter structure: `lib/`, `android/`, `ios/`, `pubspec.yaml`, etc.
- `README.md`: This file.

## Features
- User-friendly Flutter interface for DID requests and verification.
- Secure Node.js backend for issuing verifiable credentials.
- Support for TypeScript development with compiled JavaScript builds (source in `src/`, compiled in `dist/` for `did-key-issuer`).
- APK generation for Android deployment.
- RESTful API for integration and testing.

## Prerequisites
- **Flutter SDK**: Version 3.24.0 or higher. Install from [flutter.dev](https://flutter.dev).
- **Node.js**: Version 18.x or higher. Install from [nodejs.org](https://nodejs.org).
- **npm**: Version 9.x or higher (comes with Node.js).
- **Android Studio**: For Android development and APK building (includes Android SDK).
- **Git**: For cloning the repository.
- Optional: VS Code or Android Studio for IDE.

Ensure your development environment is set up with Flutter doctor (`flutter doctor`) and Node version check (`node -v`).

## Installation

### 1. Clone the Repository
```bash
git clone https://github.com/Stakeylock/sih_protoV2.git
cd sih_protoV2
```

### 2. Backend Setup (DID Issuer)
The backend is located in the `did-key-issuer` directory. It uses TypeScript for development (source in `src/`) and compiles to JavaScript (in `dist/`).

```bash
cd did-key-issuer
npm install
```

- **For TypeScript Users (Development Mode)**:
  - Run the server directly from source:
    ```bash
    npm run dev  # Uses ts-node to run src/server.ts
    ```
  - This watches for changes in `src/` and restarts on save.

- **For JavaScript Users (Production Mode)**:
  - First, compile TypeScript to JavaScript:
    ```bash
    npm run build  # Compiles src/ to dist/
    ```
  - Then run the server:
    ```bash
    npm start  # Runs dist/server.js
    ```

The server will start on `http://localhost:3000` by default. Check `package.json` for scripts and `src/index.ts` for configuration (e.g., port, database connections).

### 3. Frontend Setup (Flutter App)
The Flutter app is in the `sih_proto` directory.

```bash
cd ../sih_proto  # From root or did-key-issuer
flutter pub get
```

- Ensure the backend is running before proceeding to usage.

## Usage

### Running the Flutter App
1. Start the backend server (as described in Backend Setup).
2. In the `sih_proto` directory:
   ```bash
   cd sih_proto
   flutter run
   ```
   - This launches the app on a connected device or emulator (Android/iOS).
   - The app will connect to the backend at `http://localhost:3000` (update `lib/config.dart` for custom URLs in production).

### Testing the App
- Use an Android emulator or physical device.
- Navigate through screens: Login → DID Request → Verification.
- Logs: Check Flutter console for app logs and Node.js terminal for backend logs.

## Building APK for Android

To generate a release-ready APK:

1. Ensure the backend is configured for production (e.g., update API base URL in `sih_proto/lib/config.dart` to your deployed server).
2. In the `sih_proto` directory:
   ```bash
   flutter build apk --release
   ```
   - Output: `build/app/outputs/flutter-apk/app-release.apk`.
   - This creates a signed APK (default debug keystore; for production, generate a keystore via `keytool` and update `android/key.properties`).

3. Install on device:
   ```bash
   adb install build/app/outputs/flutter-apk/app-release.apk
   ```

For App Bundle (Google Play):
```bash
flutter build appbundle --release
```

**Notes**:
- Obfuscate code for production: Add `--obfuscate --split-debug-info=build/`.
- Test on multiple devices for compatibility.

## API Documentation

The backend exposes RESTful APIs for DID issuance and verification. Use tools like Postman, Insomnia, or curl for testing. Base URL: `http://localhost:3000/api/v1`.

All endpoints require authentication (JWT token in `Authorization: Bearer <token>` header, obtained via `/auth/login`).

### Authentication
- **POST /api/v1/auth/login**
  - Body: `{ "email": "string", "password": "string" }`
  - Response: `{ "token": "string", "userId": "string" }`
  - Description: Authenticate user and get JWT.

- **POST /api/v1/auth/register**
  - Body: `{ "email": "string", "password": "string", "name": "string" }`
  - Response: `{ "userId": "string", "message": "User created" }`
  - Description: Register a new user.

### DID Issuer Endpoints
- **POST /api/v1/did/request**
  - Headers: `Authorization: Bearer <token>`
  - Body: `{ "userId": "string", "attributes": ["name", "email"] }` (array of verifiable attributes)
  - Response: `{ "did": "did:example:123", "status": "pending", "credential": "vc-json-string" }`
  - Description: Request a new DID. Returns verifiable credential (VC) in JSON-LD format.

- **GET /api/v1/did/:did/verify**
  - Headers: `Authorization: Bearer <token>`
  - Path Param: `did` (e.g., `did:example:123`)
  - Response: `{ "valid": true, "proof": "signature-data", "claims": { "name": "John Doe" } }`
  - Description: Verify an existing DID/VC.

- **GET /api/v1/did/user/:userId**
  - Headers: `Authorization: Bearer <token>`
  - Path Param: `userId`
  - Response: Array of `{ "did": "string", "issuedAt": "ISO-date", "status": "active/revoked" }`
  - Description: List user's issued DIDs.

### Error Handling
- All errors return: `{ "error": "string", "code": 400/401/500 }`
- Common codes:
  - 400: Bad Request (invalid body).
  - 401: Unauthorized (missing/invalid token).
  - 500: Internal Server Error (log for details).

### Testing APIs
- Run the server and use:
  ```bash
  curl -X POST http://localhost:3000/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","password":"password"}'
  ```
- For full OpenAPI spec, run `npm run docs` in `did-key-issuer` (generates Swagger JSON in `docs/` if Swagger is integrated).

## Contributing
1. Fork the repo.
2. Create a feature branch (`git checkout -b feature/AmazingFeature`).
3. Commit changes (`git commit -m 'Add some AmazingFeature'`).
4. Push to branch (`git push origin feature/AmazingFeature`).
5. Open a Pull Request.

For backend: Update `src/` and run `npm run build`. For frontend: Run `flutter pub get` after changes.

## License
This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Contact
- **Author**: Stakeylock
- **Email**: [bhairab.ok@gmail.com](mailto:bhairab.ok@gmail.com)
- **Issues**: Report bugs or request features on GitHub.

---
