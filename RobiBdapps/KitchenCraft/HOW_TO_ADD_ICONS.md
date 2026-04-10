# How to Add Your Downloaded Icons to KitchenCraft

## Step 1: Extract the ZIP file
Right-click your downloaded ZIP file → Extract All

## Step 2: Find the Right Icon Files

After extracting, look for these files:

### For Android & iOS (Flutter will auto-generate all sizes):
- Look for the **largest PNG file** (usually 1024x1024 or 512x512)
- Common names: `icon.png`, `app_icon.png`, `android_icon.png`, or similar

### For Web:
- Look for a file like `favicon.png` or `web_icon.png`

## Step 3: Copy Files to Correct Locations

### Option A: Simple Method (One Icon for All)
Copy the largest/best quality icon to BOTH locations:
```
E:\Flutter\KitchenCraft\assets\images\app_icon.png
E:\Flutter\KitchenCraft\assets\images\app_icon_foreground.png
```
(They can be the same file with different names)

### Option B: If You Have Separate Android Folders
If your extracted folder has multiple mipmap folders like:
- mipmap-hdpi
- mipmap-mdpi
- mipmap-xhdpi
- etc.

You have two choices:
1. **Easier:** Just copy the largest icon to `assets/images/app_icon.png` and let Flutter generate the rest
2. **Manual:** Copy all mipmap folders to `E:\Flutter\KitchenCraft\android\app\src\main\res\`

### For Web Icon:
Copy the web icon to:
```
E:\Flutter\KitchenCraft\web\favicon.png
```

## Step 4: Run the Icon Generator

### Method 1: Using flutter_launcher_icons (Recommended)
If you placed a single icon in `assets/images/app_icon.png`:

```powershell
cd E:\Flutter\KitchenCraft
flutter pub run flutter_launcher_icons
```

This automatically generates all sizes for Android and iOS!

### Method 2: Manual Copy (if you have all mipmap folders)
Skip the generator if you manually copied all Android folders to the res directory.

## Step 5: Rebuild Your App

```powershell
cd E:\Flutter\KitchenCraft\android
.\gradlew.bat assembleRelease
```

## Quick Command Summary:
```powershell
# After placing icons
cd E:\Flutter\KitchenCraft
flutter pub run flutter_launcher_icons
cd android
.\gradlew.bat assembleRelease
```

## Need Help?
Tell me:
1. Where you extracted the ZIP file (path)
2. What files/folders you see inside
3. Which file looks like the main icon

I can help you move them to the right places!
