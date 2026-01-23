local Button = require 'utils.Button'
local Background = require 'renderers.background'
local Scenery = require 'renderers.scenery'
local Speakers = require 'renderers.speakers'
local MenuUI = require 'renderers.menu_ui'
local MainMenu = {}

function MainMenu:enter()
    local w, h = 1280, 720
    self.time = 0
    
    -- Init visualizer bars in scenery
    Scenery.init(w, h)
end

function MainMenu:update(dt)
    self.time = self.time + dt
    -- Animate visualizer bars
    Scenery.update(dt)
end

-- Background with dotted paper texture
-- Delegated renderers live in renderers/*

-- Speakers are drawn by renderers.speakers

-- Buttons are drawn by renderers.menu_ui

function MainMenu:draw()
    local w, h = 1280, 720
    
    Background.draw(w, h)
    Scenery.draw(w, h)
    
    Speakers.draw(90, 230, 150, 320, false)
    Speakers.draw(w - 260, 250, 150, 320, true)
    
    local rects = MenuUI.draw(w, h)
    self.btn1, self.btn2, self.btn3 = rects.btn1, rects.btn2, rects.btn3
end

function MainMenu:mousepressed(x, y, button)
    -- Check button 1: "NE ME CLIQUE PAS" (Start Game)
    if self.btn1 and x > self.btn1.x and x < self.btn1.x + self.btn1.w and 
       y > self.btn1.y and y < self.btn1.y + self.btn1.h then
        gClickCount = gClickCount + 1
        gStateMachine:change('game')
    end
    
    -- Check button 2: "CLIQUE MOI FORT" (Minigames)
    if self.btn2 and x > self.btn2.x and x < self.btn2.x + self.btn2.w and 
       y > self.btn2.y and y < self.btn2.y + self.btn2.h then
        gClickCount = 0
        gStateMachine:change('selector')
    end
    
    -- Check button 3: "NE ME CLIQUE SURTOUT PAS" (Quit)
    if self.btn3 and x > self.btn3.x and x < self.btn3.x + self.btn3.w and 
       y > self.btn3.y and y < self.btn3.y + self.btn3.h then
        love.event.quit()
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
