# Flutter Runner Script
# This script sets the correct JAVA_HOME and runs Flutter commands
# Usage: .\run-flutter.ps1 run
#        .\run-flutter.ps1 build apk --debug
#        .\run-flutter.ps1 clean

$env:JAVA_HOME = 'C:\Program Files\Android\Android Studio\jbr'

# Run flutter with all provided arguments
flutter @args
