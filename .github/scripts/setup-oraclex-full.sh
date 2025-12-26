#!/bin/bash

################################################################################
# OracleX Full Automated Setup Script
# 
# This script provides comprehensive setup for the OracleX app including:
# - Flutter environment setup
# - Firebase configuration
# - Android Keystore generation
# - Git initialization and configuration
# - GitHub Actions workflows setup
# - GitHub API secret creation and management
#
# Usage: ./setup-oraclex-full.sh [OPTIONS]
# Options:
#   --flutter-only          Setup Flutter only
#   --firebase-only         Setup Firebase only
#   --keystore-only         Generate Keystore only
#   --git-init              Initialize Git and GitHub
#   --setup-workflows       Setup GitHub Actions workflows
#   --create-secrets        Create GitHub API secrets
#   --interactive           Run in interactive mode (default)
#   --help                  Display this help message
################################################################################

set -e

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Script configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
SETUP_LOG="${PROJECT_ROOT}/.setup-oraclex.log"
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')

# Default settings
INTERACTIVE_MODE=true
SETUP_FLUTTER=false
SETUP_FIREBASE=false
SETUP_KEYSTORE=false
SETUP_GIT=false
SETUP_WORKFLOWS=false
SETUP_SECRETS=false
VERBOSE=false

################################################################################
# Utility Functions
################################################################################

# Logging function
log() {
    local level=$1
    shift
    local message="$@"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo -e "${CYAN}[${timestamp}]${NC} [${level}] ${message}" | tee -a "$SETUP_LOG"
}

log_info() {
    echo -e "${BLUE}[INFO]${NC} $@" | tee -a "$SETUP_LOG"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $@" | tee -a "$SETUP_LOG"
}

log_warn() {
    echo -e "${YELLOW}[WARNING]${NC} $@" | tee -a "$SETUP_LOG"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $@" | tee -a "$SETUP_LOG"
}

# Check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Check if running on supported OS
get_os() {
    case "$OSTYPE" in
        linux-gnu*)   echo "linux" ;;
        darwin*)      echo "macos" ;;
        msys|cygwin)  echo "windows" ;;
        *)           echo "unknown" ;;
    esac
}

# Spinner for long-running operations
show_spinner() {
    local pid=$1
    local task=$2
    local spinner=( '⠋' '⠙' '⠹' '⠸' '⠼' '⠴' '⠦' '⠧' '⠇' '⠏' )
    
    while kill -0 $pid 2>/dev/null; do
        for i in "${spinner[@]}"; do
            echo -ne "\r${CYAN}${i}${NC} ${task}..."
            sleep 0.1
        done
    done
    echo -ne "\r"
}

################################################################################
# Flutter Setup Functions
################################################################################

setup_flutter() {
    log_info "Starting Flutter environment setup..."
    
    local os=$(get_os)
    
    # Check if Flutter is already installed
    if command_exists flutter; then
        log_success "Flutter is already installed"
        flutter --version | tee -a "$SETUP_LOG"
        return 0
    fi
    
    log_info "Flutter not found. Installing Flutter..."
    
    case "$os" in
        macos)
            log_info "Detected macOS. Installing Flutter via Homebrew..."
            if ! command_exists brew; then
                log_error "Homebrew is not installed. Please install it first."
                return 1
            fi
            brew install flutter 2>&1 | tee -a "$SETUP_LOG"
            ;;
        linux)
            log_info "Detected Linux. Downloading Flutter SDK..."
            setup_flutter_linux
            ;;
        windows)
            log_error "Please download Flutter from https://flutter.dev/docs/get-started/install/windows"
            return 1
            ;;
        *)
            log_error "Unsupported operating system: $os"
            return 1
            ;;
    esac
    
    # Configure Flutter
    log_info "Configuring Flutter..."
    flutter config --enable-android 2>&1 | tee -a "$SETUP_LOG"
    flutter config --enable-ios 2>&1 | tee -a "$SETUP_LOG"
    
    # Run Flutter doctor
    log_info "Running Flutter doctor..."
    flutter doctor -v 2>&1 | tee -a "$SETUP_LOG" || true
    
    log_success "Flutter setup completed"
}

