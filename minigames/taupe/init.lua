local Minigame = {
    instruction = "TAPE !"
}

-- Helper to safely load image
local function safeLoad(path)
    local status, img = pcall(love.graphics.newImage, path)
    if status then return img else print("Failed to load: " .. path) return nil end
end

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

    -- Load Assets
    self.bgImage = safeLoad("minigames/taupe/assets/stand.jpg")
    self.panelImage = safeLoad("minigames/taupe/assets/panneau-removebg-preview.png")
    self.moleImage = safeLoad("minigames/taupe/assets/taupe-removebg-preview.png")
    self.catImage = safeLoad("minigames/taupe/assets/chat-removebg-preview.png")
    self.goldImage = safeLoad("minigames/taupe/assets/taupe_doree-removebg-preview.png")
    self.helmetImage = safeLoad("minigames/taupe/assets/taupe_casque-removebg-preview.png")
    self.hitImage = safeLoad("minigames/taupe/assets/taupe_tapee-removebg-preview.png")
    self.cursorImage = safeLoad("minigames/taupe/assets/marteau-removebg-preview.png")

    -- Load Sounds
    local function loadSound(path)
        local status, src = pcall(love.audio.newSource, path, "static")
        if status then 
            src:setVolume(0.5) -- Reduce volume by half
            return src 
        else 
            print("Failed to load sound: " .. path) 
            return nil 
        end
    end
    self.sndAppear = loadSound("minigames/taupe/assets/mole_hit.ogg")
    self.sndCatHit = loadSound("minigames/taupe/assets/Cat_hit.wav") -- Changed to .wav as present on disk
    self.sndHammer = loadSound("minigames/taupe/assets/coutDeMarteau.ogg")


    -- Level Progression Logic
    self.timeLimit = 15
    
    self.timer = self.timeLimit
    self.won = false
    self.lost = false
    self.missed = 0
    self.maxMisses = 3 -- Vies

    self.clickBonus = 1 -- Default bonus per click

    -- Grid settings
    -- Fixed 3x3 for the background image
    self.rows = 3
    self.cols = 3

    self.holeRadius = 50
    
    -- CONFIGURATION TAILLE (A modifier si trop petit/grand)
    self.moleTargetSize = 250 
    self.moleRadius = self.moleTargetSize / 2.6 -- Rayon de la hitbox réduit (était 2.2)

    -- Calculate grid positions
    self.grid = {}
    
    -- CONFIGURATION DES POSITIONS (A modifier si l'image change)
    -- Ajustez les valeurs x et y pour aligner avec les trous de votre image
    local positions = {
        -- Ligne du haut
        { x = 450, y = 322 }, { x = 640, y = 322 }, { x = 825, y = 322 },
        -- Ligne du milieu
        { x = 440, y = 420 }, { x = 640, y = 420 }, { x = 840, y = 420 },
        -- Ligne du bas
        { x = 425, y = 535 }, { x = 640, y = 535 }, { x = 858, y = 535 }
    }

    for i, pos in ipairs(positions) do
        table.insert(self.grid, {
            x = pos.x,
            y = pos.y,
            state = 'idle',  -- idle, rising, up, hit, hiding
            type = 'normal', -- normal, gold, cat, helmet
            hp = 1,
            timer = 0,
            id = i
        })
    end

    -- Mole logic
    self.activeMole = nil
    self.spawnTimer = 0
    self.spawnInterval = math.max(0.3, 1.6 - (self.difficulty * 0.12))

    -- Up Duration:
    self.upDuration = math.max(0.75, 1.0 - (self.difficulty * 0.02))

    self.font20 = love.graphics.newFont(20)
    self.font30 = love.graphics.newFont(30)
    self.uiFont = love.graphics.newFont(25) -- Reduced font size (was 35)
    
    -- DEBUG: Show system cursor for alignment
    love.mouse.setVisible(false) -- User calibrated, hiding cursor
    
    self.mx = 0
    self.my = 0

    -- CONFIGURATION CURSEUR
    -- Ajustez ces valeurs pour décaler le marteau par rapport à la souris
    -- ox, oy sont le "point d'ancrage" de l'image (le point de l'image qui sera sous la souris)
    -- Si le marteau est trop à droite, augmentez cursorAnchorX. Trop à gauche, diminuez.
    -- Si le marteau est trop bas, augmentez cursorAnchorY.
    self.cursorAnchorX = 330 -- Valeur par défaut (sera écrasée par le centrage si à 0, modifiez pour tester)
    self.cursorAnchorY = 140
end

