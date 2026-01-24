local Minigame = {
    name = 'never_give_up',
    instruction = "MINE !"
}

function Minigame:enter(difficulty)
    self.difficulty = difficulty or 1
    self.state = nil

    -- Target clicks: starts at 15, increases slowly with difficulty
    self.targetClicks = math.floor(15 + (self.difficulty - 1) * 2)
    self.currentClicks = 0

    -- Time limit: 5 seconds, decreases very slightly
    self.timeLimit = math.max(3.5, 5 - (self.difficulty - 1) * 0.05)
    self.timer = self.timeLimit

    -- Animation state
    self.swingTimer = 0

    -- Pickaxe sound
    self.clickSound = nil
    if love.filesystem.getInfo("minigames/never_give_up/assets/pickaxe.ogg") then
        self.clickSound = love.audio.newSource("minigames/never_give_up/assets/pickaxe.ogg", "static")
    end
end

function Minigame:update(dt)
    if self.state == 'won' then return 'won' end
    if self.state == 'lot' then return 'lost' end -- Internal 'lot' used for actual transition

    if self.state == 'giving_up' then
        self.lossTimer = self.lossTimer - dt
        if self.lossTimer <= 0 then
            self.state = 'lot'
            return 'lost'
        end
        return
    end

    self.timer = self.timer - dt
    if self.timer <= 0 then
        self.state = 'giving_up'
        self.lossTimer = 0.5
        return
    end

    if self.swingTimer > 0 then
        self.swingTimer = self.swingTimer - dt
    end
end

function Minigame:draw()
    -- Cave Background (Dark Brown)
    love.graphics.setColor(0.15, 0.08, 0.04)
    love.graphics.rectangle("fill", 0, 0, 1280, 720)

    -- Tunnel Floor
    love.graphics.setColor(0.25, 0.15, 0.08)
    love.graphics.rectangle("fill", 0, 500, 1280, 220)

    -- Tunnel Ceiling
    love.graphics.setColor(0.25, 0.15, 0.08)
    love.graphics.rectangle("fill", 0, 0, 1280, 150)

    -- Constants for layout
    local diamondStackX = 1100
    local minerWidth = 50
    local startX = 100

    -- Progress: how far we are
    local progress = self.currentClicks / self.targetClicks

    -- Miner Position: moves from startX towards diamondStackX
    local maxMinerX = diamondStackX - minerWidth - 10
    local minerX = startX + progress * (maxMinerX - startX)

    -- Walk away animation if giving up
    local isGivingUp = (self.state == 'giving_up' or self.state == 'lot')
    if isGivingUp and self.lossTimer then
        local walkDist = (0.5 - self.lossTimer) * 120 -- Move 60px in 0.5s
        minerX = minerX - walkDist
    end

    -- Diamonds (Far right, always visible)
    love.math.setRandomSeed(123)
    love.graphics.setColor(0, 0.9, 1, 0.7 + math.sin(love.timer.getTime() * 8) * 0.3)
    for i = 1, 20 do
        local dx = diamondStackX + love.math.random(0, 100)
        local dy = 250 + love.math.random(0, 200)
        love.graphics.circle("fill", dx, dy, 15)
    end
    love.math.setRandomSeed(os.time())

    -- Wall: From the point where the miner stopped back to the diamond stack
    local wallX = startX + progress * (maxMinerX - startX) + minerWidth
    local wallWidth = diamondStackX - wallX

    if wallWidth > 2 then
        love.graphics.setColor(0.4, 0.3, 0.2)
        love.graphics.rectangle("fill", wallX, 150, wallWidth, 350)
        -- Rock detail lines
        love.graphics.setColor(0.3, 0.2, 0.1)
        love.graphics.setLineWidth(3)
        love.graphics.rectangle("line", wallX, 150, wallWidth, 350)
    end

    -- Miner
    local isGivingUp = (self.state == 'giving_up' or self.state == 'lot')
    local swingOffset = (self.swingTimer > 0 and not isGivingUp) and 20 or 0

    -- Body
    love.graphics.setColor(0.2, 0.5, 0.8)
    love.graphics.rectangle("fill", minerX, 400, minerWidth, 100)
    -- Head
    love.graphics.setColor(1, 0.8, 0.6)
    love.graphics.circle("fill", minerX + minerWidth / 2, 380, 20)

    -- Pickaxe (Mirrored if giving up)
    love.graphics.setColor(0.7, 0.7, 0.7)
    love.graphics.setLineWidth(6)
    if isGivingUp then
        -- Mirror: Face left
        local px, py = minerX - swingOffset, 420
        love.graphics.line(px, py, px - 50, py - 40)           -- handle
        love.graphics.line(px - 40, py - 50, px - 60, py - 30) -- blade
    else
        -- Face right
        local px, py = minerX + minerWidth + swingOffset, 420
        love.graphics.line(px, py, px + 50, py - 40)           -- handle
        love.graphics.line(px + 40, py - 50, px + 60, py - 30) -- blade
    end

    -- UI
    love.graphics.setColor(1, 1, 1)
    love.graphics.setFont(love.graphics.newFont(40))
    if isGivingUp then
        love.graphics.printf("you gave up...", 0, 50, 1280, "center")
    else
        love.graphics.printf("NEVER GIVE UP!", 0, 50, 1280, "center")
    end

    love.graphics.setFont(love.graphics.newFont(24))
    love.graphics.printf(string.format("Time: %.1f", math.max(0, self.timer)), 0, 100, 1280, "center")

    -- Instruction
    if self.difficulty < 3 and not isGivingUp then
        love.graphics.printf("LEFT CLICK TO DIG!", 0, 600, 1280, "center")
    end
end

function Minigame:mousepressed(x, y, button)
    if self.state == 'giving_up' then return end

    -- Using left click to mine
    if button == 1 then
        self.currentClicks = self.currentClicks + 1
        self.swingTimer = 0.1
        if self.clickSound then
            self.clickSound:clone():play()
        end

        if self.currentClicks >= self.targetClicks then
            self.state = 'won'
        end
    end
end

return Minigame
