-- states/Shop.lua
local Button = require 'utils.Button'
local Shop = {}

function Shop:enter(params)
    self.score = params.score or 0
    self.difficulty = params.difficulty or 1
    self.buttons = {}
    self.shopItems = {}

    -- Scan for items
    local itemsDir = "items"
    local files = love.filesystem.getDirectoryItems(itemsDir)
    local availableItems = {}

    for _, file in ipairs(files) do
        local info = love.filesystem.getInfo(itemsDir .. "/" .. file)
        if info.type == "directory" then
            local itemPath = itemsDir .. "." .. file .. ".data"
            local success, itemModule = pcall(require, itemPath)
            if success and not itemModule.bought then
                table.insert(availableItems, itemModule)
            end
        end
    end

    -- Select random items (up to 3)
    for i = 1, 3 do
        if #availableItems == 0 then break end
        local idx = math.random(#availableItems)
        table.insert(self.shopItems, availableItems[idx])
        table.remove(availableItems, idx)
    end

    -- Continue Button
    table.insert(self.buttons, Button.new("Continue", 1280 / 2 - 100, 600, 200, 50, function()
        gStateMachine:change('game', { score = self.score, difficulty = self.difficulty, continue = true })
    end))

    -- Buy Buttons
    for i, item in ipairs(self.shopItems) do
        local btnX = 200 + (i - 1) * 350
        local btnY = 400
        table.insert(self.buttons, Button.new("Buy", btnX, btnY, 100, 40, function()
            self:buyItem(item, i)
        end))
    end
end

function Shop:buyItem(item, index)
    if gClickCount >= item.price then
        gClickCount = gClickCount - item.price
        item.bought = true
        item:onBuy()

        -- Remove from shop display
        -- Ideally we disable the button or remove it, but for simplicity let's just mark it
        -- Actually finding the button to remove is tricky with this structure.
        -- Let's just rebuild buttons or keep it simple:
        -- Reload shop? Or just nullify the item slot?

        -- Let's just toggle 'bought' status and redraw differently?
        -- For now, simple approach:
        self.buttons = {} -- Clear buttons and rebuild including continue

        -- Re-add continue
        table.insert(self.buttons, Button.new("Continue", 1280 / 2 - 100, 600, 200, 50, function()
            gStateMachine:change('game', { score = self.score, difficulty = self.difficulty, continue = true })
        end))

        -- Re-add buy buttons, but check if bought
        for i, shopItem in ipairs(self.shopItems) do
            local btnX = 200 + (i - 1) * 350
            local btnY = 400
            if not shopItem.bought then
                table.insert(self.buttons, Button.new("Buy", btnX, btnY, 100, 40, function()
                    self:buyItem(shopItem, i)
                end))
            end
        end
    end
end

function Shop:update(dt)
end

function Shop:draw()
    love.graphics.clear(0.2, 0.1, 0.2)
    love.graphics.setColor(1, 1, 1)
    love.graphics.newFont(40)
    love.graphics.printf("SHOP SCREEN", 0, 50, 1280, "center")

    love.graphics.newFont(20)
    love.graphics.printf("Click Power: " .. gClickPower, 0, 120, 1280, "center")

    -- Draw Items
    for i, item in ipairs(self.shopItems) do
        local x = 200 + (i - 1) * 350
        local y = 200

        love.graphics.setColor(1, 1, 1)
        love.graphics.rectangle("line", x, y, 200, 250)

        love.graphics.printf(item.name, x, y + 10, 200, "center")

        -- Draw item sprite
        if item.draw then
            love.graphics.push()
            -- Center sprite in box roughly
            item:draw(x + 80, y + 80, 2)
            love.graphics.pop()
        end

        if item.bought then
            love.graphics.setColor(0, 1, 0)
            love.graphics.printf("BOUGHT", x, y + 200, 200, "center")
        else
            love.graphics.setColor(1, 1, 0)
            love.graphics.printf("Price: " .. item.price, x, y + 160, 200, "center")
        end
    end

    for _, btn in ipairs(self.buttons) do
        btn:draw()
    end
end

function Shop:mousepressed(x, y, button)
    for _, btn in ipairs(self.buttons) do
        btn:clicked(x, y)
    end
end

return Shop
