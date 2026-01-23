-- states/GameLost.lua
local Button = require 'utils.Button'
local GameLost = {}

function GameLost:enter(params)
    self.score = params.score or 0
    gGameLost = true
    self.buttons = {}
    local w, h = 1280, 720

    table.insert(self.buttons, Button.new("Try Again", w / 2 - 100, h / 2 + 50, 200, 50, function()
        gClickCount = 0
        gGameLost = false
        gStateMachine:change('game')
    end))

    table.insert(self.buttons, Button.new("Menu", w / 2 - 100, h / 2 + 120, 200, 50, function()
        gGameLost = false
        gStateMachine:change('menu')
    end))
end

function GameLost:draw()
    love.graphics.clear(0.3, 0, 0)

    love.graphics.setColor(1, 1, 1)
    love.graphics.newFont(50)
    love.graphics.printf("GAME OVER", 0, 200, 1280, "center")

    love.graphics.newFont(30)
    love.graphics.printf("Score (Clicks): " .. gClickCount, 0, 300, 1280, "center")

    for _, btn in ipairs(self.buttons) do
        btn:draw()
    end
end

function GameLost:update(dt)
end

function GameLost:mousepressed(x, y, button)
    for _, btn in ipairs(self.buttons) do
        btn:clicked(x, y)
    end
end

return GameLost
