local Minigame = {
    instruction = "SURVIE !"
}

function Minigame:enter(difficulty)
    self.difficulty = difficulty or 1
    self.won = false
    self.lost = false
    
    -- Paramètres de temps et caméra
    self.timeLimit = math.max(8, 12 - difficulty * 0.3)
    self.timer = self.timeLimit
    self.cameraYaw = 0 
    self.fov = math.pi / 2 
    self.mouseSensitivity = 0.003
    
    -- Propriétés des Zombies
    self.zombies = {}
    self.zombieRadius = 30
    self.maxDistance = 500 
    self.minDistance = 50 
    
    local zombieCount = 3 + math.floor(difficulty * 0.3)
    local approachSpeed = 30 + difficulty * 8 
    
    for i = 1, zombieCount do
        -- 360 degree spawning
        local angle = (i / zombieCount) * (math.pi * 2) - math.pi
        table.insert(self.zombies, {
            angle = angle,
            distance = self.maxDistance,
            speed = approachSpeed + math.random(-5, 5),
            state = 'walking',
            hitTimer = 0,
            attackTimer = 0,
            size = 1.0 + (math.random() - 0.5) * 0.2,
            animTimer = math.random() * 1.0,
            currentFrame = 1
        })
    end
    
    self.flashTimer = 0
    self.zombiesKilled = 0
    self.totalZombies = zombieCount
    self.crosshairSize = 20
    
    love.mouse.setVisible(false)
    self.mouseX, self.mouseY = 640, 360
    
    -- Gestion des Assets
    self.img_walk = nil
    self.img_attack = nil
    self.quads_walk = {}
    self.quads_attack = {}
    self.useImages = false

    -- FONCTION CORRIGÉE : Utilisation correcte des arguments et marge de sécurité
    local function generateQuads(img, quadsTable, frameWidth, frameHeight)
        if img then
            local w, h = img:getDimensions()
            
            -- Use arguments if provided, otherwise default
            local fW = frameWidth or 32
            local fH = frameHeight or 48
            
            local numFrames = math.floor(w / fW)
            for i = 0, numFrames - 1 do
                -- Reduce height slightly (0.1) to avoid bleeding, but keep the pixel visible
                -- 'nearest' filter might still show the full pixel if center is sampled
                table.insert(quadsTable, love.graphics.newQuad(i * fW, 0, fW, fH - 0.01, w, h))
            end
            return numFrames
        end
        return 0
    end
    
    local assetPath = "minigames/zombie-shooter/assets/"
    
    -- Chargement avec FILTRE NEAREST et WARP CLAMPZERO pour éviter l'étirement
    if love.filesystem.getInfo(assetPath .. "zombie_walk.png") then
        self.img_walk = love.graphics.newImage(assetPath .. "zombie_walk.png")
        self.img_walk:setFilter("nearest", "nearest")
        -- Use clampzero if available to make edge transparent, otherwise clamp
        pcall(function() self.img_walk:setWrap("clampzero", "clampzero") end) 
        generateQuads(self.img_walk, self.quads_walk, 32, 48)
        self.useImages = true
    end
    
    if love.filesystem.getInfo(assetPath .. "zombie_attack.png") then
         self.img_attack = love.graphics.newImage(assetPath .. "zombie_attack.png")
         self.img_attack:setFilter("nearest", "nearest")
         pcall(function() self.img_attack:setWrap("clampzero", "clampzero") end)
         generateQuads(self.img_attack, self.quads_attack, 32, 48)
    end
    
    -- Load Audio
    if love.filesystem.getInfo(assetPath .. "zombie_death.ogg") then
        self.sndDeath = love.audio.newSource(assetPath .. "zombie_death.ogg", "static")
    end
    
    love.mouse.setRelativeMode(true)
    
    -- Sky Stars
    self.stars = {}
    for i = 1, 200 do
        table.insert(self.stars, {
            x = math.random(0, 1280),
            y = math.random(0, 360), -- Top half of screen
            size = math.random(1, 2),
            alpha = math.random(100, 255) / 255
        })
    end
end

