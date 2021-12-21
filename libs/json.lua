--[[ JSON.lua
Usage:
1. local JSON = require(script:GetCustomProperty('json')) and add an Asset property named 'json', set it as this script.
2. use JSON.Stringify(table) to transform a lua table into json.
3. use JSON.Parse(stringifiedObject) to transform a json string into a lua table.

Supports most basic CORE types. Most other types shouldn't be passed via JSON by value.
(pass .id or .sourceTemplateId instead)

You can contact me at nexovec#6149 on discord for bug reports or feature requests.

## JSON.Stringify:
A table is classified as an array if and only if it only has multiple consecutive number indexes starting from 1.

## JSON.Parse:
Uses JSON.null instead of nil.

--]]
JSON = {}
function KindOf(obj)
    if type(obj) ~= 'table' then
        return type(obj)
    end
    local i = 1
    for _ in pairs(obj) do
        if obj[i] ~= nil then
            i = i + 1
        else
            return 'table'
        end
    end
    return 'array'
end

function EscapeStr(s)
    local in_char = {'\\', '"', '/', '\b', '\f', '\n', '\r', '\t'}
    local out_char = {'\\', '"', '/', 'b', 'f', 'n', 'r', 't'}
    for i, c in ipairs(in_char) do
        s = s:gsub(c, '\\' .. out_char[i])
    end
    return s
end
function SkipDelim(str, pos, delim, err_if_missing)
    pos = pos + #str:match('^%s*', pos)
    if str:sub(pos, pos) ~= delim then
        if err_if_missing then
            error('Expected ' .. delim .. ' near position ' .. pos)
        end
        return pos, false
    end
    return pos + 1, true
end
function ParseStringValue(str, pos, val)
    val = val or ''
    local early_end_error = 'End of input found while parsing string.'
    if pos > #str then
        error(early_end_error)
    end
    local c = str:sub(pos, pos)
    if c == '"' then
        return val, pos + 1
    end
    if c ~= '\\' then
        return ParseStringValue(str, pos + 1, val .. c)
    end
    -- Parse special characters
    local esc_map = {b = '\b', f = '\f', n = '\n', r = '\r', t = '\t'}
    local nextc = str:sub(pos + 1, pos + 1)
    if not nextc then
        error(early_end_error)
    end
    return ParseStringValue(str, pos + 2, val .. (esc_map[nextc] or nextc))
end
function ParseNumberValue(str, pos)
    local num_str = str:match('^-?%d+%.?%d*[eE]?[+-]?%d*', pos)
    local val = tonumber(num_str)
    if not val then
        error('Error parsing number at position ' .. pos .. '.')
    end
    return val, pos + #num_str
end
function ConvertUserdataToTable(obj)
    -- FIXME: Love has completely different types
    -- obj = {type = obj:type()}
    if obj.type == 'Vector3' then
        return {type = obj.type, x = obj.x, y = obj.y, z = obj.z}
    elseif obj.type == 'Vector2' then
        return {type = obj.type, x = obj.x, y = obj.y}
    elseif obj.type == 'Rotation' then
        return {type = obj.type, x = obj.x, y = obj.y, z = obj.z}
    elseif obj.type == 'Vector4' then
        return {type = obj.type, x = obj.x, y = obj.y, z = obj.z, w = obj.w}
    elseif obj.type == 'Color' then
        return {type = obj.type, r = obj.r, g = obj.g, b = obj.b, a = obj.a}
    elseif obj.type == 'Quaternion' then
        return {type = obj.type, x = obj.x, y = obj.y, z = obj.z, w = obj.w}
    elseif obj.type == 'Transform' then
        return {
            type = obj.type,
            rotation = ConvertUserdataToTable(obj:GetRotation()),
            position = ConvertUserdataToTable(obj:GetPosition()),
            scale = ConvertUserdataToTable(obj:GetScale())
        }
    else
        -- TODO:
        warn('Userdata type ' .. obj.type .. " shouldn't be stringified. passing its id instead.")
        return {id = obj.id}
    end
end

-- Public values and functions.

