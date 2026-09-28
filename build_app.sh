#!/bin/bash
set -e

echo "🔨 Building MacAssistiveTouch with SwiftPM..."
swift build -c release

APP_DIR="MacAssistiveTouch.app"
CONTENTS_DIR="$APP_DIR/Contents"
MACOS_DIR="$CONTENTS_DIR/MacOS"
RESOURCES_DIR="$CONTENTS_DIR/Resources"

echo "📦 Packaging $APP_DIR..."
rm -rf "$APP_DIR"
mkdir -p "$MACOS_DIR"
mkdir -p "$RESOURCES_DIR"

# Binary'yi kopyala
cp .build/release/MacAssistiveTouch "$MACOS_DIR/"

# Logo ve ikonları Resources'a kopyala
if [ -f "Sources/MacAssistiveTouch/Resources/AppIcon.icns" ]; then
    cp Sources/MacAssistiveTouch/Resources/AppIcon.icns "$RESOURCES_DIR/"
fi
if [ -f "Sources/MacAssistiveTouch/Resources/AppLogo.png" ]; then
    cp Sources/MacAssistiveTouch/Resources/AppLogo.png "$RESOURCES_DIR/"
fi

# Info.plist oluştur
cat << 'EOF' > "$CONTENTS_DIR/Info.plist"
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>MacAssistiveTouch</string>
    <key>CFBundleIdentifier</key>
    <string>com.abdurrahimicyer.MacAssistiveTouch</string>
    <key>CFBundleName</key>
    <string>MacAssistiveTouch</string>
    <key>CFBundleDisplayName</key>
    <string>AssistiveTouch</string>
    <key>CFBundleIconFile</key>
    <string>AppIcon</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>LSMinimumSystemVersion</key>
    <string>14.0</string>
    <key>LSUIElement</key>
    <true/>
    <key>NSHighResolutionCapable</key>
    <true/>
</dict>
</plist>
EOF

echo "✅ Successfully created $APP_DIR"
