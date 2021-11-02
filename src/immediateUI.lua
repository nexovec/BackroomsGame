local UI = {}

-- hinted settings
local preferredBorders = nil
local preferredPadding = nil
local minimumCellSize  = nil
local maximumCellCount = nil

local layoutCache = {}

function UI.startFlexLayout()
    -- assert(minimumCellSize)
    -- assert(maximumCellCount)
    -- assert(preferredPadding)
    -- assert(preferredBorders)
    -- if minimumCellSize  == nil then minimumCellSize  = {x = 200, y = 200} end 
    -- if maximumCellCount == nil then maximumCellCount = {x = 3, y = 3}     end 
    -- if preferredBorders == nil then preferredBorders = {x = 50, y = 50}   end 
    -- if preferredPadding == nil then preferredPadding = {x = 50, y = 50}   end 

    -- TODO: use metatable __index instead of replaceIfNil??
    layoutCache[#layoutCache+1] = {
        currentCol = 1,
        currentRow = 1,
        minimumCellSize  = replaceIfNil(minimumCellSize,  shallowCopy({x = 50, y = 50})), 
        maximumCellCount = replaceIfNil(preferredBorders, shallowCopy({x = 3, y = 3})),
        preferredBorders = replaceIfNil(preferredBorders, shallowCopy({x = 50, y = 50})),
        preferredPadding = replaceIfNil(preferredPadding, shallowCopy({x = 50, y = 50}))
    }
end

function UI.nextCol()
    assert(#layoutCache ~= 0)
    local layout = layoutCache[#layoutCache]
    assert(layout.maximumCellCount.x ~= nil)
    if layout.currentCol >= layout.maximumCellCount.x then
        error("Exceeded maximum allowed", 2)
    end
    layout.currentCol = layout.currentCol + 1
end

function UI.nextRow()
    assert(#layoutCache ~= 0)
    local layout = layoutCache[#layoutCache]
    assert(layout.maximumCellCount.y ~= nil)
    if layout.currentRow >= layout.maximumCellCount.y then
        error("Exceeded maximum allowed", 2)
    end
    layout.currentRow = layout.currentRow + 1
end

-- HACK: WHY even make such setters?
function UI.setPreferredLayoutBorders(x, y)
    assert(x and type(x) == "number", "Wrong argument type")
    assert(y and type(y) == "number", "Wrong argument type")

    preferredBorders = {x = x, y = y}
end

function UI.setPreferredLayoutPadding(x, y)
    assert(x and type(x) == "number", "Wrong argument type")
    assert(y and type(y) == "number", "Wrong argument type")

    preferredPadding = {x = x, y = y}
end

function UI.setMinimumLayoutCellSize(x, y)
    assert(x and type(x) == "number", "Wrong argument type")
    assert(y and type(y) == "number", "Wrong argument type")

    minimumCellSize = {x = x, y = y}
end

function UI.setMaximumLayoutCellCount(x, y)
    assert(x and type(x) == "number", "Wrong argument type")
    assert(y and type(y) == "number", "Wrong argument type")
    
    maximumCellCount = {x = x, y = y}
end

function UI.popLayout()
    layoutCache = {}
end

return UI