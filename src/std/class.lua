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
function createClass(typename, ...)
    assert(#... == 0, "Not yet implemented.")
    -- TODO: add static objects to classInnards
    -- TODO: classRef.__index to access static variables
    -- TODO: use inferred strict types by default
-- TODO: implements

    local classBody = select(2, ...)
    assert(type(classBody == "table"), "Second argument must be of type table (Class modifiers are not yet implemented).")
    local staticMembers = classBody["static"] or {}
    assert(type(staticMembers) == "table")

    local memberVars = {}
    for i, v in pairs(classBody) do
        if i ~= "static" then
            memberVars[i] = v
        end
    end

    local classInnards = {}
    -- TODO: ensure static member isn't a keyword
    function classInnards.__call()
        error("Wtf this was never supposed to run!!")
    end
    function classInnards.__index(i)
        -- error("Not yet implemented.", 2)
        return staticMembers[i]
    end
    function classInnards.__newindex()
        error("Not allowed.", 2)
    end
    function classInnards.new()
        -- TODO: default constructor
        local objInstance = {}
        -- TODO:
    end

    local classRef = function()
        error("A class reference object cannot be called.", 2)
    end
    return setmetatable(classRef, classInnards)
end
return createClass