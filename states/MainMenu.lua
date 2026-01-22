local Button = require 'utils.Button'
local MainMenu = {}

function MainMenu:enter()
    self.buttons = {}
    local w, h = 1280, 720

    -- Start Button
    table.insert(self.buttons, Button.new("Start Game", w / 2 - 100, h / 2 - 50, 200, 50, function()
        gStateMachine:change('game')
    end))

    -- Selector Button
    table.insert(self.buttons, Button.new("Minigames", w / 2 - 100, h / 2 + 20, 200, 50, function()
        gStateMachine:change('selector')
    end))

    -- Quit Button
    table.insert(self.buttons, Button.new("Quit", w / 2 - 100, h / 2 + 90, 200, 50, function()
        love.event.quit()
    end))
end

function MainMenu:update(dt)
end

function MainMenu:draw()
    love.graphics.setColor(0.1, 0.1, 0.1) -- Dark bg
    love.graphics.rectangle("fill", 0, 0, 1280, 720)

    love.graphics.setColor(1, 1, 1)
    love.graphics.newFont(40)
    love.graphics.printf("WARIO-LIKE JAM", 0, 100, 1280, "center")

    for _, btn in ipairs(self.buttons) do
        btn:draw()
    end
end

function MainMenu:mousepressed(x, y, button)
    for _, btn in ipairs(self.buttons) do
        btn:clicked(x, y)
    end
end

function MainMenu:keypressed(key)
    if key == 'escape' then
        love.event.quit()
    end
end

function MainMenu:exit()
end

return MainMenu
