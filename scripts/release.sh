#!/bin/bash
# MikuNotes 自动 release 脚本
# 用法: ./scripts/release.sh [patch|minor|major]
#  默认 patch (0.4.0+4 → 0.4.1+5)
#  patch:  PATCH++ (默认)
#  minor:  MINOR++, PATCH=0
#  major:  MAJOR++, MINOR=0, PATCH=0
set -e

cd "$(dirname "$0")/.."

BUMP_TYPE="${1:-patch}"
CURRENT=$(grep "^version:" pubspec.yaml | sed 's/version: *//')
echo "当前版本: $CURRENT"

# 解析 0.4.0+4
if [[ ! "$CURRENT" =~ ^([0-9]+)\.([0-9]+)\.([0-9]+)\+([0-9]+)$ ]]; then
    echo "❌ 版本号格式错误: $CURRENT (应该是 MAJOR.MINOR.PATCH+BUILD)"
    exit 1
fi

MAJOR="${BASH_REMATCH[1]}"
MINOR="${BASH_REMATCH[2]}"
PATCH="${BASH_REMATCH[3]}"
BUILD="${BASH_REMATCH[4]}"

case "$BUMP_TYPE" in
    patch)
        PATCH=$((PATCH + 1))
        ;;
    minor)
        MINOR=$((MINOR + 1))
        PATCH=0
        ;;
    major)
        MAJOR=$((MAJOR + 1))
        MINOR=0
        PATCH=0
        ;;
    *)
        echo "❌ 未知类型: $BUMP_TYPE (patch/minor/major)"
        exit 1
        ;;
esac

NEW_BUILD=$((BUILD + 1))
NEW_VERSION="$MAJOR.$MINOR.$PATCH+$NEW_BUILD"
echo "新版本: $NEW_VERSION"

# 改 pubspec.yaml
sed -i '' "s/^version: .*/version: $NEW_VERSION/" pubspec.yaml

# Build
echo "🔨 flutter build apk --release..."
PATH="/Users/fundou/flutter/bin:$PATH" flutter build apk --release 2>&1 | tail -3

# 上传 FTP
FTP_NAME="mikunotes-v$MAJOR.$MINOR.$PATCH-release.apk"
echo "📤 上传到 FTP: $FTP_NAME"
curl -s --connect-timeout 30 -u "fundou:fred9110" \
    -T build/app/outputs/flutter-apk/app-release.apk \
    "ftp://192.168.31.172/$FTP_NAME" 2>&1 | tail -1

# 同时也覆盖最新的
curl -s --connect-timeout 30 -u "fundou:fred9110" \
    -T build/app/outputs/flutter-apk/app-release.apk \
    "ftp://192.168.31.172/mikunotes-latest-release.apk" 2>&1 | tail -1

# Git commit
git add -A
git -c user.email="fundou1081@users.noreply.github.com" \
    -c user.name="fundou1081" \
    commit -m "release: v$MAJOR.$MINOR.$PATCH (build $NEW_BUILD)" 2>&1 | tail -1

echo "✅ Release 完成: $FTP_NAME (versionCode=$NEW_BUILD)"
ls -lh build/app/outputs/flutter-apk/app-release.apk
