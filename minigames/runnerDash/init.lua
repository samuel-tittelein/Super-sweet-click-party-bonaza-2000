local Minigame = {
    instruction = "SAUTE !"
}

function Minigame:enter(difficulty)
    self.difficulty = difficulty or 1
    
    -- Design Constants (8-bit style)
    self.colors = {
        bg = {0.9, 0.9, 0.9}, -- Dark purple-ish
        floor = {1, 1, 1}, -- Retro green
        player = {0.9, 0.9, 0.2}, -- Yellow
        obstacle = {0.9, 0.2, 0.2}, -- Red
        white = {1, 1, 1}
    }

    -- Load Images securely (fallback to shapes if missing)
    self.images = {}
    local function loadImage(path)
        local status, img = pcall(love.graphics.newImage, path)
        if status then return img else return nil end
    end

    self.images.player = loadImage('minigames/runnerDash/assets/cube.png')
    self.images.spike = loadImage('minigames/runnerDash/assets/spike.png')
    self.images.block = loadImage('minigames/runnerDash/assets/block.png')
    self.images.ground = loadImage('minigames/runnerDash/assets/ground.png')
    self.images.background = loadImage('minigames/runnerDash/assets/background.jpg')

    
    -- Game State
    self.gameState = "playing" -- "playing", "won", "lost"
    self.timer = 0
    self.winTime = 10
    
    -- Physics
    -- Physics
    -- Make it less floaty by increasing base gravity significantly (was 2500)
    -- Gravity increases with difficulty
    -- Gravity increases with difficulty
    self.gravity = 6000 + (self.difficulty * 80) -- Was 80
    self.jumpForce = -1350 -- Stronger jump to compensate for high gravity
    self.groundY = 550
    -- Increase speed scaling: base 400, +80 per difficulty level
    self.speed = 400 + (self.difficulty * 50) -- Was 50
    
    -- Player
    self.player = {
        x = 200,
        y = self.groundY+50,
        w = 60,
        h = 60,
        dy = 0,
        isGrounded = true,
        rotation = 0
    }
    
    -- Obstacles
    self.obstacles = {}
    self.spawnTimer = 0
    self.currentPattern = 1
    
    self.musicTimer = 0
    
    -- Score Logic
    self.score = 0
    self.scoreDisplay = {
        value = 0,
        scale = 1,
        rotation = 0,
        baseScale = 1,
        targetScale = 1,
        color = {1, 1, 1}
    }


    -- Music Logic
    self.music = nil
    -- Try mp3
    local status, music = pcall(love.audio.newSource, 'minigames/runnerDash/assets/music.ogg', 'stream')
    if status then
        self.music = music
        self.music:setLooping(true)
        self.music:play()
    else
        -- Try wav as fallback just in case
        local statusWav, musicWav = pcall(love.audio.newSource, 'minigames/runnerDash/assets/music.ogg', 'stream')
        if statusWav then
            self.music = musicWav
            self.music:setLooping(true)
            self.music:play()
        end
    end

    -- SFX Logic
    self.sfx = {}
    local statusPop, popSfx = pcall(love.audio.newSource, 'minigames/runnerDash/assets/pop.ogg', 'static')
    if statusPop then
        self.sfx.pop = popSfx
    end
end

