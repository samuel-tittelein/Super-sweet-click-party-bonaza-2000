local Minigame = {}

function Minigame:enter(difficulty)
    self.difficulty = difficulty or 1
    self.won = false
    self.lost = false
    self.clickBonus = 30
    
    -- Calculate hand position based on difficulty (linear)
    -- Higher difficulty = hand is lower = less reaction time
    -- Start at y=100, move down 40px per difficulty level
    self.handY = math.min(100 + (self.difficulty - 1) * 40, 500)
    self.handX = 640 -- Center of screen
    
    -- Random delay before dropping (1-2 seconds)
    self.releaseDelay = math.random() + 1.0 -- Random between 1.0 and 2.0
    self.timer = 0
    
    -- Stick properties
    self.stickX = self.handX
    self.stickY = self.handY + 30 -- Below hand
    self.stickWidth = 20
    self.stickHeight = 120
    self.stickVelocity = 0
    self.stickRotation = 0
    self.stickRotationSpeed = 0
    
    -- Generous hitbox padding (30px on all sides)
    self.hitboxPadding = 30
    
    -- Game phases: "waiting", "falling", "caught", "missed"
    self.phase = "waiting"
    
    -- Try to load images, use shapes as fallback
    self.useImages = false
    local success, handImg = pcall(love.graphics.newImage, "minigames/catch-stick/assets/images/hand.png")
    if success then
        self.img_hand = handImg
        local success2, stickImg = pcall(love.graphics.newImage, "minigames/catch-stick/assets/images/stick.png")
        if success2 then
            self.img_stick = stickImg
            self.useImages = true
            self.stickWidth = self.img_stick:getWidth()
            self.stickHeight = self.img_stick:getHeight()
        end
    end
    
    -- Visual feedback
    self.feedbackTimer = 0
    self.feedbackMessage = ""
end

function Minigame:update(dt)
    if self.won then return "won" end
    if self.lost then return "lost" end
    
    self.timer = self.timer + dt
    
    if self.phase == "waiting" then
        -- Wait for random delay, then release stick
        if self.timer >= self.releaseDelay then
            self.phase = "falling"
            self.stickRotationSpeed = 0 -- No rotation, falls straight
        end
        
    elseif self.phase == "falling" then
        -- Apply gravity to stick
        local gravity = 1200
        self.stickVelocity = self.stickVelocity + gravity * dt
        self.stickY = self.stickY + self.stickVelocity * dt
        self.stickRotation = self.stickRotation + self.stickRotationSpeed * dt
        
        -- Check if stick hit ground (missed)
        if self.stickY > 720 + self.stickHeight then
            self.phase = "missed"
            self.lost = true
            self.feedbackMessage = "MISSED!"
            self.feedbackTimer = 1
        end
        
    elseif self.phase == "caught" then
        -- Success! Show feedback briefly then win
        self.feedbackTimer = self.feedbackTimer - dt
        if self.feedbackTimer <= 0 then
            self.won = true
        end
        
    elseif self.phase == "missed" then
        -- Already lost, just waiting for feedback
        self.feedbackTimer = self.feedbackTimer - dt
    end
    
    return nil
end

function Minigame:draw()
    -- Background
    love.graphics.setColor(0.7, 0.85, 1, 1) -- Sky blue
    love.graphics.rectangle("fill", 0, 0, 1280, 720)
    
    -- Ground
    love.graphics.setColor(0.4, 0.6, 0.3, 1) -- Grass green
    love.graphics.rectangle("fill", 0, 650, 1280, 70)
    
    if self.phase == "waiting" or self.phase == "falling" then
        -- Draw hand holding or releasing stick
        self:drawHand()
        self:drawStick()
    elseif self.phase == "caught" then
        -- Draw stick caught (frozen)
        self:drawStick()
        love.graphics.setColor(0, 1, 0, 1)
        love.graphics.printf("CAUGHT!", 0, 300, 1280, "center")
    elseif self.phase == "missed" then
        love.graphics.setColor(1, 0, 0, 1)
        love.graphics.printf("MISSED!", 0, 300, 1280, "center")
    end
    
    -- Instructions during waiting phase
    if self.phase == "waiting" then
        love.graphics.setColor(0.2, 0.2, 0.2, 1)
        love.graphics.printf("Wait for the hand to release the stick...", 0, 100, 1280, "center")
        love.graphics.printf("Then click to catch it!", 0, 140, 1280, "center")
    end
    
    -- Difficulty indicator
    love.graphics.setColor(0.5, 0.5, 0.5, 1)
    love.graphics.printf("Difficulty: " .. self.difficulty, 0, 680, 1280, "center")
