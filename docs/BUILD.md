# MikuNotes 编译指南

## ✅ 当前配置 (已验证可用, 75s build)

### settings.gradle.kts
```kotlin
dependencyResolutionManagement {
    repositoriesMode.set(RepositoriesMode.PREFER_SETTINGS)  // ← 关键!
    repositories {
        maven { url = uri("file:///Users/fundou/maven_local") }
        maven { url = uri("file:///Users/fundou/flutter_engine_maven") }
    }
}
pluginManagement {
    repositories {
        maven { url = uri("file:///Users/fundou/maven_local") }
        maven { url = uri("file:///Users/fundou/flutter_engine_maven") }
    }
}
```

### build.gradle.kts
```kotlin
// NO repositories block! PREFER_SETTINGS handles it.
```

### gradle.properties
```properties
org.gradle.jvmargs=-Xmx3G -XX:MaxMetaspaceSize=512m -XX:ReservedCodeCacheSize=512m
org.gradle.workers.max=2
android.useAndroidX=true
```

### gradle-wrapper.properties
```properties
distributionUrl=https\://mirrors.aliyun.com/macports/distfiles/gradle/gradle-8.14-all.zip
```

### ~/flutter/packages/flutter_tools/gradle/settings.gradle.kts
```kotlin
dependencyResolutionManagement {
    repositoriesMode.set(RepositoriesMode.FAIL_ON_PROJECT_REPOS)
    repositories {
        maven { url = uri("file:///Users/fundou/maven_local") }
    }
}
```

## 🔑 原理

`PREFER_SETTINGS` 模式会**阻止** any `allprojects { repositories { ... } }` 的动态添加。
Flutter Gradle Plugin 在运行时调用 `rootProject.allprojects { repositories.maven { url = uri("https://storage.googleapis.com/...") } }` 被彻底拦截。

## 🏗️ 本地 Maven 仓库

- `~/maven_local/`: 1.4GB, 所有缓存 artifacts 的副本
- `~/flutter_engine_maven/`: Flutter 引擎专用 artifacts (io.flutter:*)

创建方法:
```python
# 从 Gradle 全局缓存复制所有 artifacts
import os, shutil
cache = os.path.expanduser("~/.gradle/caches/modules-2/files-2.1")
local = os.path.expanduser("~/maven_local")
for group in os.listdir(cache):
    for artifact in os.listdir(f"{cache}/{group}"):
        for version in os.listdir(f"{cache}/{group}/{artifact}"):
            for h in os.listdir(f"{cache}/{group}/{artifact}/{version}"):
                for f in os.listdir(f"{cache}/{group}/{artifact}/{version}/{h}"):
                    dest = f"{local}/{group.replace('.','/')}/{artifact}/{version}"
                    os.makedirs(dest, exist_ok=True)
                    shutil.copy2(f"{cache}/{group}/{artifact}/{version}/{h}/{f}", f"{dest}/{f}")
```

## ⚠️ 注意事项

- **绝不删除** `~/.gradle/caches/modules-2/metadata-*/` — metadata 无法手动重建
- `local-engine-repo` gradle 属性会导致 FlutterPlugin crash
- 在 8GB 机器上, `-Xmx3G` 是上限 (配合 `workers.max=2`)
