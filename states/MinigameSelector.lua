-- states/MinigameSelector.lua
local Button = require 'utils.Button'
local MinigameSelector = {}

function MinigameSelector:enter()
    self.buttons = {}
    local w, h = 1280, 720

    table.insert(self.buttons, Button.new("Back to Menu", 10, 10, 150, 40, function()
        gStateMachine:change('menu')
    end))

    local rows = 3
    local cols = 3
    local btnW, btnH = 200, 100
    local startX = 250
    local startY = 200
    local padding = 20

    local gameNames = {'Taupe', 'Game 2', 'Game 3', 'Game 4', 'Game 5', 'Popup', 'Stocks', 'Taiko'}
    for i = 1, 8 do
        local r = math.floor((i - 1) / cols)
        local c = (i - 1) % cols

        local x = startX + c * (btnW + padding)
        local y = startY + r * (btnH + padding)

        local name = gameNames[i] or ("Game " .. i)
        table.insert(self.buttons, Button.new(name, x, y, btnW, btnH, function()
            gStateMachine:change('game', { mode = 'single', gameIndex = i })
        end))
    end
end

function MinigameSelector:draw()
    love.graphics.clear(0.1, 0.1, 0.2)
    love.graphics.setColor(1, 1, 1)
    love.graphics.newFont(30)
    love.graphics.printf("SELECT A MINIGAME", 0, 100, 1280, "center")

    for _, btn in ipairs(self.buttons) do
        btn:draw()
    end
end

function MinigameSelector:mousepressed(x, y, button)
    for _, btn in ipairs(self.buttons) do
        btn:clicked(x, y)
    end
end

return MinigameSelector
