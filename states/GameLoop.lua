-- states/GameLoop.lua
local GameLoop = {}

function GameLoop:enter(params)
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
    local minigameList = {'taupe', 'minigame2', 'minigame3', 'minigame4', 'minigame5', 'popup', 'stocks-timing', 'taiko', 'burger' ,'time_matcher', 'catch-stick', 'wait', 'runnerDash', 'find-different', 'cute_and_creepy' }
    for _, name in ipairs(minigameList) do
        local success, mg = pcall(require, 'minigames.' .. name .. '.init')
        if success then
            table.insert(self.availableMinigames, mg)
        else
            error("Failed to load minigame: " .. name .. "\nError: " .. tostring(mg))
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
            self.resultMessage = "YOU WON!"
            self.timer = 5 -- Show result for 5s (Intermission)
            self.score = self.score + 1

            -- Add click bonus
            local bonus = self.currentMinigame.clickBonus or 10
            gClickCount = gClickCount + bonus

            -- Record win for unlocks
            if self.currentMinigame.name then
                gUnlockedMinigames[self.currentMinigame.name] = true
            end

            -- self.difficulty = self.difficulty + 0.1 -- Removing old increment
        elseif result == 'lost' then
            self:stopMinigame()
            gLives = gLives - 1
            if gLives <= 0 then
                gStateMachine:change('lost', { score = self.score })
            else
                self.phase = 'result'
                self.resultMessage = "LIFE LOST!"
                self.timer = 2 -- Short delay before next game
                -- No score increment, no click bonus
            end
        end
    elseif self.phase == 'result' then
        self.timer = self.timer - dt
        if self.timer <= 0 then
            self:nextLevel()
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
    -- Draw black background for UI template logic
    love.graphics.clear(0, 0, 0)

    -- Draw Minigame
    if self.currentMinigame then
        -- Clip or just draw? Requirement said "in a rectangle at the center"
        -- Let's define a game area, e.g. 800x600 centered
        -- or just full screen if minigames are designed 1280x720.
        -- User said: "have the mini games in a rectangle at the center"

        -- Let's make the minigame area a bit smaller to show the "Game UI Template" around it
        local gameW, gameH = 800, 450
        local gameX, gameY = (1280 - gameW) / 2, (720 - gameH) / 2 + 30

        -- Draw UI Text
        love.graphics.setColor(1, 1, 1)
        love.graphics.newFont(30)
        love.graphics.printf("Score: " .. gClickCount .. " | Lives: " .. gLives, 0, 20, 1280, "center")

        -- Clip and Draw Game
        love.graphics.setScissor(gTransX + (gameX * gScale), gTransY + (gameY * gScale), gameW * gScale, gameH * gScale)

        love.graphics.push()
        love.graphics.translate(gameX, gameY)
        -- If minigames are built for 1280x720, we might need to scale them down
        -- Or just let them draw. The generic minigames use 'printf' centered at 1280.
        -- To make them fit, let's scale them.
        local mgScale = gameW / 1280
        love.graphics.scale(mgScale, mgScale)

        love.graphics.push("all") -- Protect global state (fonts, line width, etc.)
        self.currentMinigame:draw()
        love.graphics.pop()

        love.graphics.pop()
        love.graphics.setScissor()

        -- Draw Border around game
        love.graphics.setColor(1, 1, 1)
        love.graphics.setLineWidth(2)
        love.graphics.rectangle("line", gameX, gameY, gameW, gameH)
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
        love.graphics.newFont(20)
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
        love.graphics.setColor(0, 0, 0, 0.7)
        love.graphics.rectangle("fill", 0, 0, 1280, 720)
        love.graphics.setColor(0, 1, 0)
        love.graphics.printf(self.resultMessage, 0, 300, 1280, "center")
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
        self.score = self.score + 1
        local bonus = (self.currentMinigame and self.currentMinigame.clickBonus) or 10
        gClickCount = gClickCount + bonus
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
        -- Need to adjust mouse coordinates to minigame space if we are scaling/translating
        local gameW, gameH = 800, 450
        local gameX, gameY = (1280 - gameW) / 2, (720 - gameH) / 2 + 30
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
        -- Coordinate transform
        local gameW, gameH = 800, 450
        local gameX, gameY = (1280 - gameW) / 2, (720 - gameH) / 2 + 30
        local mgScale = gameW / 1280

        local mx = (x - gameX) / mgScale
        local my = (y - gameY) / mgScale
        self.currentMinigame:mousereleased(mx, my, button)
    end
end

function GameLoop:mousemoved(x, y, dx, dy)
    if self.phase == 'play' and self.currentMinigame.mousemoved then
        -- Coordinate transform
        local gameW, gameH = 800, 450
        local gameX, gameY = (1280 - gameW) / 2, (720 - gameH) / 2 + 30
        local mgScale = gameW / 1280

        local mx = (x - gameX) / mgScale
        local my = (y - gameY) / mgScale
        local mdx = dx / mgScale
        local mdy = dy / mgScale

        self.currentMinigame:mousemoved(mx, my, mdx, mdy)
    end
end

return GameLoop
