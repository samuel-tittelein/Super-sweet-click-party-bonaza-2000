-- states/GameLoop.lua
local GameLoop = {}

-- Shared HUD background for all minigames
local HUD_IMAGE = nil

function GameLoop:enter(params)
        -- Lazy-load HUD background image used for all minigames
        if not HUD_IMAGE then
            HUD_IMAGE = love.graphics.newImage('assets/hud.png')
        end
    params = params or {}
    self.score = params.score or 0
    self.difficulty = params.difficulty or 1
    self.gamesPlayedSinceShop = 0
    self.minigameCount = 0 -- Total or just since shop? Let's say per session.
    self.mode = params.mode or 'normal'
    self.targetGameIndex = params.gameIndex
    -- Actually if we continue, we might want to keep total count?
    if params.continue then
        -- keep total if needed, but the requirement said "restart the loop (5 games, shop...)"
        -- so resetting gamesPlayedSinceShop is correct.
    end

    -- Load all minigames identifiers
    self.availableMinigames = {}
    for _, mgData in ipairs(G_MINIGAMES) do
        local success, mg = pcall(require, 'minigames.' .. mgData.id .. '.init')
        if success then
            table.insert(self.availableMinigames, mg)
        else
            error("Failed to load minigame: " .. mgData.id .. "\nError: " .. tostring(mg))
        end
    end
    -- Manual insertions removed in favor of list



    self.currentMinigame = nil
    self.currentMinigameIndex = 0

    self.phase = 'start' -- start, intro, play, result, lost
    self.timer = 0
    self.resultMessage = ""

    -- Load item definitions for UI
    self.itemDefs = {}
    local itemFiles = { 'heart', 'downgrade' }
    -- We assume they exist in items/name/init.lua now
    for _, name in ipairs(itemFiles) do
        local success, itemTitle = pcall(require, 'items.' .. name .. '.init')
        if success then
            self.itemDefs[name] = itemTitle
        end
    end

    self.fonts = {
        ui = love.graphics.newFont(30),
        small = love.graphics.newFont(20),
        large = love.graphics.newFont(48),
        medium = love.graphics.newFont(32),
        resultSmall = love.graphics.newFont(24)
    }

    self.scoreUI = {
        scale = 1,
        rotation = 0,
        baseScale = 1
    }
    self.scoreUI = {
        scale = 1,
        rotation = 0,
        baseScale = 1
    }
    self.lastKnownScore = gClickCount -- Track changes
    
    self.presentationProgress = 0 -- 0 = Windowed, 1 = Fullscreen
    
    self.heartAnim = {
        active = false,
        timer = 0,
        phase = 'idle' -- 'tremble', 'explode'
    }
    
    -- Load Intermission Sound
    self.sndIntermission = {}
    if love.filesystem.getInfo("states/assets/bouclewin1.ogg") then
        table.insert(self.sndIntermission, love.audio.newSource("states/assets/bouclewin1.ogg", "static"))
    end
    if love.filesystem.getInfo("states/assets/bouclewin2.ogg") then
        table.insert(self.sndIntermission, love.audio.newSource("states/assets/bouclewin2.ogg", "static"))
    end
     if love.filesystem.getInfo("states/assets/perduvie.ogg") then
        table.insert(self.sndIntermission, love.audio.newSource("states/assets/perduvie.ogg", "static"))
    end
    if love.filesystem.getInfo("states/assets/perdufin.ogg") then
        table.insert(self.sndIntermission, love.audio.newSource("states/assets/perdufin.ogg", "static"))
    end
    
    self:nextLevel()
end

