
local Minigame = {}

-- Cute and Creepy Minigame
-- Goal: Drag and drop images into correct categories (Cute or Creepy)
-- Controls: Mouse drag and drop

function Minigame:enter(difficulty)
    self.difficulty = difficulty or 1
    
    -- Load images
    local basePath = "minigames/cute_and_creepy/assets/images/"
    self.backgroundImage = love.graphics.newImage(basePath .. "background.png")
    
    -- Load cute images
    self.cuteImages = {
        love.graphics.newImage(basePath .. "cute/calamar.png"),
        love.graphics.newImage(basePath .. "cute/piaf.png"),
        love.graphics.newImage(basePath .. "cute/penguin.png"),
        love.graphics.newImage(basePath .. "cute/star.png"),
        love.graphics.newImage(basePath .. "cute/waifu.png"),
    }
    
    -- Load creepy images
    self.creepyImages = {
        love.graphics.newImage(basePath .. "creepy/evil.png"),
        love.graphics.newImage(basePath .. "creepy/skeleton.png"),
        love.graphics.newImage(basePath .. "creepy/skull.png"),
        love.graphics.newImage(basePath .. "creepy/troll_face.png"),
        love.graphics.newImage(basePath .. "creepy/clown.png"),
    }
    
    -- Difficulty settings
    -- Grid size: 3 lines for items
    self.gridCols = 5 + math.floor((self.difficulty - 1) * 0.5)
    self.gridRows = 3
    -- Safety clamps to avoid tiny grids if difficulty is passed as 0/nil
    if not self.gridCols or self.gridCols < 5 then self.gridCols = 5 end
    if not self.gridCols or self.gridCols > 7 then self.gridCols = 7 end

    self.gridSize = self.gridCols * self.gridRows
    
    -- Time limit scales with difficulty (more items = more time, but harder)
    self.timeLimit = 20 + (self.gridSize * 1.2)
    self.timer = self.timeLimit
    
    self.won = false
    self.lost = false
    self.error = false
    self.maxErrors = 2
    
    -- Generate items (cute or creepy)
    self.items = self:generateItems()
    
    -- Dragging state
    self.draggingItem = nil
    self.dragOffsetX = 0
    self.dragOffsetY = 0
    
    -- Categories (drop zones)
    self.categories = self:initializeCategories()
    
    -- Placed items counter
    self.placedCount = 0
end