setup_flutter_linux() {
    local flutter_dir="$HOME/flutter"
    
    if [ -d "$flutter_dir" ]; then
        log_warn "Flutter directory already exists at $flutter_dir"
        return 0
    fi
    
    log_info "Downloading Flutter SDK to $flutter_dir..."
    git clone https://github.com/flutter/flutter.git -b stable "$flutter_dir" 2>&1 | tee -a "$SETUP_LOG"
    
    # Add Flutter to PATH
    log_info "Adding Flutter to PATH..."
    if ! grep -q "export PATH=\".*flutter/bin" ~/.bashrc; then
        echo 'export PATH="$HOME/flutter/bin:$PATH"' >> ~/.bashrc
        export PATH="$HOME/flutter/bin:$PATH"
        log_success "Flutter added to PATH"
    fi
}

verify_flutter_dependencies() {
    log_info "Verifying Flutter dependencies..."
    
    local missing_deps=0
    
    # Check for Java
    if ! command_exists java; then
        log_warn "Java is not installed"
        missing_deps=1
    else
        log_success "Java found: $(java -version 2>&1 | head -1)"
    fi
    
    # Check for Android SDK
    if [ -z "$ANDROID_HOME" ]; then
        log_warn "ANDROID_HOME is not set"
        missing_deps=1
    else
        log_success "ANDROID_HOME is set: $ANDROID_HOME"
    fi
    
    # Run Flutter doctor
    if flutter doctor | grep -q "Doctor summary"; then
        log_success "Flutter doctor completed"
    fi
    
    return $missing_deps
}

################################################################################
# Firebase Setup Functions
################################################################################

setup_firebase() {
    log_info "Starting Firebase setup..."
    
    # Check if FlutterFire CLI is installed
    if ! command_exists flutterfire; then
        log_info "Installing FlutterFire CLI..."
        flutter pub global activate flutterfire_cli 2>&1 | tee -a "$SETUP_LOG"
    else
        log_success "FlutterFire CLI is already installed"
    fi
    
    # Create firebase configuration directory
    local firebase_config_dir="${PROJECT_ROOT}/firebase"
    mkdir -p "$firebase_config_dir"
    log_info "Firebase configuration directory: $firebase_config_dir"
    
    # Check if google-services.json exists
    if [ -f "${PROJECT_ROOT}/android/app/google-services.json" ]; then
        log_success "google-services.json already exists"
    else
        log_warn "google-services.json not found"
        log_info "Please download google-services.json from Firebase Console and place it at:"
        log_info "  android/app/google-services.json"
    fi
    
    # Check if GoogleService-Info.plist exists
    if [ -f "${PROJECT_ROOT}/ios/Runner/GoogleService-Info.plist" ]; then
        log_success "GoogleService-Info.plist already exists"
    else
        log_warn "GoogleService-Info.plist not found"
        log_info "Please download GoogleService-Info.plist from Firebase Console and place it at:"
        log_info "  ios/Runner/GoogleService-Info.plist"
    fi
    
    # Create Firebase pubspec configuration
    create_firebase_pubspec_config
    
    log_success "Firebase setup completed"
}

create_firebase_pubspec_config() {
    local firebase_config="${PROJECT_ROOT}/lib/config/firebase_config.dart"
    mkdir -p "$(dirname "$firebase_config")"
    
    if [ -f "$firebase_config" ]; then
        log_info "Firebase configuration file already exists"
        return 0
    fi
    
    cat > "$firebase_config" << 'EOF'
/// Firebase Configuration Module
/// 
/// This file contains Firebase configuration and initialization logic.
/// Generated by setup-oraclex-full.sh

import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

/// Initialize Firebase
Future<void> initializeFirebase() async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
}

/// Firebase services configuration
class FirebaseConfig {
  static const String projectId = 'oraclex-project';
  static const String apiKey = 'YOUR_API_KEY_HERE';
  static const String appId = 'YOUR_APP_ID_HERE';
  static const String messagingSenderId = 'YOUR_MESSAGING_SENDER_ID_HERE';
  
