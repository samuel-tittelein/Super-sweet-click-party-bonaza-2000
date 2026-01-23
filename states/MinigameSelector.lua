-- states/MinigameSelector.lua
local Button = require 'utils.Button'
local MinigameSelector = {}

function MinigameSelector:enter()
    self.selectedLevel = 1
    self.buttons = {}
    local w, h = 1280, 720

    table.insert(self.buttons, Button.new("Back to Menu", 10, 10, 150, 40, function()
        gStateMachine:change('menu')
    end))

    local rows = 4
    local cols = 4
    local btnW, btnH = 200, 60
    local startX = 200
    local startY = 220
    local padding = 15

    for i, mgData in ipairs(G_MINIGAMES) do
        local r = math.floor((i - 1) / cols)
        local c = (i - 1) % cols

        local x = startX + c * (btnW + padding)
        local y = startY + r * (btnH + padding)

        table.insert(self.buttons, Button.new(mgData.name, x, y, btnW, btnH, function()
            gStateMachine:change('game', { mode = 'single', gameIndex = i, difficulty = self.selectedLevel })
        end))
    end
end

function MinigameSelector:draw()
    love.graphics.clear(0.1, 0.1, 0.2)
    love.graphics.setColor(1, 1, 1)
    love.graphics.newFont(30)
    love.graphics.printf("SELECT A MINIGAME", 0, 100, 1280, "center")

    love.graphics.printf("< Level " .. self.selectedLevel .. " >", 0, 150, 1280, "center")
    love.graphics.newFont(20)
    love.graphics.printf("(Use Left/Right arrows to change)", 0, 180, 1280, "center")

    for _, btn in ipairs(self.buttons) do
        btn:draw()
    end
end

function MinigameSelector:mousepressed(x, y, button)
    for _, btn in ipairs(self.buttons) do
        btn:clicked(x, y)
    end
end

function MinigameSelector:keypressed(key)
    if key == 'right' then
        self.selectedLevel = self.selectedLevel + 1
        if self.selectedLevel > 100 then self.selectedLevel = 100 end
    elseif key == 'left' then
        self.selectedLevel = self.selectedLevel - 1
        if self.selectedLevel < 1 then self.selectedLevel = 1 end
    elseif key == 'escape' then
        gStateMachine:change('menu')
    end
end

return MinigameSelector
