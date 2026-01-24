local Minigame = {
    instruction = "TROUVE !"
}

function Minigame:enter(difficulty)
    self.difficulty = difficulty or 1
    self.won = false
    self.lost = false
    self.clickBonus = 35
    
    -- Time limit decreases with difficulty
    self.timeLimit = math.max(8, 15 - difficulty * 0.5)
    self.timer = self.timeLimit
    
    -- Object count jumps based on difficulty thresholds
    local objectCount
    if difficulty <= 3 then
        objectCount = 9
    elseif difficulty <= 6 then
        objectCount = 16
    else
        objectCount = 25
    end
    
    -- Object properties
    self.objectRadius = 35
    self.objects = {}
    
    -- Create objects at random positions across the screen
    local margin = self.objectRadius + 10
    local minDistance = self.objectRadius * 2.5 -- Minimum distance between objects
    
    for i = 1, objectCount do
        local x, y
        local attempts = 0
        local validPosition = false
        
        -- Try to find a position that doesn't overlap too much
        while not validPosition and attempts < 100 do
            x = margin + math.random() * (1280 - margin * 2)
            y = margin + 100 + math.random() * (720 - margin * 2 - 150) -- Leave space for UI
            
            validPosition = true
            -- Check distance from other objects
            for _, other in ipairs(self.objects) do
                local dx = x - other.x
                local dy = y - other.y
                local dist = math.sqrt(dx * dx + dy * dy)
                if dist < minDistance then
                    validPosition = false
                    break
                end
            end
            
            attempts = attempts + 1
        end
        
        local obj = {
            x = x,
            y = y,
            originalX = x,
            originalY = y,
            type = 'normal',
            state = 'visible',
            clicked = false,
            -- Visual properties (will vary with difficulty)
            baseRadius = self.objectRadius,
            color = {0.3, 0.5, 0.8}, -- Blue-ish for normal heads
            rotation = 0,
            scale = 1.0,
            pulsePhase = math.random() * math.pi * 2,
            -- Movement properties
            velocityX = 0,
            velocityY = 0,
            circleAngle = math.random() * math.pi * 2,
            circleRadius = 20,
            circleSpeed = 1,
            driftAngle = math.random() * math.pi * 2,
            driftSpeed = 20,
            bounceSpeed = 100
        }
        
        table.insert(self.objects, obj)
    end
    
    -- Mark one random object as the treasure (different one)
    local treasureIdx = math.random(#self.objects)
    self.objects[treasureIdx].type = 'treasure'
    self.objects[treasureIdx].color = {0.9, 0.7, 0.2} -- Gold color for treasure
    
    -- Apply difficulty-based variations
    self:applyDifficultyVariations()
    
    -- Visual feedback
    self.feedbackTimer = 0
    self.feedbackMessage = ""
    self.feedbackColor = {1, 1, 1}
    
    -- Try to load images (fallback to shapes if not available)
    self.useImages = false
    local success1, normalImg = pcall(love.graphics.newImage, "minigames/find-different/assets/images/normal.png")
    local success2, treasureImg = pcall(love.graphics.newImage, "minigames/find-different/assets/images/treasure.png")
    if success1 and success2 then
        self.img_normal = normalImg
        self.img_treasure = treasureImg
        self.useImages = true
    end
end

function Minigame:applyDifficultyVariations()
    -- Multiple combined differences that get harder with difficulty
    
    for _, obj in ipairs(self.objects) do
        -- Difficulty 1-2: Basic differences
        if self.difficulty >= 1 then
            -- Slight color variations for normal objects
            if obj.type == 'normal' then
                local colorVar = 0.1
                obj.color[1] = obj.color[1] + (math.random() - 0.5) * colorVar
                obj.color[2] = obj.color[2] + (math.random() - 0.5) * colorVar
                obj.color[3] = obj.color[3] + (math.random() - 0.5) * colorVar
            end
        end
        
        -- Difficulty 3+: Add size variations
        if self.difficulty >= 3 then
            local sizeVar = 0.05 + (self.difficulty - 3) * 0.03
            obj.scale = 1.0 + (math.random() - 0.5) * sizeVar
        end
        
        -- Difficulty 4+: Add rotation
        if self.difficulty >= 4 then
            obj.rotation = (math.random() - 0.5) * 0.4
        end
        
        -- Difficulty 5+: Add pulsing animation
        if self.difficulty >= 5 then
            obj.pulseSpeed = 2 + math.random() * 2
            obj.pulseAmount = 0.05 + math.random() * 0.1
        else
            obj.pulseSpeed = 0
            obj.pulseAmount = 0
        end
        
        -- Difficulty 2+: Movement starts
        if self.difficulty >= 2 then
            -- Random drift
            obj.velocityX = (math.random() - 0.5) * obj.driftSpeed * (1 + self.difficulty * 0.2)
            obj.velocityY = (math.random() - 0.5) * obj.driftSpeed * (1 + self.difficulty * 0.2)
        end
        
        -- Difficulty 5+: Free movement with bouncing all over the screen
        if self.difficulty >= 5 then
            obj.bounceSpeed = 80 + self.difficulty * 15
            obj.velocityX = (math.random() - 0.5) * obj.bounceSpeed
            obj.velocityY = (math.random() - 0.5) * obj.bounceSpeed
        end
        
        -- Difficulty 6+: Add circular motion component (only if not free bouncing)
        if self.difficulty >= 6 and self.difficulty < 5 then
            obj.circleSpeed = 1 + self.difficulty * 0.15
            obj.circleRadius = 15 + math.random() * 20
        end
    end
end

function Minigame:update(dt)
    if self.won then return "won" end
    if self.lost then return "lost" end
    
    -- Countdown timer
    self.timer = self.timer - dt
    if self.timer <= 0 then
        self.lost = true
        self.feedbackMessage = "TIME'S UP!"
        self.feedbackColor = {1, 0.3, 0.3}
        return "lost"
    end
    
    -- Update feedback timer
    if self.feedbackTimer > 0 then
        self.feedbackTimer = self.feedbackTimer - dt
    end
    
    -- Update object positions and animations
    for _, obj in ipairs(self.objects) do
        if obj.state == 'visible' then
            -- Pulsing animation (difficulty 5+)
            if obj.pulseSpeed > 0 then
                obj.pulsePhase = obj.pulsePhase + obj.pulseSpeed * dt
            end
            
            -- Movement (difficulty 2+)
            if self.difficulty >= 2 then
                -- Difficulty 5+: Free bouncing movement all over screen
                if self.difficulty >= 5 then
                    -- Free movement with bouncing
                    obj.x = obj.x + obj.velocityX * dt
                    obj.y = obj.y + obj.velocityY * dt
                    
                    -- Bounce off screen borders
                    local margin = obj.baseRadius * obj.scale
                    if obj.x - margin < 0 or obj.x + margin > 1280 then
                        obj.velocityX = -obj.velocityX
                        obj.x = math.max(margin, math.min(1280 - margin, obj.x))
                    end
                    if obj.y - margin < 100 or obj.y + margin > 720 then
                        obj.velocityY = -obj.velocityY
                        obj.y = math.max(100 + margin, math.min(720 - margin, obj.y))
                    end
                else
                    -- Lower difficulty: simple drift
                    obj.x = obj.x + obj.velocityX * dt
                    obj.y = obj.y + obj.velocityY * dt
                    
                    -- Keep within screen bounds
                    local margin = obj.baseRadius * obj.scale
                    obj.x = math.max(margin, math.min(1280 - margin, obj.x))
                    obj.y = math.max(100 + margin, math.min(720 - margin, obj.y))
                end
            end
        end
    end
    
    return nil
end

function Minigame:draw()
    -- Background
    love.graphics.setColor(0.15, 0.15, 0.2, 1)
    love.graphics.rectangle("fill", 0, 0, 1280, 720)
    
    -- Draw all objects
    for _, obj in ipairs(self.objects) do
        if obj.state == 'visible' or obj.clicked then
            self:drawObject(obj)
        end
    end
    
    -- Timer display
    love.graphics.setColor(1, 1, 1, 1)
    local timeColor = self.timer < 3 and {1, 0.3, 0.3} or {1, 1, 1}
    love.graphics.setColor(timeColor)
    love.graphics.printf(string.format("Time: %.1f", self.timer), 0, 20, 1280, "center")
    
    -- Instructions
    love.graphics.setColor(0.7, 0.7, 0.7, 1)
    love.graphics.printf("Find the TREASURE!", 0, 60, 1280, "center")
    
    -- Difficulty indicator
    love.graphics.setColor(0.5, 0.5, 0.5, 1)
    love.graphics.printf("Difficulty: " .. self.difficulty, 10, 680, 200, "left")
    
    -- Feedback message
    if self.feedbackTimer > 0 then
        love.graphics.setColor(self.feedbackColor)
        love.graphics.printf(self.feedbackMessage, 0, 320, 1280, "center")
    end
end

function Minigame:drawObject(obj)
    love.graphics.push()
    love.graphics.translate(obj.x, obj.y)
    love.graphics.rotate(obj.rotation)
    
    -- Calculate current scale with pulsing
    local currentScale = obj.scale
    if obj.pulseSpeed > 0 then
        currentScale = currentScale + math.sin(obj.pulsePhase) * obj.pulseAmount
    end
    
    local radius = obj.baseRadius * currentScale
    
    if self.useImages then
        -- Draw with images
        local img = (obj.type == 'treasure') and self.img_treasure or self.img_normal
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.draw(img, 0, 0, 0, currentScale, currentScale,
            img:getWidth() / 2, img:getHeight() / 2)
    else
        -- Draw placeholder shapes
        if obj.type == 'treasure' then
            -- Treasure: Gold square/chest
            love.graphics.setColor(obj.color)
            love.graphics.rectangle("fill", -radius * 0.8, -radius * 0.8, 
                radius * 1.6, radius * 1.6, radius * 0.2)
            -- Lock/keyhole
            love.graphics.setColor(0.3, 0.2, 0.1)
            love.graphics.circle("fill", 0, 0, radius * 0.3)
            love.graphics.rectangle("fill", -radius * 0.1, 0, 
                radius * 0.2, radius * 0.4)
        else
            -- Normal: Circle "head"
            love.graphics.setColor(obj.color)
            love.graphics.circle("fill", 0, 0, radius)
            -- Simple face
            love.graphics.setColor(0.1, 0.1, 0.1)
            love.graphics.circle("fill", -radius * 0.3, -radius * 0.2, radius * 0.15)
            love.graphics.circle("fill", radius * 0.3, -radius * 0.2, radius * 0.15)
            -- Smile
            love.graphics.arc("line", "open", 0, radius * 0.1, radius * 0.4, 0.2, math.pi - 0.2)
        end
    end
    
    -- Visual feedback for clicked objects
    if obj.clicked then
        if obj.type == 'treasure' then
            love.graphics.setColor(0, 1, 0, 0.5)
        else
            love.graphics.setColor(1, 0, 0, 0.5)
        end
        love.graphics.circle("fill", 0, 0, radius * 1.3)
    end
    
    love.graphics.pop()
end

function Minigame:mousepressed(x, y, button)
    if button == 1 and not self.won and not self.lost then
        -- Check click against all visible objects
        for _, obj in ipairs(self.objects) do
            if obj.state == 'visible' and not obj.clicked then
                local dx = x - obj.x
                local dy = y - obj.y
                local radius = obj.baseRadius * obj.scale
                local distSq = dx * dx + dy * dy
                
                if distSq <= radius * radius then
                    obj.clicked = true
                    obj.state = 'clicked'
                    
                    if obj.type == 'treasure' then
                        -- Found the treasure!
                        self.won = true
                        self.feedbackMessage = "TREASURE FOUND!"
                        self.feedbackColor = {0.2, 1, 0.2}
                        self.feedbackTimer = 0.5
                    else
                        -- Wrong one!
                        self.lost = true
                        self.feedbackMessage = "WRONG ONE!"
                        self.feedbackColor = {1, 0.3, 0.3}
                        self.feedbackTimer = 0.5
                    end
                    break
                end
            end
        end
    end
end

return Minigame