  /// Initialize Firebase services
  static Future<void> initialize() async {
    await initializeFirebase();
  }
}
EOF
    log_success "Firebase configuration file created"
}

################################################################################
# Android Keystore Functions
################################################################################

setup_android_keystore() {
    log_info "Starting Android Keystore setup..."
    
    local keystore_dir="${PROJECT_ROOT}/android/app"
    local keystore_file="${keystore_dir}/upload-keystore.jks"
    local keystore_properties="${keystore_dir}/key.properties"
    
    # Check if keystore already exists
    if [ -f "$keystore_file" ]; then
        log_warn "Keystore already exists at $keystore_file"
        if confirm_action "Do you want to regenerate the keystore?"; then
            rm -f "$keystore_file"
        else
            return 0
        fi
    fi
    
    # Create keystore directory
    mkdir -p "$keystore_dir"
    
    log_info "Generating Android Keystore..."
    log_info "This keystore is used for signing and uploading your app to the Play Store."
    
    # Get keystore details from user
    local keystore_alias="${KEYSTORE_ALIAS:-oraclex_key}"
    local keystore_password="${KEYSTORE_PASSWORD:-}"
    local key_password="${KEY_PASSWORD:-}"
    local validity_days="${KEYSTORE_VALIDITY:-10950}" # 30 years
    
    if [ -z "$keystore_password" ]; then
        log_warn "KEYSTORE_PASSWORD environment variable not set"
        read -sp "Enter keystore password: " keystore_password
        echo
    fi
    
    if [ -z "$key_password" ]; then
        log_warn "KEY_PASSWORD environment variable not set"
        read -sp "Enter key password (usually same as keystore password): " key_password
        echo
    fi
    
    # Generate keystore
    keytool -genkey -v -keystore "$keystore_file" \
        -keyalg RSA -keysize 2048 -validity "$validity_days" \
        -storepass "$keystore_password" \
        -keypass "$key_password" \
        -alias "$keystore_alias" \
        -dname "CN=OracleX, OU=Business, O=OracleX, C=US" 2>&1 | tee -a "$SETUP_LOG"
    
    if [ $? -ne 0 ]; then
        log_error "Failed to generate keystore"
        return 1
    fi
    
    # Create key.properties file
    create_key_properties "$keystore_properties" "$keystore_alias" "$keystore_password" "$key_password"
    
    # Set file permissions
    chmod 600 "$keystore_file"
    chmod 600 "$keystore_properties"
    
    # Output keystore information
    log_info "Keystore Information:"
    keytool -list -v -keystore "$keystore_file" -storepass "$keystore_password" 2>&1 | tee -a "$SETUP_LOG" || true
    
    log_success "Android Keystore setup completed"
    log_info "Keystore file: $keystore_file"
    log_info "Key properties file: $keystore_properties"
    log_warn "IMPORTANT: Keep these files secure and add them to .gitignore"
}

create_key_properties() {
    local properties_file=$1
    local key_alias=$2
    local keystore_password=$3
    local key_password=$4
    
    cat > "$properties_file" << EOF
storePassword=${keystore_password}
keyPassword=${key_password}
keyAlias=${key_alias}
storeFile=upload-keystore.jks
EOF
    
    log_success "key.properties created"
}

################################################################################
# Git Initialization Functions
################################################################################

