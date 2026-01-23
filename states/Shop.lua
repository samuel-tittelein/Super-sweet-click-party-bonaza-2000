-- states/Shop.lua
local Button = require 'utils.Button'
local Shop = {}

function Shop:enter(params)
    params = params or {}
    self.score = params.score or 0
    self.difficulty = params.difficulty or 1
    self.buttons = {}
    self.shopItems = {}

    -- Load Background Images
    -- Using safe loading or pcall to avoid crash if missing
    local function load(path) return love.graphics.newImage(path) end
    self.bgAccueil = load('states/shop_accueil.jpg')
    self.bgChoix1 = load('states/shope_choix1.jpg') 
    self.bgChoix2 = load('states/shop_choix2.jpg')
    self.bgChoix3 = load('states/shop_choix3.jpg')
    
    self.currentBg = self.bgAccueil

    -- Back Button
    table.insert(self.buttons, Button.new("Back", 10, 10, 100, 40, function()
        gStateMachine:change('selector') -- Go back to selector for testing
    end))

    -- Scan for items
    local itemsDir = "items"
    local files = love.filesystem.getDirectoryItems(itemsDir)
    local availableItems = {}

    for _, file in ipairs(files) do
        local info = love.filesystem.getInfo(itemsDir .. "/" .. file)
        if info.type == "directory" then
            -- Try requiring 'init' or 'data' or just folder name
            -- Standard lua require for folder 'items.name' loads 'items/name/init.lua'
            local itemPath = itemsDir .. "." .. file
            local success, itemModule = pcall(require, itemPath .. ".data")
            if not success then
                success, itemModule = pcall(require, itemPath .. ".init")
            end
            if not success then
                success, itemModule = pcall(require, itemPath)
            end

            if success then
                -- Filtering Logic for Item Unlocks
                local themedItems = {
                    ["jeux_de_lettres"] = true,
                    ["informatique_et_etoile"] = true,
                    ["balade_dans_les_bois"] = true,
                    ["cute_and_creepy"] = true,
                    ["chasse_aux_tresors"] = true,
                    ["merveilles_des_profondeurs"] = true,
                    ["maitre_du_temps"] = true,
                    ["legende_etheree"] = true,
                    ["melodie_a_l_infini"] = true,
                    ["fete_des_clics"] = true
                }

                local isLocked = false
                if themedItems[file] then
                    isLocked = true -- All themed items locked by default

                    -- Specific Unlock Conditions
                    if file == "maitre_du_temps" and gUnlockedMinigames["time_matcher"] then
                        isLocked = false
                    elseif file == "melodie_a_l_infini" and gUnlockedMinigames["taiko"] then
                        isLocked = false
                    elseif file == "jeux_de_lettres" and gUnlockedMinigames["letterbox"] then
                        isLocked = false
                    end
                end

                if not isLocked then
                    -- If it's consumable, always add. If not, check if bought.
                    if itemModule.type == 'consumable' or not itemModule.bought then
                        table.insert(availableItems, itemModule)
                    end
                end
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

        if item.type == 'consumable' then
            gInventory[item.key] = (gInventory[item.key] or 0) + 1
        else
            item.bought = true
            item:onBuy()
        end

        -- Check for Win Condition
        local themedItems = {
            "jeux_de_lettres", "informatique_et_etoile", "balade_dans_les_bois",
            "cute_and_creepy", "chasse_aux_tresors", "merveilles_des_profondeurs",
            "maitre_du_temps", "legende_etheree", "melodie_a_l_infini", "fete_des_clics"
        }

        local allBought = true
        for _, theme in ipairs(themedItems) do
            local path = "items." .. theme .. ".data"
            local status, module = pcall(require, path)
            if not status or not module.bought then
                allBought = false
                break
            end
        end

        if allBought then
            gStateMachine:change('won')
            return
        end

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
        
        -- Re-add back button
        table.insert(self.buttons, Button.new("Back", 10, 10, 100, 40, function()
            gStateMachine:change('selector')
        end))

        -- Re-add buy buttons
        for i, shopItem in ipairs(self.shopItems) do
            local btnX = 200 + (i - 1) * 350
            local btnY = 400

            -- If consumable, always show button. If not, show only if not bought.
            if shopItem.type == 'consumable' then
                table.insert(self.buttons, Button.new("Buy", btnX, btnY, 100, 40, function()
                    self:buyItem(shopItem, i)
                end))
            elseif not shopItem.bought then
                table.insert(self.buttons, Button.new("Buy", btnX, btnY, 100, 40, function()
                    self:buyItem(shopItem, i)
                end))
            end
        end
    end
