@ECHO off
mkdir ./build
7z a ./build/files.zip BackroomsGame.love main.lua src libs resources data -mx=9
pushd build
copy files.zip TempGame.love
copy "C:\Program Files\LOVE\love.exe" love.exe
copy /b "./love.exe"+"./TempGame.love" "./BackroomsGame.exe"
del love.exe TempGame.love files.zip
popd
start ./build/BackroomsGame.exe