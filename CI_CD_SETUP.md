# CI/CD Setup Guide for App Icon Maker

## Overview

This document describes the complete CI/CD setup for the App Icon Maker iOS application, including automated testing, code quality checks, and deployment pipelines.

---

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                     GitHub Repository                        │
│                  (yanggavin/icon-maker)                     │
└────────────────────┬────────────────────────────────────────┘
                     │
                     │ Push/PR
                     ▼
┌─────────────────────────────────────────────────────────────┐
│                   GitHub Actions                             │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐     │
│  │ Build & Test │  │ Code Quality │  │ Performance  │     │
│  └──────────────┘  └──────────────┘  └──────────────┘     │
└────────────────────┬────────────────────────────────────────┘
                     │
                     │ Results
                     ▼
┌─────────────────────────────────────────────────────────────┐
│                      Artifacts                               │
│  • Test Results  • Coverage  • Build Archive                │
└─────────────────────────────────────────────────────────────┘
```

---

## Components

### 1. GitHub Actions Workflows

Located in `.github/workflows/`:

#### `ios-ci.yml`
Main CI pipeline that runs on every push and PR.

**Triggers:**
- Push to `main` or `develop` branches
- Pull requests to `main` or `develop` branches

**Jobs:**
1. **Build and Test** - Builds and tests on multiple simulators
2. **Code Quality** - Runs SwiftLint and code analysis
3. **Build Archive** - Creates release archive (main branch only)
4. **Performance Check** - Analyzes build performance and binary size

**Matrix Strategy:**
Tests run in parallel on:
- iPhone 15 Pro (iOS 17.0)
- iPhone SE 3rd gen (iOS 17.0)
- iPad Pro 12.9" (iOS 17.0)

### 2. SwiftLint Configuration

Located at `.swiftlint.yml`

**Features:**
- 50+ enabled rules for code quality
- Custom rules for common issues
- Excludes test files from strict rules
- GitHub Actions integration

**Custom Rules:**
- No print statements (use proper logging)
- No force unwrapping (use optional binding)
- No force casting (use conditional casting)

### 3. Fastlane

Located in `fastlane/` directory

**Available Lanes:**

```bash
# Run all tests
fastlane test

# Build the app
fastlane build

# Run SwiftLint
fastlane lint

# Run all quality checks
fastlane quality

# Build for release
fastlane release_build

# Take screenshots
fastlane screenshots

# Run performance tests
fastlane performance

# Generate coverage report
fastlane coverage

# Clean build artifacts
fastlane clean
```

### 4. Unit Tests

Located in `AppIconMakerTests/`

**Test Coverage:**
- Model tests (IconSize, Platform, BackgroundStyle)
- Service tests (ImageCache, ImageProcessor)
- Performance tests
- Integration tests

**Current Tests:**
- ✅ Icon size initialization
- ✅ Platform cases
- ✅ Background style equality
- ✅ Icon size specifications
- ✅ AppIconSet initialization
- ✅ Contents.json generation
- ✅ Image cache operations
- ✅ Image processing (resize, crop)
- ✅ Performance benchmarks

---

## Setup Instructions

### Prerequisites

1. **macOS** with Xcode 15.0 or later
2. **Homebrew** package manager
3. **Git** version control
4. **GitHub account** with repository access

### Local Setup

#### 1. Install Dependencies

```bash
# Install Homebrew (if not installed)
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Install SwiftLint
brew install swiftlint

# Install Fastlane
brew install fastlane

# Install xcpretty (optional, for prettier output)
sudo gem install xcpretty

# Install xcov (optional, for coverage reports)
sudo gem install xcov
```

#### 2. Verify Installation

```bash
# Check versions
xcodebuild -version
swiftlint version
fastlane --version
```

#### 3. Run Local Tests

```bash
# Navigate to project directory
cd /path/to/icon-maker

# Run SwiftLint
swiftlint

# Run tests with xcodebuild
xcodebuild test \
  -project AppIconMaker.xcodeproj \
  -scheme AppIconMaker \
  -destination 'platform=iOS Simulator,name=iPhone 15 Pro'

