local types = {}
local lua = require("std.luaOverrides")
local assert = require("std.assert")

-- luacheck:ignore typeNamesLua
local typeNamesLua = {"string", "nil", "userdata", "number", "function", "table", "boolean", "thread"}

-- luacheck:ignore typeNamesLove
local typeNamesLove = { -- TODO: Exclude the ones excluded in config.lua
-- TODO: Move into a json file
"Object", "Data", "CompressedData", "CompressedImageData", "FileData", "FontData", "GlyphData", "ImageData",
"SoundData", "BezierCurve", "RandomGenerator", "Body", "Contact", "Fixture", "World", "Shape", "ChainShape",
"CircleShape", "EdgeShape", "PolygonShape", "Joint", "FrictionJoint", "GearJoint", "MotorJoint", "MouseJoint",
"PrismaticJoint", "PulleyJoint", "RevoluteJoint", "RopeJoint", "WeldJoint", "WheelJoint", "Channel", "Thread", "Cursor",
"PixelEffect", "Shader", "Quad", "Drawable", "Texture", "Canvas", "Framebuffer", "Image", "Mesh", "ParticleSystem",
"SpriteBatch", "Text", "Video", "Decoder", "Source", "QueuableSource", "File", "Font", "Rasterizer", "Joystick",
"VideoStream", "Variant"}

-- luacheck:ignore typeNamesStd
local typeNamesStd = {"class"}

function types.makeType(obj, typeName)
    if type(typeName) ~= "string" then
        error("You must specify a type name!", 2)
    end
    obj.type = typeName
    obj.__index = obj.__index or obj
    return obj
end

function types.assertIsDimensions(obj)
    assert(obj, "", 2)
    assert(not not obj.x, "", 2)
    assert(not not obj.y, "", 2)
    assert(not not obj.width, "", 2)
    assert(not not obj.height, "", 2)
end

function types.isCallable(var)
    return type(var) == "function" or (type(var) == "table" and getmetatable(var).__call)
end

function types.isint(num)
    if type(num) ~= "number" then
        return false
    end
    if math.floor(num) ~= num then
        return false
    end
    return true
end
function types.isuint(num)
    if types.isint(num) == false then
        return false
    end
    if num >= 0 then
        return true
    end
    return false
end

function types.isureal(num)
    if type(num) ~= "number" then
        return false
    end
    if num <= 0 then
        return false
    end
    return true
end

function types.optionalCall(func, ...)
    if lua.isCallable(func) then
        return func(...)
    end
end

function types.checked(var, typeName, errorLevel, errHandle)
    errorLevel = errorLevel or 1
    if type(typeName) ~= "string" then
        error("You must specify a type name!", 2)
    end
    if type(var) == typeName then
        return var
    elseif type(var) == "userdata" and var.type == typeName then
        return var
    else
        if errHandle then
            error("Not yet implemented.")
        else
            if errorLevel == 0 then
                error("Unexpected variable of type " .. type(var) .. ", " .. typeName .. " expected.", 1 + errorLevel)
            end
        end
    end
end
return types
