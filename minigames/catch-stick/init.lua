local Minigame = {}

function Minigame:enter(difficulty)
    self.difficulty = difficulty or 1
    self.won = false
    self.lost = false
    self.clickBonus = 30
    
    -- Calculate hand position
    -- NEW: Fixed position mechanism as per user request
    self.catchY = 550 -- The vertical line where we must catch
    self.handY = self.catchY -- Keep handY variable for compatibility if used elsewhere
    self.handX = 640 -- Center of screen
    
    -- Random delay before dropping (1-2 seconds)
    self.releaseDelay = math.random() + 1.0 -- Random between 1.0 and 2.0
    self.timer = 0
    
    -- Stick properties
    self.stickX = self.handX
    -- Stick starts higher up now, maybe even off the top of the screen or just at the top edge
    self.stickY = -150 
    self.stickWidth = 20
    self.stickHeight = 120
    self.stickVelocity = 0
    self.stickRotation = 0
    self.stickRotationSpeed = 0
    
    -- Generous hitbox padding (30px on all sides)
    self.hitboxPadding = 30
    
    -- Game phases: "waiting", "falling", "caught", "missed"
    self.phase = "waiting"
    
    -- Try to load images
    self.useImages = false
    local basePath = "minigames/catch-stick/assets/"
    
    -- Randomize background and audio (1 to 3)
    local idx = math.random(1, 3)
    local bgPath = basePath .. "fond.jpg"
    local audioPath = basePath .. "fond-sonore.ogg"
    
    if idx > 1 then
        bgPath = basePath .. "fond_" .. idx .. ".jpg"
        audioPath = basePath .. "fond-sonore-" .. idx .. ".ogg"
    end
    
    local success, bg = pcall(love.graphics.newImage, bgPath)
    if success then self.img_bg = bg end
    
    -- Load and play audio
    local audioSuccess, audio = pcall(love.audio.newSource, audioPath, "stream")
    if audioSuccess then
        self.bgMusic = audio
        self.bgMusic:setLooping(true)
        print("AUDIO: Catch-stick playing bgMusic")
        self.bgMusic:play()
    end
    
    local s1, hVide = pcall(love.graphics.newImage, basePath .. "main-vide-removebg-preview.png")
    local s2, hTot = pcall(love.graphics.newImage, basePath .. "attrape-tard-removebg-preview.png")
    local s3, hParfait = pcall(love.graphics.newImage, basePath .. "attrape-parfait-removebg-preview.png")
    local s4, hTard = pcall(love.graphics.newImage, basePath .. "attrape-tot-removebg-preview.png")
    
    if s1 and s2 and s3 and s4 then
        self.img_hand_vide = hVide
        self.img_hand_tot = hTot
        self.img_hand_parfait = hParfait
        self.img_hand_tard = hTard
        self.useImages = true
    end
    
    -- Stick image
    local s5, stickImg = pcall(love.graphics.newImage, basePath .. "baton-removebg-preview.png")
    if s5 then
        self.img_stick = stickImg
        self.stickWidth = self.img_stick:getWidth() * 0.65 -- Scale stick down a bit?
       
        self.stickHeight = self.img_stick:getHeight() * 0.65
    end
    
    self.catchResult = nil -- "tot", "parfait", "tard"
    
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
    love.graphics.setColor(1, 1, 1, 1)
    if self.img_bg then
        local bgScaleX = 1280 / self.img_bg:getWidth()
        local bgScaleY = 720 / self.img_bg:getHeight()
        love.graphics.draw(self.img_bg, 0, 0, 0, bgScaleX, bgScaleY)
    else
        love.graphics.setColor(0.7, 0.85, 1, 1) -- Sky blue
        love.graphics.rectangle("fill", 0, 0, 1280, 720)
        
        -- Ground
        love.graphics.setColor(0.4, 0.6, 0.3, 1) -- Grass green
        love.graphics.rectangle("fill", 0, 650, 1280, 70)
    end
    
    if self.phase == "waiting" or self.phase == "falling" then
        -- Draw stick falling
        self:drawStick()
    elseif self.phase == "caught" then
        -- Draw stick caught (frozen) -> REMOVED because hand sprite contains stick
        -- self:drawStick()
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
    
    self:drawPlayerHand()
end

