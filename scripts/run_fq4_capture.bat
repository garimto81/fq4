@echo off
echo =====================================================
echo   First Queen 4 - Palette Capture Mode
echo =====================================================
echo.
echo Press Ctrl+F5 in game to take screenshots!
echo Screenshots will be saved to: capture\
echo.
echo Take screenshots at:
echo   - Title screen (character portraits)
echo   - Battle scene (character sprites)  
echo   - Status/equipment screen
echo.
pause
DOSBox.exe -conf dosbox.conf GAME
