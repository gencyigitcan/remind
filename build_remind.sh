#!/bin/bash
set -e

APP_NAME="Remind"
APP_BUNDLE="${APP_NAME}.app"
DMG_NAME="${APP_NAME}.dmg"

echo "🚀 Building ${APP_NAME} for $(uname -m)..."
swift build -c release

# Locate binary
BUILD_DIR=$(swift build -c release --show-bin-path)
echo "📍 Binary found at: ${BUILD_DIR}"

echo "📦 Creating App Bundle..."
rm -rf "$APP_BUNDLE"
mkdir -p "$APP_BUNDLE/Contents/MacOS"
mkdir -p "$APP_BUNDLE/Contents/Resources"

# Copy binary
cp "$BUILD_DIR/$APP_NAME" "$APP_BUNDLE/Contents/MacOS/"
chmod +x "$APP_BUNDLE/Contents/MacOS/$APP_NAME"

# Copy Info.plist
cp Info.plist "$APP_BUNDLE/Contents/"

# Set PkgInfo (standard practice)
echo "APPL????" > "$APP_BUNDLE/Contents/PkgInfo"

echo "🎨 Processing Icon..."
# Create iconset folder
mkdir -p Remind.iconset
# Resize original image to required sizes. valid commands with explicit format.
sips -z 16 16     -s format png Remind_Icon.png --out Remind.iconset/icon_16x16.png
sips -z 32 32     -s format png Remind_Icon.png --out Remind.iconset/icon_16x16@2x.png
sips -z 32 32     -s format png Remind_Icon.png --out Remind.iconset/icon_32x32.png
sips -z 64 64     -s format png Remind_Icon.png --out Remind.iconset/icon_32x32@2x.png
sips -z 128 128   -s format png Remind_Icon.png --out Remind.iconset/icon_128x128.png
sips -z 256 256   -s format png Remind_Icon.png --out Remind.iconset/icon_128x128@2x.png
sips -z 256 256   -s format png Remind_Icon.png --out Remind.iconset/icon_256x256.png
sips -z 512 512   -s format png Remind_Icon.png --out Remind.iconset/icon_256x256@2x.png
sips -z 512 512   -s format png Remind_Icon.png --out Remind.iconset/icon_512x512.png
sips -z 1024 1024 -s format png Remind_Icon.png --out Remind.iconset/icon_512x512@2x.png

# Convert iconset to icns
iconutil -c icns Remind.iconset -o AppIcon.icns
# Move to Resources
mv AppIcon.icns "$APP_BUNDLE/Contents/Resources/"
# Cleanup
rm -rf Remind.iconset

echo "🔏 Signing App (Ad-Hoc)..."
# This allows it to run locally without "developer unknown" blocking immediately on some systems, 
# although Gatekeeper might still complain if moved to another machine without notarization.
codesign --force --deep --sign - "$APP_BUNDLE"

echo "💿 Creating DMG..."
rm -f "$DMG_NAME"
hdiutil create -volname "$APP_NAME" -srcfolder "$APP_BUNDLE" -ov -format UDZO "$DMG_NAME"

echo "✅ Done! ${DMG_NAME} created."
open .
