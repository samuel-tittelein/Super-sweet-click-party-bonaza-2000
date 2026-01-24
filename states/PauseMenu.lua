-- states/PauseMenu.lua
local Button = require 'utils.Button'
local PauseMenu = {}

function PauseMenu:enter()
    self.buttons = {}
    local w, h = 1280, 720

    table.insert(self.buttons, Button.new("Resume", w / 2 - 100, h / 2 - 60, 200, 50, function()
        gStateMachine:pop()
    end))

    table.insert(self.buttons, Button.new("Settings", w / 2 - 100, h / 2, 200, 50, function()
        gStateMachine:push('settings')
    end))

    table.insert(self.buttons, Button.new("Quit to Menu", w / 2 - 100, h / 2 + 60, 200, 50, function()
        -- Directly change to menu, but StateMachine logic handles exit() of TOP state.
        -- We need to ensure GameLoop (underneath) is also exited or cleaned up.
        -- Since 'change' replaces the top, and Pause is top... GameLoop stays if we don't clear.

        -- Improved Quit Logic:
        -- 1. Call exit() on GameLoop (state below us)
        -- 2. Clear stack manually or assume change handles it if we want to reset.
        -- StateMachine implementation of 'change' only pops TOP.

        -- Clean up GameLoop explicitly if it exists
        -- We know Pause is on top, GameLoop is likely below.
        for i = #gStateMachine.stack - 1, 1, -1 do
            if gStateMachine.stack[i].exit then
                gStateMachine.stack[i]:exit()
            end
        end

        -- Reset stack completely and go to menu
        gStateMachine.stack = {}
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