# Or use Fastlane
fastlane test
```

### GitHub Actions Setup

#### 1. Enable Actions

1. Go to repository on GitHub
2. Navigate to **Settings** → **Actions** → **General**
3. Ensure "Allow all actions and reusable workflows" is selected
4. Save changes

#### 2. Configure Branch Protection (Optional)

1. Go to **Settings** → **Branches**
2. Add rule for `main` branch
3. Enable "Require status checks to pass before merging"
4. Select required checks:
   - Build and Test
   - Code Quality
5. Enable "Require branches to be up to date before merging"
6. Save changes

#### 3. Add Secrets (For Advanced Features)

Go to **Settings** → **Secrets and variables** → **Actions**

Add these secrets if needed:

```
APPLE_ID=your.apple.id@email.com
TEAM_ID=XXXXXXXXXX
FASTLANE_PASSWORD=xxxx-xxxx-xxxx-xxxx
MATCH_PASSWORD=your_match_password
SLACK_WEBHOOK_URL=https://hooks.slack.com/...
```

---

## Usage

### Running CI Locally

#### Quick Test
```bash
# Run all tests
fastlane test

# Run specific test
xcodebuild test \
  -project AppIconMaker.xcodeproj \
  -scheme AppIconMaker \
  -destination 'platform=iOS Simulator,name=iPhone 15 Pro' \
  -only-testing:AppIconMakerTests/AppIconMakerTests/testIconSizeInitialization
```

#### Code Quality Check
```bash
# Run SwiftLint
swiftlint

# Auto-fix issues
swiftlint --fix

# Run with custom config
swiftlint --config .swiftlint.yml
```

#### Build
```bash
# Debug build
xcodebuild build \
  -project AppIconMaker.xcodeproj \
  -scheme AppIconMaker \
  -destination 'platform=iOS Simulator,name=iPhone 15 Pro'

# Release build
xcodebuild build \
  -project AppIconMaker.xcodeproj \
  -scheme AppIconMaker \
  -configuration Release