setup_git_repository() {
    log_info "Starting Git repository initialization..."
    
    cd "$PROJECT_ROOT"
    
    # Check if already a git repository
    if [ -d ".git" ]; then
        log_success "Git repository already initialized"
        git status | tee -a "$SETUP_LOG"
        return 0
    fi
    
    log_info "Initializing new Git repository..."
    git init 2>&1 | tee -a "$SETUP_LOG"
    
    # Configure git user
    if [ -z "$(git config --global user.email)" ]; then
        log_warn "Git user email not configured"
        read -p "Enter your email: " git_email
        git config --global user.email "$git_email"
    fi
    
    if [ -z "$(git config --global user.name)" ]; then
        log_warn "Git user name not configured"
        read -p "Enter your name: " git_name
        git config --global user.name "$git_name"
    fi
    
    # Create .gitignore if it doesn't exist
    create_gitignore
    
    # Add and commit initial files
    log_info "Creating initial commit..."
    git add . 2>&1 | tee -a "$SETUP_LOG" || true
    git commit -m "Initial commit: OracleX app setup" 2>&1 | tee -a "$SETUP_LOG" || true
    
    # Add remote if GitHub URL is provided
    if [ ! -z "$GITHUB_REPO_URL" ]; then
        log_info "Adding GitHub remote..."
        git remote add origin "$GITHUB_REPO_URL" 2>&1 | tee -a "$SETUP_LOG" || true
        git branch -M main
        log_info "To push your code, run: git push -u origin main"
    fi
    
    log_success "Git setup completed"
}

create_gitignore() {
    local gitignore_file="${PROJECT_ROOT}/.gitignore"
    
    if [ -f "$gitignore_file" ]; then
        log_info ".gitignore already exists"
        return 0
    fi
    
    cat > "$gitignore_file" << 'EOF'
# Flutter
.dart_tool/
.flutter-plugins
.flutter-plugins-dependencies
.packages
.pub/
.pub-cache/
pubspec.lock
build/
.idea/
.vscode/

# Android
.gradle/
*.apk
*.aar
*.ap_
*.aab
local.properties
/android/app/debug/
/android/app/profile/
/android/app/release/
android/app/google-services.json
android/app/key.properties
android/app/upload-keystore.jks

# iOS
ios/Pods/
ios/Podfile.lock
ios/Flutter/Flutter.podspec
ios/Runner/GeneratedPluginRegistrant.*
ios/Runner/GoogleService-Info.plist

# macOS
macos/Pods/
macos/Flutter/Flutter-Release.xcconfig
macos/Flutter/Flutter-Debug.xcconfig

# Windows
windows/flutter/generated_plugins.cmake
windows/flutter/generated_plugin_props.json

# Web
web/canvaskit/
web/canvaskit_wasm

# General
*.log
*.pyc
*.pyo
*.pyd
.DS_Store
*.swp
*.swo
*~
.env
.env.local
*.keystore
*.jks
key.properties

# Firebase
firebase-debug.log

# IDE
.idea/
*.iml
.vscode/
*.code-workspace
*.sublime-project
*.sublime-workspace

# Generated files
lib/firebase_options.dart
EOF
    log_success ".gitignore created"
}

################################################################################
# GitHub Actions Workflow Functions
################################################################################

setup_github_workflows() {
    log_info "Starting GitHub Actions workflows setup..."
    
    local workflows_dir="${PROJECT_ROOT}/.github/workflows"
    mkdir -p "$workflows_dir"
    
    # Create Flutter CI workflow
    create_flutter_ci_workflow "$workflows_dir"
    
    # Create Flutter CD workflow
    create_flutter_cd_workflow "$workflows_dir"
    
    # Create code quality workflow
    create_code_quality_workflow "$workflows_dir"
    
    log_success "GitHub Actions workflows setup completed"
}

