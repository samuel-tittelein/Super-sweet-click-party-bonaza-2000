-- states/PauseMenu.lua
local Button = require 'utils.Button'
local PauseMenu = {}

function PauseMenu:enter()
    self.buttons = {}
    local w, h = 1280, 720

    table.insert(self.buttons, Button.new("Resume", w / 2 - 100, h / 2 - 50, 200, 50, function()
        gStateMachine:pop()
    end))

    table.insert(self.buttons, Button.new("Quit to Menu", w / 2 - 100, h / 2 + 20, 200, 50, function()
        -- Pop everything and go to menu... or just switch
        gStateMachine:change('menu')
    end))
end

function PauseMenu:draw()
    -- Draw semi-transparent background
    love.graphics.setColor(0, 0, 0, 0.5)
    love.graphics.rectangle("fill", 0, 0, 1280, 720)

    love.graphics.setColor(1, 1, 1)
    love.graphics.newFont(40)
    love.graphics.printf("PAUSED", 0, 200, 1280, "center")

    for _, btn in ipairs(self.buttons) do
        btn:draw()
    end
end

function PauseMenu:update(dt)
end

function PauseMenu:mousepressed(x, y, button)
    for _, btn in ipairs(self.buttons) do
        btn:clicked(x, y)
    end
end

function PauseMenu:keypressed(key)
    if key == 'escape' then
        gStateMachine:pop()
    end
end

return PauseMenu