function Minigame:drawPlayerHand()
    if self.useImages then
        -- Static position
        -- Center hand visually on the line. 
        -- If the hand sprite includes the forearm, the center might be lower than the "fingers".
        -- User wanted it "higher", so we subtract from Y.
        local mx, my = self.handX, self.catchY - 50 
        love.graphics.setColor(1, 1, 1, 1)
        
        local img = self.img_hand_vide
        local scale = 1
        
        if self.phase == "caught" then
            if self.catchResult == "tot" and self.img_hand_tot then
                img = self.img_hand_tot
            elseif self.catchResult == "parfait" and self.img_hand_parfait then
                img = self.img_hand_parfait
            elseif self.catchResult == "tard" and self.img_hand_tard then
                img = self.img_hand_tard
            end
        end
        
        -- Player hand comes from bottom
        love.graphics.draw(img, mx, my, 0, scale, scale, 
            img:getWidth()/2, img:getHeight()/2)
            
    end
end




function Minigame:drawStick()
    if self.useImages and self.img_stick then
        love.graphics.setColor(1, 1, 1, 1)
        
        -- Calculate scale to match the desired width/height
        local sx = self.stickWidth / self.img_stick:getWidth()
        local sy = self.stickHeight / self.img_stick:getHeight()
        
        love.graphics.draw(self.img_stick, self.stickX, self.stickY, 
            self.stickRotation, sx, sy,
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
    -- Click anywhere to catch, as long as it's falling (or near falling?)
    if button == 1 and self.phase == "falling" then
        -- Timing based catch
        -- catchY is where the hand is (550).
        -- stickY is the center of the stick.
        
        -- If stickY is exactly catchY, the center of the stick is in the hand.
        local offset = self.stickY - self.catchY
        local threshold = self.stickHeight * 0.4 -- Allow capturing within 40% of stick height
        
        -- stickY increases as it falls.
        -- If stickY < catchY, stick is above hand (offset negative).
        -- If stickY > catchY, stick is below hand (offset positive).
        
        -- Wait, earlier I said:
        -- stickY > catchY (stick lower than hand) -> Stick fell too far -> Late?
        -- stickY < catchY (stick higher than hand) -> Stick not reached yet -> Early?
        
        -- Let's refine based on "Tot / Parfait / Tard" images:
        -- "Tot" (Early) = Catching the BOTTOM of the stick? 
        --   If we click EARLY, the stick hasn't fallen enough. Stick is HIGH. stickY < catchY.
        --   So we catch the BOTTOM of the stick physically? Yes, hand is at 550, stick center is at 400. Hand touches bottom of stick.
        
        -- "Tard" (Late) = Catching the TOP of the stick?
        --   If we click LATE, the stick has fallen TOO MUCH. Stick is LOW. stickY > catchY.
        --   Hand is at 550, stick center is at 700. Hand touches top of stick.
        
        if math.abs(offset) < threshold + 20 then -- Add a bit of absolute tolerance
            -- Caught!
            self.phase = "caught" 
            self.feedbackTimer = 1.0
            
            if offset < -threshold/2 then
                -- Stick is above hand (Offset negative) -> Hand catches bottom -> EARLY
                self.catchResult = "tot"
                self.feedbackMessage = "EARLY!"
            elseif offset > threshold/2 then
                 -- Stick is below hand (Offset positive) -> Hand catches top -> LATE
                self.catchResult = "tard"
                self.feedbackMessage = "LATE!"
            else
                self.catchResult = "parfait"
                self.feedbackMessage = "PERFECT!"
            end
            
            -- Stop stick
            self.stickVelocity = 0
            self.stickRotationSpeed = 0
            
        else
            -- Missed (too early or too late, outside range)
            -- For now, if we click way too early, do we punish? 
            -- User said "on ne l attrape plus quand on veut... timing precis".
            -- If we miss the window, maybe we just don't catch it and it falls to ground?
            -- Or we fail immediately? 
            -- Usually spam clicking is bad. Let's make it fail if we click?
            -- Or just ignore clicks that are WAY off?
            -- Let's ignore clicks that are way off (e.g. stick is still at top of screen).
            
            -- If stick is somewhat close but we missed the threshold:
             if self.stickY > self.catchY + self.stickHeight then
                 -- Actually if it's past us, we probably already triggered "missed" in update().
             end
             
             -- If we click and miss, let's treat it as a "failed attempt" -> Loss?
             -- Or just let it fall? Let's let it fall for now to avoid frustration from accidental clicks.
        end
    end
end


function Minigame:leave()
    if self.bgMusic then
        self.bgMusic:stop()
    end
end

return Minigame