```

### Viewing CI Results

#### On GitHub

1. Go to repository **Actions** tab
2. Click on a workflow run
3. View job details and logs
4. Download artifacts (test results, coverage, archives)

#### Status Badges

Add to README.md:

```markdown
![iOS CI](https://github.com/yanggavin/icon-maker/workflows/iOS%20CI/badge.svg)
![Tests](https://github.com/yanggavin/icon-maker/workflows/Tests/badge.svg)
```

### Artifacts

CI generates several artifacts:

#### Test Results
- **Format:** `.xcresult` bundle
- **Location:** Actions → Workflow Run → Artifacts
- **Retention:** 90 days
- **Contents:** Test logs, screenshots, performance data

#### Code Coverage
- **Format:** JSON
- **Location:** Actions → Workflow Run → Artifacts
- **Contents:** Line and function coverage percentages

#### Build Archive
- **Format:** `.xcarchive`
- **Location:** Actions → Workflow Run → Artifacts (main branch only)
- **Retention:** 7 days
- **Use:** Distribution, debugging

---

## Performance Targets

### Build Times
- **Debug Build:** < 2 minutes
- **Release Build:** < 3 minutes
- **Test Suite:** < 5 minutes
- **Full CI Pipeline:** < 10 minutes

### Test Coverage
- **Target:** > 50%
- **Current:** TBD (run `fastlane coverage`)

### Code Quality
- **SwiftLint Warnings:** < 10
- **SwiftLint Errors:** 0
- **Cyclomatic Complexity:** < 10 per function

---

## Troubleshooting

### Common Issues

#### 1. Build Failures

**Symptom:** "No such module" errors

**Solution:**
```bash
# Clean derived data
rm -rf ~/Library/Developer/Xcode/DerivedData

# Clean build folder
xcodebuild clean

# Rebuild
xcodebuild build ...
```

#### 2. Test Failures

**Symptom:** Tests fail on CI but pass locally

**Solution:**
- Check simulator availability
- Verify Xcode version matches
- Check for timing issues (add delays if needed)
- Review test logs in artifacts

#### 3. SwiftLint Errors

**Symptom:** Too many warnings/errors

**Solution:**
```bash
# Auto-fix what's possible
swiftlint --fix

# Update configuration
vim .swiftlint.yml

# Disable specific rules if needed
```

#### 4. Simulator Issues

**Symptom:** Simulator not found or won't boot

**Solution:**
```bash
# List available simulators
xcrun simctl list devices

# Boot specific simulator
xcrun simctl boot "iPhone 15 Pro"

# Reset all simulators
xcrun simctl erase all
```

#### 5. Code Signing Errors

**Symptom:** Code signing fails in CI

**Solution:**
Ensure these flags are set in xcodebuild commands:
```bash
CODE_SIGN_IDENTITY="" \
CODE_SIGNING_REQUIRED=NO \
CODE_SIGNING_ALLOWED=NO
```

---

## Best Practices

### 1. Commit Practices
- ✅ Run tests before committing
- ✅ Run SwiftLint before committing
- ✅ Write descriptive commit messages
- ✅ Keep commits focused and atomic

### 2. PR Practices
- ✅ Ensure CI passes before requesting review
- ✅ Add tests for new features
- ✅ Update documentation
- ✅ Keep PRs small and focused

### 3. Testing Practices
- ✅ Write unit tests for business logic
- ✅ Write integration tests for workflows
- ✅ Add performance tests for critical paths
- ✅ Maintain > 50% code coverage

### 4. Code Quality
- ✅ Follow SwiftLint rules
- ✅ Keep functions small (< 50 lines)
- ✅ Keep files focused (< 500 lines)
- ✅ Document public APIs
- ✅ Use meaningful names

---

## Monitoring

### GitHub Actions Dashboard

View at: `https://github.com/yanggavin/icon-maker/actions`

**Metrics to Monitor:**
- Build success rate
- Test pass rate
- Average build time
- Code coverage trend
- SwiftLint warnings trend

### Notifications

Configure in **Settings** → **Notifications**:
- Email on workflow failure
- Slack/Discord webhooks
- GitHub mobile app

---

## Advanced Features

### Scheduled Builds

Add to workflow for nightly builds:

```yaml
on:
  schedule:
    - cron: '0 0 * * *'  # Daily at midnight UTC
```

### Deployment

Add deployment lanes to Fastfile:

```ruby
lane :deploy_testflight do
  build_app
  upload_to_testflight
end

lane :deploy_appstore do
  build_app
  upload_to_app_store
end
```

### UI Testing

Add UI tests:

```swift
class AppIconMakerUITests: XCTestCase {
    func testWelcomeScreen() {
        let app = XCUIApplication()
        app.launch()
        
        XCTAssertTrue(app.buttons["Select Image"].exists)
    }
}
```

---

## Maintenance

### Regular Tasks

#### Weekly
- Review CI metrics
- Check for flaky tests
- Update dependencies

#### Monthly
- Review code coverage
- Update Xcode version
- Update SwiftLint rules
- Clean up old artifacts

#### Quarterly
- Review and optimize CI pipeline
- Update documentation
- Audit security practices

---

## Resources

### Documentation
- [GitHub Actions Docs](https://docs.github.com/en/actions)
- [Fastlane Docs](https://docs.fastlane.tools/)
- [SwiftLint Rules](https://realm.github.io/SwiftLint/rule-directory.html)
- [Xcode Build Settings](https://xcodebuildsettings.com/)

### Tools
- [xcpretty](https://github.com/xcpretty/xcpretty) - Prettier xcodebuild output
- [xcov](https://github.com/fastlane-community/xcov) - Code coverage reports
- [danger](https://danger.systems/) - Automated PR reviews

---

## Support

For CI/CD issues:
1. Check workflow logs in GitHub Actions
2. Review this documentation
3. Check [GitHub Actions status](https://www.githubstatus.com/)
4. Open an issue in the repository

---

## Changelog

### 2024-10-22
- ✅ Initial CI/CD setup
- ✅ GitHub Actions workflow
- ✅ SwiftLint configuration
- ✅ Fastlane setup
- ✅ Unit tests
- ✅ Documentation

---

**Status:** ✅ Active and Operational
**Last Updated:** 2024-10-22
**Maintained By:** Development Team
