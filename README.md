# Laboratorio 15 - FieldTech Móvil (IF0009, UCR Sede del Atlántico)

    laboratorio_15_workspace/
    ├── fieldtech-backend/   Spring Boot 3 (domain, data, business, controller) + H2
    └── fieldtech_mobile/    Flutter 3 (sqflite, geolocator, image_picker, http)

## Backend
    cd fieldtech-backend
    mvn test
    mvn spring-boot:run

## Móvil
    cd fieldtech_mobile
    .\setup_mobile.ps1        # genera android/ios, aplica permisos, flutter pub get
    flutter analyze
    flutter test
    flutter run

Las carpetas android/ e ios/ no vienen incluidas: las genera setup_mobile.ps1.
NO ejecute `flutter create .` a mano sin el script: sobrescribe lib/main.dart y pubspec.yaml.
