🍳 KitchenCraft App Icon Setup Instructions
===========================================

## Quick Start - Get Your Icon Ready

### Step 1: Create Your App Icon (Choose ONE option)

#### Option A: Use Icon.Kitchen (Recommended - Easiest!)
1. Visit: https://icon.kitchen/
2. Click "Icon" tab
3. Search for "chef" or "cooking" or "kitchen"
4. Choose an icon you like
5. Change color to orange (#FF6D00)
6. Click "Download" → Download as PNG (1024x1024)
7. Save as: `app_icon.png` in `E:\Flutter\KitchenCraft\assets\images\`
8. For adaptive icon: Save same icon as `app_icon_foreground.png`

#### Option B: Use Flaticon (Free Icons)
1. Visit: https://www.flaticon.com/
2. Search: "chef hat" or "cooking" or "restaurant"
3. Download free PNG (1024x1024 or larger)
4. Save as both:
   - `app_icon.png`
   - `app_icon_foreground.png`
   
#### Option C: Use Canva (Design Custom Icon)
1. Visit: https://www.canva.com/
2. Create: 1024x1024px design
3. Search "cooking icon" in elements
4. Customize with orange colors (#FF6D00)
5. Download as PNG with transparent background
6. Save as both required files

### Step 2: After Saving Your Icons
Once you have your icons saved in `E:\Flutter\KitchenCraft\assets\images\`, run:

```powershell
cd E:\Flutter\KitchenCraft
flutter pub run flutter_launcher_icons
```

### Step 3: Rebuild and Install
```powershell
cd android
.\gradlew.bat assembleRelease
flutter install -d RFCXC05TVPF --use-application-binary="android\app\build\outputs\apk\release\app-release.apk"
```

## Files You Need to Create:
✓ `E:\Flutter\KitchenCraft\assets\images\app_icon.png` (1024x1024 px)
✓ `E:\Flutter\KitchenCraft\assets\images\app_icon_foreground.png` (1024x1024 px)

## Icon Design Tips:
- ✓ Simple and recognizable at small sizes
- ✓ Orange (#FF6D00) matches your app theme
- ✓ Kitchen/cooking themed (chef hat, pot, utensils, recipe book)
- ✓ No text (works better at small sizes)
- ✓ PNG with transparent background

## Testing Your Icon:
After installation, you'll see your custom icon:
- On phone home screen (launcher)
- In app drawer
- In recent apps menu
- Much more professional than default Flutter icon!