create_flutter_ci_workflow() {
    local workflows_dir=$1
    local workflow_file="${workflows_dir}/flutter-ci.yml"
    
    cat > "$workflow_file" << 'EOF'
name: Flutter CI

on:
  push:
    branches: [ main, develop ]
  pull_request:
    branches: [ main, develop ]

jobs:
  analyze:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Setup Flutter
        uses: subosito/flutter-action@v2
        with:
          flutter-version: 'stable'
      
      - name: Get dependencies
        run: flutter pub get
      
      - name: Analyze code
        run: flutter analyze
      
      - name: Format check
        run: flutter format --set-exit-if-changed lib test

  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Setup Flutter
        uses: subosito/flutter-action@v2
        with:
          flutter-version: 'stable'
      
      - name: Get dependencies
        run: flutter pub get
      
      - name: Run tests
        run: flutter test --coverage
      
      - name: Upload coverage
        uses: codecov/codecov-action@v3
        with:
          files: ./coverage/lcov.info

  build_apk:
    needs: [analyze, test]
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Setup Flutter
        uses: subosito/flutter-action@v2
        with:
          flutter-version: 'stable'
      
      - name: Setup Java
        uses: actions/setup-java@v3
        with:
          distribution: 'temurin'
          java-version: '11'
      
      - name: Get dependencies
        run: flutter pub get
      
      - name: Build APK
        run: flutter build apk --release
      
      - name: Upload APK
        uses: actions/upload-artifact@v3
        with:
          name: app-release.apk
          path: build/app/outputs/flutter-apk/app-release.apk

  build_ios:
    needs: [analyze, test]
    runs-on: macos-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Setup Flutter
        uses: subosito/flutter-action@v2
        with:
          flutter-version: 'stable'
      
      - name: Get dependencies
        run: flutter pub get
      
      - name: Build iOS
        run: flutter build ios --release --no-codesign
      
      - name: Upload iOS build
        uses: actions/upload-artifact@v3
        with:
          name: ios-build
          path: build/ios/iphoneos/
EOF
    log_success "Flutter CI workflow created"
}

create_flutter_cd_workflow() {
    local workflows_dir=$1
    local workflow_file="${workflows_dir}/flutter-cd.yml"
    
    cat > "$workflow_file" << 'EOF'
name: Flutter CD

on:
  push:
    tags:
      - 'v*'

jobs:
  create_release:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Setup Flutter
        uses: subosito/flutter-action@v2
        with:
          flutter-version: 'stable'
      
      - name: Setup Java
        uses: actions/setup-java@v3
        with:
          distribution: 'temurin'
          java-version: '11'
      
      - name: Get dependencies
        run: flutter pub get
      
      - name: Build APK
        run: flutter build apk --release
      
      - name: Create Release
        uses: actions/create-release@v1
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
        with:
          tag_name: ${{ github.ref }}
          release_name: Release ${{ github.ref }}
          draft: false
          prerelease: false
      
      - name: Upload Release Assets
        uses: actions/upload-release-asset@v1
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
        with:
          upload_url: ${{ steps.create_release.outputs.upload_url }}
          asset_path: ./build/app/outputs/flutter-apk/app-release.apk
          asset_name: oraclex-${{ github.ref }}.apk
          asset_content_type: application/vnd.android.package-archive
EOF
    log_success "Flutter CD workflow created"
}

create_code_quality_workflow() {
    local workflows_dir=$1
    local workflow_file="${workflows_dir}/code-quality.yml"
    
    cat > "$workflow_file" << 'EOF'
name: Code Quality

on:
  push:
    branches: [ main, develop ]
  pull_request:
    branches: [ main, develop ]

jobs:
  quality:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Setup Flutter
        uses: subosito/flutter-action@v2
        with:
          flutter-version: 'stable'
      
      - name: Get dependencies
        run: flutter pub get
      
      - name: Run analyzer
        run: flutter analyze --no-fatal-infos
      
      - name: Check formatting
        run: flutter format --set-exit-if-changed lib test
      
      - name: Run tests with coverage
        run: flutter test --coverage
      
      - name: Generate coverage report
        run: |
          flutter pub global activate coverage
          coverage
      
      - name: Upload to codecov
        uses: codecov/codecov-action@v3
        with:
          files: ./coverage/lcov.info
          fail_ci_if_error: true
EOF
    log_success "Code quality workflow created"
}

################################################################################
# GitHub API Secrets Functions
################################################################################

setup_github_secrets() {
    log_info "Starting GitHub API secrets setup..."
    
    # Check if GitHub CLI is installed
    if ! command_exists gh; then
        log_error "GitHub CLI is not installed. Please install it from https://cli.github.com"
        return 1
    fi
    
    # Check if authenticated with GitHub
    if ! gh auth status >/dev/null 2>&1; then
        log_error "Not authenticated with GitHub. Please run: gh auth login"
        return 1
    fi
    
    log_info "Creating GitHub repository secrets..."
    
    create_firebase_secrets
    create_android_secrets
    create_app_secrets
    
    log_success "GitHub API secrets setup completed"
}

