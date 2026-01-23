local Minigame = {}

function Minigame:enter(difficulty)
    self.difficulty = difficulty or 1
    self.won = false
    self.lost = false
    self.clickBonus = 40
    
    -- Time limit for zombies to reach player
    self.timeLimit = math.max(8, 12 - difficulty * 0.3)
    self.timer = self.timeLimit
    
    -- Camera settings
    self.cameraYaw = 0 -- Rotation angle in radians
    self.fov = math.pi / 2 -- 90 degrees field of view
    self.mouseSensitivity = 0.003
    
    -- Player position (center of world)
    self.playerX = 640
    self.playerY = 360
    
    -- Zombie properties
    self.zombies = {}
    self.zombieRadius = 30
    self.maxDistance = 500 -- Starting distance from player
    self.minDistance = 50 -- Distance at which zombie "reaches" player
    
    -- Spawn zombies based on difficulty
    local zombieCount = 3 + math.floor(difficulty * 0.3)
    local approachSpeed = 30 + difficulty * 8 -- Pixels per second, scales faster with difficulty
    
    -- Calculate reachable angle range based on camera rotation limits
    -- Camera can rotate from -pi/2 to pi/2 based on mouse position
    local maxCameraYaw = math.pi / 2
    local minCameraYaw = -math.pi / 2
    -- With FOV of pi/2, the reachable angles are:
    local minReachableAngle = minCameraYaw - self.fov / 2
    local maxReachableAngle = maxCameraYaw + self.fov / 2
    local angleRange = maxReachableAngle - minReachableAngle
    
    for i = 1, zombieCount do
        -- Spawn zombies only within reachable angle range
        local angle = minReachableAngle + (i / zombieCount) * angleRange
        table.insert(self.zombies, {
            angle = angle, -- Angle from player (radians)
            distance = self.maxDistance, -- Distance from player
            speed = approachSpeed + math.random(-5, 5), -- Speed variation
            state = 'active', -- 'active', 'hit', 'dead'
            hitTimer = 0,
            size = 1.0 + (math.random() - 0.5) * 0.2 -- Size variation
        })
    end
    
    -- Shooting feedback
    self.flashTimer = 0
    self.flashColor = {1, 0, 0}
    self.crosshairSize = 20
    
    -- Score tracking
    self.zombiesKilled = 0
    self.totalZombies = zombieCount
    self.shotsFired = 0
    
    -- Hide system cursor and track mouse
    love.mouse.setVisible(false)
    self.mouseX = 640
    self.mouseY = 360
    
    -- Try to load zombie image (fallback to shapes)
    self.useImages = false
    local success, zombieImg = pcall(love.graphics.newImage, "minigames/zombie-shooter/assets/images/zombie.png")
    if success then
        self.img_zombie = zombieImg
        self.useImages = true
    end
end

function Minigame:exit()
    love.mouse.setVisible(true)
end

function Minigame:mousemoved(x, y, dx, dy)
    self.mouseX = x
    self.mouseY = y
    
    -- Update camera yaw based on mouse X position
    -- Map mouse X (0-1280) to yaw rotation
    local centerX = 640
    local mouseOffset = x - centerX
    self.cameraYaw = (mouseOffset / centerX) * (self.fov / 2) * 2 -- Scale to allow full rotation
end

function Minigame:update(dt)
    if self.won then return "won" end
    if self.lost then return "lost" end
    
    -- Countdown timer
    self.timer = self.timer - dt
    
    -- Update flash timer
    if self.flashTimer > 0 then
        self.flashTimer = self.flashTimer - dt
    end
    
    -- Update zombies
    local activeZombies = 0
    for _, zombie in ipairs(self.zombies) do
        if zombie.state == 'active' then
            -- Move zombie closer
            zombie.distance = zombie.distance - zombie.speed * dt
            
            -- Check if zombie reached player
            if zombie.distance <= self.minDistance then
                self.lost = true
                return "lost"
            end
            
            activeZombies = activeZombies + 1
        elseif zombie.state == 'hit' then
            zombie.hitTimer = zombie.hitTimer - dt
            if zombie.hitTimer <= 0 then
                zombie.state = 'dead'
            end
        end
    end
    
    -- Check win condition
    if activeZombies == 0 and self.zombiesKilled == self.totalZombies then
        self.won = true
        return "won"
    end
    
    -- Lose condition: time out
    if self.timer <= 0 then
        self.lost = true
        return "lost"
    end
    
    return nil
end

function Minigame:draw()
    -- Background (dark/night)
    love.graphics.setColor(0.05, 0.05, 0.1, 1)
    love.graphics.rectangle("fill", 0, 0, 1280, 720)
    
    -- Draw ground/horizon
    love.graphics.setColor(0.1, 0.15, 0.1, 1)
    love.graphics.rectangle("fill", 0, 360, 1280, 360)
    
    -- Draw zombies in pseudo-3D
    self:drawZombies()
    
    -- Red flash on hit
    if self.flashTimer > 0 then
        local alpha = self.flashTimer / 0.2
        love.graphics.setColor(1, 0, 0, alpha * 0.3)
        love.graphics.rectangle("fill", 0, 0, 1280, 720)
    end
    
    -- Draw crosshair
    self:drawCrosshair()
    
    -- HUD
    self:drawHUD()
end

