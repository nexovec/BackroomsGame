# The BackroomsGame
This is the backrooms game private repository. (This is public for now) I am a solo developer, so you shouldn't even be here. Go away.
## Conventions:
- Return values of modules must have the same name as the file.
- Don't define global variables, including functions. Don't monkeypatch anything on built-in objects.
- use `var = "string"` instead of `var = 'string'`.
- For std, don't have dependencies to external code.
## How to run the game:
You need to have love installed and have it inside Path, or have it in this folder. In this folder, run:
```batch
love .
```
## How to package the game into an executable:
You need to have 7-zip installed and have it inside Path. In this folder, run:
```batch
BUILD.bat
```
## Roadmap
I have long term goals of reusing the tooling from this game for my other projects and I'm mainly
interested in learning. That's why I will be focusing solely on the heavily technical aspect of game-dev for now.
- [] shader preprocessor
- [] fade-in/out shader
- [] grayscale shader
- [] settings menu
- [] phone/gameboy shader
- [] vignette, film-grain, possibly FXAA
- [] loading screen
## Changelog
> ## v.0.0.0 basic project setup
> - project build
> - correct rendering, animations