create_firebase_secrets() {
    log_info "Setting up Firebase secrets..."
    
    local repo_owner=$(git config --get remote.origin.url | sed -E 's|.*github.com[/:](.*)/(.*)\.git|\1|')
    local repo_name=$(git config --get remote.origin.url | sed -E 's|.*github.com[/:](.*)/(.*)\.git|\2|')
    
    if [ -z "$repo_owner" ] || [ -z "$repo_name" ]; then
        log_warn "Could not determine repository owner and name"
        read -p "Enter repository owner: " repo_owner
        read -p "Enter repository name: " repo_name
    fi
    
    # Firebase API Key
    read -sp "Enter Firebase API Key (or press Enter to skip): " firebase_api_key
    echo
    if [ ! -z "$firebase_api_key" ]; then
        gh secret set FIREBASE_API_KEY -b"$firebase_api_key" -R"${repo_owner}/${repo_name}" 2>&1 | tee -a "$SETUP_LOG"
        log_success "FIREBASE_API_KEY secret created"
    fi
    
    # Firebase Project ID
    read -p "Enter Firebase Project ID (or press Enter to skip): " firebase_project_id
    if [ ! -z "$firebase_project_id" ]; then
        gh secret set FIREBASE_PROJECT_ID -b"$firebase_project_id" -R"${repo_owner}/${repo_name}" 2>&1 | tee -a "$SETUP_LOG"
        log_success "FIREBASE_PROJECT_ID secret created"
    fi
    
    # Firebase Messaging Sender ID
    read -p "Enter Firebase Messaging Sender ID (or press Enter to skip): " firebase_sender_id
    if [ ! -z "$firebase_sender_id" ]; then
        gh secret set FIREBASE_MESSAGING_SENDER_ID -b"$firebase_sender_id" -R"${repo_owner}/${repo_name}" 2>&1 | tee -a "$SETUP_LOG"
        log_success "FIREBASE_MESSAGING_SENDER_ID secret created"
    fi
}

create_android_secrets() {
    log_info "Setting up Android secrets..."
    
    local repo_owner=$(git config --get remote.origin.url | sed -E 's|.*github.com[/:](.*)/(.*)\.git|\1|')
    local repo_name=$(git config --get remote.origin.url | sed -E 's|.*github.com[/:](.*)/(.*)\.git|\2|')
    
    # Keystore Password
    read -sp "Enter Keystore Password (or press Enter to skip): " keystore_password
    echo
    if [ ! -z "$keystore_password" ]; then
        gh secret set KEYSTORE_PASSWORD -b"$keystore_password" -R"${repo_owner}/${repo_name}" 2>&1 | tee -a "$SETUP_LOG"
        log_success "KEYSTORE_PASSWORD secret created"
    fi
    
    # Key Password
    read -sp "Enter Key Password (or press Enter to skip): " key_password
    echo
    if [ ! -z "$key_password" ]; then
        gh secret set KEY_PASSWORD -b"$key_password" -R"${repo_owner}/${repo_name}" 2>&1 | tee -a "$SETUP_LOG"
        log_success "KEY_PASSWORD secret created"
    fi
}

create_app_secrets() {
    log_info "Setting up application secrets..."
    
    local repo_owner=$(git config --get remote.origin.url | sed -E 's|.*github.com[/:](.*)/(.*)\.git|\1|')
    local repo_name=$(git config --get remote.origin.url | sed -E 's|.*github.com[/:](.*)/(.*)\.git|\2|')
    
    # App Name
    read -p "Enter App Name (or press Enter to skip): " app_name
    if [ ! -z "$app_name" ]; then
        gh secret set APP_NAME -b"$app_name" -R"${repo_owner}/${repo_name}" 2>&1 | tee -a "$SETUP_LOG"
        log_success "APP_NAME secret created"
    fi
    
    # App Bundle ID
    read -p "Enter App Bundle ID (or press Enter to skip): " app_bundle_id
    if [ ! -z "$app_bundle_id" ]; then
        gh secret set APP_BUNDLE_ID -b"$app_bundle_id" -R"${repo_owner}/${repo_name}" 2>&1 | tee -a "$SETUP_LOG"
        log_success "APP_BUNDLE_ID secret created"
    fi
    
    # API Base URL
    read -p "Enter API Base URL (or press Enter to skip): " api_base_url
    if [ ! -z "$api_base_url" ]; then
        gh secret set API_BASE_URL -b"$api_base_url" -R"${repo_owner}/${repo_name}" 2>&1 | tee -a "$SETUP_LOG"
        log_success "API_BASE_URL secret created"
    fi
}

