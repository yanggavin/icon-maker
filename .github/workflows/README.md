# CI/CD Workflows

This directory contains GitHub Actions workflows for automated testing and deployment of the App Icon Maker iOS app.

## Workflows

### 1. iOS CI (`ios-ci.yml`)

Runs on every push and pull request to `main` and `develop` branches.

**Jobs:**

#### Build and Test
- Runs on macOS 13 with Xcode 15.0
- Tests on multiple simulators:
  - iPhone 15 Pro (iOS 17.0)
  - iPhone SE 3rd gen (iOS 17.0)
  - iPad Pro 12.9" 6th gen (iOS 17.0)
- Generates code coverage reports
- Uploads test results as artifacts

#### Code Quality
- Runs SwiftLint for code style checks
- Checks for TODO/FIXME comments
- Reports issues directly in PR

#### Build Archive
- Only runs on `main` branch
- Creates an archive build
- Uploads archive as artifact (7-day retention)

#### Performance Check
- Builds in Release configuration
- Checks binary size
- Monitors build performance

## Setup Instructions

### 1. Enable GitHub Actions

GitHub Actions should be enabled by default. If not:
1. Go to repository Settings
2. Navigate to Actions → General
3. Enable "Allow all actions and reusable workflows"

### 2. Configure Secrets (Optional)

For advanced features, add these secrets in repository Settings → Secrets:

```
APPLE_ID=your.apple.id@email.com
TEAM_ID=your_team_id
FASTLANE_PASSWORD=your_app_specific_password
MATCH_PASSWORD=your_match_password
```

### 3. Install Dependencies Locally

To run the same checks locally:

```bash
# Install Homebrew (if not installed)
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Install SwiftLint
brew install swiftlint

# Install Fastlane
brew install fastlane

# Install xcpretty (optional, for prettier output)
gem install xcpretty
```

## Running Locally

### Build and Test
```bash
# Using xcodebuild
xcodebuild test \
  -project AppIconMaker.xcodeproj \
  -scheme AppIconMaker \
  -destination 'platform=iOS Simulator,name=iPhone 15 Pro'

# Using Fastlane
fastlane test
```

### Code Quality
```bash
# Run SwiftLint
swiftlint

# Run all quality checks
fastlane quality
```

### Build
```bash
# Using xcodebuild
xcodebuild build \
  -project AppIconMaker.xcodeproj \
  -scheme AppIconMaker \
  -destination 'platform=iOS Simulator,name=iPhone 15 Pro'

# Using Fastlane
fastlane build
```

## Workflow Triggers

### Automatic Triggers
- **Push to main/develop**: Runs full CI pipeline
- **Pull Request to main/develop**: Runs build and test
- **Tag push (v*)**: Triggers release build (if configured)

### Manual Triggers
You can manually trigger workflows from the Actions tab:
1. Go to Actions
2. Select the workflow
3. Click "Run workflow"
4. Choose branch and parameters

## Artifacts

Workflows generate several artifacts:

### Test Results
- Location: Actions → Workflow Run → Artifacts
- Format: `.xcresult` bundle
- Retention: 90 days
- Contains: Test logs, screenshots, performance data

### Code Coverage
- Location: Actions → Workflow Run → Artifacts
- Format: JSON
- Contains: Line and function coverage data

### Build Archive
- Location: Actions → Workflow Run → Artifacts (main branch only)
- Format: `.xcarchive`
- Retention: 7 days
- Use for: Distribution, debugging

## Status Badges

Add these badges to your README.md:

```markdown
![iOS CI](https://github.com/yanggavin/icon-maker/workflows/iOS%20CI/badge.svg)
![Code Quality](https://github.com/yanggavin/icon-maker/workflows/Code%20Quality/badge.svg)
```

## Troubleshooting

### Build Failures

**Issue**: "No such module" errors
**Solution**: Clean derived data and rebuild
```bash
rm -rf ~/Library/Developer/Xcode/DerivedData
xcodebuild clean build ...
```

**Issue**: Simulator not found
**Solution**: Update simulator name in workflow or install required simulator

**Issue**: Code signing errors
**Solution**: Ensure `CODE_SIGNING_REQUIRED=NO` is set in build commands

### Test Failures

**Issue**: Tests timeout
**Solution**: Increase timeout in workflow or optimize tests

**Issue**: Flaky tests
**Solution**: Add retry logic or fix test dependencies

### SwiftLint Failures

**Issue**: Too many warnings
**Solution**: Update `.swiftlint.yml` configuration

**Issue**: SwiftLint not found
**Solution**: Ensure SwiftLint is installed in workflow

## Performance Optimization

### Caching
The workflow caches:
- Swift Package Manager dependencies
- Derived Data
- CocoaPods (if used)

### Parallel Execution
Tests run in parallel across multiple simulators using matrix strategy.

### Conditional Jobs
Some jobs only run on specific branches or conditions to save CI minutes.

## Best Practices

1. **Keep workflows fast**: Aim for < 10 minutes total
2. **Use caching**: Cache dependencies and build artifacts
3. **Fail fast**: Run quick checks (lint) before slow ones (tests)
4. **Parallel execution**: Use matrix strategy for multiple configurations
5. **Artifact cleanup**: Set appropriate retention periods
6. **Secrets management**: Never commit secrets, use GitHub Secrets
7. **Branch protection**: Require CI to pass before merging

## Monitoring

### View Workflow Status
1. Go to repository Actions tab
2. See all workflow runs
3. Click on a run to see details
4. View logs for each job

### Notifications
Configure notifications in GitHub Settings → Notifications:
- Email on workflow failure
- Slack/Discord integration (via webhooks)
- GitHub mobile app notifications

## Advanced Features

### Scheduled Runs
Add to workflow for nightly builds:
```yaml
on:
  schedule:
    - cron: '0 0 * * *'  # Daily at midnight UTC
```

### Deployment
Add deployment jobs for:
- TestFlight uploads
- App Store submissions
- Beta distribution

### Integration Tests
Add jobs for:
- UI testing
- Performance testing
- Accessibility testing

## Resources

- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [Fastlane Documentation](https://docs.fastlane.tools/)
- [SwiftLint Rules](https://realm.github.io/SwiftLint/rule-directory.html)
- [Xcode Build Settings](https://xcodebuildsettings.com/)

## Support

For issues with CI/CD:
1. Check workflow logs
2. Review this documentation
3. Check GitHub Actions status page
4. Open an issue in the repository
