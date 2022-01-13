@ECHO off
mkdir ./build
7z a ./build/files.zip BackroomsGame.love conf.lua main.lua src libs resources data build/**.dll -mx=9
pushd build
mkdir BackroomsGame-build
copy files.zip TempGame.love
copy "C:\Program Files\LOVE\lovec.exe" "./lovec.exe"
copy "C:\Program Files\LOVE\lua51.dll" "./BackroomsGame-build/lua51.dll"
copy "C:\Program Files\LOVE\love.dll" "./BackroomsGame-build/love.dll"
copy "C:\Program Files\LOVE\SDL2.dll" "./BackroomsGame-build/SDL2.dll"
copy "C:\Program Files\LOVE\mpg123.dll" "./BackroomsGame-build/mpg123.dll"
copy "C:\Program Files\LOVE\msvcp120.dll" "./BackroomsGame-build/msvcp120.dll"
copy "C:\Program Files\LOVE\msvcr120.dlll" "./BackroomsGame-build/msvcr120.dll"
copy "C:\Program Files\LOVE\OpenAL32.dll" "./BackroomsGame-build/OpenAL32.dll"
copy /b "./lovec.exe"+"./TempGame.love" "./BackroomsGame-build/BackroomsGame.exe"
del TempGame.love files.zip
7z a ./BackroomsGame.zip BackroomsGame-build
@REM del love.exe
popd
@REM ECHO ...STARTING THE GAME...
@REM call .\build\BackroomsGame-build\BackroomsGame.exe