function Minigame:mousemoved(x, y, dx, dy)
    self.mx = x
    self.my = y
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

        -- Play appear sound
        if self.sndAppear then self.sndAppear:stop(); self.sndAppear:play() end

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
    else
        -- Just to be safe, ensure mouse hidden
        -- love.mouse.setVisible(false)
    end

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
    -- Background
    if self.bgImage then
        local sx = 1280 / self.bgImage:getWidth()
        local sy = 720 / self.bgImage:getHeight()
        love.graphics.setColor(1, 1, 1)
        love.graphics.draw(self.bgImage, 0, 0, 0, sx, sy)
    else
        love.graphics.setColor(0.2, 0.6, 0.2)
        love.graphics.rectangle("fill", 0, 0, 1280, 720)
    end

    -- UI: Panel
    if self.panelImage then
        -- Draw panel top center
        local px = (1280 - self.panelImage:getWidth()) / 2
        local py = -100 -- padding top
        love.graphics.setColor(1, 1, 1)
        love.graphics.draw(self.panelImage, px, py)

        -- Text on panel
        love.graphics.setFont(self.uiFont)
        local timeText = math.ceil(self.timer)
        local lifeText = (self.maxMisses - self.missed)
        local fullText = timeText .. "                     " .. lifeText
        
        -- Shadow (Black)
        love.graphics.setColor(0, 0, 0) 
        love.graphics.printf(fullText, px + 3, py + 165 + 3, self.panelImage:getWidth(), "center")
        
        -- Text (Less vivid red)
        love.graphics.setColor(0.8, 0.1, 0.1)
        love.graphics.printf(fullText, px, py + 165, self.panelImage:getWidth(), "center")
    else
        -- Fallback if panel fail load
        love.graphics.setColor(1, 1, 1)
        love.graphics.setFont(self.font20)
        love.graphics.printf("TIME: " .. math.ceil(self.timer) .. " | LIVES: " .. (self.maxMisses - self.missed), 0, 50, 1280, "center")
    end

    if self.msgTimer and self.msgTimer > 0 then
        love.graphics.setColor(0, 1, 0)
        love.graphics.setFont(self.font30)
        love.graphics.printf("EXTRA LIFE!", 0, 150, 1280, "center")
    end

    -- Draw holes and moles
    love.graphics.setColor(1, 1, 1) -- Reset color to white so images aren't tinted
    for _, hole in ipairs(self.grid) do
        -- Hole (Darken dirt under mole)
        -- love.graphics.setColor(0, 0, 0, 0.5)
        -- love.graphics.circle("fill", hole.x, hole.y, self.holeRadius)
        -- love.graphics.setColor(1, 1, 1)

        local img = nil
        
        if hole.state == 'up' then
            if hole.type == 'gold' then
                img = self.goldImage or self.moleImage
            elseif hole.type == 'cat' then
                img = self.catImage
            elseif hole.type == 'helmet' then
                img = self.helmetImage or self.moleImage
            else
                img = self.moleImage
            end
        elseif hole.state == 'hit' then
             if hole.type == 'cat' then
                 -- If we hit a cat, maybe show it angry or just the cat?
                 img = self.catImage
             else
                 img = self.hitImage or self.moleImage
             end
        end

        if img then
             -- Scale image to moleTargetSize, centered
             local s = self.moleTargetSize / math.max(img:getWidth(), img:getHeight())
             local ox = img:getWidth() / 2
             local oy = img:getHeight() / 2
             
             -- Optional shake or effect could go here
             love.graphics.draw(img, hole.x, hole.y, 0, s, s, ox, oy)
        end

        if hole.state == 'hit' then
             -- No text feedback, just the image change
        end
        
        -- DEBUG STATE (Remove later)
        -- love.graphics.setColor(0, 0, 1)
        -- love.graphics.print(hole.state, hole.x, hole.y)
        -- love.graphics.setColor(1, 1, 1)
    end
    
    -- Draw Cursor
    if self.cursorImage then
        -- Use coordinates from mousemoved
        local mx, my = self.mx, self.my
        
        -- Use configured anchor point
        local ox = self.cursorAnchorX
        local oy = self.cursorAnchorY
        
        -- Fallback if not set (though strictly initialized above)
        if ox == 0 and oy == 0 then
             ox = self.cursorImage:getWidth() / 2
             oy = self.cursorImage:getHeight() / 2
        end

        love.graphics.setColor(1, 1, 1)
        love.graphics.draw(self.cursorImage, mx, my, 0, 0.4, 0.4, ox, oy)
    end
end

function Minigame:leave()
    love.mouse.setVisible(true)
end

function Minigame:pause()
    love.mouse.setVisible(true)
end

function Minigame:resume()
    love.mouse.setVisible(false)
end

function Minigame:keypressed(key)
    -- Debug win
    if key == 'w' then self.won = true end
end

function Minigame:mousepressed(x, y, button)
    if self.won or self.lost then return end

    if button == 1 then -- Left click
        local hitSomething = false

        for _, hole in ipairs(self.grid) do
            if hole.state == 'up' then
                -- Check distance (simple circular hitbox)
                local dx = x - hole.x
                local dy = y - hole.y
                if dx * dx + dy * dy <= self.moleRadius * self.moleRadius then
                    
                    if self.sndHammer then self.sndHammer:stop(); self.sndHammer:play() end

                    hitSomething = true

                    if hole.type == 'cat' then
                        self.missed = self.missed + 1
                        hole.state = 'hit'
                        hole.timer = 0.5
                        if self.sndCatHit then self.sndCatHit:stop(); self.sndCatHit:play() end
                        break -- Stop checking other holes
                    end

                    if hole.type == 'helmet' and hole.hp > 1 then
                        hole.hp = hole.hp - 1
                        -- Small visual feedback without changing state to hit
                        break 
                    end

                    -- Hit!
                    hole.state = 'hit'
                    hole.timer = 0.5 -- Show hit for 0.5s

                    if hole.type == 'gold' then
                        self.clickBonus = 5 
                    else
                        self.clickBonus = 1
                    end

                    self.score = self.score + 1
                    break -- Only hit one at a time
                end
            end
        end

        if not hitSomething then
            -- Missed click (clicked on nothing)
            self.missed = self.missed + 1
            if self.sndHammer then self.sndHammer:stop(); self.sndHammer:play() end -- Also play sound on miss? Or maybe a "whoosh"? User didn't specify, but hammer sound usually plays on click.
        end
    end
end

return Minigame
