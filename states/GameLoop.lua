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
    for i = 1, 5 do
        table.insert(self.availableMinigames, require('minigames.minigame' .. i .. '.init'))
    end
    -- Add stocks-timing minigame
    table.insert(self.availableMinigames, require('minigames.stocks-timing.init'))

    self.currentMinigame = nil
    self.currentMinigameIndex = 0

    self.phase = 'start' -- start, intro, play, result, lost
    self.timer = 0
    self.resultMessage = ""

    self:nextLevel()
end

function GameLoop:nextLevel()
    -- Check for shop
    if self.mode ~= 'single' and self.gamesPlayedSinceShop >= 5 then
        gStateMachine:change('shop', { score = self.score, difficulty = self.difficulty })
        return
    end

    if self.mode == 'single' and self.minigameCount > 0 then
        gStateMachine:change('selector')
        return
    end

    local idx
    if self.mode == 'single' then
        idx = self.targetGameIndex
    else
        idx = math.random(#self.availableMinigames)
    end

    self.currentMinigame = self.availableMinigames[idx]
    self.currentMinigameIndex = idx

    -- Increase difficulty slightly or logic here
    self.minigameCount = self.minigameCount + 1
    self.gamesPlayedSinceShop = self.gamesPlayedSinceShop + 1

    self.phase = 'intro'
    self.timer = 2 -- 2 seconds intro

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
            self.phase = 'result'
            self.resultMessage = "YOU WON!"
            self.timer = 1 -- Show result for 1s
            self.score = self.score + 1

            -- Add click bonus
            local bonus = self.currentMinigame.clickBonus or 10
            gClickCount = gClickCount + bonus

            self.difficulty = self.difficulty + 0.1 -- Example difficulty increase
        elseif result == 'lost' then
            gStateMachine:change('lost', { score = self.score })
        end
    elseif self.phase == 'result' then
        self.timer = self.timer - dt
        if self.timer <= 0 then
            self:nextLevel()
        end
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
        love.graphics.printf("GAME UI TEMPLATE - Score (Clicks): " .. gClickCount, 0, 20, 1280, "center")

        -- Clip and Draw Game
        love.graphics.setScissor(gTransX + (gameX * gScale), gTransY + (gameY * gScale), gameW * gScale, gameH * gScale)

        love.graphics.push()
        love.graphics.translate(gameX, gameY)
        -- If minigames are built for 1280x720, we might need to scale them down
        -- Or just let them draw. The generic minigames use 'printf' centered at 1280.
        -- To make them fit, let's scale them.
        local mgScale = gameW / 1280
        love.graphics.scale(mgScale, mgScale)

        self.currentMinigame:draw()

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
        love.graphics.printf(string.format("%.1f", self.timer), 0, 350, 1280, "center")
    elseif self.phase == 'result' then
        love.graphics.setColor(0, 0, 0, 0.7)
        love.graphics.rectangle("fill", 0, 0, 1280, 720)
        love.graphics.setColor(0, 1, 0)
        love.graphics.printf(self.resultMessage, 0, 300, 1280, "center")
    end
end

function GameLoop:keypressed(key)
    if key == 'escape' then
        gStateMachine:push('pause') -- Pause menu is on top
    else
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
    end
end

return GameLoop
