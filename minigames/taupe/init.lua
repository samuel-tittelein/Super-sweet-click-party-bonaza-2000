local Minigame = {}

function Minigame:addLife()
    self.maxMisses = self.maxMisses + 1
    self.msgTimer = 1 -- Show message
end

-- Whack-a-Mole Minigame
-- Goal: Hit the required number of moles to win.
-- Controls: Mouse click

function Minigame:enter(difficulty)
    self.score = 0
    self.difficulty = difficulty or 1

    -- Level Progression Logic
    -- New Balancing:
    -- upDuration: Stays mainly constant (~1s) to allow reaction time (especially for helmets)
    -- spawnInterval: Decreases significantly to create "waves" / simultaneous moles

    -- No generic speedMod anymore, individual tuning:

    self.timeLimit = 15
    -- self.molesToHit = 10 + math.floor(self.difficulty) -- Removed target score, survival mode now

    self.timer = self.timeLimit
    self.won = false
    self.lost = false
    self.missed = 0
    self.maxMisses = 3

    self.clickBonus = 1 -- Default bonus per click

    -- Grid settings
    -- Lvl 5+: Increase grid (4x3)
    if self.difficulty >= 5 then
        self.rows = 3
        self.cols = 4
    else
        self.rows = 3
        self.cols = 3
    end

    self.holeRadius = 50
    self.moleRadius = 40

    -- Calculate grid positions
    self.grid = {}
    local spacingX = 200
    local spacingY = 150

    -- Recenter based on cols
    local totalW = (self.cols - 1) * spacingX
    local totalH = (self.rows - 1) * spacingY

    local startX = (1280 - totalW) / 2
    local startY = (720 - totalH) / 2 + 30

    for r = 1, self.rows do
        for c = 1, self.cols do
            local x = startX + (c - 1) * spacingX
            local y = startY + (r - 1) * spacingY
            table.insert(self.grid, {
                x = x,
                y = y,
                state = 'idle',  -- idle, rising, up, hit, hiding
                type = 'normal', -- normal, gold, cat, helmet
                hp = 1,
                timer = 0,
                id = (r - 1) * self.cols + c
            })
        end
    end

    -- Mole logic
    self.activeMole = nil
    self.spawnTimer = 0
    -- self.spawnInterval = (self.timeLimit - 1.0) / (self.molesToHit + 2) -- Old Formula
    -- New spawn interval logic as target is removed:
    -- Constant pressure based on difficulty?
    -- Or just re-use the old speedMod logic roughly?
    -- Let's stick to a fast pace: 0.5s to 1.5s range
    -- New spawn interval logic:
    -- Lvl 1: ~1.5s interval (One by one)
    -- Lvl 7: ~0.8s interval (Overlaps since duration is 1s)
    -- Formula: Start 1.6s, minus 0.1s per level roughly?
    -- math.max(0.3, 1.6 - (self.difficulty * 0.12)) -> Lvl 7 = 1.6 - 0.84 = 0.76s. Good.
    self.spawnInterval = math.max(0.3, 1.6 - (self.difficulty * 0.12))

    -- Up Duration:
    -- Lvl 1: 1.0s
    -- Should not go below 0.7s really for accessibility/helmets
    self.upDuration = math.max(0.75, 1.0 - (self.difficulty * 0.02))

    -- Pre-warm
    -- self:spawnMole() -- REMOVED: No pre-spawn during 'Get Ready'

    self.font20 = love.graphics.newFont(20)
    self.font30 = love.graphics.newFont(30)
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
        hole.state = 'up'
        hole.timer = self.upDuration

        -- Determine Type
        local rnd = math.random()

        -- Default
        hole.type = 'normal'
        hole.hp = 1

        -- Gold (All levels, rare) - 5%
        if rnd < 0.05 then
            hole.type = 'gold'
            -- Cat (Lvl 3+, rare) - 10% (if not gold)
        elseif self.difficulty >= 3 and rnd < 0.15 then
            hole.type = 'cat'
            -- Helmet (Lvl 7+, uncommon) - 20%
        elseif self.difficulty >= 7 and rnd < 0.35 then
            hole.type = 'helmet'
            hole.hp = 2
        end
    end
end

