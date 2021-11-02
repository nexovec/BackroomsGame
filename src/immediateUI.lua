local UI = {}

-- hinted settings
local preferredBorders = nil
local preferredPadding = nil
local minimumCellSize  = nil
local maximumCellCount = nil

local layoutCache = {}

local function ensureCellIsCached()
    local cache = layoutCache[#layoutCache]
    cache.renderCache[cache.currentRow] = cache.renderCache[cache.currentRow] or {}

    -- for a list of render items
    -- cache.renderCache[cache.currentRow][cache.currentCol] = cache.renderCache[cache.currentRow][cache.currentCol] or {} 

    -- for one render item
    cache.renderCache[cache.currentRow][cache.currentCol] = cache.renderCache[cache.currentRow][cache.currentCol] or nil
end

function UI.startFlexLayout()
    -- TODO: load default values from data.json
    layoutCache[#layoutCache+1] = {
        currentCol = 1,
        currentRow = 1,
        minimumCellSize  = minimumCellSize  or shallowCopy({x = 50, y = 50}),
        maximumCellCount = preferredBorders or shallowCopy({x = 3, y = 3}),
        preferredBorders = preferredBorders or shallowCopy({x = 50, y = 50}),
        preferredPadding = preferredPadding or shallowCopy({x = 50, y = 50}),
        renderCache = {}
    }
    ensureCellIsCached()
end
function UI.renderCanvas(cvs)
    assert(cvs)
    local layout = layoutCache[#layoutCache]

    -- a list of items
    -- local cache = layout.renderCache[layout.currentRow][layout.currentCol]
    -- cache[#cache+1] = cvs

    -- one item
    layout.renderCache[layout.currentRow][layout.currentCol] = cvs
end


function UI.nextCol()    
    assert(#layoutCache ~= 0)
    local layout = layoutCache[#layoutCache]
    assert(layout.maximumCellCount.x ~= nil)
    if layout.currentCol >= layout.maximumCellCount.x then
        error("Exceeded maximum allowed", 2)
    end
    layout.currentCol = layout.currentCol + 1
    ensureCellIsCached()
end

function UI.nextRow()
    assert(#layoutCache ~= 0)
    local layout = layoutCache[#layoutCache]
    assert(layout.maximumCellCount.y ~= nil)
    if layout.currentRow >= layout.maximumCellCount.y then
        error("Exceeded maximum allowed", 2)
    end
    layout.currentRow = layout.currentRow + 1
    ensureCellIsCached()
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

function UI.popLayout(renderTarget)
    renderTarget = renderTarget or nil
    love.graphics.setCanvas(renderTarget)
    local renderCache = layoutCache[#layoutCache].renderCache
    local height = #renderCache
    for k, renderRowList in ipairs(renderCache) do
        local width = #renderRowList
        for index, renderItem in ipairs(renderRowList) do
            -- assume renderItem is always a canvas
            if renderItem ~= nil then
                assert(type(renderItem) == "table", "renderItem has data type " .. type(renderItem) .. " instead of table")
                assert(renderItem:type() == "Canvas", "renderItem has data type " .. renderItem:type() .. " instead of Canvas")
                -- TODO: align layout and compute padding
                -- TODO: stretch cells based on json
                love.graphics.draw(renderItem, love.graphics.newQuad(0, 0, 640, 480, playfieldCanvas:getDimensions()), 100, 100, 0, 1, 1, 0, 0, 0, 0)
            end
        end
    end
    layoutCache[#layoutCache] = nil
end

return UI