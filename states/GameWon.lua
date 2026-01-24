-- states/GameWon.lua
local Button = require 'utils.Button'
local GameWon = {}

-- Configurable Credits Text
local CREDITS_TEXT = {
    "Super sweet clic party bonaza 2000",
    "",
    "Merci d'avoir joue !",
    "",
    "Cliquez pour celebrer !",
    "",
    "--- DEVELOPPEURS ---",
    "Théo DELAUDE",
    "Romain LECHENE",
    "A. Jakubiak",
    "Enzo GOMEZ GONZALEZ",
    "Théo MORTREUX",
    "Samuel TITTELEIN",
    "Etienne FOCQUET",
    "",
    "--- ATTRIBUTIONS ---",
    "cat meowing.wav by timtube",
    "https://freesound.org/s/61259/",
    "License: Attribution NonCommercial 4.0",
    "",
    "Kampina forest spring009 190322_1321.wav by klankbeeld",
    "https://freesound.org/s/546179/",
    "License: Attribution 4.0",
    "",
    "pine forest Kampina NL 06 190908_0072.wav by klankbeeld",
    "https://freesound.org/s/487448/",
    "License: Attribution 4.0",
    "",
    "Outer space by Victor_Natas",
    "https://freesound.org/s/612070/",
    "License: Attribution 4.0",
    "",
    "Zombie_015.wav by Dreadwolf910",
    "https://freesound.org/s/541630/",
    "License: Attribution NonCommercial 4.0",
    "",
    "scary-night-at-forest.wav by serop2012",
    "https://freesound.org/s/169458/",
    "License: Attribution NonCommercial 3.0",
    "",
    "--- OUTILS UTILISES ---",
    "LOVE2D",
    "",
    "--- REMERCIEMENTS ---",
    "A Romain Wallon, le meilleur coach de tout les temps!",
    "A toute l'equipe Game Jam !",
    "Et a VOUS pour vos clics !",
    "",
    "",
    "",
    "Fin."
}

function GameWon:enter()
    self.buttons = {}
    local w, h = 1280, 720

    self.scrollY = h + 50 -- Start below screen
    self.scrollSpeed = 60 -- Pixels per second
    self.finished = false

    self.fireworks = {}
    self.clickCountAtEnd = nil

    -- Continue counting clicks?
    -- User request: "Continue de compter les clics." until the end.
    -- gGameLost = false -- Ensure we can click (main.lua handles this)
    -- Actually game logic in main.lua checks 'gGameLost' to stop counting usually.
    -- We'll manually handle click counting here if main.lua doesn't.
    -- But main.lua says: if not gGameLost then count.
    -- So we set gGameLost = false to ensure clicks count.
    gGameLost = false

    self.fonts = {
        title = love.graphics.newFont(40),
        header = love.graphics.newFont(30),
        normal = love.graphics.newFont(26),
        small = love.graphics.newFont(20)
    }

    -- Create Gradient Mesh once
    local meshData = {
        { 0, 0, 0, 0, 0, 0,   0, 1 }, -- Top Left (Black)
        { w, 0, 0, 0, 0, 0,   0, 1 }, -- Top Right (Black)
        { w, h, 0, 0, 1, 0.5, 0, 1 }, -- Bottom Right (Orange)
        { 0, h, 0, 0, 1, 0.5, 0, 1 }  -- Bottom Left (Orange)
    }
    self.gradientMesh = love.graphics.newMesh(meshData, "fan", "static")

    -- Load Firework Sound
    self.sndFirework = nil
    if love.filesystem.getInfo("states/assets/firework.ogg") then
        self.sndFirework = love.audio.newSource("states/assets/firework.ogg", "static")
    end
end

function GameWon:update(dt)
    if not self.finished then
        self.scrollY = self.scrollY - self.scrollSpeed * dt

        -- Check if finished
        -- Estimate height: #CREDITS_TEXT * 50
        local totalHeight = #CREDITS_TEXT * 50
        if self.scrollY < -totalHeight - 100 then
            self:finishCredits()
        end
    end

    -- Update Fireworks
    for i = #self.fireworks, 1, -1 do
        local fw = self.fireworks[i]
        fw.life = fw.life - dt
        fw.x = fw.x + fw.vx * dt
        fw.y = fw.y + fw.vy * dt
        fw.vy = fw.vy + 200 * dt -- Gravity

        if fw.life <= 0 then
            table.remove(self.fireworks, i)
        end
    end
end

function GameWon:finishCredits()
    self.finished = true
    self.clickCountAtEnd = gClickCount

    -- Create Button
    local w, h = 1280, 720
    table.insert(self.buttons, Button.new("Retour Accueil", w / 2 - 150, h - 150, 300, 60, function()
        -- Reset game and change to menu
        gResetGame()
        gStateMachine:change('menu')
    end))
end

function GameWon:draw()
    local w, h = 1280, 720

    -- Gradient Background (Black -> Orange)
    love.graphics.draw(self.gradientMesh)

    -- Draw Fireworks
    for _, fw in ipairs(self.fireworks) do
        love.graphics.setColor(fw.r, fw.g, fw.b, fw.life / fw.maxLife)
        love.graphics.circle("fill", fw.x, fw.y, 4)
    end

    -- Draw Credits Text
    if not self.finished then
        for i, line in ipairs(CREDITS_TEXT) do
            local y = self.scrollY + (i - 1) * 50
            if y > -50 and y < h + 50 then
                if i == 1 then
                    love.graphics.setColor(1, 0.8, 0.2) -- Gold title
                    love.graphics.setFont(self.fonts.title)
                elseif string.sub(line, 1, 3) == "---" then
                    love.graphics.setColor(0.6, 0.6, 1) -- Section Header
                    love.graphics.setFont(self.fonts.header)
                else
                    love.graphics.setColor(1, 1, 1)
                    love.graphics.setFont(self.fonts.normal)
                end

                love.graphics.printf(line, 0, y, w, "center")
            end
        end
    end

    -- Final Screen
    if self.finished then
        love.graphics.setColor(1, 1, 1)
        love.graphics.setFont(self.fonts.title)
        love.graphics.printf("MERCI D'AVOIR JOUE !", 0, h / 2 - 100, w, "center")

        love.graphics.setColor(1, 0.8, 0.2)
        love.graphics.printf("Score Final: " .. tostring(gClickCount), 0, h / 2, w, "center")

        for _, btn in ipairs(self.buttons) do
            btn:draw()
        end
    else
        -- No click count indicator here anymore
    end
end

function GameWon:mousepressed(x, y, button)
    -- Fireworks!
    for i = 1, 20 do
        table.insert(self.fireworks, {
            x = x,
            y = y,
            vx = math.random(-200, 200),
            vy = math.random(-200, 200),
            life = math.random(0.5, 1.5),
            maxLife = 1.0,
            r = math.random(),
            g = math.random(),
            b = math.random()
        })
    end

    -- Play Firework Sound
    if self.sndFirework then
        self.sndFirework:stop()
        self.sndFirework:play()
    end

    -- Count click (if not finished)
    if not self.finished then
        gClickCount = gClickCount + gClickPower
    end

    -- Button interaction
    for _, btn in ipairs(self.buttons) do
        btn:clicked(x, y)
    end
end

return GameWon
