-- states/MinigameSelector.lua
local Button = require 'utils.Button'
local MinigameSelector = {}

function MinigameSelector:enter()
    self.buttons = {}
    local w, h = 1280, 720

    table.insert(self.buttons, Button.new("Back to Menu", 10, 10, 150, 40, function()
        gStateMachine:change('menu')
    end))

    local rows = 2
    local cols = 3
    local btnW, btnH = 200, 100
    local startX = 250
    local startY = 200
    local padding = 20

    local gameNames = {"Game 1", "Game 2", "Game 3", "Game 4", "Game 5", "Stocks"}
    for i = 1, 6 do
        local r = math.floor((i - 1) / cols)
        local c = (i - 1) % cols

        local x = startX + c * (btnW + padding)
        local y = startY + r * (btnH + padding)

        table.insert(self.buttons, Button.new(gameNames[i], x, y, btnW, btnH, function()
            -- For specific testing, maybe launch just that game repeatedly?
            -- Or launch GameLoop forcing that game?
            -- User said "return to the mini game selection after the mini game is done"

            -- We need a way to launch a SPECIFIC game in GameLoop and then callback.
            -- Or better, have GameLoop handle a 'single' mode.

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
