#!/usr/bin/env bash
set -euo pipefail

FLUTTER_HOME="${HOME}/flutter"

if [ ! -x "${FLUTTER_HOME}/bin/flutter" ]; then
  git clone --depth 1 --branch stable https://github.com/flutter/flutter.git "${FLUTTER_HOME}"
fi

export PATH="${FLUTTER_HOME}/bin:${PATH}"

flutter config --no-analytics
flutter pub get
flutter build web --release --dart-define="API_URL=${API_URL}"
