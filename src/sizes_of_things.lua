local sizes = {}
local dims = require("dims")
local assets = require("assets")

sizes.resolutionConversionRatio = assets.get("settings").realResolution[2] / 1080.0
sizes.UITileSize = 16
sizes.UIScale = 5 * sizes.resolutionConversionRatio

sizes.testMugItemDims = dims.wrap {
    x = 0,
    y = 0,
    width = 256,
    height = 256
}
sizes.sceneviewDims = dims.wrap {
    x = (sizes.UIScale / sizes.resolutionConversionRatio) * sizes.UITileSize *
        (0.5 - (8 - (720 * sizes.resolutionConversionRatio) / (sizes.UITileSize * sizes.UIScale))),
    y = (sizes.UIScale / sizes.resolutionConversionRatio) * sizes.UITileSize *
        (0.5 - (8 - (720 * sizes.resolutionConversionRatio) / (sizes.UITileSize * sizes.UIScale))),
    width = 720,
    height = 720
}
sizes.chatboxDims = dims.wrap {
    x = 16.5,
    y = 1,
    width = 7,
    height = 12
}
sizes.chatMessagesBoundingBox = dims.wrap {
    x = sizes.chatboxDims.x * sizes.UITileSize * sizes.UIScale,
    y = sizes.chatboxDims.y * sizes.UITileSize * sizes.UIScale,
    width = 500 * sizes.resolutionConversionRatio,
    height = 1000 * sizes.resolutionConversionRatio
}
sizes.chatboxSendBtnDims = dims.wrap {
    x = sizes.chatMessagesBoundingBox.x + 475 * sizes.resolutionConversionRatio,
    y = sizes.chatMessagesBoundingBox.y + 865 * sizes.resolutionConversionRatio,
    width = sizes.UITileSize * 4 * sizes.resolutionConversionRatio,
    height = sizes.UITileSize * 4 * sizes.resolutionConversionRatio
}
sizes.mainHandInventorySlotDims = dims.wrap {
    x = 9 - 0.2,
    y = 4,
    width = 2,
    height = 2
}
sizes.loginboxDims = dims.wrap {
    x = 4,
    y = 4,
    width = 8,
    height = 3
}
sizes.loginboxBtnDims = dims.wrap {
    x = sizes.UITileSize / 2 * sizes.UIScale * (sizes.loginboxDims.x * 2 + 10 - 0.5),
    y = sizes.UITileSize / 2 * sizes.UIScale * (sizes.loginboxDims.y * 2 + 4 - 0.1),
    width = 3 * sizes.UITileSize * sizes.UIScale,
    height = sizes.UITileSize * sizes.UIScale
}
sizes.settingsBoxDimensionsInTiles = dims.wrap {
    x = 6,
    y = 6,
    width = 4,
    height = 6
}
sizes.settingsBtnDimensions = dims.wrap {
    x = 1830 * sizes.resolutionConversionRatio,
    y = 10 * sizes.resolutionConversionRatio,
    width = sizes.UITileSize * 4 * sizes.resolutionConversionRatio,
    height = sizes.UITileSize * 4 * sizes.resolutionConversionRatio
}

sizes.loginboxTextFieldsSizes = {
    username = {
        x = sizes.loginboxDims.x * sizes.UITileSize * sizes.UIScale + 270 * sizes.resolutionConversionRatio,
        y = sizes.loginboxDims.y * sizes.UITileSize * sizes.UIScale + 60 * sizes.resolutionConversionRatio,
        width = 300 * sizes.resolutionConversionRatio,
        margins = 2 * sizes.resolutionConversionRatio
    },
    password = {
        x = sizes.loginboxDims.x * sizes.UITileSize * sizes.UIScale + 270 * sizes.resolutionConversionRatio,
        y = sizes.loginboxDims.y * sizes.UITileSize * sizes.UIScale + 110 * sizes.resolutionConversionRatio,
        width = 300 * sizes.resolutionConversionRatio,
        margins = 2 * sizes.resolutionConversionRatio
    }
}
return sizes
