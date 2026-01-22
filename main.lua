-- main.lua
require 'conf'

-- Global StateMachine
local StateMachine = require 'utils.StateMachine'
gStateMachine = nil

-- Base resolution
VIRTUAL_WIDTH = 1280
VIRTUAL_HEIGHT = 720

-- Scaling variables
gScale = 1
gTransX = 0
gTransY = 0

function love.load()
    love.graphics.setDefaultFilter('nearest', 'nearest')

    -- Load states
    local states = {
        ['menu'] = require 'states.MainMenu',
        ['game'] = require 'states.GameLoop',
        ['shop'] = require 'states.Shop',
        ['selector'] = require 'states.MinigameSelector',
        ['pause'] = require 'states.PauseMenu',
        ['lost'] = require 'states.GameLost'
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
end

function love.keypressed(key)
    gStateMachine:keypressed(key)
end

function love.mousepressed(x, y, button)
    -- Convert screen coords to virtual coords
    local vx = (x - gTransX) / gScale
    local vy = (y - gTransY) / gScale

    if vx >= 0 and vx <= VIRTUAL_WIDTH and vy >= 0 and vy <= VIRTUAL_HEIGHT then
        gStateMachine:mousepressed(vx, vy, button)
    end
end
