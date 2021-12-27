-- ! sets a global object
class = {}

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
function class.__call(typename)
    assert(typeNamesLove:excludes(typename))
    return {
        type = className
    }
end

function class.__newindex(table, key, value)
    error("Syntax error!")
end

function class.immutable()
    error("Not yet implemented.")
end
function class.setImmutable(class)
    error("Not yet implemented.")
end
setmetatable(class, class)
return class