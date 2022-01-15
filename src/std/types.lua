local types = {}
local set = require("std.set")

typeNamesLua = set.createSet{
    "string",
    "nil",
    "userdata",
    "number",
    "function",
    "table",
    "boolean",
    "thread"
}

typeNamesLove = set.createSet{
    -- TODO: exclude the ones excluded in config.lua
    -- TODO: move into a json file
    "Object",
    "Data",
    "CompressedData",
    "CompressedImageData",
    "FileData",
    "FontData",
    "GlyphData",
    "ImageData",
    "SoundData",
    "BezierCurve",
    "RandomGenerator",
    "Body",
    "Contact",
    "Fixture",
    "World",
    "Shape",
    "ChainShape",
    "CircleShape",
    "EdgeShape",
    "PolygonShape",
    "Joint",
    "FrictionJoint",
    "GearJoint",
    "MotorJoint",
    "MouseJoint",
    "PrismaticJoint",
    "PulleyJoint",
    "RevoluteJoint",
    "RopeJoint",
    "WeldJoint",
    "WheelJoint",
    "Channel",
    "Thread",
    "Cursor",
    "PixelEffect",
    "Shader",
    "Quad",
    "Drawable",
    "Texture",
    "Canvas",
    "Framebuffer",
    "Image",
    "Mesh",
    "ParticleSystem",
    "SpriteBatch",
    "Text",
    "Video",
    "Decoder",
    "Source",
    "QueuableSource",
    "File",
    "Font",
    "Rasterizer",
    "Joystick",
    "VideoStream",
    "Variant"
}

local typeNamesStd = {
    "class"
}

function types.makeType(obj, typeName)
    -- assert(type(typeName) == "string")
    obj.type = typeName
    obj.__index = obj.__index or obj
    return obj
end
function types.isint(num)
    if type(num) ~= "number" then return false end
    if math.floor(num) ~= num then return false end
    return true
end
function types.isuint(num)
    if types.isint(num) == false then return false end
    if num >= 0 then
        return true
    end
    return false
end

function types.isureal(num)
    if type(num) ~= "number" then return false end
    if num<=0 then return false end
    return true
end

function types.checked(var, typeName, errorLevel, errHandle)
    errorLevel = errorLevel or 1
    assert(errorLevel >= 0)
    assert(type(typeName) == "string")
    if type(var) == typeName then
        return var
    else
        if errHandle then
            error("Not yet implemented.")
        else
            if errorLevel == 0 then error("Unexpected variable of type " .. type(var) .. ", " .. typeName .. " expected.", 1 + errorLevel) end
        end
    end
end
return types