end

function Shop:update(dt)
    -- Scaling logic reverse to get virtual coordinates
    local mx, my = love.mouse.getPosition()
    local vx = (mx - gTransX) / gScale
    local vy = (my - gTransY) / gScale

    -- Define Zones
    -- Left: < 1280/3 approx 426
    -- Center: 426 - 853
    -- Right: > 853
    
    -- Refined with 3 squares logic for testing as requested
    -- Let's say squares are roughly the size of the item display areas:
    -- Item 1: X=200, W=200 -> Range 200-400
    -- Item 2: X=550, W=200 -> Range 550-750 
    -- Item 3: X=900, W=200 -> Range 900-1100
    
    -- User said "zone we can say squares, for testing... hover left square... center... right"
    -- I'll implement simple vertical screen thirds for broader detection or specific squares if implied.
    -- "if on survole l item le plus à gauche" -> hovering the item.
    
    local inLeft = (vx >= 200 and vx <= 400 and vy >= 200 and vy <= 450)
    local inCenter = (vx >= 550 and vx <= 750 and vy >= 200 and vy <= 450)
    local inRight = (vx >= 900 and vx <= 1100 and vy >= 200 and vy <= 450)
    
    if inLeft then
        self.currentBg = self.bgChoix1
    elseif inCenter then
        self.currentBg = self.bgChoix2
    elseif inRight then
        self.currentBg = self.bgChoix3
    else
        self.currentBg = self.bgAccueil
    end
end

function Shop:draw()
    love.graphics.clear(0, 0, 0)
    
    -- Draw Background
    if self.currentBg then
        local sx = 1280 / self.currentBg:getWidth()
        local sy = 720 / self.currentBg:getHeight()
        love.graphics.setColor(1, 1, 1)
        love.graphics.draw(self.currentBg, 0, 0, 0, sx, sy)
    end

    love.graphics.setColor(1, 1, 1)
    love.graphics.newFont(40)
    love.graphics.printf("SHOP SCREEN", 0, 50, 1280, "center")

    love.graphics.newFont(20)
    love.graphics.printf("Click Power: " .. gClickPower .. " | Lives: " .. gLives, 0, 120, 1280, "center")

    -- Draw Items
    for i, item in ipairs(self.shopItems) do
        local x = 200 + (i - 1) * 350
        local y = 200

        -- Draw item box/highlight?
        -- love.graphics.setColor(1, 1, 1)
        -- love.graphics.rectangle("line", x, y, 200, 250)

        love.graphics.printf(item.name, x, y + 10, 200, "center")

        -- Draw item sprite
        if item.draw then
            love.graphics.push()
            -- Center sprite in box roughly
            item:draw(x + 80, y + 80, 2)
            love.graphics.pop()
        end

        if item.bought and item.type ~= 'consumable' then
            love.graphics.setColor(0, 1, 0)
            love.graphics.printf("BOUGHT", x, y + 200, 200, "center")
        else
            love.graphics.setColor(1, 1, 0)
            love.graphics.printf("Price: " .. item.price, x, y + 160, 200, "center")
            if item.type == 'consumable' then
                love.graphics.setColor(1, 1, 1)
                love.graphics.printf("Stock: " .. (gInventory[item.key] or 0), x, y + 185, 200, "center")
            end
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
