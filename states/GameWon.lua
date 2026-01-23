-- states/GameWon.lua
local Button = require 'utils.Button'
local GameWon = {}

function GameWon:enter()
    self.buttons = {}
    local w, h = 1280, 720

    gGameLost = true -- Stop click counting (or just to freeze state)

    table.insert(self.buttons, Button.new("Main Menu", w / 2 - 100, h / 2 + 100, 200, 50, function()
        gResetGame()
        gStateMachine:change('menu')
    end))
end

function GameWon:draw()
    love.graphics.clear(0, 0, 0.3)  -- Dark blue bg

    love.graphics.setColor(1, 1, 0) -- Gold text
    love.graphics.newFont(50)
    love.graphics.printf("YOU COLLECTED ALL THEMES!", 0, 200, 1280, "center")

    love.graphics.setColor(1, 1, 1)
    love.graphics.newFont(30)
    love.graphics.printf("THE CLICK FESTIVAL IS COMPLETE!", 0, 300, 1280, "center")

    for _, btn in ipairs(self.buttons) do
        btn:draw()
    end
end

function GameWon:update(dt)
end

function GameWon:mousepressed(x, y, button)
    for _, btn in ipairs(self.buttons) do
        btn:clicked(x, y)
    end
end

return GameWon