function JSON.Stringify(obj, as_key)
    -- i = i + 1
    -- if i % maxIterationsPerTick == 0 then
    --     Task.Wait()
    -- end
    local s = {}
    local kind = KindOf(obj)
    if kind == 'array' then
        if as_key then
            error("Can't encode array as key.")
        end
        s[#s + 1] = '['
        for i, val in ipairs(obj) do
            if i > 1 then
                s[#s + 1] = ', '
            end
            s[#s + 1] = JSON.Stringify(val)
        end
        s[#s + 1] = ']'
    elseif kind == 'table' then
        if as_key then
            error("Can't encode table as key.")
        end
        s[#s + 1] = '{'
        for k, v in pairs(obj) do
            if #s > 1 then
                s[#s + 1] = ', '
            end
            s[#s + 1] = JSON.Stringify(k, true)
            s[#s + 1] = ':'
            s[#s + 1] = JSON.Stringify(v)
        end
        s[#s + 1] = '}'
    elseif kind == 'string' then
        return '"' .. EscapeStr(obj) .. '"'
    elseif kind == 'number' then
        if as_key then
            return '"' .. tostring(obj) .. '"'
        end
        return tostring(obj)
    elseif kind == 'userdata' then
        return JSON.Stringify(ConvertUserdataToTable(obj))
    elseif kind == 'boolean' then
        return tostring(obj)
    elseif kind == 'nil' then
        return 'null'
    else
        error('Unjsonifiable type: ' .. kind .. '.')
    end
    return table.concat(s)
end
function ConstructUserdataFromTable(obj)
    local kind = KindOf(obj)
    if obj.type == 'Vector3' then
        return Vector3.New(obj.x, obj.y, obj.z)
    elseif obj.type == 'Vector2' then
        return Vector2.New(obj.x, obj.y)
    elseif obj.type == 'Rotation' then
        return Rotation.New(obj.x, obj.y, obj.z)
    elseif obj.type == 'Vector4' then
        return Vector4.New(obj.x, obj.y, obj.z, obj.w)
    elseif obj.type == 'Color' then
        return Color.New(obj.r, obj.g, obj.b, obj.a or 1)
    elseif obj.type == 'Quaternion' then
        return Quaternion.New(obj.x, obj.y, obj.z, obj.w)
    elseif obj.type == 'Transform' then
        return Transform.New(
            ConstructUserdataFromTable(obj.rotation),
            ConstructUserdataFromTable(obj.position),
            ConstructUserdataFromTable(obj.scale)
        )
    else
        error('Userdata type ' .. obj.type .. ' was not yet implemented')
    end
end

JSON.null = {}

function JSON.Parse(str, pos, end_delim)
    pos = pos or 1
    if pos > #str then
        error('Reached unexpected end of input.')
    end
    pos = pos + #str:match('^%s*', pos) -- Skip whitespace.
    local first = str:sub(pos, pos)
    if first == '{' then -- Parse an object.
        local obj, delim_found = {}, true
        local key
        pos = pos + 1
        while true do
            key, pos = JSON.Parse(str, pos, '}')
            -- key, pos = Parse(str, pos, '}')
            if key == nil then
                if obj.type ~= nil then
                    return ConstructUserdataFromTable(obj), pos
                end
                return obj, pos
            end
            if not delim_found then
                error('Comma missing between object items.')
            end
            pos = SkipDelim(str, pos, ':', true) -- true -> error if missing.
            obj[key], pos = JSON.Parse(str, pos)
            pos, delim_found = SkipDelim(str, pos, ',')
        end
    elseif first == '[' then -- Parse an array.
        local arr, delim_found = {}, true
        local val
        pos = pos + 1
        while true do
            val, pos = JSON.Parse(str, pos, ']')
            if val == nil then
                return arr, pos
            end
            if not delim_found then
                error('Comma missing between array items.')
            end
            arr[#arr + 1] = val
            pos, delim_found = SkipDelim(str, pos, ',')
        end
    elseif first == '"' then -- Parse a string.
        return ParseStringValue(str, pos + 1)
    elseif first == '-' or first:match('%d') then -- Parse a number.
        return ParseNumberValue(str, pos)
    elseif first == end_delim then -- End of an object or array.
        return nil, pos + 1
    else -- Parse true, false, or null.
        local literals = {['true'] = true, ['false'] = false, ['null'] = JSON.null}
        for lit_str, lit_val in pairs(literals) do
            local lit_end = pos + #lit_str - 1
            if str:sub(pos, lit_end) == lit_str then
                return lit_val, lit_end + 1
            end
        end
        local pos_info_str = 'position ' .. pos .. ': ' .. str:sub(pos, pos + 10)
        error('Invalid JSON syntax starting at ' .. pos_info_str)
    end
end
return JSON