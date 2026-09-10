#!/bin/zsh
cd -- "$(dirname -- "$0")" || exit 1
flutter_bin="$(command -v flutter)"
if [[ -z "$flutter_bin" && -x "$HOME/development/flutter/bin/flutter" ]]; then
  flutter_bin="$HOME/development/flutter/bin/flutter"
fi
if [[ -z "$flutter_bin" ]]; then
  echo "Flutter was not found. Add the Flutter SDK bin directory to PATH."
  exit 1
fi
exec "$flutter_bin" run -t lib/main_demo.dart "$@"