function Minigame:update(dt)
    if self.gameState ~= "playing" then return self.gameState end
    
    self.timer = self.timer + dt
    -- Removed win condition based on time for now, or keep it? 
    -- User wanted score animations, so maybe the game should go on longer?
    -- Let's keep the winTime but make it longer or rely on difficulty.
    -- Actually, let's just let it run.
    if self.timer >= self.winTime then
        self.gameState = "won"
        if self.music then self.music:stop() end
        return "won"
    end

    -- Update Score
    local prevScore = self.score
    self.score = self.score + (self.speed * dt) / 20 
    
    -- Animation Decay (Slower return to base for visibility)
    self.scoreDisplay.scale = self.scoreDisplay.scale + (self.scoreDisplay.baseScale - self.scoreDisplay.scale) * 3 * dt
    self.scoreDisplay.rotation = self.scoreDisplay.rotation + (0 - self.scoreDisplay.rotation) * 3 * dt
    
    -- Milestone Detection (Robust)
    if math.floor(self.score) > math.floor(prevScore) then
        local crossed1000 = math.floor(prevScore / 1000) < math.floor(self.score / 1000)
        local crossed100 = math.floor(prevScore / 100) < math.floor(self.score / 100)
        local crossed10 = math.floor(prevScore / 10) < math.floor(self.score / 10)
        
        if crossed1000 then
            -- Huge Effect
            self.scoreDisplay.scale = 4.0
            self.scoreDisplay.rotation = math.rad(math.random(-45, 45))
            -- Also play sound if available?
            if self.sfx.pop then self.sfx.pop:play() end
        elseif crossed100 then
             -- Big Effect
            self.scoreDisplay.scale = 2.5
            self.scoreDisplay.rotation = math.rad(math.random(-25, 25))
            if self.sfx.pop then self.sfx.pop:play() end
        elseif crossed10 then
             -- Small Effect
            self.scoreDisplay.scale = 1.5
            self.scoreDisplay.rotation = math.rad(math.random(-10, 10))
        end
    end


    
    -- Player Physics
    self.player.dy = self.player.dy + self.gravity * dt
    self.player.y = self.player.y + self.player.dy * dt
    
    if self.player.y >= self.groundY - self.player.h then
        self.player.y = self.groundY - self.player.h
        self.player.dy = 0
        self.player.isGrounded = true
         -- Snap rotation on ground
        local r = self.player.rotation % (math.pi / 2)
        if r < 0.1 or r > (math.pi/2 - 0.1) then
             self.player.rotation = math.floor((self.player.rotation + math.pi/4) / (math.pi/2)) * (math.pi/2)
        else
             self.player.rotation = self.player.rotation + (10 * dt) -- spin execution effect
        end
    else
        self.player.isGrounded = false
        self.player.rotation = self.player.rotation + (5 * dt)
    end
    
    -- Auto-jump (Hold to retry)
    if self.player.isGrounded then
        if love.mouse.isDown(1) then
            self.player.dy = self.jumpForce
            self.player.isGrounded = false
        end
    end
    
    -- Obstacle Spawning
    self.spawnTimer = self.spawnTimer - dt
    if self.spawnTimer <= 0 then
        self:spawnObstacle()
        -- Randomize spawn timer based on speed to ensure gaps are jumpable but varied
        -- Faster speed = shorter time between obstacles needs to be allowed, but distance is speed*time.
        -- We want distance between obstacles to be reasonable.
        
        -- Increase min distance with difficulty to prevent impossible jumps at high speeds
        local minDistance = 250 + (self.difficulty * 30) 
        local maxDistance = 600 + (self.difficulty * 20)
        
        local distance = math.random(minDistance, maxDistance)
        self.spawnTimer = distance / self.speed
    end
    
    -- Update Obstacles
    for i = #self.obstacles, 1, -1 do
        local obs = self.obstacles[i]
        obs.x = obs.x - self.speed * dt
        
        -- Collision
        if self:checkCollision(self.player, obs) then
            self.gameState = "lost"
            if self.music then self.music:stop() end
            if self.sfx.pop then self.sfx.pop:play() end
            return "lost"
        end
        
        -- Remove if offscreen
        if obs.x < -100 then
            table.remove(self.obstacles, i)
        end
    end
end