end

function Minigame:drawHand()
    if self.useImages and self.img_hand then
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.draw(self.img_hand, self.handX, self.handY, 0, 1, 1,
            self.img_hand:getWidth() / 2, self.img_hand:getHeight() / 2)
    else
        -- Draw simple hand shape
        love.graphics.setColor(1, 0.8, 0.6, 1) -- Skin color
        
        if self.phase == "waiting" then
            -- Closed fist holding stick
            love.graphics.circle("fill", self.handX, self.handY, 25)
            -- Thumb
            love.graphics.circle("fill", self.handX + 20, self.handY - 10, 12)
        else
            -- Open hand (released)
            love.graphics.circle("fill", self.handX, self.handY, 25)
            -- Fingers spread
            love.graphics.circle("fill", self.handX - 15, self.handY - 15, 8)
            love.graphics.circle("fill", self.handX + 15, self.handY - 15, 8)
            love.graphics.circle("fill", self.handX - 20, self.handY + 5, 8)
            love.graphics.circle("fill", self.handX + 20, self.handY + 5, 8)
        end
    end
end

function Minigame:drawStick()
    if self.useImages and self.img_stick then
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.draw(self.img_stick, self.stickX, self.stickY, 
            self.stickRotation, 1, 1,
            self.img_stick:getWidth() / 2, self.img_stick:getHeight() / 2)
    else
        -- Draw simple stick shape
        love.graphics.push()
        love.graphics.translate(self.stickX, self.stickY)
        love.graphics.rotate(self.stickRotation)
        
        -- Brown stick
        love.graphics.setColor(0.6, 0.4, 0.2, 1)
        love.graphics.rectangle("fill", -self.stickWidth/2, -self.stickHeight/2, 
            self.stickWidth, self.stickHeight, 3, 3)
        
        love.graphics.pop()
    end
    
    -- Debug: Draw hitbox (comment out in production)
    -- love.graphics.setColor(1, 0, 0, 0.3)
    -- love.graphics.rectangle("line", 
    --     self.stickX - self.stickWidth/2 - self.hitboxPadding,
    --     self.stickY - self.stickHeight/2 - self.hitboxPadding,
    --     self.stickWidth + self.hitboxPadding * 2,
    --     self.stickHeight + self.hitboxPadding * 2)
end

function Minigame:mousepressed(x, y, button)
    if button == 1 and self.phase == "falling" then
        -- Check if click is within generous hitbox
        local hitboxLeft = self.stickX - self.stickWidth/2 - self.hitboxPadding
        local hitboxRight = self.stickX + self.stickWidth/2 + self.hitboxPadding
        local hitboxTop = self.stickY - self.stickHeight/2 - self.hitboxPadding
        local hitboxBottom = self.stickY + self.stickHeight/2 + self.hitboxPadding
        
        if x >= hitboxLeft and x <= hitboxRight and 
           y >= hitboxTop and y <= hitboxBottom then
            -- Caught the stick!
            self.phase = "caught"
            self.feedbackTimer = 0.5 -- Show success message for 0.5 seconds
            self.feedbackMessage = "CAUGHT!"
            -- Stop stick motion
            self.stickVelocity = 0
            self.stickRotationSpeed = 0
        end
    end
end

return Minigame
