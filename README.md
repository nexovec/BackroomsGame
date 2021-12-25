# The BackroomsGame
This is the backrooms game private repository. (This is public for now) I am a solo developer, so you shouldn't even be here. Go away.
## Conventions:
- Return values of modules must have the same name as the file.
- Don't use `'function obj:func() ... end'` notation. Instead, use ``'function obj.func() ... end'``.
- Don't define global variables, including functions. Don't monkeypatch anything on built-in objects.
- use `var = "string"` instead of `var = 'string'`.
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
## Changelog
> ## v.0.0.0 basic project setup
> - project build
> - correct rendering, animations
