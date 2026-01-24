---@diagnostic disable: undefined-global
local Minigame = {
    name = 'letterbox',
    instruction = "POSTE !"
}

function Minigame:enter(difficulty)
    self.difficulty = difficulty or 1
    self.state = nil

    -- Color Definitions (8 total for max mailbox count)
    self.colors = {
        { name = "ROUGE",   rgb = { 1, 0, 0 } },
        { name = "VERT",    rgb = { 0, 1, 0 } },
        { name = "BLEU",    rgb = { 0, 0, 1 } },
        { name = "JAUNE",   rgb = { 1, 1, 0 } },
        { name = "MAGENTA", rgb = { 1, 0, 1 } },
        { name = "CYAN",    rgb = { 0, 1, 1 } },
        { name = "ORANGE",  rgb = { 1, 0.5, 0 } },
        { name = "BLANC",   rgb = { 1, 1, 1 } }
    }

    -- Difficulty Settings
    -- numBoxes (3 to 8, increases every 2 levels)
    self.numBoxes = math.min(8, 3 + math.floor((self.difficulty - 1) / 2))

    -- Mismatch Probability
    -- Level 1: 0% mismatch
    -- Even levels: 100% mismatch
    -- Odd levels (3+): 25% mismatch
    if self.difficulty == 1 then
        self.mismatchProb = 0
    elseif self.difficulty % 2 == 0 then
        self.mismatchProb = 1
    else
        self.mismatchProb = 0.25
    end

    -- SPECIAL OVERRIDE: Once all 8 boxes are available, ALWAYS use 25% mismatch
    if self.numBoxes == 8 then
        self.mismatchProb = 0.25
    end

    -- Time limit per round (2s per box)
    self.timeLimit = self.numBoxes * 2
    self.timer = self.timeLimit

    -- Round count: Start 3, max 10 at level 12
    -- formula: 3 + (diff-1) * (7/11)
    self.totalRounds = math.min(10, math.floor(3 + (self.difficulty - 1) * (7 / 11)))
    self.round = 1
    self.lastCombo = nil -- Track last (word, color) to prevent repeats

    self.font40 = love.graphics.newFont(40)
    self.font24 = love.graphics.newFont(24)

    -- Asset Loading
    self.bgImage = love.graphics.newImage("minigames/letterbox/assets/house.jpg")
    self.boxImage = love.graphics.newImage("minigames/letterbox/assets/letterbox.png")
    self.mailSound = love.audio.newSource("minigames/letterbox/assets/mail.ogg", "static")

    self:nextRound()
end

function Minigame:nextRound()
    if self.round > self.totalRounds then
        self.state = 'won'
        return
    end

    -- Reset timer for the new round
    self.timer = self.timeLimit

    -- Pick Target Color (Meaning) and Ink Color with no-repeat rule
    repeat
        -- Pick meaning
        self.targetIndex = math.random(self.numBoxes)

        -- Determine ink
        local rand = math.random()
        if rand < self.mismatchProb then
            -- Mismatch: pick a DIFFERENT color for the ink
            repeat
                self.inkIndex = math.random(self.numBoxes)
            until self.numBoxes <= 1 or self.inkIndex ~= self.targetIndex
        else
            -- Match: ink is the same as meaning
            self.inkIndex = self.targetIndex
        end
        -- Combine meaning and ink indices to check for repeats against last letter
    until not self.lastCombo or (self.targetIndex ~= self.lastCombo.word or self.inkIndex ~= self.lastCombo.ink)

    -- Save this combo for next time
    self.lastCombo = { word = self.targetIndex, ink = self.inkIndex }

    -- Setup box layout (Two lines)
    self.boxes = {}
    local boxWidth = 106
    local boxHeight = 149
    local spacingX = 30
    local spacingY = 15

    local boxesPerRow = math.ceil(self.numBoxes / 2)
    local firstRowBoxes = boxesPerRow
    local secondRowBoxes = self.numBoxes - firstRowBoxes

    for i = 1, self.numBoxes do
        local row = i <= firstRowBoxes and 0 or 1
        local col = (i <= firstRowBoxes) and (i - 1) or (i - firstRowBoxes - 1)
        local inThisRow = row == 0 and firstRowBoxes or secondRowBoxes

        local totalRowWidth = (boxWidth * inThisRow) + (spacingX * (inThisRow - 1))
        local startX = (1280 - totalRowWidth) / 2

        table.insert(self.boxes, {
            x = startX + col * (boxWidth + spacingX),
            y = 70 + row * (boxHeight + spacingY), -- Moved up from 105
            w = boxWidth,
            h = boxHeight,
            color = self.colors[i]
        })
    end
