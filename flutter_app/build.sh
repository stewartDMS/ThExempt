#!/bin/bash
set -e

# Download Flutter stable
git clone https://github.com/flutter/flutter.git -b stable --depth 1

# Export flutter to path
export PATH="$PATH:$(pwd)/flutter/bin"

# Enable web support
flutter config --enable-web

# Get dependencies and build
flutter pub get
flutter build web