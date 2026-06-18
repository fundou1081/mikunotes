# MikuNotes 编译指南

## 中国网络环境下的编译

**已知问题**: `dl.google.com` 和 `storage.googleapis.com` 从中国无法访问，
Flutter 引擎 artifacts (`io.flutter:*`) 无法下载。

### 方案 1: Android Studio (推荐)

```bash
# 恢复干净配置
cd ~/flutter && git checkout -- packages/flutter_tools/gradle/settings.gradle.kts
cd ~/my_proj/mikunotes && git checkout -- android/settings.gradle.kts android/build.gradle.kts android/gradle.properties

# Android Studio → File → Open → my_proj/mikunotes/android
# Build → Build APK
```

### 方案 2: VPN

终端设置代理后:
```bash
export https_proxy=http://127.0.0.1:7890
flutter build apk --release
```

### 方案 3: 本地 Maven 仓库 (实验性)
```bash
# 1. 从缓存提取本地 Maven 仓库
python3 script/extract_gradle_cache_to_maven.py

# 2. 配置纯本地仓库 (改 3 个 gradle 文件, 全指向 file:///Users/fundou/maven_local)

# 3. flutter build apk --release
```
