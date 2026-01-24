-- main.lua
require 'conf'

-- Global StateMachine
local StateMachine = require 'utils.StateMachine'
local MainMenu = require 'states.MainMenu'
gStateMachine = nil
gClickCount = 0
gClickPower = 1
gInventory = { heart = 100, downgrade = 100 } -- Unlimited items for testing
gGameLost = false
gDevMode = true
gLives = 3
gVolume = 1.0
gDisplayMode = 'windowed' -- 'windowed', 'fullscreen', 'borderless'
gUnlockedMinigames = {}   -- Track beats for item unlocks
G_MINIGAMES = {
    { id = 'taupe',           name = 'Taupe' },
    { id = 'popup',           name = 'Popup' },
    { id = 'stocks-timing',   name = 'Stocks' },
    { id = 'taiko',           name = 'Taiko' },
    { id = 'burger',          name = 'Burger' },
    { id = 'time_matcher',    name = 'Time Matcher' },
    { id = 'catch-stick',     name = 'Stick Catch' },
    { id = 'wait',            name = 'Wait' },
    { id = 'runnerDash',      name = 'Runner Dash' },
    { id = 'find-different',  name = 'Find Different' },
    { id = 'cute_and_creepy', name = 'Cute and Creepy' },
    { id = 'letterbox',       name = 'Letterbox' },
    { id = 'zombie-shooter',  name = 'Zombie Shooter' },
    { id = 'letterbox',       name = 'Letterbox' },
    { id = 'never_give_up',   name = 'Never Give Up' },
    { id = 'space_invader',   name = 'Space Invader' }
}

-- Base resolution
VIRTUAL_WIDTH = 1280
VIRTUAL_HEIGHT = 720

-- Scaling variables
gScale = 1
gTransX = 0
gTransY = 0

function love.load()
    gApplySettings()
    love.graphics.setDefaultFilter('nearest', 'nearest')

    -- Load states
    local states = {
        ['menu'] = MainMenu,
        ['game'] = require 'states.GameLoop',
        ['shop'] = require 'states.Shop',
        ['selector'] = require 'states.MinigameSelector',
        ['pause'] = require 'states.PauseMenu',
        ['lost'] = require 'states.GameLost',
        ['won'] = require 'states.GameWon',
        ['settings'] = require 'states.SettingsMenu'
    }

    gStateMachine = StateMachine.new(states)
    gStateMachine:change('menu')

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
end

function love.draw()
    -- Apply scaling
    love.graphics.push()
    love.graphics.translate(gTransX, gTransY)
    love.graphics.scale(gScale)

    -- Clip to 16:9 area (optional, keeps clean edges)
    love.graphics.setScissor(gTransX, gTransY, VIRTUAL_WIDTH * gScale, VIRTUAL_HEIGHT * gScale)

    -- Clear background for the virtual area (if needed, states usually cover it)
    -- love.graphics.clear(0, 0, 0)

    gStateMachine:draw()

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

function gApplySettings()
    -- Apply Volume
    love.audio.setVolume(gVolume)

    -- Apply Display Mode
    if gDisplayMode == 'fullscreen' then
        love.window.setFullscreen(true, "exclusive")
    elseif gDisplayMode == 'borderless' then
        love.window.setFullscreen(true, "desktop")
    else
        love.window.setFullscreen(false)
    end
end
