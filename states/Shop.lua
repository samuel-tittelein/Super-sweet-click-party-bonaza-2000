-- states/Shop.lua
local Button = require 'utils.Button'
local Shop = {}

function Shop:enter(params)
    self.score = params.score or 0
    self.difficulty = params.difficulty or 1
    self.buttons = {}

    table.insert(self.buttons, Button.new("Continue", 1280 / 2 - 100, 500, 200, 50, function()
        -- Return to game loop but reset the shop counter?
        -- Actually GameLoop logic might need to be re-entered or just reset the counter if we passed the state instance
        -- But since we changed state to Shop, we will effectively restart GameLoop enter()
        -- We need to pass back the score and difficulty

        -- wait, if we call GameLoop:enter again, it resets everything?
        -- GameLoop:enter resets 'gamesPlayedSinceShop = 0', score=0... oops.
        -- We need to modify GameLoop to accept params for continuing.

        gStateMachine:change('game', { score = self.score, difficulty = self.difficulty, continue = true })
    end))
end

function Shop:update(dt)
end

function Shop:draw()
    love.graphics.clear(0.2, 0.1, 0.2)
    love.graphics.setColor(1, 1, 1)
    love.graphics.newFont(40)
    love.graphics.printf("SHOP SCREEN", 0, 100, 1280, "center")
    love.graphics.printf("Current Score: " .. self.score, 0, 200, 1280, "center")
    love.graphics.printf("Items bought: 0 (Placeholder)", 0, 300, 1280, "center")

    for _, btn in ipairs(self.buttons) do
        btn:draw()
    end
end

function Shop:mousepressed(x, y, button)
    for _, btn in ipairs(self.buttons) do
        btn:clicked(x, y)
    end
end

return Shop