function Minigame:update(dt)
    if self.won or self.lost then return end

    -- Global timer
    self.timer = self.timer - dt
    if self.timer <= 0 then
        if not self.lost then
            self.won = true
        end
    end

    -- Win condition: Survive until time runs out
    -- if self.score >= self.molesToHit then ... end -- Removed

    -- Timeout is now victory if not lost
    -- (Handled in timer check above)
    if self.timer <= 0 and not self.lost then
        self.won = true
        return "won"
    end

    if self.msgTimer and self.msgTimer > 0 then
        self.msgTimer = self.msgTimer - dt
    end

    if self.missed >= self.maxMisses then
        self.lost = true
    end

    if self.lost then return "lost" end

    -- Spawn logic
    self.spawnTimer = self.spawnTimer - dt
    if self.spawnTimer <= 0 then
        self:spawnMole()
        -- Reset timer to interval strictly to prevent burst spawning after a lag spike
        -- (Do not let negative values accumulate)
        self.spawnTimer = self.spawnInterval
    end

    -- Update holes
    for _, hole in ipairs(self.grid) do
        if hole.state == 'up' then
            hole.timer = hole.timer - dt
            if hole.timer <= 0 then
                hole.state = 'idle'
                if hole.type ~= 'cat' then
                    self.missed = self.missed + 1
                end
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
    love.graphics.setFont(self.font20)
    love.graphics.printf("SURVIVE!", 0, 50, 1280, "center")
    love.graphics.printf("TIME: " .. math.ceil(self.timer) .. " | LEVEL: " .. self.difficulty, 0, 80, 1280, "center")
    love.graphics.printf("SCORE: " .. self.score .. " | MISSES: " .. self.missed .. "/" .. self.maxMisses, 0, 110, 1280,
        "center")

    if self.msgTimer and self.msgTimer > 0 then
        love.graphics.setColor(0, 1, 0)
        love.graphics.setFont(self.font30)
        love.graphics.printf("EXTRA LIFE!", 0, 150, 1280, "center")
    end

    -- Draw holes and moles
    for _, hole in ipairs(self.grid) do
        -- Hole
        love.graphics.setColor(0.2, 0.1, 0) -- Dark dirt
        love.graphics.circle("fill", hole.x, hole.y, self.holeRadius)

        -- Mole
        if hole.state == 'up' then
            if hole.type == 'gold' then
                love.graphics.setColor(1, 0.8, 0)     -- Gold
            elseif hole.type == 'cat' then
                love.graphics.setColor(0.5, 0.5, 0.5) -- Grey cat
            elseif hole.type == 'helmet' then
                love.graphics.setColor(0.4, 0.6, 0.4) -- Greenish/Helmet
            else
                love.graphics.setColor(0.6, 0.4, 0.2) -- Mole brown
            end

            love.graphics.circle("fill", hole.x, hole.y, self.moleRadius)

            -- Accessories
            if hole.type == 'cat' then
                -- Ears (simple triangles)
                love.graphics.polygon("fill", hole.x - 30, hole.y - 20, hole.x - 10, hole.y - 50, hole.x, hole.y - 30)
                love.graphics.polygon("fill", hole.x + 30, hole.y - 20, hole.x + 10, hole.y - 50, hole.x, hole.y - 30)
            elseif hole.type == 'helmet' then
                -- Helmet stripe
                love.graphics.setColor(0.2, 0.2, 0.2)
                love.graphics.rectangle("fill", hole.x - 30, hole.y - 30, 60, 10)
            end

            -- Eyes
            love.graphics.setColor(0, 0, 0)
            love.graphics.circle("fill", hole.x - 10, hole.y - 10, 5)
            love.graphics.circle("fill", hole.x + 10, hole.y - 10, 5)
            -- Nose
            love.graphics.setColor(1, 0.5, 0.5)
            love.graphics.circle("fill", hole.x, hole.y + 5, 8)
        elseif hole.state == 'hit' then
            if hole.type == 'cat' then
                love.graphics.setColor(1, 0, 0)
                love.graphics.circle("fill", hole.x, hole.y, self.moleRadius)
                love.graphics.setColor(1, 1, 1)
                love.graphics.print("WRONG!", hole.x - 25, hole.y - 10)
            else
                love.graphics.setColor(1, 0, 0) -- Hit flash
                love.graphics.circle("fill", hole.x, hole.y, self.moleRadius)
                love.graphics.setColor(1, 1, 1)
                love.graphics.print("OUCH!", hole.x - 20, hole.y - 10)
            end
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
                if dx * dx + dy * dy <= self.moleRadius * self.moleRadius then
                    if hole.type == 'cat' then
                        self.missed = self.missed + 1
                        hole.state = 'hit'
                        hole.timer = 0.5
                        -- Feedback specific to cat?
                        return
                    end

                    if hole.type == 'helmet' and hole.hp > 1 then
                        hole.hp = hole.hp - 1
                        -- Feedback for hit but not dead?
                        -- Maybe sound or shake
                        return -- Do not kill yet
                    end

                    -- Hit!
                    hole.state = 'hit'
                    hole.timer = 0.5 -- Show hit for 0.5s

                    if hole.type == 'gold' then
                        self.clickBonus = 5 -- Used by GameLoop for global click count
                    else
                        self.clickBonus = 1
                    end

                    self.score = self.score + 1
                    break -- Only hit one at a time
                end
            end
        end
    end
end

return Minigame
