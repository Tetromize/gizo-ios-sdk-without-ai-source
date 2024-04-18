# Check for arguments
if [ $# -eq 0 ]; then
    echo "No arguments provided. First argument has to be version, e.g. '1.8.1', and second one the name of framework, e.g. 'NetworkModule'"
    exit 1
fi

# Set properties
FRAMEWORK_VERSION=$2
FRAMEWORK_NAME=$1

echo "SDK Name : $FRAMEWORK_NAME"
echo "Version  : $FRAMEWORK_VERSION"

1. Remove old data for prevent issues for the new data
echo "Remove old xcframework resources..."
rm -rf "$FRAMEWORK_NAME.xcframework"
rm -rf "$FRAMEWORK_NAME.xcframework.zip"
rm -rf archives
rm -rf NetworkModuleDistribution


# 2. Archive framework (iOS)
echo "Building for iOS..."
xcodebuild archive \
  -scheme $FRAMEWORK_NAME \
  -destination="iOS" \
  -archivePath "archives/ios_devices.xcarchive" \
  -sdk iphoneos \
  BUILD_LIBRARY_FOR_DISTRIBUTION=YES \
  OTHER_SWIFT_FLAGS=-no-verify-emitted-module-interface \
  SKIP_INSTALL=NO


# 3. Archive framework (iOS Simulators)
echo "Building for iOS Simulator..."
xcodebuild archive \
  -scheme $FRAMEWORK_NAME \
  -sdk iphonesimulator \
  -archivePath "archives/ios_simulators.xcarchive" \
  -arch x86_64 -arch arm64 \
  BUILD_LIBRARY_FOR_DISTRIBUTION=YES \
  OTHER_SWIFT_FLAGS=-no-verify-emitted-module-interface \
  SKIP_INSTALL=NO

# 5. Build XCFramework
echo "Building XCFramework..."
xcodebuild -create-xcframework -output "$FRAMEWORK_NAME.xcframework" \
  -framework "archives/ios_devices.xcarchive/Products/Library/Frameworks/$FRAMEWORK_NAME.framework" \
  -framework "archives/ios_simulators.xcarchive/Products/Library/Frameworks/$FRAMEWORK_NAME.framework"


# 6. Compress XCframework for distribute on a hosted way
echo "Compressing XCFramework..."
zip -r -X "$FRAMEWORK_NAME.xcframework.zip" "$FRAMEWORK_NAME.xcframework"


# 1. Remove old data for prevent issues for the new data
echo "Remove old xcframework resources..."
rm -rf "$FRAMEWORK_NAME.xcframework"
rm -rf archives
rm -rf gizo-ios-sdk-alpha

# 9. Clone distribution framework to manage from here the release and distribution via SPM
echo "Cloning distribution framework..."
git clone https://github.com/artificient-ai/gizo-ios-sdk-alpha.git

# 10. Move XCFramework generated to the Distribution repository
echo "Move XCFramework inside cloned repo..."
mv ${FRAMEWORK_NAME}.xcframework.zip gizo-ios-sdk-alpha

# 11. Place to the cloned repo directory
echo "cd gizo-ios-sdk-alpha ..."
cd gizo-ios-sdk-alpha


# 12. Launch prepare_package script within cloned repo
echo "sh prepare_package.sh $FRAMEWORK_VERSION $FRAMEWORK_NAME..."
sh prepare_package.sh $FRAMEWORK_VERSION $FRAMEWORK_NAME

# 13. Remove old gizo-ios-sdk-alpha folder
echo "Remove old gizo-ios-sdk-alpha folder"
rm -rf gizo-ios-sdk-alpha
