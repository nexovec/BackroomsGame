# The BackroomsGame

This is the backrooms game private repository. (This is public for now) I am a solo developer, so you shouldn't even be here. Go away.

## Conventions

- Don't define global variables, including functions. Don't monkeypatch anything on built-in objects.
- Use `var = "string"` instead of `var = 'string'`.
- For std, don't have dependencies to external code.

## How to run the game

You need to have love installed and have it inside Path, or have it in this folder. In this folder, run:
> FIXME: resources/images/fireCircles.png needs to exist. I will add it soon... I have the image, but I need to scale it down... wanted to make my own program to do that.
```batch
love .
```

## How to package the game into an executable

You need to have 7-zip installed and have it inside Path. In this folder, run:

```batch
BUILD.bat
```

## Roadmap

I have long term goals of reusing the tooling from this game for my other projects and I'm mainly
interested in learning. That's why I will be focusing solely on the heavily technical aspect of game-dev for now.

- [x] Hot-reload shaders and data
- [ ] Whole-app testing. (auto-login)
- [ ] Shader preprocessor
- [ ] Fade-in/out shader
- [ ] Grayscale shader
- [ ] Settings menu
- [ ] Phone/gameboy shader
- [ ] Loading screen
- [ ] Vignette, film-grain, possibly FXAA

## Changelog

> ## v.0.0.0 basic project setup
>
> - project build
> - correct rendering, animations