function GameLoop:nextLevel()
    -- Check for shop
    -- Check for shop
    -- "tous les autant de niveaux qu'il existe" -> #availableMinigames
    local shopInterval = #self.availableMinigames
    if shopInterval < 3 then shopInterval = 3 end -- Minimum logic if few games

    if self.mode ~= 'single' and self.gamesPlayedSinceShop >= shopInterval then
        self:stopMinigame()
        gStateMachine:change('shop', { score = self.score, difficulty = self.difficulty })
        return
    end

    if self.mode == 'single' and self.minigameCount > 0 then
        self:stopMinigame()
        gStateMachine:change('selector')
        return
    end

    local idx
    if self.mode == 'single' then
        idx = self.targetGameIndex
        if self.minigameCount > 0 then
            self.difficulty = math.floor(self.difficulty) + 1
        end
    else
        -- Random selection from ALL available games
        local numGames = #self.availableMinigames
        if numGames > 0 then
            repeat
                idx = math.random(numGames)
            until numGames <= 1 or idx ~= self.currentMinigameIndex
        else
            idx = 1
        end

        -- Increment difficulty every few games instead of every loop
        if self.minigameCount % numGames == 0 then
            self.difficulty = math.floor(self.difficulty) + 1
        end
    end

    -- Cleanup previous minigame
    if self.currentMinigame and self.currentMinigame.leave then
        self.currentMinigame:leave()
    end

    self.currentMinigame = self.availableMinigames[idx]
    self.currentMinigameIndex = idx

    -- Safety check: if minigame is nil, use first minigame
    if not self.currentMinigame then
        if #self.availableMinigames > 0 then
            self.currentMinigame = self.availableMinigames[1]
            self.currentMinigameIndex = 1
        else
            gStateMachine:change('menu')
            return
        end
    end

    -- Increase difficulty slightly or logic here
    self.minigameCount = self.minigameCount + 1
    self.gamesPlayedSinceShop = self.gamesPlayedSinceShop + 1

    self.phase = 'intro'
    self.timer = 1 -- 1 second intro for item selection

    -- Reset minigame
    if self.currentMinigame.enter then
        self.currentMinigame:enter(self.difficulty)
    end
end

