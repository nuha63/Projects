@echo off
cd /d E:\Flutter\KitchenCraft

echo Stopping Gradle...
cd android
call gradlew --stop
cd ..

echo Killing Java processes...
taskkill /F /IM java.exe 2>nul

timeout /t 3

echo Deleting Gradle cache...
rd /s /q "%USERPROFILE%\.gradle" 2>nul

echo Cleaning Flutter...
call flutter clean
rd /s /q android\.gradle 2>nul
rd /s /q android\app\build 2>nul
rd /s /q android\build 2>nul

echo Getting dependencies...
call flutter pub get

echo Building...
call flutter run -d emulator-5554

pause