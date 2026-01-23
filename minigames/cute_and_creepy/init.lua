local Minigame = {}

-- Cute and Creepy Minigame
-- Goal: Drag and drop images into correct categories (Cute or Creepy)
-- Controls: Mouse drag and drop

function Minigame:enter(difficulty)
    self.difficulty = difficulty or 1
    
    -- Difficulty settings
    -- Grid size: 4x5 at difficulty 1, 4x6 at difficulty 3, 4x7 at difficulty 5, etc.
    self.gridCols = 5 + math.floor((self.difficulty - 1) * 0.5)
    self.gridRows = 4
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
    local cuteNames = {"Puppy", "Kitten", "Baby", "Bunny", "Flower", "Butterfly", "Heart", "Angel"}
    local creepyNames = {"Ghost", "Skull", "Spider", "Zombie", "Witch", "Monster", "Demon", "Devil"}
    
    local cutePerGrid = math.ceil(self.gridSize / 2)
    local creepyPerGrid = self.gridSize - cutePerGrid
    
    -- Create cute items
    for i = 1, cutePerGrid do
        local idx = ((i - 1) % #cuteNames) + 1
        table.insert(items, {
            id = i,
            type = "cute",
            name = cuteNames[idx],
            x = 0,
            y = 0,
            w = 80,
            h = 60,
            placed = false,
            placed_in = nil
        })
    end
    
    -- Create creepy items
    for i = 1, creepyPerGrid do
        local idx = ((i - 1) % #creepyNames) + 1
        table.insert(items, {
            id = cutePerGrid + i,
            type = "creepy",
            name = creepyNames[idx],
            x = 0,
            y = 0,
            w = 80,
            h = 60,
            placed = false,
            placed_in = nil
        })
    end
    
    -- Shuffle items
    for i = #items, 2, -1 do
        local j = math.random(i)
        items[i], items[j] = items[j], items[i]
    end
    
    -- Position items in grid
    local gridItemWidth = 100
    local gridItemHeight = 80
    local startX = 100
    local startY = 100
    local spacingX = 120
    local spacingY = 100
    
    for idx, item in ipairs(items) do
        local row = math.floor((idx - 1) / self.gridCols)
        local col = (idx - 1) % self.gridCols
        item.x = startX + col * spacingX
        item.y = startY + row * spacingY
    end
    
    return items
end

function Minigame:initializeCategories()
    local w, h = 1280, 720
    local zoneHeight = 180
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
    -- Background
    love.graphics.setColor(1, 1, 1)
    love.graphics.rectangle("fill", 0, 0, 1280, 720)
    
    -- Header
    love.graphics.setColor(0, 0, 0)
    love.graphics.setFont(love.graphics.newFont(28))
    love.graphics.printf("CUTE AND CREEPY", 0, 20, 1280, "center")
    
    -- Timer and stats
    love.graphics.setFont(love.graphics.newFont(16))
    love.graphics.printf("TIME: " .. math.ceil(math.max(0, self.timer)), 50, 70, 200, "left")
    
    -- Draw categories (drop zones)
    for name, cat in pairs(self.categories) do
        love.graphics.setColor(cat.color[1], cat.color[2], cat.color[3])
        love.graphics.rectangle("fill", cat.x, cat.y, cat.w, cat.h)
        love.graphics.setColor(0, 0, 0)
        love.graphics.setLineWidth(3)
        love.graphics.rectangle("line", cat.x, cat.y, cat.w, cat.h)
        
        -- Category label
        love.graphics.setColor(0, 0, 0)
        love.graphics.setFont(love.graphics.newFont(18))
        love.graphics.printf(cat.name, cat.x, cat.y + 10, cat.w, "center")

    end
    
    -- Draw unplaced items
    love.graphics.setFont(love.graphics.newFont(14))
    for _, item in ipairs(self.items) do
        if not item.placed then
            local itemType = item.type == "cute" and "CUTE" or "CREEPY"
            
            -- Item rectangle
            if self.draggingItem == item then
                love.graphics.setColor(1, 1, 0, 0.8)
            else
                love.graphics.setColor(0.8, 0.8, 0.8)
            end
            love.graphics.rectangle("fill", item.x, item.y, item.w, item.h)
            
            -- Item border
            love.graphics.setColor(0, 0, 0)
            love.graphics.setLineWidth(2)
            love.graphics.rectangle("line", item.x, item.y, item.w, item.h)
            
            -- Item text
            love.graphics.setColor(0, 0, 0)
            love.graphics.printf(item.name, item.x, item.y + 8, item.w, "center")
            love.graphics.printf("(" .. itemType .. ")", item.x, item.y + 30, item.w, "center")
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

return Minigame
