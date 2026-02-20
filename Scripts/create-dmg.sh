#!/bin/bash
set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
APP_NAME="EKTimer"
VERSION="1.0.0"
DMG_NAME="${APP_NAME}-${VERSION}"
DMG_FINAL="$PROJECT_DIR/${DMG_NAME}.dmg"
DMG_TEMP="$PROJECT_DIR/.build/${DMG_NAME}-temp.dmg"
STAGING_DIR="$PROJECT_DIR/.build/dmg-staging"

# Step 1: Build the app
echo "==> Building app..."
"$PROJECT_DIR/Scripts/build.sh"

APP_BUNDLE="$PROJECT_DIR/$APP_NAME.app"
if [ ! -d "$APP_BUNDLE" ]; then
    echo "Error: $APP_BUNDLE not found"
    exit 1
fi

# Step 2: Create staging directory
echo "==> Preparing DMG contents..."
rm -rf "$STAGING_DIR"
mkdir -p "$STAGING_DIR"
cp -R "$APP_BUNDLE" "$STAGING_DIR/"
ln -s /Applications "$STAGING_DIR/Applications"

# Step 3: Generate background image with Swift (CoreGraphics, no deps)
echo "==> Generating background image..."
BACKGROUND_DIR="$STAGING_DIR/.background"
mkdir -p "$BACKGROUND_DIR"

SWIFT_TEMP="$PROJECT_DIR/.build/dmg-background-gen.swift"
cat > "$SWIFT_TEMP" << 'SWIFTEOF'
import AppKit
import CoreGraphics
import CoreText
import ImageIO
import Foundation
import UniformTypeIdentifiers

let outputPath = CommandLine.arguments[1]
let width = 600, height = 400

let colorSpace = CGColorSpaceCreateDeviceRGB()
guard let ctx = CGContext(
    data: nil, width: width, height: height,
    bitsPerComponent: 8, bytesPerRow: width * 4,
    space: colorSpace,
    bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
) else {
    print("Failed to create context")
    exit(1)
}

// Dark background
ctx.setFillColor(red: 0.15, green: 0.15, blue: 0.17, alpha: 1.0)
ctx.fill(CGRect(x: 0, y: 0, width: width, height: height))

// Arrow line
ctx.setStrokeColor(red: 0.55, green: 0.55, blue: 0.6, alpha: 1.0)
ctx.setLineWidth(2.5)
ctx.move(to: CGPoint(x: 210, y: 200))
ctx.addLine(to: CGPoint(x: 380, y: 200))
ctx.strokePath()

// Arrowhead
ctx.setFillColor(red: 0.55, green: 0.55, blue: 0.6, alpha: 1.0)
ctx.move(to: CGPoint(x: 365, y: 215))
ctx.addLine(to: CGPoint(x: 385, y: 200))
ctx.addLine(to: CGPoint(x: 365, y: 185))
ctx.closePath()
ctx.fillPath()

// "Drag to install" text
let text = "Drag to install" as NSString
let attrs: [NSAttributedString.Key: Any] = [
    .font: NSFont.systemFont(ofSize: 14, weight: .medium),
    .foregroundColor: NSColor(red: 0.7, green: 0.7, blue: 0.75, alpha: 1.0)
]
let attrStr = NSAttributedString(string: text as String, attributes: attrs)
let line = CTLineCreateWithAttributedString(attrStr)
let textBounds = CTLineGetBoundsWithOptions(line, [])
let textX = CGFloat(width) / 2.0 - textBounds.width / 2.0
ctx.textPosition = CGPoint(x: textX, y: 235)
CTLineDraw(line, ctx)

// Save as PNG
guard let image = ctx.makeImage() else {
    print("Failed to create image")
    exit(1)
}
let url = URL(fileURLWithPath: outputPath) as CFURL
guard let dest = CGImageDestinationCreateWithURL(url, UTType.png.identifier as CFString, 1, nil) else {
    print("Failed to create image destination")
    exit(1)
}
CGImageDestinationAddImage(dest, image, nil)
CGImageDestinationFinalize(dest)
print("Background image saved: \(outputPath)")
SWIFTEOF

# Compile and run the Swift background generator
DMG_BG_BIN="$PROJECT_DIR/.build/dmg-bg-gen"
swiftc -o "$DMG_BG_BIN" "$SWIFT_TEMP"
"$DMG_BG_BIN" "$BACKGROUND_DIR/background.png"
rm -f "$SWIFT_TEMP" "$DMG_BG_BIN"

# Step 4: Calculate DMG size (app size + 20MB headroom)
APP_SIZE_KB=$(du -sk "$APP_BUNDLE" | cut -f1)
DMG_SIZE_KB=$((APP_SIZE_KB + 20480))

# Step 5: Create read-write DMG
echo "==> Creating DMG..."
rm -f "$DMG_TEMP" "$DMG_FINAL"

hdiutil create \
    -srcfolder "$STAGING_DIR" \
    -volname "$APP_NAME" \
    -fs HFS+ \
    -fsargs "-c c=64,a=16,e=16" \
    -format UDRW \
    -size "${DMG_SIZE_KB}k" \
    "$DMG_TEMP"

# Step 6: Mount and configure window layout via AppleScript
echo "==> Configuring DMG window..."
MOUNT_OUTPUT=$(hdiutil attach -readwrite -noverify -noautoopen "$DMG_TEMP")
DEVICE=$(echo "$MOUNT_OUTPUT" | grep "^/dev/" | head -1 | awk '{print $1}')
MOUNT_POINT="/Volumes/$APP_NAME"

# Wait for mount
sleep 2

# Set window properties with AppleScript
osascript << APPLESCRIPT
tell application "Finder"
    tell disk "$APP_NAME"
        open
        set current view of container window to icon view
        set toolbar visible of container window to false
        set statusbar visible of container window to false
        set bounds of container window to {100, 100, 700, 500}
        set theViewOptions to icon view options of container window
        set arrangement of theViewOptions to not arranged
        set icon size of theViewOptions to 80
        set background picture of theViewOptions to file ".background:background.png"
        set position of item "$APP_NAME.app" of container window to {150, 200}
        set position of item "Applications" of container window to {450, 200}
        close
        open
        update without registering applications
        delay 2
        close
    end tell
end tell
APPLESCRIPT

# Ensure writes are flushed
sync
sleep 2

# Step 7: Unmount
hdiutil detach "$DEVICE" -quiet || hdiutil detach "$DEVICE" -force

# Step 8: Convert to compressed read-only DMG
echo "==> Compressing DMG..."
hdiutil convert "$DMG_TEMP" \
    -format UDZO \
    -imagekey zlib-level=9 \
    -o "$DMG_FINAL"

rm -f "$DMG_TEMP"
rm -rf "$STAGING_DIR"

echo ""
echo "==> Done! Installer created:"
echo "    $DMG_FINAL"
DMG_SIZE=$(du -h "$DMG_FINAL" | cut -f1)
echo "    Size: $DMG_SIZE"
