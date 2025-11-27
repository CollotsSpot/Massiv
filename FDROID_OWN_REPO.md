# Your Own F-Droid Repository - Setup Guide

This guide will help you set up your own automated F-Droid repository using GitHub Pages.

## Overview

Once set up, this system will:
- ✅ Automatically build an F-Droid repository when you create a release
- ✅ Host the repository on GitHub Pages (free)
- ✅ Allow users to add your repo to their F-Droid app
- ✅ Provide automatic updates through F-Droid

## Setup Steps

### 1. Enable GitHub Pages

1. Go to your repository on GitHub
2. Click **Settings** (top menu)
3. Click **Pages** (left sidebar)
4. Under "Source", select:
   - **Branch:** `gh-pages`
   - **Folder:** `/ (root)`
5. Click **Save**

GitHub will show you the URL where your repo will be published:
```
https://collotsspot.github.io/Assistant-To-The-Music/
```

### 2. Create Your First Release

The F-Droid repo is automatically generated when you create a GitHub release:

```bash
# Tag your current version
git tag -a v1.0.0 -m "Release version 1.0.0"
git push origin v1.0.0

# Create a release on GitHub with the APK
gh release create v1.0.0 \
  --title "v1.0.0 - First Release" \
  --notes "Initial release with all features" \
  build/app/outputs/flutter-apk/app-release.apk
```

Or create the release through GitHub web interface:
1. Go to **Releases** → **Create a new release**
2. Choose tag `v1.0.0`
3. Add release notes
4. **Upload the APK file** as an asset
5. Click **Publish release**

### 3. Wait for GitHub Actions

After creating the release:
1. Go to **Actions** tab in your GitHub repo
2. You'll see the "Build F-Droid Repository" workflow running
3. Wait for it to complete (usually ~2-5 minutes)
4. Once done, your F-Droid repo will be live!

### 4. Verify Your Repository

Visit your F-Droid repository URL:
```
https://collotsspot.github.io/Assistant-To-The-Music/fdroid/repo
```

You should see an `index-v1.json` file and your APK.

## How Users Add Your Repository

### On Their Device:

1. **Open F-Droid app**
2. Go to **Settings** → **Repositories**
3. Tap the **"+"** button (top right)
4. Enter your repository URL:
   ```
   https://collotsspot.github.io/Assistant-To-The-Music/fdroid/repo
   ```
5. Tap **OK**
6. F-Droid will scan your repository
7. Your app appears in F-Droid!

### Share This With Users:

You can add this to your README:

```markdown
## Install via F-Droid

### Add Our Repository

1. Open F-Droid app
2. Go to Settings → Repositories
3. Tap "+" and add: `https://collotsspot.github.io/Assistant-To-The-Music/fdroid/repo`
4. Install Assistant To The Music from your F-Droid app!
```

Or create a clickable link (requires F-Droid 1.12+):
```markdown
[<img src="https://fdroid.gitlab.io/artwork/badge/get-it-on.png"
     alt="Get it on F-Droid"
     height="80">](https://collotsspot.github.io/Assistant-To-The-Music/fdroid/repo?fingerprint=YOUR_FINGERPRINT)
```

## Updating Your App

Whenever you want to release a new version:

1. **Update version in `pubspec.yaml`:**
   ```yaml
   version: 1.1.0+2  # Increment both version name and code
   ```

2. **Build and release:**
   ```bash
   # Build the APK
   flutter build apk --release

   # Tag and push
   git add pubspec.yaml
   git commit -m "Bump version to 1.1.0"
   git push

   git tag -a v1.1.0 -m "Release version 1.1.0"
   git push origin v1.1.0

   # Create GitHub release with APK
   gh release create v1.1.0 \
     --title "v1.1.0 - Feature Update" \
     --notes "What's new in this version..." \
     build/app/outputs/flutter-apk/app-release.apk
   ```

3. **Automatic update:**
   - GitHub Actions builds the F-Droid repo
   - Users with your repo added will see the update in F-Droid

## Troubleshooting

### Workflow Fails

Check the Actions tab for error details. Common issues:
- APK not attached to release
- GitHub Pages not enabled
- Wrong branch selected for Pages

### Repository Not Updating

1. Check GitHub Actions completed successfully
2. Clear GitHub Pages cache (wait 5-10 minutes)
3. Verify `gh-pages` branch exists and has content

### Users Can't Find App

1. Verify repository URL is correct
2. Check GitHub Pages is enabled and published
3. Make sure `index-v1.json` exists at the repo URL
4. Users may need to refresh repositories in F-Droid

## Manual Trigger

You can manually trigger the workflow without creating a release:

1. Go to **Actions** tab
2. Select **Build F-Droid Repository**
3. Click **Run workflow**
4. Select branch and run

## What Gets Created

Your F-Droid repository will have:
```
fdroid/
├── repo/
│   ├── index-v1.json          # Repository index
│   ├── index-v1.jar           # Signed index
│   ├── icon.png               # Your app icon
│   └── app-release.apk        # Your APK
└── metadata/
    └── com.musicassistant.music_assistant.yml
```

## Benefits of This Approach

✅ **Fully automated** - Just create releases
✅ **Free hosting** - GitHub Pages
✅ **Professional** - Real F-Droid repository
✅ **Instant updates** - No approval needed
✅ **Full control** - You manage everything

## Next Steps

After setup:
1. Create your first release (see Step 2)
2. Test by adding your repo to F-Droid on your device
3. Share the repository URL with your users
4. Optionally submit to official F-Droid too!

---

**Need help?** Open an issue at: https://github.com/CollotsSpot/Assistant-To-The-Music/issues
