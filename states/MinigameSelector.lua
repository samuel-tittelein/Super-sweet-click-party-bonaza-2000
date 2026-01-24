-- states/MinigameSelector.lua
local Button = require 'utils.Button'
local MinigameSelector = {}

function MinigameSelector:enter()
    self.buttons = {}
    self.font30 = love.graphics.newFont(30)
    local w, h = 1280, 720

    -- Back Button
    table.insert(self.buttons, Button.new("Retour", 50, 50, 150, 50, function()
        gStateMachine:change('menu')
    end))

    -- Grid of minigames
    local cols = 4
    local btnW, btnH = 250, 60
    local startX = (w - (cols * btnW + (cols - 1) * 20)) / 2
    local startY = 150

    for i, mg in ipairs(G_MINIGAMES) do
        local col = (i - 1) % cols
        local row = math.floor((i - 1) / cols)

        local x = startX + col * (btnW + 20)
        local y = startY + row * (btnH + 20)

        table.insert(self.buttons, Button.new(mg.name, x, y, btnW, btnH, function()
            gStateMachine:change('game', { mode = 'single', gameIndex = i })
        end))
    end
end

function MinigameSelector:draw()
    -- Draw a nice background (similar to Shop or just dark)
    love.graphics.clear(0.05, 0.05, 0.1)

    love.graphics.setColor(1, 1, 1)
    love.graphics.setFont(self.font30)
    love.graphics.printf("SÉLECTION DES JEUX", 0, 50, 1280, "center")

    for _, btn in ipairs(self.buttons) do
        btn:draw()
    end
end

function MinigameSelector:update(dt)
end

function MinigameSelector:mousepressed(x, y, button)
    for _, btn in ipairs(self.buttons) do
        btn:clicked(x, y)
    end
end

return MinigameSelector