function Minigame:update(dt)
    if self.won then return "won" end
    if self.lost then return "lost" end
    
    self.timer = self.timer - dt
    if self.flashTimer > 0 then self.flashTimer = self.flashTimer - dt end
    
    local activeZombies = 0
    for _, zombie in ipairs(self.zombies) do
        -- Animation
        zombie.animTimer = zombie.animTimer + dt
        local animSpeed = (zombie.state == 'attacking') and 0.1 or 0.15
        local quads = (zombie.state == 'attacking' and #self.quads_attack > 0) and self.quads_attack or self.quads_walk
        
        if #quads > 0 and zombie.animTimer >= animSpeed then
            zombie.animTimer = zombie.animTimer - animSpeed
            zombie.currentFrame = (zombie.currentFrame % #quads) + 1
        end

        if zombie.state == 'walking' then
            zombie.distance = zombie.distance - zombie.speed * dt
            if zombie.distance <= self.minDistance then
                zombie.state = 'attacking'
                zombie.currentFrame = 1
            end
            activeZombies = activeZombies + 1
        elseif zombie.state == 'attacking' then
            zombie.attackTimer = zombie.attackTimer + dt
            if zombie.attackTimer > 0.5 then self.lost = true end
            activeZombies = activeZombies + 1
        elseif zombie.state == 'hit' then
            zombie.hitTimer = zombie.hitTimer - dt
            if zombie.hitTimer <= 0 then zombie.state = 'dead' end
        end
    end
    
    if activeZombies == 0 and self.zombiesKilled == self.totalZombies then self.won = true end
    if self.timer <= 0 then self.lost = true end
end

function Minigame:drawZombies()
    local sortedZombies = {}
    for i, zombie in ipairs(self.zombies) do
        if zombie.state ~= 'dead' then
            table.insert(sortedZombies, zombie)
        end
    end
    table.sort(sortedZombies, function(a, b) return a.distance > b.distance end)
    
    for _, zombie in ipairs(sortedZombies) do
        local relativeAngle = zombie.angle - self.cameraYaw
        while relativeAngle > math.pi do relativeAngle = relativeAngle - 2 * math.pi end
        while relativeAngle < -math.pi do relativeAngle = relativeAngle + 2 * math.pi end
        
        if math.abs(relativeAngle) < self.fov / 2 then
            local screenX = 640 + (relativeAngle / (self.fov / 2)) * 640
            local scale = math.max(0.2, math.min((self.maxDistance / zombie.distance) * zombie.size, 3))
            local screenY = 360 + (1 - zombie.distance / self.maxDistance) * 150 -- Un peu plus bas
            
            if zombie.state == 'hit' then love.graphics.setColor(1, 0, 0, 1)
            else love.graphics.setColor(1, 1, 1, 1) end
            
            if self.useImages then
                local img = (zombie.state == 'attacking' and self.img_attack) or self.img_walk
                local quads = (zombie.state == 'attacking' and #self.quads_attack > 0) and self.quads_attack or self.quads_walk
                
                if img and #quads > 0 then
                    local quad = quads[math.min(zombie.currentFrame, #quads)]
                    local _, _, qw, qh = quad:getViewport()
                    
                    -- DESSIN CORRIGÉ : math.floor et ancrage au pied (qh)
                    love.graphics.draw(img, quad, 
                        math.floor(screenX), 
                        math.floor(screenY), 
                        0, 
                        scale, scale, 
                        math.floor(qw / 2), 
                        qh
                    )
                end
            end
        end
    end
end

-- Reste des fonctions de dessin (draw, HUD, etc.)
function Minigame:draw()
    -- Background (dark/night)
    love.graphics.setColor(0.05, 0.05, 0.1, 1)
    love.graphics.rectangle("fill", 0, 0, 1280, 720)
    
    -- Draw Sky Stars
    if self.stars then
        love.graphics.setColor(1, 1, 1)
        for _, star in ipairs(self.stars) do
            love.graphics.setColor(1, 1, 1, star.alpha)
            love.graphics.circle("fill", star.x, star.y, star.size)
        end
    end
    
    love.graphics.setColor(0.1, 0.15, 0.1, 1)
    love.graphics.rectangle("fill", 0, 360, 1280, 360)
    
    self:drawZombies()
    
    if self.flashTimer > 0 then
        love.graphics.setColor(1, 0, 0, (self.flashTimer / 0.2) * 0.3)
        love.graphics.rectangle("fill", 0, 0, 1280, 720)
    end
    
    self:drawCrosshair()
    self:drawHUD()
end

function Minigame:drawCrosshair()
    love.graphics.setColor(1, 1, 1, 0.8)
    love.graphics.line(640 - self.crosshairSize, 360, 640 + self.crosshairSize, 360)
    love.graphics.line(640, 360 - self.crosshairSize, 640, 360 + self.crosshairSize)
end

function Minigame:drawHUD()
    love.graphics.setColor(1, 1, 1)
    love.graphics.print(string.format("Time: %.1f", self.timer), 10, 20)
    love.graphics.print(string.format("Zombies: %d/%d", self.totalZombies - self.zombiesKilled, self.totalZombies), 1100, 20)
end

function Minigame:mousemoved(x, y, dx, dy)
    self.cameraYaw = self.cameraYaw + dx * self.mouseSensitivity
    -- Normalize to -pi to pi for cleanliness, but wrap around instead of clamp
    while self.cameraYaw > math.pi do self.cameraYaw = self.cameraYaw - 2 * math.pi end
    while self.cameraYaw < -math.pi do self.cameraYaw = self.cameraYaw + 2 * math.pi end
end

function Minigame:mousepressed(x, y, button)
    if button == 1 and not self.won and not self.lost then
        for _, zombie in ipairs(self.zombies) do
            if zombie.state == 'walking' or zombie.state == 'attacking' then
                local relativeAngle = zombie.angle - self.cameraYaw
                while relativeAngle > math.pi do relativeAngle = relativeAngle - 2 * math.pi end
                while relativeAngle < -math.pi do relativeAngle = relativeAngle + 2 * math.pi end
                
                local screenX = 640 + (relativeAngle / (self.fov / 2)) * 640
                local scale = math.max(0.2, math.min((self.maxDistance / zombie.distance) * zombie.size, 3))
                local hitRadius = self.zombieRadius * scale
                
                if math.abs(screenX - 640) < hitRadius then
                    zombie.state = 'hit'
                    zombie.hitTimer = 0.2
                    self.zombiesKilled = self.zombiesKilled + 1
                    self.flashTimer = 0.2
                    
                    if self.sndDeath then
                        self.sndDeath:stop()
                        self.sndDeath:play()
                    end
                    
                    break
                end
            end
        end
    end
end

function Minigame:exit()
    love.mouse.setVisible(true)
    love.mouse.setRelativeMode(false)
end

return Minigame