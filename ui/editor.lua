local Editor = {
    enabled = false,
    layoutFile = 'ui_layout.lua',
    minSize = 28,
    handleSize = 14,
    layoutById = {},
    frameList = {},
    frameById = {},
    selectedId = nil,
    dragMode = nil,
    dragOffsetX = 0,
    dragOffsetY = 0,
    resizeBaseW = 0,
    resizeBaseH = 0,
    pressX = 0,
    pressY = 0
}

local function copyRect(target)
    return {
        id = target.id,
        x = target.x,
        y = target.y,
        w = target.w,
        h = target.h
    }
end

local function ensureRectFields(rect, defaults)
    rect.x = rect.x or defaults.x or 0
    rect.y = rect.y or defaults.y or 0
    rect.w = rect.w or defaults.w or Editor.minSize
    rect.h = rect.h or defaults.h or Editor.minSize
    return rect
end

local function normalizeEntry(entry, defaults)
    defaults = defaults or {}
    local rect = {
        id = entry.id or defaults.id,
        x = entry.x,
        y = entry.y,
        w = entry.w,
        h = entry.h
    }
    return ensureRectFields(rect, defaults)
end

local function pointInRect(px, py, rect)
    return px >= rect.x and px <= rect.x + rect.w and py >= rect.y and py <= rect.y + rect.h
end

local function onHandle(px, py, rect)
    return px >= rect.x + rect.w - Editor.handleSize and px <= rect.x + rect.w and
           py >= rect.y + rect.h - Editor.handleSize and py <= rect.y + rect.h
end

local function clampSize(rect)
    rect.w = math.max(Editor.minSize, rect.w)
    rect.h = math.max(Editor.minSize, rect.h)
end

local function clampToViewport(rect)
    if VIRTUAL_WIDTH then
        rect.w = math.min(rect.w, VIRTUAL_WIDTH)
        rect.x = math.min(rect.x, VIRTUAL_WIDTH - rect.w)
        rect.x = math.max(rect.x, 0)
    end
    if VIRTUAL_HEIGHT then
        rect.h = math.min(rect.h, VIRTUAL_HEIGHT)
        rect.y = math.min(rect.y, VIRTUAL_HEIGHT - rect.h)
        rect.y = math.max(rect.y, 0)
    end
end

local function ingestLayout(data)
    if type(data) ~= 'table' then
        return
    end
    for _, entry in pairs(data) do
        if type(entry) == 'table' and entry.id then
            Editor.layoutById[entry.id] = normalizeEntry(entry, {})
        end
    end
end

function Editor.init(opts)
    opts = opts or {}
    if opts.enabled ~= nil then Editor.enabled = opts.enabled end
    if opts.minSize then Editor.minSize = opts.minSize end
    if opts.handleSize then Editor.handleSize = opts.handleSize end
    if opts.layoutFile then Editor.layoutFile = opts.layoutFile end
    Editor:loadLayout()
end

function Editor.loadLayout()
    Editor.layoutById = Editor.layoutById or {}
    local info = love.filesystem.getInfo(Editor.layoutFile)
    if not info then
        return
    end
    local chunk, err = love.filesystem.load(Editor.layoutFile)
    if not chunk then
        print('UI editor: failed to load layout: ' .. tostring(err))
        return
    end
    local ok, data = pcall(chunk)
    if not ok then
        print('UI editor: error evaluating layout: ' .. tostring(data))
        return
    end
    ingestLayout(data)
end

function Editor.beginFrame()
    Editor.frameList = {}
    Editor.frameById = {}
end

function Editor.track(id, defaults)
    defaults = defaults or {}
    defaults.id = id
    local rect = Editor.layoutById[id]
    if rect then
        ensureRectFields(rect, defaults)
    else
        rect = normalizeEntry(defaults, defaults)
        Editor.layoutById[id] = rect
    end

    table.insert(Editor.frameList, rect)
    Editor.frameById[id] = rect
    return rect
end

