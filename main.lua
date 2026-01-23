-- main.lua
require 'conf'

-- Global StateMachine
local StateMachine = require 'utils.StateMachine'
local MainMenu = require 'states.MainMenu'
local UIEditor = require 'ui.editor'
gStateMachine = nil
gClickCount = 0
gClickPower = 1
gInventory = { heart = 100, downgrade = 100 } -- Unlimited items for testing
gGameLost = false
gDevMode = true
gLives = 3
gUnlockedMinigames = {} -- Track beats for item unlocks
local DEBUG_UI_EDITOR = false

-- Base resolution
VIRTUAL_WIDTH = 1280
VIRTUAL_HEIGHT = 720

-- Scaling variables
gScale = 1
gTransX = 0
gTransY = 0

function love.load()
    love.audio.setVolume(1.0)
    print("AUDIO: Volume set to 1.0")
    love.graphics.setDefaultFilter('nearest', 'nearest')

    -- Load states
    local states = {
        ['menu'] = MainMenu,
        ['game'] = require 'states.GameLoop',
        ['shop'] = require 'states.Shop',
        ['selector'] = require 'states.MinigameSelector',
        ['pause'] = require 'states.PauseMenu',
        ['lost'] = require 'states.GameLost',
        ['won'] = require 'states.GameWon'
    }

    gStateMachine = StateMachine.new(states)
    gStateMachine:change('menu')

    UIEditor.init({
        enabled = DEBUG_UI_EDITOR,
        layoutFile = 'ui_layout.lua',
        minSize = 24,
        handleSize = 14
    })

    updateScaling()
end

function updateScaling()
    local w, h = love.graphics.getDimensions()
    local scaleX = w / VIRTUAL_WIDTH
    local scaleY = h / VIRTUAL_HEIGHT

    gScale = math.min(scaleX, scaleY)

    gTransX = (w - (VIRTUAL_WIDTH * gScale)) / 2
    gTransY = (h - (VIRTUAL_HEIGHT * gScale)) / 2
end

function love.resize(w, h)
    updateScaling()
end

function love.update(dt)
    gStateMachine:update(dt)
    UIEditor.update(dt)
end

function love.draw()
    UIEditor.beginFrame()

    -- Apply scaling
    love.graphics.push()
    love.graphics.translate(gTransX, gTransY)
    love.graphics.scale(gScale)

    -- Clip to 16:9 area (optional, keeps clean edges)
    love.graphics.setScissor(gTransX, gTransY, VIRTUAL_WIDTH * gScale, VIRTUAL_HEIGHT * gScale)

    -- Clear background for the virtual area (if needed, states usually cover it)
    -- love.graphics.clear(0, 0, 0)

    gStateMachine:draw()
    UIEditor.draw()

    love.graphics.setScissor()
    love.graphics.pop()

    -- Draw black bars if needed (letterboxing is handled by the screen clear)

    -- Draw Global Click Counter
    if gStateMachine.stack[#gStateMachine.stack] ~= MainMenu then
        love.graphics.setColor(1, 1, 1, 1) -- Ensure white color
        love.graphics.print("Clicks: " .. gClickCount, 10, 10)
    end
end

function love.keypressed(key)
    UIEditor.keypressed(key)

    if gDevMode then
        if key == 'c' then
            gClickCount = gClickCount + 100000
        elseif key == 'f1' then
            gDevMode = not gDevMode
        end
    end
    gStateMachine:keypressed(key)
end

function love.mousepressed(x, y, button)
    -- Convert screen coords to virtual coords
    local vx = (x - gTransX) / gScale
    local vy = (y - gTransY) / gScale

    if vx >= 0 and vx <= VIRTUAL_WIDTH and vy >= 0 and vy <= VIRTUAL_HEIGHT then
        UIEditor.mousepressed(vx, vy, button)
        gStateMachine:mousepressed(vx, vy, button)
    end

    if button == 1 or button == 2 then
        if not gGameLost then
            gClickCount = gClickCount + gClickPower
        end
    end
end

function love.mousereleased(x, y, button)
    local vx = (x - gTransX) / gScale
    local vy = (y - gTransY) / gScale

    if vx >= 0 and vx <= VIRTUAL_WIDTH and vy >= 0 and vy <= VIRTUAL_HEIGHT then
        UIEditor.mousereleased(vx, vy, button)
    end
end

function love.mousemoved(x, y, dx, dy)
    local vx = (x - gTransX) / gScale
    local vy = (y - gTransY) / gScale
    local vdx = dx / gScale
    local vdy = dy / gScale

    if vx >= 0 and vx <= VIRTUAL_WIDTH and vy >= 0 and vy <= VIRTUAL_HEIGHT then
        UIEditor.mousemoved(vx, vy, vdx, vdy)
    end
end

function love.mousereleased(x, y, button)
    local vx = (x - gTransX) / gScale
    local vy = (y - gTransY) / gScale
    if vx >= 0 and vx <= VIRTUAL_WIDTH and vy >= 0 and vy <= VIRTUAL_HEIGHT then
        gStateMachine:mousereleased(vx, vy, button)
    end
end

function love.mousemoved(x, y, dx, dy)
    local vx = (x - gTransX) / gScale
    local vy = (y - gTransY) / gScale
    -- dx/dy also need scaling? Yes.
    local vdx = dx / gScale
    local vdy = dy / gScale

    if vx >= 0 and vx <= VIRTUAL_WIDTH and vy >= 0 and vy <= VIRTUAL_HEIGHT then
        gStateMachine:mousemoved(vx, vy, vdx, vdy)
    end
end

function gResetGame()
    gClickCount = 0
    gClickPower = 1
    gGameLost = false
    gLives = 3
    gUnlockedMinigames = {} -- Clear unlocks on reset

    -- Reset Items by clearing them from package.loaded
    -- This forces them to be re-required and thus re-initialized (bought = false)
    local itemsDir = "items"
    local files = love.filesystem.getDirectoryItems(itemsDir)
    for _, file in ipairs(files) do
        local info = love.filesystem.getInfo(itemsDir .. "/" .. file)
        if info.type == "directory" then
            local itemPath = itemsDir .. "." .. file .. ".data"
            package.loaded[itemPath] = nil
        end
    end
end
