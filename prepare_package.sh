#!/bin/sh

# Check for arguments
if [ $# -eq 0 ]; then
    echo "No arguments provided. First argument has to be version, e.g. '1.8.1'"
    exit 1
fi
NEW_VERSION=$1
FRAMEWORK_NAME=$2

echo "download new zip file"
echo "calculate new checksum"
NEW_CHECKSUM=$(swift package compute-checksum $FRAMEWORK_NAME.xcframework.zip)
echo "print out new shasum for convenience reasons"
echo "New checksum is $NEW_CHECKSUM"
echo "replace name module information in package manifest"
sed -E -i '' 's/let moduleName = ".+"/let moduleName = "'$FRAMEWORK_NAME\"/ Package.swift
echo "replace version information in package manifest"
sed -E -i '' 's/let version = ".+"/let version = "'$NEW_VERSION\"/ Package.swift
echo "replace checksum information in package manifest"
sed -E -i '' 's/let checksum = ".+"/let checksum = "'$NEW_CHECKSUM\"/ Package.swift
echo "print out package manifes for convenience reasons"
cat Package.swift


echo "git commit all without framework and push"
git add Package.swift
git commit -m "New $FRAMEWORK_NAME version $NEW_VERSION"
git push

echo "Releasing the new version"
gh release create "$NEW_VERSION" --generate-notes "./$FRAMEWORK_NAME.xcframework.zip"
echo "delete downloaded zip file"
rm $FRAMEWORK_NAME.xcframework.zip