function GameLoop:update(dt)
    -- Presentation Transition
    local targetProgress = 1
    if self.phase == 'result' or self.phase == 'lost' then
        targetProgress = 0
    end
    
    -- Smooth lerp
    self.presentationProgress = self.presentationProgress + (targetProgress - self.presentationProgress) * 5 * dt

    if self.phase == 'intro' then
        self.timer = self.timer - dt
        if self.timer <= 0 then
            self.phase = 'play'
        end
    elseif self.phase == 'play' then
        -- Update minigame

        local result = self.currentMinigame:update(dt)

        if result == 'won' then
            self:stopMinigame()
            self.phase = 'result'
            
            -- Play Intermission Sound
            if #self.sndIntermission > 0 then 
                local snd = self.sndIntermission[math.random(#self.sndIntermission)]
                snd:stop()
                snd:play()
            end
            
            self.resultMessage = "VICTOIRE !"
            
            -- Base 10s, accelerates with difficulty (minimum 3s)
            -- More aggressive scaling: -0.8s per level
            local duration = math.max(1, 5 - ((self.difficulty - 1) * 0.8))
            
            self.timer = duration -- Show result for calculated duration (Intermission)
            self.resultDuration = duration
            self.score = self.score + 1

            -- Add click bonus
            local bonus = self.currentMinigame.clickBonus or 100 -- Increased default for visibility
            
            -- Setup Score Animation
            self.scoreStart = gClickCount -- Old score
            self.scoreTarget = gClickCount + bonus -- New score
            self.displayScore = self.scoreStart
            
            -- Update global immediately (so it's saved), but animate display
            gClickCount = self.scoreTarget

            -- Record win for unlocks
            if self.currentMinigame.name then
                gUnlockedMinigames[self.currentMinigame.name] = true
            end

        elseif result == 'lost' then
            self:stopMinigame()
            gLives = gLives - 1

            -- Play Intermission Sound
            if #self.sndIntermission > 0 then 
                local snd = self.sndIntermission[math.random(#self.sndIntermission)]
                snd:stop()
                snd:play()
            end
            
            -- Trigger Heart Loss Animation
            self.heartAnim.active = true
            self.heartAnim.timer = 0.5 -- Trenble duration
            self.heartAnim.phase = 'tremble'
            
            if gLives <= 0 then
                gStateMachine:change('lost', { score = self.score })
            else
                self.phase = 'result'
                self.resultMessage = "VIE PERDUE..."
                self.timer = 2 -- Short delay before next game
                self.resultDuration = 2

                -- No score change
                self.scoreStart = gClickCount
                self.scoreTarget = gClickCount
                self.displayScore = gClickCount
            end
        end
    elseif self.phase == 'result' then
        self.timer = self.timer - dt
        
        -- Score Animation
        -- User wants it to slow down at the end and have a clear pause.
        -- We make the animation faster than the total timer.
        local animDuration = self.resultDuration - 3.0 -- End animation 3s before state change
        if animDuration < 0.5 then animDuration = 0.5 end -- Safety
        
        local timerElapsed = self.resultDuration - self.timer
        
        if self.scoreTarget > self.scoreStart then
            local progress = timerElapsed / animDuration
            
            -- Clamp 0-1
            if progress < 0 then progress = 0 end
            if progress > 1 then progress = 1 end
            
            -- Ease Out Cubic: 1 - (1 - x)^3
            -- Starts fast, slows down at the end
            local curve = 1 - math.pow(1 - progress, 3)
            
            self.displayScore = math.floor(self.scoreStart + (self.scoreTarget - self.scoreStart) * curve)
        else
            self.displayScore = self.scoreTarget
        end

         -- Score Animation Logic (During Result Counting)
        local currentDisplayScore = self.displayScore
        
        -- Detect Changes
        if currentDisplayScore > self.lastKnownScore then
            -- Use thresholds (10, 100, 1000)
            local crossed1000 = math.floor(self.lastKnownScore / 1000) < math.floor(currentDisplayScore / 1000)
            local crossed100 = math.floor(self.lastKnownScore / 100) < math.floor(currentDisplayScore / 100)
            local crossed10 = math.floor(self.lastKnownScore / 10) < math.floor(currentDisplayScore / 10)
            
            if crossed1000 then
                 -- Huge Amplified Effect
                self.scoreUI.scale = 3.0
                self.scoreUI.rotation = math.rad(math.random(-30, 30))
            elseif crossed100 then
                 -- Medium Amplified Effect
                self.scoreUI.scale = 2.0
                self.scoreUI.rotation = math.rad(math.random(-15, 15))
            elseif crossed10 then
                 -- Small Effect
                self.scoreUI.scale = 1.3
                self.scoreUI.rotation = math.rad(math.random(-5, 5))
            end
            
            self.lastKnownScore = currentDisplayScore
        end
        
        -- Decay Animation
        self.scoreUI.scale = self.scoreUI.scale + (self.scoreUI.baseScale - self.scoreUI.scale) * 5 * dt
        self.scoreUI.rotation = self.scoreUI.rotation + (0 - self.scoreUI.rotation) * 5 * dt

        if self.timer <= 0 then

            self:nextLevel()
        end
        
        -- Heart Animation Update
        if self.heartAnim.active then
            self.heartAnim.timer = self.heartAnim.timer - dt
            if self.heartAnim.phase == 'tremble' then
                if self.heartAnim.timer <= 0 then
                    self.heartAnim.phase = 'explode'
                    self.heartAnim.timer = 0.5 -- Explosion duration
                    -- Play sound?
                end
            elseif self.heartAnim.phase == 'explode' then
                if self.heartAnim.timer <= 0 then
                    self.heartAnim.active = false
                    self.heartAnim.phase = 'idle'
                end
            end
        end
    end
end

function GameLoop:exit()
    self:stopMinigame()
end

function GameLoop:stopMinigame()
    if self.currentMinigame and self.currentMinigame.exit then
        self.currentMinigame:exit()
    end
end

function GameLoop:draw()
    -- Draw HUD background over the full virtual area (no clipping)
    if HUD_IMAGE then
        local iw, ih = HUD_IMAGE:getWidth(), HUD_IMAGE:getHeight()
        local sx, sy = 1280 / iw, 720 / ih
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.draw(HUD_IMAGE, 0, 0, 0, sx, sy)
    end

    -- Draw Minigame inside the arcade cabinet screen
    if self.currentMinigame then
        -- Arcade cabinet screen area (sized for the screen inside hud.png)
        local gameW, gameH = 800, 450
        local gameX, gameY = (1280 - gameW) / 2, (720 - gameH) / 2 + 30

        -- Clip and Draw Game
        love.graphics.setScissor(gTransX + (gameX * gScale), gTransY + (gameY * gScale), gameW * gScale, gameH * gScale)

        love.graphics.push()
        love.graphics.translate(gameX, gameY)
        
        -- Scale minigame to fit the screen area
        local mgScale = gameW / 1280
        love.graphics.scale(mgScale, mgScale)

        love.graphics.push("all") -- Protect global state
        self.currentMinigame:draw()
        love.graphics.pop()

        love.graphics.pop()
        love.graphics.setScissor()
    end

    -- Draw Phase Overlays
    if self.phase == 'intro' then
        love.graphics.setColor(0, 0, 0, 0.7)
        love.graphics.rectangle("fill", 0, 0, 1280, 720)
        love.graphics.setColor(1, 1, 1)
        love.graphics.printf("GET READY!", 0, 300, 1280, "center")
        love.graphics.printf("GET READY!", 0, 300, 1280, "center")
        love.graphics.printf(string.format("%.1f", self.timer), 0, 350, 1280, "center")

        -- Draw UI Items
        love.graphics.setColor(1, 1, 1)
        love.graphics.setFont(self.fonts.small)
        love.graphics.print("BONUS ITEMS:", 1000, 150)

        local startY = 200
        for name, def in pairs(self.itemDefs) do
            local count = gInventory[name] or 0
            if count > 0 then
                -- Draw box logic (simple)
                love.graphics.setColor(1, 1, 1, 0.5)
                love.graphics.rectangle("fill", 1000, startY, 200, 60)

                love.graphics.setColor(1, 1, 1)
                love.graphics.print(def.name .. " x" .. count, 1010, startY + 20)

                -- Draw logic from item definition?
                if def.draw then
                    love.graphics.push()
                    -- icon size?
                    def:draw(1150, startY + 10, 1)
                    love.graphics.pop()
                end

                startY = startY + 70
            end
        end
    elseif self.phase == 'result' then
        -- Background
        love.graphics.setColor(0.1, 0.1, 0.15, 0.95)
        love.graphics.rectangle("fill", 0, 0, 1280, 720)

        -- Title
        love.graphics.setFont(self.fonts.large)
        if self.resultMessage == "VICTOIRE !" then
            love.graphics.setColor(0.2, 0.8, 0.2)
        else
            love.graphics.setColor(0.9, 0.3, 0.3)
        end
        love.graphics.printf(self.resultMessage, 0, 120, 1280, "center")

        -- Panel
        love.graphics.setColor(0.2, 0.2, 0.25)
        love.graphics.rectangle("fill", 340, 220, 600, 200, 15, 15)
        love.graphics.setColor(1, 1, 1)
        love.graphics.setLineWidth(2)
        love.graphics.rectangle("line", 340, 220, 600, 200, 15, 15)

        -- Stats
        love.graphics.setFont(self.fonts.medium)
        love.graphics.setColor(1, 1, 1)
        love.graphics.printf("Score Total", 0, 250, 1280, "center")
        love.graphics.setColor(1, 0.9, 0.2)
        
        -- Draw animated score in Result Screen
        local displayVal = self.displayScore or gClickCount
        
        love.graphics.push()
        love.graphics.translate(640, 290 + 20) -- Center pivot (approx center + half height)
        love.graphics.rotate(self.scoreUI.rotation)
        love.graphics.scale(self.scoreUI.scale, self.scoreUI.scale)
        
        -- Color override if big milestone?
        if self.scoreUI.scale > 1.5 then
            love.graphics.setColor(1, 0.2, 0.2) -- Flash Red
        elseif self.scoreUI.scale > 1.1 then
            love.graphics.setColor(1, 1, 0.2) -- Flash Yellow
        else
            love.graphics.setColor(1, 0.9, 0.2) -- Gold
        end

        love.graphics.printf(tostring(displayVal), -640, -20, 1280, "center")
        love.graphics.pop()

        love.graphics.setColor(1, 1, 1)

        love.graphics.printf("Vies Restantes", 0, 350, 1280, "center")
        
        -- Draw Hearts
        local heartSize = 60 -- Increased size
        local gap = 20
        -- Total width includes the dying heart if animating
        local numHeartsInfo = gLives
        if self.heartAnim.active then numHeartsInfo = gLives + 1 end
        
        local totalW = (numHeartsInfo * heartSize) + ((numHeartsInfo - 1) * gap)
        local startX = (1280 - totalW) / 2
        local startY = 390
        
        love.graphics.setColor(1, 0.3, 0.3)
        for i = 1, numHeartsInfo do
            local hx = startX + (i-1) * (heartSize + gap)
            local centerX = hx + heartSize / 2
            local centerY = startY + heartSize / 2
            
            -- State Logic
            local isDyingHeart = (self.heartAnim.active and i == numHeartsInfo)
            
            love.graphics.push()
            love.graphics.translate(centerX, centerY)
            
            if isDyingHeart then
                if self.heartAnim.phase == 'tremble' then
                    -- Tremble
                    local shakeAmt = 5 * (self.heartAnim.timer / 0.5) -- Decaying shake? or constant
                    shakeAmt = 5
                    love.graphics.translate(math.random(-shakeAmt, shakeAmt), math.random(-shakeAmt, shakeAmt))
                    -- Also flash white?
                     if math.floor(love.timer.getTime() * 20) % 2 == 0 then
                        love.graphics.setColor(1, 1, 1)
                    else
                        love.graphics.setColor(1, 0.3, 0.3)
                    end
                elseif self.heartAnim.phase == 'explode' then
                    -- Explode: Scale UP and Fade OUT
                    local progress = 1 - (self.heartAnim.timer / 0.5)
                    local scaleEx = 1.0 + progress * 2.0 -- 1.0 -> 3.0
                    local alpha = 1.0 - progress
                    
                    love.graphics.scale(scaleEx, scaleEx)
                    love.graphics.setColor(1, 0.3, 0.3, alpha)
                end
                
                -- Draw the dying heart
                 love.graphics.translate(-centerX, -centerY)
                 love.graphics.polygon("fill", 
                    hx + heartSize/2, startY + heartSize,      
                    hx, startY + heartSize/3,                  
                    hx + heartSize/4, startY,                  
                    hx + heartSize/2, startY + heartSize/4,    
                    hx + heartSize*0.75, startY,               
                    hx + heartSize, startY + heartSize/3       
                )
            else
                -- Normal Heart logic
                -- Animation: vivid, rhythmic, synchronized
                local time = love.timer.getTime()
                local speed = 8 -- Faster, more rhythmic
                
                -- Rotation
                local angle = math.sin(time * speed) * 0.4 
                
                -- Scale
                local scale = 1.0 + math.abs(math.sin(time * speed)) * 0.25
                
                -- Shockwave effect from dying heart?
                if self.heartAnim.active and self.heartAnim.phase == 'explode' then
                     local progress = 1 - (self.heartAnim.timer / 0.3) -- faster shockwave
                     -- Push away from the right (where the dying heart is)
                     -- The closer to the right (higher index), the more push?
                     -- Actually push everything left?
                     local push = -20 * progress * (i / gLives) 
                     love.graphics.translate(push, 0)
                end

                love.graphics.rotate(angle)
                love.graphics.scale(scale, scale) -- Apply scale
                
                love.graphics.translate(-centerX, -centerY)
                
                -- Draw Heart Shape 
                love.graphics.setColor(1, 0.3, 0.3)
                love.graphics.polygon("fill", 
                    hx + heartSize/2, startY + heartSize,      -- Bottom tip
                    hx, startY + heartSize/3,                  -- Left middle
                    hx + heartSize/4, startY,                  -- Left top humb
                    hx + heartSize/2, startY + heartSize/4,    -- Center dip
                    hx + heartSize*0.75, startY,               -- Right top hump
                    hx + heartSize, startY + heartSize/3       -- Right middle
                )
            end
            
            love.graphics.pop()
        end

        -- Transition
        love.graphics.setFont(self.fonts.resultSmall)
        love.graphics.setColor(0.7, 0.7, 0.7)
        love.graphics.printf("Prochain mini-jeu...", 0, 520, 1280, "center")

        -- Bar
        local barW, barH = 600, 10
        local barX, barY = (1280 - barW)/2, 560
        
        love.graphics.setColor(0.3, 0.3, 0.3)
        love.graphics.rectangle("fill", barX, barY, barW, barH, 5, 5)
        
        local pct = 0
        if self.resultDuration and self.resultDuration > 0 then
            pct = 1 - (self.timer / self.resultDuration)
        end
        love.graphics.setColor(0.2, 0.6, 1.0)
        love.graphics.rectangle("fill", barX, barY, barW * pct, barH, 5, 5)
        
        -- Restore font default (just in case)
        love.graphics.setFont(love.graphics.newFont(12))
    end
end

function GameLoop:exit()
    if self.currentMinigame and self.currentMinigame.leave then
        self.currentMinigame:leave()
    end
end

function GameLoop:onPause()
    love.mouse.setVisible(true)
    if self.currentMinigame and self.currentMinigame.pause then
        self.currentMinigame:pause()
    end
    gStateMachine:push('pause')
end

function GameLoop:resume()
    if self.currentMinigame and self.currentMinigame.resume then
        self.currentMinigame:resume()
    end
end

function GameLoop:keypressed(key)
    if key == 'escape' then
        gStateMachine:push('pause') -- Pause menu is on top
    elseif gDevMode and key == 'space' then
        -- Force Win
        self.phase = 'result'
        self.resultMessage = "DEV WIN"
        self.timer = 0.5
        self.resultDuration = 0.5
        self.score = self.score + 1
        local bonus = (self.currentMinigame and self.currentMinigame.clickBonus) or 10
        
        self.scoreStart = gClickCount
        self.scoreTarget = gClickCount + bonus
        self.displayScore = self.scoreStart
        
        gClickCount = self.scoreTarget
    elseif gDevMode and key == 's' then
        -- Go to Shop
        gStateMachine:change('shop', { score = self.score, difficulty = self.difficulty })
    else
        -- Item Inputs REMOVED (replaced by UI)
        -- 'd' for Downgrade logic removed
        -- 'h' for Heart logic removed

        if self.phase == 'play' and self.currentMinigame.keypressed then
            self.currentMinigame:keypressed(key)
        end
    end
end

function GameLoop:mousepressed(x, y, button)
    if self.phase == 'play' and self.currentMinigame.mousepressed then
        -- Use fixed arcade screen dimensions (same as draw)
        local gameW, gameH = 800, 450
        local gameX = (1280 - gameW) / 2
        local gameY = (720 - gameH) / 2 + 30
        local mgScale = gameW / 1280

        local mx = (x - gameX) / mgScale
        local my = (y - gameY) / mgScale

        self.currentMinigame:mousepressed(mx, my, button)
    elseif self.phase == 'intro' and button == 1 then
        -- Check clicks on items
        local startY = 200
        for name, def in pairs(self.itemDefs) do
            local count = gInventory[name] or 0
            if count > 0 then
                if x >= 1000 and x <= 1200 and y >= startY and y <= startY + 60 then
                    -- Item Clicked!
                    if name == 'heart' then
                        if self.currentMinigame.addLife then
                            gInventory.heart = gInventory.heart - 1
                            self.currentMinigame:addLife()
                            -- optional feedback in log or sound
                        end
                    elseif name == 'downgrade' then
                        if self.difficulty > 1 then
                            gInventory.downgrade = gInventory.downgrade - 1
                            self.difficulty = self.difficulty - 1
                            if self.currentMinigame.enter then
                                self.currentMinigame:enter(self.difficulty)
                            end
                        end
                    end
                    return -- Handle one click
                end
                startY = startY + 70
            end
        end
    end
end

function GameLoop:mousereleased(x, y, button)
    if self.phase == 'play' and self.currentMinigame.mousereleased then
        -- Use fixed arcade screen dimensions (same as draw)
        local gameW, gameH = 800, 450
        local gameX = (1280 - gameW) / 2
        local gameY = (720 - gameH) / 2 + 30
        local mgScale = gameW / 1280

        local mx = (x - gameX) / mgScale
        local my = (y - gameY) / mgScale
        self.currentMinigame:mousereleased(mx, my, button)
    end
end

function GameLoop:mousemoved(x, y, dx, dy)
    if self.phase == 'play' and self.currentMinigame.mousemoved then
        -- Use fixed arcade screen dimensions (same as draw)
        local gameW, gameH = 800, 450
        local gameX = (1280 - gameW) / 2
        local gameY = (720 - gameH) / 2 + 30
        local mgScale = gameW / 1280

        local mx = (x - gameX) / mgScale
        local my = (y - gameY) / mgScale
        local mdx = dx / mgScale
        local mdy = dy / mgScale

        self.currentMinigame:mousemoved(mx, my, mdx, mdy)
    end
end

return GameLoop