end

function Minigame:update(dt)
    if self.state == 'won' then return 'won' end
    if self.state == 'lost' then return 'lost' end

    self.timer = self.timer - dt
    if self.timer <= 0 then
        self.state = 'lost'
        return 'lost'
    end
end

function Minigame:draw()
    -- Background (House)
    love.graphics.setColor(1, 1, 1)
    local bgW, bgH = self.bgImage:getDimensions()
    love.graphics.draw(self.bgImage, 0, 0, 0, 1280 / bgW, 720 / bgH)

    -- Overlay to make UI more readable
    love.graphics.setColor(0, 0, 0, 0.4)
    love.graphics.rectangle("fill", 0, 0, 1280, 100)

    -- UI
    love.graphics.setColor(1, 1, 1)
    love.graphics.setFont(self.font24)
    local displayRound = math.min(self.round, self.totalRounds)
    love.graphics.printf("Boîte aux lettres : Manche " .. displayRound .. "/" .. self.totalRounds, 0, 40, 1280, "center")
    love.graphics.printf(string.format("Temps : %.1f", self.timer), 0, 70, 1280, "center")

    -- Draw Color Boxes (Using tinted sprites)
    for i, box in ipairs(self.boxes) do
        -- Draw Tinted Sprite
        love.graphics.setColor(box.color.rgb)
        local imgW, imgH = self.boxImage:getDimensions()
        love.graphics.draw(self.boxImage, box.x, box.y, 0, box.w / imgW, box.h / imgH)
    end

    -- Draw Letter (Bottom - Smaller Envelope Style)
    local lw, lh = 300, 180 -- Shrunk from 400x250
    local letterX = 640 - (lw / 2)
    local letterY = 490     -- Moved down from 400

    -- Main Body (Slightly off-white for "paper" feel)
    love.graphics.setColor(0.98, 0.98, 0.95)
    love.graphics.rectangle("fill", letterX, letterY, lw, lh)

    -- Envelope fold (Back side style)
    love.graphics.setColor(0.9, 0.9, 0.85)
    love.graphics.polygon("fill", letterX, letterY, letterX + lw, letterY, letterX + lw / 2, letterY + lh / 2)

    -- Stamp
    love.graphics.setColor(0.8, 0.3, 0.3)
    love.graphics.rectangle("fill", letterX + lw - 50, letterY + 15, 35, 45)
    love.graphics.setColor(1, 1, 1, 0.5)
    love.graphics.rectangle("line", letterX + lw - 46, letterY + 19, 27, 37)

    -- Address lines (Bottom left)
    love.graphics.setColor(0.7, 0.7, 0.7)
    love.graphics.setLineWidth(2)
    love.graphics.line(letterX + 25, letterY + lh - 50, letterX + 150, letterY + lh - 50)
    love.graphics.line(letterX + 25, letterY + lh - 40, letterX + 120, letterY + lh - 40)

    -- Border
    love.graphics.setColor(0.3, 0.3, 0.3)
    love.graphics.setLineWidth(3)
    love.graphics.rectangle("line", letterX, letterY, lw, lh)

    -- Draw the Text (The Trick)
    local colorName = self.colors[self.targetIndex].name
    local inkColor = self.colors[self.inkIndex].rgb

    love.graphics.setFont(self.font40)

    -- Visibility Fix: Add a small black shadow/outline
    love.graphics.setColor(0, 0, 0)
    love.graphics.printf(colorName, letterX + 2, letterY + lh / 2 - 18, lw, "center")

    love.graphics.setColor(inkColor)
    love.graphics.printf(colorName, letterX, letterY + lh / 2 - 20, lw, "center")
end

function Minigame:mousepressed(x, y, button)
    if button == 1 then
        for i, box in ipairs(self.boxes) do
            if x >= box.x and x <= box.x + box.w and y >= box.y and y <= box.y + box.h then
                if i == self.targetIndex then
                    -- Correct!
                    self.mailSound:clone():play()
                    self.round = self.round + 1
                    self:nextRound()
                else
                    -- Wrong!
                    self.state = 'lost'
                end
            end
        end
    end
end

return Minigame