################################################################################
# Helper Functions
################################################################################

confirm_action() {
    local prompt=$1
    read -p "${prompt} (y/n): " -n 1 -r
    echo
    [[ $REPLY =~ ^[Yy]$ ]]
}

print_help() {
    cat << EOF
${CYAN}OracleX Full Automated Setup Script${NC}

${BLUE}Usage:${NC}
  ./setup-oraclex-full.sh [OPTIONS]

${BLUE}Options:${NC}
  --flutter-only          Setup Flutter only
  --firebase-only         Setup Firebase only
  --keystore-only         Generate Android Keystore only
  --git-init              Initialize Git and GitHub
  --setup-workflows       Setup GitHub Actions workflows
  --create-secrets        Create GitHub API secrets
  --interactive           Run in interactive mode (default)
  --all                   Run all setup steps
  --verbose               Enable verbose output
  --help                  Display this help message

${BLUE}Examples:${NC}
  # Run in interactive mode (default)
  ./setup-oraclex-full.sh

  # Setup only Flutter
  ./setup-oraclex-full.sh --flutter-only

  # Run all setup steps
  ./setup-oraclex-full.sh --all

  # Setup Flutter, Firebase, and Keystore
  ./setup-oraclex-full.sh --flutter-only --firebase-only --keystore-only

${BLUE}Environment Variables:${NC}
  KEYSTORE_ALIAS          Android Keystore alias (default: oraclex_key)
  KEYSTORE_PASSWORD       Android Keystore password
  KEY_PASSWORD            Android Key password
  KEYSTORE_VALIDITY       Keystore validity in days (default: 10950)
  GITHUB_REPO_URL         GitHub repository URL for remote setup

${BLUE}Generated Files:${NC}
  Setup Log:              ${SETUP_LOG}
  Firebase Config:        lib/config/firebase_config.dart
  .gitignore:             .gitignore
  Workflows:              .github/workflows/*.yml
  Keystore:               android/app/upload-keystore.jks
  Key Properties:         android/app/key.properties

${BLUE}Requirements:${NC}
  - Flutter SDK
  - Java Development Kit (for Android)
  - Git
  - GitHub CLI (for secret management)

${BLUE}Documentation:${NC}
  Flutter: https://flutter.dev/docs
  Firebase: https://firebase.google.com/docs
  Android Keystore: https://developer.android.com/studio/publish/app-signing
  GitHub Actions: https://docs.github.com/actions

EOF
}

print_summary() {
    log_info "=========================================="
    log_success "Setup Summary"
    log_info "=========================================="
    log_info "Flutter Setup: ${SETUP_FLUTTER}"
    log_info "Firebase Setup: ${SETUP_FIREBASE}"
    log_info "Keystore Setup: ${SETUP_KEYSTORE}"
    log_info "Git Initialization: ${SETUP_GIT}"
    log_info "GitHub Workflows: ${SETUP_WORKFLOWS}"
    log_info "GitHub Secrets: ${SETUP_SECRETS}"
    log_info "Setup Log: ${SETUP_LOG}"
    log_info "=========================================="
}

################################################################################
# Main Menu and Interactive Mode
################################################################################

show_main_menu() {
    clear
    echo -e "${CYAN}"
    cat << 'EOF'
╔══════════════════════════════════════════════════════════╗
║                                                          ║
║      OracleX Full Automated Setup Script                ║
║                                                          ║
║  Comprehensive setup for Flutter, Firebase, Android,    ║
║  GitHub Actions, and more!                              ║
║                                                          ║
╚══════════════════════════════════════════════════════════╝
EOF
    echo -e "${NC}"
    
    echo -e "${BLUE}Setup Components:${NC}"
    echo "1) Setup Flutter"
    echo "2) Setup Firebase"
    echo "3) Generate Android Keystore"
    echo "4) Initialize Git Repository"
    echo "5) Setup GitHub Actions Workflows"
    echo "6) Create GitHub API Secrets"
    echo "7) Run All Setup Steps"
    echo "0) Exit"
    echo
    read -p "Select an option (0-7): " menu_choice
}

interactive_mode() {
    while true; do
        show_main_menu
        
        case $menu_choice in
            1)
                setup_flutter
                ;;
            2)
                setup_firebase
                ;;
            3)
                setup_android_keystore
                ;;
            4)
                setup_git_repository
                ;;
            5)
                setup_github_workflows
                ;;
            6)
                setup_github_secrets
                ;;
            7)
                log_info "Running all setup steps..."
                setup_flutter && \
                setup_firebase && \
                setup_android_keystore && \
                setup_git_repository && \
                setup_github_workflows && \
                setup_github_secrets
                ;;
            0)
                log_info "Exiting setup script"
                exit 0
                ;;
            *)
                log_error "Invalid option. Please try again."
                ;;
        esac
        
        if [ $? -eq 0 ]; then
            echo
            read -p "Press Enter to continue..."
        fi
    done
}

################################################################################
# Main Execution
################################################################################

main() {
    # Initialize setup log
    touch "$SETUP_LOG"
    log_info "OracleX Setup Script started at $TIMESTAMP"
    log_info "Project Root: $PROJECT_ROOT"
    log_info "OS: $(get_os)"
    
    # Parse command line arguments
    while [ $# -gt 0 ]; do
        case "$1" in
            --flutter-only)
                INTERACTIVE_MODE=false
                SETUP_FLUTTER=true
                ;;
            --firebase-only)
                INTERACTIVE_MODE=false
                SETUP_FIREBASE=true
                ;;
            --keystore-only)
                INTERACTIVE_MODE=false
                SETUP_KEYSTORE=true
                ;;
            --git-init)
                INTERACTIVE_MODE=false
                SETUP_GIT=true
                ;;
            --setup-workflows)
                INTERACTIVE_MODE=false
                SETUP_WORKFLOWS=true
                ;;
            --create-secrets)
                INTERACTIVE_MODE=false
                SETUP_SECRETS=true
                ;;
            --all)
                INTERACTIVE_MODE=false
                SETUP_FLUTTER=true
                SETUP_FIREBASE=true
                SETUP_KEYSTORE=true
                SETUP_GIT=true
                SETUP_WORKFLOWS=true
                SETUP_SECRETS=true
                ;;
            --verbose)
                VERBOSE=true
                ;;
            --help)
                print_help
                exit 0
                ;;
            *)
                log_error "Unknown option: $1"
                print_help
                exit 1
                ;;
        esac
        shift
    done
    
    # Run interactive mode if no specific options provided
    if [ "$INTERACTIVE_MODE" = true ]; then
        interactive_mode
    else
        # Run selected setup steps
        if [ "$SETUP_FLUTTER" = true ]; then
            setup_flutter || exit 1
        fi
        
        if [ "$SETUP_FIREBASE" = true ]; then
            setup_firebase || exit 1
        fi
        
        if [ "$SETUP_KEYSTORE" = true ]; then
            setup_android_keystore || exit 1
        fi
        
        if [ "$SETUP_GIT" = true ]; then
            setup_git_repository || exit 1
        fi
        
        if [ "$SETUP_WORKFLOWS" = true ]; then
            setup_github_workflows || exit 1
        fi
        
        if [ "$SETUP_SECRETS" = true ]; then
            setup_github_secrets || exit 1
        fi
        
        print_summary
    fi
    
    log_success "OracleX setup completed successfully!"
    log_info "Setup log saved to: $SETUP_LOG"
}

# Exit on any error in non-interactive mode
trap 'log_error "Script failed at line $LINENO"' ERR

# Run main function
main "$@"