function Editor.mousepressed(x, y, button)
    if not Editor.enabled or button ~= 1 then
        return
    end

    local target, mode
    for i = #Editor.frameList, 1, -1 do
        local rect = Editor.frameList[i]
        if onHandle(x, y, rect) then
            target = rect
            mode = 'resize'
            break
        elseif pointInRect(x, y, rect) then
            target = rect
            mode = 'move'
            break
        end
    end

    if target then
        Editor.selectedId = target.id
        if mode == 'move' then
            Editor.dragMode = 'move'
            Editor.dragOffsetX = x - target.x
            Editor.dragOffsetY = y - target.y
        else
            Editor.dragMode = 'resize'
            Editor.pressX = x
            Editor.pressY = y
            Editor.resizeBaseW = target.w
            Editor.resizeBaseH = target.h
        end
    end
end

function Editor.mousereleased(_, _, button)
    if button ~= 1 then
        return
    end
    Editor.dragMode = nil
end

function Editor.mousemoved(x, y)
    if not Editor.enabled or not Editor.dragMode or not Editor.selectedId then
        return
    end
    local rect = Editor.frameById[Editor.selectedId]
    if not rect then
        rect = Editor.layoutById[Editor.selectedId]
    end
    if not rect then
        return
    end

    if Editor.dragMode == 'move' then
        rect.x = x - Editor.dragOffsetX
        rect.y = y - Editor.dragOffsetY
    elseif Editor.dragMode == 'resize' then
        rect.w = Editor.resizeBaseW + (x - Editor.pressX)
        rect.h = Editor.resizeBaseH + (y - Editor.pressY)
    end

    clampSize(rect)
    clampToViewport(rect)
end

local function serialize()
    local list = {}
    for _, rect in pairs(Editor.layoutById) do
        table.insert(list, copyRect(rect))
    end
    table.sort(list, function(a, b) return a.id < b.id end)

    local lines = {"return {"}
    for _, rect in ipairs(list) do
        table.insert(lines, string.format(
            "    { id = %q, x = %.2f, y = %.2f, w = %.2f, h = %.2f },",
            rect.id, rect.x, rect.y, rect.w, rect.h
        ))
    end
    table.insert(lines, "}")
    return table.concat(lines, '\n')
end

function Editor.saveLayout()
    local content = serialize()
    local base = love.filesystem.getSourceBaseDirectory()
    local written = false

    if base then
        local path = base .. '/' .. Editor.layoutFile
        local file, err = io.open(path, 'w')
        if file then
            file:write(content)
            file:close()
            written = true
        else
            print('UI editor: source write failed, falling back to save dir: ' .. tostring(err))
        end
    end

    if not written then
        local ok, err = love.filesystem.write(Editor.layoutFile, content)
        if not ok then
            print('UI editor: failed to write layout: ' .. tostring(err))
            return false
        end
    end

    print('UI editor: layout saved to ' .. Editor.layoutFile)
    return true
end

function Editor.keypressed(key)
    if key == 'f2' then
        Editor.enabled = not Editor.enabled
        if not Editor.enabled then
            Editor.dragMode = nil
            Editor.selectedId = nil
        end
        return true
    end

    if not Editor.enabled then
        return false
    end

    if key == 's' then
        Editor.saveLayout()
        return true
    end

    return false
end

function Editor.update(dt)
    -- Placeholder for future status timers or snapping toggles
    return dt
end

function Editor.draw()
    if not Editor.enabled then
        return
    end

    local prevLine = love.graphics.getLineWidth()
    love.graphics.setLineWidth(1.5)

    for _, rect in ipairs(Editor.frameList) do
        local isSelected = rect.id == Editor.selectedId
        love.graphics.setColor(0, 1, 0, isSelected and 0.7 or 0.35)
        love.graphics.rectangle('line', rect.x, rect.y, rect.w, rect.h)

        love.graphics.setColor(1, 0.8, 0.2, 0.8)
        love.graphics.rectangle('fill', rect.x + rect.w - Editor.handleSize, rect.y + rect.h - Editor.handleSize, Editor.handleSize, Editor.handleSize)

        love.graphics.setColor(1, 1, 1, 0.8)
        love.graphics.print(rect.id, rect.x + 4, rect.y - 14)
    end

    love.graphics.setLineWidth(prevLine)
    love.graphics.setColor(1, 1, 1, 1)
end

return Editor
