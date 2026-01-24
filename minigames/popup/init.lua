local Minigame = {}

-- Popup Minigame
-- Goal: Close all popup windows
-- Controls: Mouse click

function Minigame:enter(difficulty)
    self.difficulty = difficulty or 1
    
    self.timeLimit = 10 -- 10 seconds to close everything
    
    -- Number of popups scales with difficulty
    self.popupCount = math.floor(3 + self.difficulty * 1.5) 
    
    self.timer = self.timeLimit
    self.won = false
    self.lost = false
    
    self.popups = {}
    
    -- Create popups
    local screenW, screenH = 1280, 720
    self.popupImages = {
        love.graphics.newImage("minigames/popup/assets/bonzi.jpg"),
        love.graphics.newImage("minigames/popup/assets/scam.jpg"),
        love.graphics.newImage("minigames/popup/assets/peach.png")
    }
    for i = 1, self.popupCount do
        local w = math.random(200, 400)
        local h = math.random(150, 300)
        local x = math.random(0, screenW - w)
        local y = math.random(0, screenH - h)
        local img = self.popupImages[math.random(1, #self.popupImages)]
        table.insert(self.popups, {
            x = x,
            y = y,
            w = w,
            h = h,
            color = {math.random(), math.random(), math.random()},
            title = "ADVERTISEMENT " .. i,
            closed = false,
            id = i,
            image = img
        })
    end
end

function Minigame:update(dt)
    if self.won or self.lost then return end
    
    self.timer = self.timer - dt
    if self.timer <= 0 then
        self.lost = true
    end
    
    -- Check win condition
    local allClosed = true
    for _, p in ipairs(self.popups) do
        if not p.closed then
            allClosed = false
            break
        end
    end
    
    if allClosed then
        self.won = true
        return "won" -- Immediate win logic
    end
    
    if self.lost then return "lost" end
    return nil
end

function Minigame:draw()
    -- Desktop background
    love.graphics.setColor(0.2, 0.4, 0.6)
    love.graphics.rectangle("fill", 0, 0, 1280, 720)
    
    love.graphics.setColor(1, 1, 1)
    love.graphics.printf("CLOSE ALL POPUPS!", 0, 20, 1280, "center")
    love.graphics.printf("TIME: " .. math.ceil(self.timer) .. " | LEVEL: " .. self.difficulty, 0, 50, 1280, "center")

    -- Draw popups (reverse order to draw top-most last usually, but simple list is fine)
    -- Actually for clicking, last drawn is "on top".
    for _, p in ipairs(self.popups) do
        if not p.closed then
            -- Window body
            love.graphics.setColor(p.color)
            love.graphics.rectangle("fill", p.x, p.y, p.w, p.h)
            
            -- Window border
            love.graphics.setColor(0.8, 0.8, 0.8)
            love.graphics.setLineWidth(2)
            love.graphics.rectangle("line", p.x, p.y, p.w, p.h)
            
            -- Title bar
            love.graphics.setColor(0, 0, 0.5)
            love.graphics.rectangle("fill", p.x, p.y, p.w, 30)
            
            -- Title text
            love.graphics.setColor(1, 1, 1)
            love.graphics.print(p.title, p.x + 10, p.y + 5)
            
            -- Close button (Red square top right)
            local btnSize = 26
            love.graphics.setColor(1, 0, 0)
            love.graphics.rectangle("fill", p.x + p.w - btnSize - 2, p.y + 2, btnSize, btnSize)
            love.graphics.setColor(1, 1, 1)
            love.graphics.print("X", p.x + p.w - btnSize + 5, p.y + 2)

            -- Affiche l'image de la popup centrée dans la popup
            local imgW, imgH = p.image:getWidth(), p.image:getHeight()
            local scale = math.min((p.w-20)/imgW, (p.h-50)/imgH, 1)
            local imgX = p.x + (p.w - imgW*scale)/2
            local imgY = p.y + 35 + (p.h-35 - imgH*scale)/2
            love.graphics.setColor(1, 1, 1)
            love.graphics.draw(p.image, imgX, imgY, 0, scale, scale)
        end
    end
end

function Minigame:mousepressed(x, y, button)
    if self.won or self.lost then return end
    
    if button == 1 then
        -- Iterate backwards to click top-most windows first
        for i = #self.popups, 1, -1 do
            local p = self.popups[i]
            if not p.closed then
                -- Check close button collision
                local btnSize = 30 -- slightly bigger hit area
                local bx = p.x + p.w - 28
                local by = p.y + 2
                
                -- Simple bounding box for the whole title bar area right side essentially
                if x >= bx and x <= bx + 30 and y >= by and y <= by + 30 then
                    p.closed = true
                    -- Play sound?
                    return -- Handle one click at a time
                end
                
                -- Optional: if clicked inside window but not button, bring to front?
                -- For now just ignoring
                if x >= p.x and x <= p.x + p.w and y >= p.y and y <= p.y + p.h then
                    -- Clicked this window, don't click windows underneath
                    return 
                end
            end
        end
    end
end

function Minigame:keypressed(key)
    if key == 'w' then self.won = true end -- Debug
end

return Minigame
