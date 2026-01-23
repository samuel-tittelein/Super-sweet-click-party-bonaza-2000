local Minigame = {}

-- Whack-a-Mole Minigame
-- Goal: Hit the required number of moles to win.
-- Controls: Mouse click

function Minigame:enter(difficulty)
    self.score = 0
    self.difficulty = difficulty or 1
    
    -- Game settings based on difficulty
    -- Difficulty 1: normal speed
    -- Difficulty >1: faster
    local speedMultiplier = self.difficulty
    
    self.timeLimit = 15 -- 15 seconds to win
    self.molesToHit = 10 -- Target score
    
    self.timer = self.timeLimit
    self.won = false
    self.lost = false
    self.missed = 0
    self.maxMisses = 3
    
    -- Grid settings
    -- We'll use a virtual grid centered on screen.
    -- Assuming screen 1280x720. 
    -- Let's define a 3x3 grid.
    self.rows = 3
    self.cols = 3
    self.holeRadius = 50
    self.moleRadius = 40
    
    -- Calculate grid positions
    self.grid = {}
    local spacingX = 200
    local spacingY = 150
    local startX = 1280 / 2 - spacingX
    local startY = 720 / 2 - spacingY + 30 -- slightly offset for UI
    
    for r = 1, self.rows do
        for c = 1, self.cols do
            local x = startX + (c - 1) * spacingX
            local y = startY + (r - 1) * spacingY
            table.insert(self.grid, {
                x = x, 
                y = y, 
                state = 'idle', -- idle, rising, up, hit, hiding
                timer = 0,
                id = (r-1)*self.cols + c
            })
        end
    end
    
    -- Mole logic
    self.activeMole = nil -- Only one at a time for simplicity? Or multiple? Let's do single for now but fast.
    self.spawnTimer = 0
    self.spawnInterval = math.max(0.5, 1.5 - (self.difficulty * 0.1)) -- Faster spawn as diff increases
    self.upDuration = math.max(0.4, 1.0 - (self.difficulty * 0.1)) -- Moles stay up shorter
    
    -- Pre-warm
    self:spawnMole()
end

function Minigame:spawnMole()
    -- Find idle holes
    local idleHoles = {}
    for i, hole in ipairs(self.grid) do
        if hole.state == 'idle' then
            table.insert(idleHoles, hole)
        end
    end
    
    if #idleHoles > 0 then
        local hole = idleHoles[math.random(#idleHoles)]
        hole.state = 'up' -- Skip animation for prototype
        hole.timer = self.upDuration
    end
end

function Minigame:update(dt)
    if self.won or self.lost then return end
    
    -- Global timer
    self.timer = self.timer - dt
    if self.timer <= 0 then
        if self.score >= self.molesToHit then
            self.won = true -- Should have won already but just in case
        else
            self.lost = true
        end
    end
    
    -- Win condition
    if self.score >= self.molesToHit then
        self.won = true
        return "won"
    end

    if self.missed >= self.maxMisses then
        self.lost = true
    end
    
    if self.lost then return "lost" end

    -- Spawn logic
    self.spawnTimer = self.spawnTimer - dt
    if self.spawnTimer <= 0 then
        self:spawnMole()
        self.spawnTimer = self.spawnInterval
    end
    
    -- Update holes
    for _, hole in ipairs(self.grid) do
        if hole.state == 'up' then
            hole.timer = hole.timer - dt
            if hole.timer <= 0 then
                hole.state = 'idle'
                self.missed = self.missed + 1
            end
        elseif hole.state == 'hit' then
            hole.timer = hole.timer - dt
            if hole.timer <= 0 then
                hole.state = 'idle'
            end
        end
    end
    
    if self.won then return "won" end
    if self.lost then return "lost" end
    return nil
end

function Minigame:draw()
    -- Background for the game area
    love.graphics.setColor(0.2, 0.6, 0.2) -- Grass green
    love.graphics.rectangle("fill", 0, 0, 1280, 720)
    
    -- UI
    love.graphics.setColor(1, 1, 1)
    love.graphics.newFont(20)
    love.graphics.printf("HIT " .. self.molesToHit .. " MOLES!", 0, 50, 1280, "center")
    love.graphics.printf("TIME: " .. math.ceil(self.timer), 0, 80, 1280, "center")
    love.graphics.printf("SCORE: " .. self.score .. " | MISSES: " .. self.missed .. "/" .. self.maxMisses, 0, 110, 1280, "center")

    -- Draw holes and moles
    for _, hole in ipairs(self.grid) do
        -- Hole
        love.graphics.setColor(0.2, 0.1, 0) -- Dark dirt
        love.graphics.circle("fill", hole.x, hole.y, self.holeRadius)
        
        -- Mole
        if hole.state == 'up' then
            love.graphics.setColor(0.6, 0.4, 0.2) -- Mole brown
            love.graphics.circle("fill", hole.x, hole.y, self.moleRadius)
            -- Eyes
            love.graphics.setColor(0, 0, 0)
            love.graphics.circle("fill", hole.x - 10, hole.y - 10, 5)
            love.graphics.circle("fill", hole.x + 10, hole.y - 10, 5)
            -- Nose
            love.graphics.setColor(1, 0.5, 0.5)
            love.graphics.circle("fill", hole.x, hole.y + 5, 8)
        elseif hole.state == 'hit' then
            love.graphics.setColor(1, 0, 0) -- Hit flash
            love.graphics.circle("fill", hole.x, hole.y, self.moleRadius)
            love.graphics.setColor(1, 1, 1)
            love.graphics.print("OUCH!", hole.x - 20, hole.y - 10)
        end
    end
end

function Minigame:keypressed(key)
    -- Debug win
    if key == 'w' then self.won = true end
end

function Minigame:mousepressed(x, y, button)
    if self.won or self.lost then return end
    
    if button == 1 then -- Left click
        for _, hole in ipairs(self.grid) do
            if hole.state == 'up' then
                -- Check distance
                local dx = x - hole.x
                local dy = y - hole.y
                if dx*dx + dy*dy <= self.moleRadius * self.moleRadius then
                    -- Hit!
                    hole.state = 'hit'
                    hole.timer = 0.5 -- Show hit for 0.5s
                    self.score = self.score + 1
                    break -- Only hit one at a time
                end
            end
        end
    end
end

return Minigame
