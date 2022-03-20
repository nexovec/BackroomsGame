local sizes = {}
local dims = require("dims")

sizes.UITileSize = 16
sizes.UIScale = 5

sizes.testMugItemDims = dims.wrap {
    x = 0,
    y = 0,
    width = 256,
    height = 256
}
sizes.sceneviewDims = dims.wrap {
    x = sizes.UIScale * sizes.UITileSize * (0.5 - (8 - 720 / (sizes.UITileSize * sizes.UIScale))),
    y = sizes.UIScale * sizes.UITileSize * (0.5 - (8 - 720 / (sizes.UITileSize * sizes.UIScale))),
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
    width = 500,
    height = 1000
}
sizes.chatboxSendBtnDims = dims.wrap {
    x = sizes.chatMessagesBoundingBox.x + 475,
    y = sizes.chatMessagesBoundingBox.y + 865,
    width = 64,
    height = 64
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
    x = 1830,
    y = 10,
    width = 64,
    height = 64
}

sizes.loginboxTextFieldsSizes = {
    username = {
        x = sizes.loginboxDims.x * sizes.UITileSize * sizes.UIScale + 270,
        y = sizes.loginboxDims.y * sizes.UITileSize * sizes.UIScale + 60,
        width = 300,
        margins = 2
    },
    password = {
        x = sizes.loginboxDims.x * sizes.UITileSize * sizes.UIScale + 270,
        y = sizes.loginboxDims.y * sizes.UITileSize * sizes.UIScale + 110,
        width = 300,
        margins = 2
    }
}
return sizes
