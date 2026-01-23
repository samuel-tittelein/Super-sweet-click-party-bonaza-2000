local Minigame = {}

-- Ingredient Definitions (images loaded in enter)
local INGREDIENTS = {
    BUN_TOP = { name = "Bun Top", imgPath = "minigames/burger/assets/pain_dessus-removebg-preview.png", type = "bun_top", offset = 20 },
    BUN_BOTTOM = { name = "Bun Bottom", imgPath = "minigames/burger/assets/pain_dessous-removebg-preview.png", type = "bun_bottom", offset = 35 },
    PATTY = { name = "Steak", imgPath = "minigames/burger/assets/steak-removebg-preview.png", type = "patty", offset = 15 },
    CHEESE = { name = "Fromage", imgPath = "minigames/burger/assets/fromage-removebg-preview.png", type = "cheese", offset = 10 },
    LETTUCE = { name = "Salade", imgPath = "minigames/burger/assets/salade-removebg-preview.png", type = "lettuce", offset = 10 },
    TOMATO = { name = "Tomate", imgPath = "minigames/burger/assets/tomate-removebg-preview.png", type = "tomato", offset = 10 },
    ONION = { name = "Oignon", imgPath = "minigames/burger/assets/oignon-removebg-preview.png", type = "onion", offset = 10 }
}

-- List of logic ingredients (excluding buns for random generation)
local LOGIC_INGREDIENTS = {
    INGREDIENTS.PATTY,
    INGREDIENTS.CHEESE,
    INGREDIENTS.LETTUCE,
    INGREDIENTS.TOMATO,
    INGREDIENTS.ONION
}

