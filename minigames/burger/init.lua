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
    self.clickBonus = 5 + (difficulty * 2)

    -- Load Images if not already loaded (caching could do this globally, but per-game is fine here)
    if not self.imagesLoaded then
        for k, v in pairs(INGREDIENTS) do
            v.img = love.graphics.newImage(v.imgPath)
        end
        self.bg = love.graphics.newImage("minigames/burger/assets/fond.jpg")
        self.imagesLoaded = true
    end

    -- Define ingredient buttons at the top
    self.ingredientButtons = {}
    local startX = 200
    local startY = 20
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
    
    -- Centering buttons
    local totalWidth = #buttonItems * (size + gap) - gap
    startX = (1280 - totalWidth) / 2

    for i, ing in ipairs(buttonItems) do
        table.insert(self.ingredientButtons, {
            x = startX + (i-1) * (size + gap),
            y = startY,
            w = size,
            h = size,
            ingredient = ing
        })
    end

    -- Generate Target Burger
    self.targetStack = {}
    table.insert(self.targetStack, INGREDIENTS.BUN_BOTTOM)
    
    local numIngredients = 3 + math.floor(difficulty)
    if numIngredients > 12 then numIngredients = 12 end

    for i = 1, numIngredients do
        local randIng = LOGIC_INGREDIENTS[math.random(#LOGIC_INGREDIENTS)]
        table.insert(self.targetStack, randIng)
    end
    
    table.insert(self.targetStack, INGREDIENTS.BUN_TOP)
    
    -- Adjust time based on number of ingredients to be fair
    self.maxTime = 2 + (numIngredients * 0.8)

    -- Current Player Stack
    self.currentStack = {}
    table.insert(self.currentStack, INGREDIENTS.BUN_BOTTOM)
end

function Minigame:update(dt)
    if self.won then return "won" end
    if self.lost then return "lost" end
    
    self.timer = self.timer + dt
    if self.timer >= self.maxTime then
        self.lost = true
        return "lost"
    end
    
    return nil
end

function Minigame:draw()
    -- Draw Background
    love.graphics.setColor(1, 1, 1)
    if self.bg then
        local sx = 1280 / self.bg:getWidth()
        local sy = 720 / self.bg:getHeight()
        love.graphics.draw(self.bg, 0, 0, 0, sx, sy)
    else
        love.graphics.setColor(0.95, 0.95, 0.9)
        love.graphics.rectangle("fill", 0, 0, 1280, 720)
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
        
        love.graphics.setColor(0, 0, 0)
        love.graphics.printf(btn.ingredient.name, btn.x, btn.y + btn.h + 5, btn.w, "center")
    end

    -- Draw Target Burger (Left)
    local targetX = 350
    local targetY = 600
    self:drawBurger(self.targetStack, targetX, targetY)

    -- Draw Current Burger (Right)
    local currentX = 850
    local currentY = 600
    self:drawBurger(self.currentStack, currentX, currentY)
    
    -- Draw Timer
    love.graphics.setColor(0, 0, 0)
    love.graphics.newFont(25)
    love.graphics.print("Temps: " .. string.format("%.1f", self.maxTime - self.timer), 580, 200)
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
        end
    else
        self.timer = self.timer + 1
    end
end

return Minigame