function Minigame:spawnObstacle()
    local r = math.random()
    local type = "spike"
    
    if r < 0.4 then type = "spike"
    elseif r < 0.7 then type = "block"
    else type = "double_spike" end
    
    local obs = {
        x = 1300,
        y = 0,
        w = 40,
        h = 40,
        type = type
    }
    
    if obs.type == "spike" then
        obs.y = self.groundY - 40
    elseif obs.type == "double_spike" then
        obs.y = self.groundY - 40
        obs.w = 80 -- Wider hitbox for double spike
    else -- block
        obs.y = self.groundY - 50
        obs.w = 50
        obs.h = 50
    end
    
    table.insert(self.obstacles, obs)
end

function Minigame:checkCollision(p, o)
    -- Simple AABB for now, refine for spikes later if needed
    -- Shrink hitboxes slightly to be forgiving
    local px, py, pw, ph = p.x + 10, p.y + 10, p.w - 20, p.h - 20 -- more forgiving
    local ox, oy, ow, oh = o.x + 5, o.y + 5, o.w - 10, o.h - 10
    
    if o.type == "spike" or o.type == "double_spike" then
        -- Triangle hitbox approximation (center bottom is safe-ish, top is dangerous)
        -- Just use a smaller box at the bottom center of the spike
        ox = o.x + 10
        ow = o.w - 20
        oy = o.y + 10
        oh = o.h - 10
    end

    return px < ox + ow and
           px + pw > ox and
           py < oy + oh and
           py + ph > oy
end

