# KitchenCraft App Icon Guide

## Current Status
You need to create two icon images for your KitchenCraft app:

### 1. Main Icon (app_icon.png)
- **Size:** 1024x1024 pixels (minimum 512x512)
- **Format:** PNG with transparent background
- **Design:** Should represent cooking/kitchen theme
- **Suggested Icon Ideas:**
  - Chef hat with utensils
  - Cooking pot or pan with steam
  - Fork and knife crossed
  - Kitchen apron
  - Recipe book icon
  - Orange/warm colors to match your app theme

### 2. Foreground Icon (app_icon_foreground.png) - For Android Adaptive Icons
- **Size:** 1024x1024 pixels
- **Format:** PNG with transparent background
- **Note:** The icon should fit within the safe zone (center 66% of the image)

## How to Create Your Icon

### Option 1: Use Online Icon Generator (Easiest)
1. Visit: https://icon.kitchen/ or https://www.appicon.co/
2. Choose a cooking/kitchen related icon or upload your own design
3. Customize colors to match KitchenCraft (orange #FF6D00)
4. Download the icons

### Option 2: Use Canva (Free)
1. Go to canva.com
2. Create a 1024x1024px design
3. Search for "cooking" or "kitchen" elements
4. Design your icon with orange color scheme
5. Download as PNG with transparent background

### Option 3: Use Figma/Adobe (Professional)
- Design a custom icon matching your app's branding
- Export as 1024x1024px PNG

## After Creating Your Icons

1. Save as:
   - `E:\Flutter\KitchenCraft\assets\images\app_icon.png`
   - `E:\Flutter\KitchenCraft\assets\images\app_icon_foreground.png`

2. Run the command:
   ```
   flutter pub get
   flutter pub run flutter_launcher_icons
   ```

3. Rebuild your app:
   ```
   flutter build apk --release
   ```

## Icon Specifications
- Background color: #FF6D00 (Orange - already configured)
- Recommended style: Flat, modern, simple
- Should be recognizable even at small sizes
- Avoid too much detail or text

## Example Icon Concepts for KitchenCraft:
```
Concept 1: Chef Hat Icon
- Simple chef's hat silhouette
- Orange gradient background
- White hat design

Concept 2: Cooking Pot
- Steaming pot icon
- Orange/red colors
- Simple, flat design

Concept 3: Recipe Book
- Open book with fork/spoon
- Orange accent colors
- Minimalist style
```
