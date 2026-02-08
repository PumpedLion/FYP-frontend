@echo off
"C:\\Users\\ACER\\AppData\\Local\\Android\\Sdk\\cmake\\3.22.1\\bin\\cmake.exe" ^
  "-HC:\\Users\\ACER\\Downloads\\flutter_windows_3.29.0-stable\\flutter\\packages\\flutter_tools\\gradle\\src\\main\\groovy" ^
  "-DCMAKE_SYSTEM_NAME=Android" ^
  "-DCMAKE_EXPORT_COMPILE_COMMANDS=ON" ^
  "-DCMAKE_SYSTEM_VERSION=21" ^
  "-DANDROID_PLATFORM=android-21" ^
  "-DANDROID_ABI=x86_64" ^
  "-DCMAKE_ANDROID_ARCH_ABI=x86_64" ^
  "-DANDROID_NDK=C:\\Users\\ACER\\AppData\\Local\\Android\\Sdk\\ndk\\29.0.14206865" ^
  "-DCMAKE_ANDROID_NDK=C:\\Users\\ACER\\AppData\\Local\\Android\\Sdk\\ndk\\29.0.14206865" ^
  "-DCMAKE_TOOLCHAIN_FILE=C:\\Users\\ACER\\AppData\\Local\\Android\\Sdk\\ndk\\29.0.14206865\\build\\cmake\\android.toolchain.cmake" ^
  "-DCMAKE_MAKE_PROGRAM=C:\\Users\\ACER\\AppData\\Local\\Android\\Sdk\\cmake\\3.22.1\\bin\\ninja.exe" ^
  "-DCMAKE_LIBRARY_OUTPUT_DIRECTORY=D:\\Final Year Project\\FYP Frontend\\yourtales\\android\\app\\build\\intermediates\\cxx\\Debug\\432h45j2\\obj\\x86_64" ^
  "-DCMAKE_RUNTIME_OUTPUT_DIRECTORY=D:\\Final Year Project\\FYP Frontend\\yourtales\\android\\app\\build\\intermediates\\cxx\\Debug\\432h45j2\\obj\\x86_64" ^
  "-DCMAKE_BUILD_TYPE=Debug" ^
  "-BD:\\Final Year Project\\FYP Frontend\\yourtales\\android\\app\\.cxx\\Debug\\432h45j2\\x86_64" ^
  -GNinja ^
  -Wno-dev ^
  --no-warn-unused-cli
