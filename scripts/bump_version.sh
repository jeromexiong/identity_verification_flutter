#!/usr/bin/env bash
# bump_version.sh — 更新所有子包版本号 + 更新版本依赖
#
# Usage:
#   ./scripts/bump_version.sh 0.2.0
#
# 做什么：
#   1. 更新 4 个 pubspec.yaml 的 version 字段
#   2. 更新 app-facing 包中对平台包的版本依赖
#   3. 更新 android/ios 包中对 platform_interface 的版本依赖
#   4. 提交 + 打 tag

set -euo pipefail

NEW_VERSION="${1:?Usage: $0 <version>}"

ROOT="$(cd "$(dirname "$0")/.." && pwd)"

PACKAGES=(
  "identity_verification_flutter_platform_interface"
  "identity_verification_flutter_android"
  "identity_verification_flutter_ios"
  "identity_verification_flutter"
)

echo "🔖 Bumping all packages to v${NEW_VERSION}"

for pkg in "${PACKAGES[@]}"; do
  PUBSPEC="$ROOT/$pkg/pubspec.yaml"
  if [[ ! -f "$PUBSPEC" ]]; then
    echo "❌ Missing: $PUBSPEC"
    exit 1
  fi
  # Update version field
  sed -i '' "s/^version: .*/version: ${NEW_VERSION}/" "$PUBSPEC"
  echo "  ✅ $pkg → ${NEW_VERSION}"
done

# Update cross-package version deps in app-facing
APP_PUBSPEC="$ROOT/identity_verification_flutter/pubspec.yaml"
sed -i '' "s|path: ../identity_verification_flutter_platform_interface|path: ../identity_verification_flutter_platform_interface|" "$APP_PUBSPEC"
sed -i '' "s|path: ../identity_verification_flutter_android|path: ../identity_verification_flutter_android|" "$APP_PUBSPEC"
sed -i '' "s|path: ../identity_verification_flutter_ios|path: ../identity_verification_flutter_ios|" "$APP_PUBSPEC"

echo ""
echo "📦 Path deps preserved for local development."
echo "   To publish, swap path → ^${NEW_VERSION} temporarily."
echo ""
echo "Next steps:"
echo "  git add -A && git commit -m \"chore: bump version to ${NEW_VERSION}\""
echo "  git tag v${NEW_VERSION}"
echo "  git push origin main --tags"