function Minigame:enter(difficulty)
    self.difficulty = difficulty or 1
    self.won = false
    self.lost = false
    self.timer = 0
    self.endTimer = 0
    self.clickBonus = 5 + (difficulty * 2)

    -- Load Images if not already loaded (caching could do this globally, but per-game is fine here)
    if not self.imagesLoaded then
        for k, v in pairs(INGREDIENTS) do
            v.img = love.graphics.newImage(v.imgPath)
        end
        self.bgPlay = love.graphics.newImage("minigames/burger/assets/fond_en_cours.jpg")
        self.bgWin = love.graphics.newImage("minigames/burger/assets/fond_partie_finie.jpg")
        self.bgLost = love.graphics.newImage("minigames/burger/assets/fond_perdu.jpg")
        self.caisse = love.graphics.newImage("minigames/burger/assets/caisse-removebg-preview.png")
        self.cursorImg = love.graphics.newImage("minigames/burger/assets/gant-removebg-preview.png")
        
        self.soundHappy = love.audio.newSource("minigames/burger/assets/Happy.ogg", "static")
        self.soundUnhappy = love.audio.newSource("minigames/burger/assets/Unhappy.ogg", "static")
        
        self.imagesLoaded = true
    end

    -- Define ingredient buttons on the right
    self.ingredientButtons = {}
    local size = 80
    local gap = 20

    -- Order for buttons
    local buttonItems = {
        INGREDIENTS.PATTY, 
        INGREDIENTS.CHEESE, 
        INGREDIENTS.LETTUCE, 
        INGREDIENTS.TOMATO,
        INGREDIENTS.ONION
    }
    
    -- Centering buttons vertically on the right, but closer (grid layout)
    -- Pattern:
    -- X X
    -- X X
    --  X
    local startX = 1050 -- Moved closer (was 1150)
    local startY = 250
    
    for i, ing in ipairs(buttonItems) do
        local col = (i - 1) % 2
        local row = math.floor((i - 1) / 2)
        
        local bx = startX + col * (size + gap)
        local by = startY + row * (size + gap)
        
        -- Special case for the 5th item (Onion) to center it below
        if i == 5 then
            bx = startX + 0.5 * (size + gap)
        end

        table.insert(self.ingredientButtons, {
            x = bx,
            y = by,
            w = size,
            h = size,
            ingredient = ing
        })
    end

    -- Generate Target Burger
    self.targetStack = {}
    table.insert(self.targetStack, INGREDIENTS.BUN_BOTTOM)
    
    local numIngredients = 2 + (math.floor(difficulty) * 2)
    if numIngredients > 24 then numIngredients = 24 end

    for i = 1, numIngredients do
        local randIng = LOGIC_INGREDIENTS[math.random(#LOGIC_INGREDIENTS)]
        table.insert(self.targetStack, randIng)
    end
    
    table.insert(self.targetStack, INGREDIENTS.BUN_TOP)
    
    -- Adjust time based on number of ingredients to be fair
    self.maxTime = 3 + (numIngredients * 0.8)

    -- Current Player Stack
    self.currentStack = {}
    table.insert(self.currentStack, INGREDIENTS.BUN_BOTTOM)
    
    -- Hide default cursor
    love.mouse.setVisible(false)
end

function Minigame:update(dt)
    if self.won then 
        self.endTimer = self.endTimer - dt
        if self.endTimer <= 0 then
            love.mouse.setVisible(true) -- Restore cursor
            return "won" 
        else
            return nil
        end
    end
    if self.lost then 
        self.endTimer = self.endTimer - dt
        if self.endTimer <= 0 then
            love.mouse.setVisible(true) -- Restore cursor
            return "lost" 
        else
            return nil
        end
    end
    
    self.timer = self.timer + dt
    if self.timer >= self.maxTime then
        self.lost = true
        self.endTimer = 3 -- Wait 3 seconds to show lost screen
        if self.soundUnhappy then self.soundUnhappy:play() end
    end
    
    return nil
end

function Minigame:draw()
    -- Draw Background
    love.graphics.setColor(1, 1, 1)
    
    local bg = self.bgPlay
    if self.won then bg = self.bgWin end
    if self.lost then bg = self.bgLost end

    if bg then
        local sx = 1280 / bg:getWidth()
        local sy = 720 / bg:getHeight()
        love.graphics.draw(bg, 0, 0, 0, sx, sy)
    else
        love.graphics.setColor(0.95, 0.95, 0.9)
        love.graphics.rectangle("fill", 0, 0, 1280, 720)
    end

    -- Draw Cash Register (Bottom Right, peeking)
    if self.caisse then
        local cx = 900 -- Position so only corner/side is visible
        local cy = 500
        -- Scale it nice and big? or standard?
        local cScale = 1.5
        -- Rotation? Maybe slightly
        love.graphics.draw(self.caisse, cx, cy, 0, cScale, cScale)
    end

    -- Draw Ingredient Buttons
    for _, btn in ipairs(self.ingredientButtons) do
        -- Draw white background box
        love.graphics.setColor(1, 1, 1)
        love.graphics.rectangle("fill", btn.x, btn.y, btn.w, btn.h)
        love.graphics.setColor(0, 0, 0)
        love.graphics.rectangle("line", btn.x, btn.y, btn.w, btn.h)

        -- Draw Image Centered in Button
        love.graphics.setColor(1, 1, 1)
        local iconScale = (btn.w - 10) / btn.ingredient.img:getWidth()
        -- Maintain aspect ratio, fit within box
        if btn.ingredient.img:getHeight() * iconScale > btn.h - 10 then
            iconScale = (btn.h - 10) / btn.ingredient.img:getHeight()
        end
        
        local ix = btn.x + (btn.w - btn.ingredient.img:getWidth() * iconScale) / 2
        local iy = btn.y + (btn.h - btn.ingredient.img:getHeight() * iconScale) / 2
        
        love.graphics.draw(btn.ingredient.img, ix, iy, 0, iconScale, iconScale)
    end

    -- Draw Target Burger (Left)
    local targetX = 350
    local targetY = 600
    self:drawBurger(self.targetStack, targetX, targetY)

    -- Draw Current Burger (Right)
    local currentX = 850
    local currentY = 600
    self:drawBurger(self.currentStack, currentX, currentY)
    
    -- Draw Analog Clock Timer (Top Left)
    local clockX, clockY = 60, 60
    local radius = 40
    
    -- Clock Face
    love.graphics.setColor(1, 1, 1)
    love.graphics.circle("fill", clockX, clockY, radius)
    love.graphics.setColor(0, 0, 0)
    love.graphics.setLineWidth(3)
    love.graphics.circle("line", clockX, clockY, radius)
    
    -- Clock Hand
    local progress = self.timer / self.maxTime
    if progress > 1 then progress = 1 end
    local angle = -math.pi / 2 + (progress * 2 * math.pi)
    
    local handX = clockX + math.cos(angle) * (radius - 5)
    local handY = clockY + math.sin(angle) * (radius - 5)
    
    love.graphics.setColor(1, 0, 0) -- Red hand
    love.graphics.line(clockX, clockY, handX, handY)
    
    -- Reset color
    love.graphics.setColor(1, 1, 1)

    -- Draw Custom Cursor
    if self.cursorImg then
        local mx, my = love.mouse.getPosition()
        -- Convert to virtual coordinates (accounting for scaling/letterboxing in main.lua)
        local vx = (mx - gTransX) / gScale
        local vy = (my - gTransY) / gScale
        
        -- Convert Global Virtual to Minigame Local (Inverse of GameLoop transform)
        -- GameLoop vars: gameW=800, gameH=450, gameX=(1280-800)/2, gameY=(720-450)/2 + 30
        local gameW, gameH = 800, 450
        local gameX = (1280 - gameW) / 2
        local gameY = (720 - gameH) / 2 + 30
        local mgScale = gameW / 1280
        
        local localX = (vx - gameX) / mgScale
        local localY = (vy - gameY) / mgScale
        
        -- Draw offset: center the glove on the mouse
        local ox = self.cursorImg:getWidth() / 2
        local oy = self.cursorImg:getHeight() / 2
        love.graphics.setColor(1, 1, 1)
        love.graphics.draw(self.cursorImg, localX, localY, 0, 0.3, 0.3, ox, oy)
    end
end

function Minigame:drawBurger(stack, x, y)
    local targetWidth = 200
    local currentY = y

    -- Draw from bottom up
    for i, ing in ipairs(stack) do
        love.graphics.setColor(1, 1, 1)
        
        local scale = targetWidth / ing.img:getWidth()
        local h = ing.img:getHeight() * scale
        
        -- Center horizontally on X
        local drawX = x - (ing.img:getWidth() * scale) / 2
        
        -- Adjust Y based on offset (how much this layer "sinks" into the previous or just spacing)
        -- The loop moves UP, so we decrease Y.
        -- But images are drawn from top-left.
        -- We want the bottom of the image to sit on the previous one.
        
        -- For the first item (bun bottom), we define its base Y.
        -- Subsequent items stack on top.
        
        -- ACTUALLY, simpler approach:
        -- Track a 'stackHeight' variable.
        
        currentY = currentY - (ing.offset * 1.5) -- Overlap/Height factor
        
        -- Draw the image
        love.graphics.draw(ing.img, drawX, currentY, 0, scale, scale)
        
        -- The next item should be drawn slightly higher up (negative Y direction)
        -- We effectively moved currentY up by the offset for the NEXT item to use as a base?
        -- No, let's step back.
        -- Logic:
        -- Bottom Bun: Y = 600.
        -- Patty: Y = 600 - patty_overlap.
        
        -- Better loop:
        -- Keep a running Y cursor.
        -- For each item, move cursor UP by some amount (height of item - overlap).
    end
end

function Minigame:mousepressed(x, y, button)
    if self.won or self.lost then return end
    if button ~= 1 then return end

    -- Check button clicks
    for _, btn in ipairs(self.ingredientButtons) do
        if x >= btn.x and x <= btn.x + btn.w and y >= btn.y and y <= btn.y + btn.h then
            self:addIngredient(btn.ingredient)
            return
        end
    end
end

function Minigame:addIngredient(ingredient)
    local nextIndex = #self.currentStack + 1
    local targetIngredient = self.targetStack[nextIndex]

    if targetIngredient and targetIngredient.name == ingredient.name then
        table.insert(self.currentStack, ingredient)
        
        if #self.currentStack == #self.targetStack - 1 then
             -- Add top bun automatically
             table.insert(self.currentStack, INGREDIENTS.BUN_TOP)
             self.won = true
             if self.soundHappy then self.soundHappy:play() end
             self.endTimer = 1.5 -- Show win screen for 1.5 seconds
        end
    else
        self.timer = self.timer + 1
    end
end

return Minigame