function Minigame:generateItems()
    local items = {}
    
    local cutePerGrid = math.ceil(self.gridSize / 2)
    local creepyPerGrid = self.gridSize - cutePerGrid
    
    -- Create cute items
    for i = 1, cutePerGrid do
        local imgIdx = ((i - 1) % #self.cuteImages) + 1
        table.insert(items, {
            id = i,
            type = "cute",
            image = self.cuteImages[imgIdx],
            x = 0,
            y = 0,
            w = 160,
            h = 160,
            placed = false,
            placed_in = nil
        })
    end
    
    -- Create creepy items
    for i = 1, creepyPerGrid do
        local imgIdx = ((i - 1) % #self.creepyImages) + 1
        table.insert(items, {
            id = cutePerGrid + i,
            type = "creepy",
            image = self.creepyImages[imgIdx],
            x = 0,
            y = 0,
            w = 160,
            h = 160,
            placed = false,
            placed_in = nil
        })
    end
    
    -- Shuffle items
    for i = #items, 2, -1 do
        local j = math.random(i)
        items[i], items[j] = items[j], items[i]
    end
    
    -- Position items in grid (3 lines, centered horizontally)
    local gridItemWidth = 120
    local gridItemHeight = 120
    local spacingX = 150
    local spacingY = 140
    
    -- Calculate total width needed and center horizontally
    local totalWidth = (self.gridCols * spacingX) - (spacingX - gridItemWidth)
    local startX = (1280 - totalWidth) / 2
    local startY = 70
    
    for idx, item in ipairs(items) do
        local row = math.floor((idx - 1) / self.gridCols)
        local col = (idx - 1) % self.gridCols
        item.x = startX + col * spacingX
        item.y = startY + row * spacingY
        
        -- Store original image dimensions for aspect ratio
        if item.image then
            item.imgW = item.image:getWidth()
            item.imgH = item.image:getHeight()
        end
    end
    
    return items
end

function Minigame:initializeCategories()
    local w, h = 1280, 720
    local zoneHeight = 240
    local y = h - zoneHeight -- align to bottom
    local halfW = w / 2
    return {
        cute = {
            name = "CUTE",
            x = 0,
            y = y,
            w = halfW,
            h = zoneHeight,
            color = {0.2, 1, 0.5},
            items = {}
        },
        creepy = {
            name = "CREEPY",
            x = halfW,
            y = y,
            w = halfW,
            h = zoneHeight,
            color = {1, 0.2, 0.2},
            items = {}
        }
    }
end

function Minigame:getItemAtMouse(x, y)
    for i = #self.items, 1, -1 do
        local item = self.items[i]
        if not item.placed then
            if x >= item.x and x <= item.x + item.w and y >= item.y and y <= item.y + item.h then
                return item, i
            end
        end
    end
    return nil
end

function Minigame:getCategoryAtPosition(x, y)
    for name, cat in pairs(self.categories) do
        if x >= cat.x and x <= cat.x + cat.w and y >= cat.y and y <= cat.y + cat.h then
            return name, cat
        end
    end
    return nil
end

function Minigame:update(dt)
    if self.won or self.lost then return end
    
    self.timer = self.timer - dt
    if self.timer <= 0 then
        self.lost = true
    end
    
    -- Check win condition
    if self.placedCount == self.gridSize then
        self.won = true
        return "won"
    end
    
    if self.error then
        self.lost = true
        return "lost"
    end
    
    if self.lost then return "lost" end
    return nil
end

function Minigame:draw()
    -- Clear light background
    love.graphics.setColor(0.95, 0.95, 0.95)
    love.graphics.rectangle("fill", 0, 0, 1280, 720)
    
    -- Background image at bottom without deformation
    if self.backgroundImage then
        local bgW = self.backgroundImage:getWidth()
        local bgH = self.backgroundImage:getHeight()
        local scale = 1280 / bgW  -- Scale to fit width
        local scaledH = bgH * scale
        local bgY = 720 - scaledH  -- Position at bottom
        
        love.graphics.setColor(1, 1, 1)
        love.graphics.draw(self.backgroundImage, 0, bgY, 0, scale, scale)
    end
    
    -- Draw timer as dial
    self:drawTimerDial(80, 80)
    
    -- Draw categories (drop zones - invisible but functional)
    -- Les zones existent toujours pour la logique mais ne sont plus dessinées
    -- car le background affiche déjà cute vs creepy
    
    -- Draw unplaced items with images
    for _, item in ipairs(self.items) do
        if not item.placed then
            -- Draw image if available
            if item.image and item.imgW and item.imgH then
                if self.draggingItem == item then
                    love.graphics.setColor(1, 1, 1, 0.8)
                else
                    love.graphics.setColor(1, 1, 1, 1)
                end
                
                -- Draw image without deformation (preserve aspect ratio)
                local scale = math.min(item.w / item.imgW, item.h / item.imgH)
                local drawW = item.imgW * scale
                local drawH = item.imgH * scale
                local offsetX = (item.w - drawW) / 2
                local offsetY = (item.h - drawH) / 2
                
                love.graphics.draw(item.image, item.x + offsetX, item.y + offsetY, 0, scale, scale)
            else
                -- Fallback if image missing
                if self.draggingItem == item then
                    love.graphics.setColor(1, 1, 0, 0.8)
                else
                    love.graphics.setColor(0.8, 0.8, 0.8)
                end
                love.graphics.rectangle("fill", item.x, item.y, item.w, item.h)
                love.graphics.setColor(0, 0, 0)
                love.graphics.setLineWidth(2)
                love.graphics.rectangle("line", item.x, item.y, item.w, item.h)
            end
        end
    end
end

function Minigame:mousepressed(x, y, button)
    if self.won or self.lost then return end
    
    if button == 1 then
        local item = self:getItemAtMouse(x, y)
        if item then
            self.draggingItem = item
            self.dragOffsetX = x - item.x
            self.dragOffsetY = y - item.y
        end
    end
end

function Minigame:mousemoved(x, y)
    if self.draggingItem then
        self.draggingItem.x = x - self.dragOffsetX
        self.draggingItem.y = y - self.dragOffsetY
    end
end

function Minigame:mousereleased(x, y, button)
    if self.won or self.lost then return end
    
    if button == 1 and self.draggingItem then
        local item = self.draggingItem
        local catName = self:getCategoryAtPosition(x, y)
        
        if catName then
            -- Check if dropped in correct category
            if item.type == catName then
                -- Correct!
                item.placed = true
                item.placed_in = catName
                table.insert(self.categories[catName].items, item)
                self.placedCount = self.placedCount + 1
            else
                -- Wrong category!
                self.error = true
            end
        end
        
        self.draggingItem = nil
    end
end

function Minigame:keypressed(key)
    if key == 'w' then self.won = true end -- Debug
    if key == 'l' then self.lost = true end -- Debug
end

function Minigame:drawTimerDial(x, y)
    local radius = 35
    local timeRemaining = math.max(0, self.timer)
    local timePercent = math.min(1, timeRemaining / self.timeLimit)
    
    -- Draw outer circle (background)
    love.graphics.setColor(0.2, 0.2, 0.2)
    love.graphics.circle("fill", x, y, radius)
    
    -- Draw progress arc (colored based on time)
    local color_r = (1 - timePercent) * 0.9 + 0.1  -- Red when time is low
    local color_g = timePercent * 0.8 + 0.2        -- Green when time is high
    local color_b = 0.2
    love.graphics.setColor(color_r, color_g, color_b)
    
    -- Draw arc from top, going clockwise
    local startAngle = math.pi * 1.5  -- Start at top (12 o'clock)
    local endAngle = startAngle + (timePercent * math.pi * 2)
    
    -- Draw filled arc using multiple triangles
    local segments = 30
    love.graphics.setColor(color_r, color_g, color_b, 0.8)
    
    for i = 0, segments do
        local angle1 = startAngle + (i / segments) * (endAngle - startAngle)
        local angle2 = startAngle + ((i + 1) / segments) * (endAngle - startAngle)
        
        local x1 = x + math.cos(angle1) * radius
        local y1 = y + math.sin(angle1) * radius
        local x2 = x + math.cos(angle2) * radius
        local y2 = y + math.sin(angle2) * radius
        
        love.graphics.polygon("fill", x, y, x1, y1, x2, y2)
    end
    
    -- Draw inner white circle
    love.graphics.setColor(1, 1, 1)
    love.graphics.circle("fill", x, y, radius * 0.6)
    
    -- Draw border
    love.graphics.setColor(0.2, 0.2, 0.2)
    love.graphics.setLineWidth(2)
    love.graphics.circle("line", x, y, radius)
    
    -- Draw time text in center
    love.graphics.setColor(0, 0, 0)
    love.graphics.setFont(love.graphics.newFont(14))
    local timeText = math.ceil(timeRemaining)
    local textW = love.graphics.getFont():getWidth(timeText)
    love.graphics.print(timeText, x - textW / 2, y - 7)
end

return Minigame