function Minigame:drawZombies()
    -- Sort zombies by distance (far to near for proper layering)
    local sortedZombies = {}
    for i, zombie in ipairs(self.zombies) do
        if zombie.state ~= 'dead' then
            table.insert(sortedZombies, {index = i, zombie = zombie})
        end
    end
    table.sort(sortedZombies, function(a, b) return a.zombie.distance > b.zombie.distance end)
    
    -- Draw each zombie if in FOV
    for _, entry in ipairs(sortedZombies) do
        local zombie = entry.zombie
        
        -- Calculate relative angle to zombie from camera
        local relativeAngle = zombie.angle - self.cameraYaw
        
        -- Normalize angle to -pi to pi
        while relativeAngle > math.pi do relativeAngle = relativeAngle - 2 * math.pi end
        while relativeAngle < -math.pi do relativeAngle = relativeAngle + 2 * math.pi end
        
        -- Check if zombie is within FOV
        if math.abs(relativeAngle) < self.fov / 2 then
            -- Calculate screen position based on angle
            local screenX = 640 + (relativeAngle / (self.fov / 2)) * 640
            
            -- Calculate size based on distance (perspective)
            local scale = (self.maxDistance / zombie.distance) * zombie.size
            scale = math.max(0.2, math.min(scale, 3))
            
            -- Calculate Y position (zombies appear lower when closer)
            local screenY = 360 + (1 - zombie.distance / self.maxDistance) * 100
            
            -- Draw zombie
            if zombie.state == 'hit' then
                love.graphics.setColor(1, 0, 0, 1) -- Flash red when hit
            else
                love.graphics.setColor(0.3, 0.6, 0.3, 1) -- Green for zombie
            end
            
            if self.useImages then
                local w = self.img_zombie:getWidth()
                local h = self.img_zombie:getHeight()
                love.graphics.draw(self.img_zombie, screenX, screenY, 0, 
                    scale * 0.8, scale * 0.8, w / 2, h / 2)
            else
                -- Placeholder: simple zombie shape
                local size = self.zombieRadius * scale
                
                -- Body
                love.graphics.circle("fill", screenX, screenY, size)
                
                -- Eyes
                love.graphics.setColor(1, 0, 0, 1)
                love.graphics.circle("fill", screenX - size * 0.3, screenY - size * 0.2, size * 0.15)
                love.graphics.circle("fill", screenX + size * 0.3, screenY - size * 0.2, size * 0.15)
                
                -- Arms (reaching forward)
                love.graphics.setColor(0.2, 0.5, 0.2, 1)
                love.graphics.rectangle("fill", screenX - size * 1.2, screenY - size * 0.3, 
                    size * 0.3, size * 0.8)
                love.graphics.rectangle("fill", screenX + size * 0.9, screenY - size * 0.3, 
                    size * 0.3, size * 0.8)
            end
        end
    end
end

function Minigame:drawCrosshair()
    local centerX = 640
    local centerY = 360
    local size = self.crosshairSize
    
    love.graphics.setColor(1, 1, 1, 0.8)
    love.graphics.setLineWidth(2)
    
    -- Cross lines
    love.graphics.line(centerX - size, centerY, centerX + size, centerY)
    love.graphics.line(centerX, centerY - size, centerX, centerY + size)
    
    -- Center dot
    love.graphics.circle("fill", centerX, centerY, 2)
    
    love.graphics.setLineWidth(1)
end

function Minigame:drawHUD()
    -- Timer
    local timeColor = self.timer < 3 and {1, 0.3, 0.3} or {1, 1, 1}
    love.graphics.setColor(timeColor)
    love.graphics.printf(string.format("Time: %.1f", self.timer), 10, 20, 200, "left")
    
    -- Zombie count
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.printf(string.format("Zombies: %d/%d", 
        self.totalZombies - self.zombiesKilled, self.totalZombies), 
        1080, 20, 200, "left")
    
    -- Difficulty
    love.graphics.setColor(0.7, 0.7, 0.7, 1)
    love.graphics.printf("Difficulty: " .. self.difficulty, 10, 680, 200, "left")
    
    -- Instructions
    love.graphics.setColor(0.5, 0.5, 0.5, 1)
    love.graphics.printf("Move mouse to aim, click to shoot", 0, 680, 1280, "center")
end

function Minigame:mousepressed(x, y, button)
    if button == 1 and not self.won and not self.lost then
        self.shotsFired = self.shotsFired + 1
        
        -- Check if any zombie is in crosshair (center of screen)
        local hitZombie = false
        local centerX = 640
        
        for _, zombie in ipairs(self.zombies) do
            if zombie.state == 'active' then
                -- Calculate relative angle
                local relativeAngle = zombie.angle - self.cameraYaw
                while relativeAngle > math.pi do relativeAngle = relativeAngle - 2 * math.pi end
                while relativeAngle < -math.pi do relativeAngle = relativeAngle + 2 * math.pi end
                
                -- Check if in FOV and close to center
                if math.abs(relativeAngle) < self.fov / 2 then
                    local screenX = 640 + (relativeAngle / (self.fov / 2)) * 640
                    local scale = (self.maxDistance / zombie.distance) * zombie.size
                    scale = math.max(0.2, math.min(scale, 3))
                    local hitRadius = self.zombieRadius * scale
                    
                    -- Check if crosshair is over zombie
                    if math.abs(screenX - centerX) < hitRadius then
                        -- Hit!
                        zombie.state = 'hit'
                        zombie.hitTimer = 0.2
                        self.zombiesKilled = self.zombiesKilled + 1
                        hitZombie = true
                        
                        -- Red flash feedback
                        self.flashTimer = 0.2
                        break
                    end
                end
            end
        end
    end
end

return Minigame