function Minigame:draw()
    -- Background
    love.graphics.setColor(1, 1, 1) -- Reset color for image
    if self.images.background then
         -- Draw background scaled to screen
         local bgw = self.images.background:getWidth()
         local bgh = self.images.background:getHeight()
         love.graphics.draw(self.images.background, 0, 0, 0, 1280/bgw, 720/bgh)
    else
        love.graphics.setColor(self.colors.bg)
        love.graphics.rectangle("fill", 0, 0, 1280, 720)
    end
    
    -- Floor
    if self.images.ground then
        love.graphics.setColor(1, 1, 1)
        local gw = self.images.ground:getWidth()
        local gh = self.images.ground:getHeight()
        -- Tile horizontally
        for x = 0, 1280, gw do
            -- Draw ground line/image
            love.graphics.draw(self.images.ground, x, self.groundY)
        end
        -- Fill below with a color matching the ground? Or just black?
        -- Let's use the floor color for the fill below
        love.graphics.setColor(self.colors.floor)
        love.graphics.rectangle("fill", 0, self.groundY + gh, 1280, 720 - self.groundY - gh)
    else
        love.graphics.setColor(self.colors.floor)
        love.graphics.rectangle("fill", 0, self.groundY, 1280, 720 - self.groundY)
        love.graphics.setColor(0,0,0,0.5)
        love.graphics.rectangle("line", 0, self.groundY, 1280, 720 - self.groundY) -- outline
    end
    
    -- Player
    love.graphics.push()
    love.graphics.translate(self.player.x + self.player.w/2, self.player.y + self.player.h/2)
    love.graphics.rotate(self.player.rotation)
    
    if self.images.player then
        love.graphics.setColor(1, 1, 1)
        local iw = self.images.player:getWidth()
        local ih = self.images.player:getHeight()
        -- Scale to fit player hitbox
        love.graphics.draw(self.images.player, -self.player.w/2, -self.player.h/2, 0, self.player.w/iw, self.player.h/ih)
    else
        love.graphics.setColor(self.colors.player)
        love.graphics.rectangle("fill", -self.player.w/2, -self.player.h/2, self.player.w, self.player.h)
        love.graphics.setColor(0,0,0)
        love.graphics.setLineWidth(3)
        love.graphics.rectangle("line", -self.player.w/2, -self.player.h/2, self.player.w, self.player.h)
    end
    love.graphics.pop()
    
    -- Obstacles
    for _, obs in ipairs(self.obstacles) do
        love.graphics.setColor(self.colors.obstacle)
        
        if obs.type == "spike" then
            if self.images.spike then
                love.graphics.setColor(1, 1, 1)
                local iw = self.images.spike:getWidth()
                local ih = self.images.spike:getHeight()
                love.graphics.draw(self.images.spike, obs.x, obs.y, 0, obs.w/iw, obs.h/ih)
            else
                -- Draw triangle
                love.graphics.polygon("fill", 
                    obs.x, obs.y + obs.h, 
                    obs.x + obs.w/2, obs.y, 
                    obs.x + obs.w, obs.y + obs.h
                )
                love.graphics.setColor(0,0,0)
                love.graphics.polygon("line", 
                    obs.x, obs.y + obs.h, 
                    obs.x + obs.w/2, obs.y, 
                    obs.x + obs.w, obs.y + obs.h
                )
            end
        elseif obs.type == "double_spike" then
             if self.images.spike then
                 love.graphics.setColor(1, 1, 1)
                 local iw = self.images.spike:getWidth()
                 local ih = self.images.spike:getHeight()
                 local w1 = obs.w / 2
                 love.graphics.draw(self.images.spike, obs.x, obs.y, 0, w1/iw, obs.h/ih)
                 love.graphics.draw(self.images.spike, obs.x + w1, obs.y, 0, w1/iw, obs.h/ih)
             else
                 -- Draw 2 triangles side by side
                 local w1 = obs.w / 2
                 -- Spike 1
                 love.graphics.setColor(self.colors.obstacle)
                 love.graphics.polygon("fill", 
                    obs.x, obs.y + obs.h, 
                    obs.x + w1/2, obs.y, 
                    obs.x + w1, obs.y + obs.h
                 )
                 love.graphics.setColor(0,0,0)
                 love.graphics.polygon("line", 
                   obs.x, obs.y + obs.h, 
                   obs.x + w1/2, obs.y, 
                   obs.x + w1, obs.y + obs.h
                 )
                 
                 -- Spike 2
                 love.graphics.setColor(self.colors.obstacle)
                 love.graphics.polygon("fill", 
                    obs.x + w1, obs.y + obs.h, 
                    obs.x + w1 + w1/2, obs.y, 
                    obs.x + obs.w, obs.y + obs.h
                 )
                 love.graphics.setColor(0,0,0)
                 love.graphics.polygon("line", 
                    obs.x + w1, obs.y + obs.h, 
                    obs.x + w1 + w1/2, obs.y, 
                    obs.x + obs.w, obs.y + obs.h
                 )
             end
             
        else -- block
            if self.images.block then
                love.graphics.setColor(1, 1, 1)
                local iw = self.images.block:getWidth()
                local ih = self.images.block:getHeight()
                love.graphics.draw(self.images.block, obs.x, obs.y, 0, obs.w/iw, obs.h/ih)
            else
                love.graphics.setColor(self.colors.obstacle) -- Red blocks? or maybe grey for blocks usually
                love.graphics.rectangle("fill", obs.x, obs.y, obs.w, obs.h)
                love.graphics.setColor(0,0,0)
                love.graphics.rectangle("line", obs.x, obs.y, obs.w, obs.h)
            end
        end
    end
    
    -- UI
    love.graphics.setColor(self.colors.white)
    local progress = math.min(100, (self.timer / self.winTime) * 100)
    love.graphics.printf("PROGRESS: " .. math.floor(progress) .. "%", 0, 50, 1280, "center")
    
    -- Scanlines effect (optional, cheap retro feel)
    love.graphics.setColor(0, 0, 0, 0.1)
    for i = 0, 720, 4 do
        love.graphics.line(0, i, 1280, i)
    end
end

function Minigame:keypressed(key)
    -- Disabled: only mouse clicks allowed
end

function Minigame:mousepressed(x, y, button)
    if button == 1 then
        if self.player.isGrounded then
            self.player.dy = self.jumpForce
            self.player.isGrounded = false
        end
    end
end

function Minigame:exit()
    if self.music then self.music:stop() end
end

function Minigame:leave()
    if self.music then self.music:stop() end
end

return Minigame
