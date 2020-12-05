all: basic admin

basic:
	flutter build appbundle && cp build/app/outputs/bundle/release/app-release.aab app-release.aab

admin:
	flutter build appbundle --dart-define=admin=true && cp build/app/outputs/bundle/release/app-release.aab app-admin.aab

install:
	flutter build apk --target-platform android-arm64 --dart-define=admin=true && flutter install
