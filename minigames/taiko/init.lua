-- minigames/taiko/init.lua
-- Minijeu de rythme façon Taiko no Tatsujin, style pixel art
local Minigame = {}

function Minigame:enter(difficulty)
    self.difficulty = difficulty or 1
    self.timer = 0
    self.timeLimit = 10
    self.won = false
    self.lost = false
    self.score = 0
    self.flashTimer = 0
    self.flashColor = nil
    self.notes = {}
    self.noteSpeed = 350 + 300 * self.difficulty -- vitesse des notes
    self.zoneY1 = 600
    self.zoneY2 = 680
    self.noteRadius = 22
    self.noteCount = 12
    self.clickBonus = 40
    self.missCount = 0 -- Compteur de notes ratées
    -- Génération des notes (gauche/droite/double, réparties sur 10s, avec un peu de hasard)
    local t = 0.7 -- délai avant la première note
    local interval = (self.timeLimit - 1.4) / (self.noteCount - 1)
    for i = 1, self.noteCount do
        local randomOffset = (math.random() - 0.5) * 0.3
        local typ
        -- 25% de notes doubles, le reste aléatoire gauche/droite
        if math.random() < 0.25 then
            typ = 'double'
        else
            typ = (math.random() < 0.5) and 'left' or 'right'
        end
        table.insert(self.notes, {
            type = typ,
            time = t + randomOffset,
            y = -self.noteRadius,
            hit = false,
            missed = false,
            leftHit = false, -- pour les notes doubles
            rightHit = false
        })
        t = t + interval
    end
end

function Minigame:update(dt)
    if self.won then return "won" end
    if self.lost then return "lost" end
    self.timer = self.timer + dt
    -- Mise à jour des notes
    for _, note in ipairs(self.notes) do
        if not note.hit and not note.missed and self.timer >= note.time then
            note.y = note.y + self.noteSpeed * dt
            -- Si la note dépasse la zone de frappe sans être touchée
            if note.y > self.zoneY2 + self.noteRadius then
                note.missed = true
                self.missCount = self.missCount + 1
                if self.missCount >= 3 then
                    self.lost = true
                    return "lost"
                end
            end


        end
    end
    -- Gestion du flash
    if self.flashTimer > 0 then
        self.flashTimer = self.flashTimer - dt
        if self.flashTimer <= 0 then
            self.flashColor = nil
        end
    end
    -- Fin du jeu
    if self.timer >= self.timeLimit then
        local success = 0
        for _, note in ipairs(self.notes) do
            if note.hit then success = success + 1 end
        end
        if success >= math.ceil(self.noteCount * 0.7) then
            self.won = true
            return "won"
        else
            self.lost = true
            return "lost"
        end
    end
    return nil
end

function Minigame:draw()
    -- Fond pixel art
    if self.flashColor then
        love.graphics.setColor(self.flashColor)
    else
        love.graphics.setColor(0.12, 0.12, 0.18)
    end
    love.graphics.rectangle("fill", 0, 0, 1280, 720)
    -- Piste verticale
    love.graphics.setColor(0.25, 0.25, 0.35)
    love.graphics.rectangle("fill", 600, 0, 80, 720)
    -- Zone de frappe
    love.graphics.setColor(0.5, 0.5, 0.7)
    love.graphics.rectangle("fill", 600, self.zoneY1, 80, self.zoneY2 - self.zoneY1)
    -- Bord pixel art
    love.graphics.setColor(0.8, 0.8, 1)
    love.graphics.setLineWidth(3)
    love.graphics.rectangle("line", 600, self.zoneY1, 80, self.zoneY2 - self.zoneY1)
    -- Dessin des notes
    for _, note in ipairs(self.notes) do
        if not note.hit and not note.missed and self.timer >= note.time then
            if note.type == 'double' then
                -- Double note : deux cercles côte à côte
                local colorL = {0.9, 0.2, 0.2}
                local colorR = {0.2, 0.4, 0.9}
                for i = 0, 2 do
                    love.graphics.setColor(colorL)
                    love.graphics.circle("line", 620, note.y, self.noteRadius - i)
                    love.graphics.setColor(colorR)
                    love.graphics.circle("line", 660, note.y, self.noteRadius - i)
                end
                love.graphics.setColor(colorL[1], colorL[2], colorL[3], 0.7)
                love.graphics.circle("fill", 620, note.y, self.noteRadius - 3)
                love.graphics.setColor(colorR[1], colorR[2], colorR[3], 0.7)
                love.graphics.circle("fill", 660, note.y, self.noteRadius - 3)
                -- Affichage de l'état de frappe
                if note.leftHit then
                    love.graphics.setColor(1, 1, 0)
                    love.graphics.setLineWidth(4)
                    love.graphics.circle("line", 620, note.y, self.noteRadius - 1)
                end
                if note.rightHit then
                    love.graphics.setColor(1, 1, 0)
                    love.graphics.setLineWidth(4)
                    love.graphics.circle("line", 660, note.y, self.noteRadius - 1)
                end
                love.graphics.setLineWidth(3)
            else
                local x = (note.type == 'left') and 620 or 660
                local color = (note.type == 'left') and {0.9, 0.2, 0.2} or {0.2, 0.4, 0.9}
                for i = 0, 2 do
                    love.graphics.setColor(color)
                    love.graphics.circle("line", x, note.y, self.noteRadius - i)
                end
                love.graphics.setColor(color[1], color[2], color[3], 0.7)
                love.graphics.circle("fill", x, note.y, self.noteRadius - 3)
                -- Affichage de l'état de frappe pour les notes simples
                if note.hit and note.y >= self.zoneY1 and note.y <= self.zoneY2 then
                    love.graphics.setColor(1, 1, 0)
                    love.graphics.setLineWidth(4)
                    love.graphics.circle("line", x, note.y, self.noteRadius - 1)
                    love.graphics.setLineWidth(3)
                end
            end
        end
    end
    -- Affichage de l'état de clic global (held) sous forme de carrés colorés
    local leftHeld = love.mouse.isDown(1)
    local rightHeld = love.mouse.isDown(2)
    local squareSize = 32
    local ySquares = self.zoneY1 - 40
    local xCenter = 1280 / 2
    -- Carré gauche (rouge)
    if leftHeld then
        love.graphics.setColor(0.9, 0.2, 0.2)
    else
        love.graphics.setColor(0.4, 0.2, 0.2)
    end
    love.graphics.rectangle("fill", xCenter - 40 - squareSize, ySquares, squareSize, squareSize)
    love.graphics.setColor(0.8, 0.8, 0.8)
    love.graphics.rectangle("line", xCenter - 40 - squareSize, ySquares, squareSize, squareSize)
    -- Carré droite (bleu)
    if rightHeld then
        love.graphics.setColor(0.2, 0.4, 0.9)
    else
        love.graphics.setColor(0.2, 0.2, 0.4)
    end
    love.graphics.rectangle("fill", xCenter + 40, ySquares, squareSize, squareSize)
    love.graphics.setColor(0.8, 0.8, 0.8)
    love.graphics.rectangle("line", xCenter + 40, ySquares, squareSize, squareSize)
    -- Score
    love.graphics.setColor(1, 1, 1)
    love.graphics.setFont(love.graphics.newFont(32))
    love.graphics.printf("TAIKO RHYTHM", 0, 40, 1280, "center")
    love.graphics.setFont(love.graphics.newFont(24))
    love.graphics.printf("Score: " .. tostring(self.score), 0, 80, 1280, "center")
    love.graphics.printf("Frappez les notes avec clic gauche/droit dans la zone bleue!", 0, 120, 1280, "center")
    love.graphics.printf(string.format("Temps restant: %.1fs", math.max(0, self.timeLimit - self.timer)), 0, 160, 1280, "center")
    -- Indicateur de difficulté
    love.graphics.setColor(0.7, 0.7, 0.9)
    love.graphics.printf(string.format("Difficulté: %.1f", self.difficulty), 0, 680, 1280, "center")
    -- Affichage du compteur de notes ratées
    love.graphics.setColor(1, 0.3, 0.3)
    love.graphics.setFont(love.graphics.newFont(24))
    love.graphics.printf("Misses: " .. tostring(self.missCount) .. " / 3", 0, 200, 1280, "center")
end

function Minigame:mousepressed(x, y, button)
    if self.won or self.lost then return end
    -- Vérifier si une note est dans la zone de frappe (tolérance augmentée)
    local tolerance = 20
    for _, note in ipairs(self.notes) do
        if not note.hit and not note.missed and self.timer >= note.time then
            if note.y >= self.zoneY1 - tolerance and note.y <= self.zoneY2 + tolerance then
                if note.type == 'double' then
                    -- Note double : il faut les deux clics
                    if button == 1 and not note.leftHit then
                        note.leftHit = true
                        self.flashColor = {0.9, 0.4, 0.4}
                        self.flashTimer = 0.15
                    elseif button == 2 and not note.rightHit then
                        note.rightHit = true
                        self.flashColor = {0.4, 0.6, 1}
                        self.flashTimer = 0.15
                    end
                    if note.leftHit and note.rightHit then
                        note.hit = true
                        self.score = self.score + 1
                    end
                else
                    if (note.type == 'left' and button == 1) or (note.type == 'right' and button == 2) then
                        note.hit = true
                        self.score = self.score + 1
                        self.flashColor = (note.type == 'left') and {0.9, 0.4, 0.4} or {0.4, 0.6, 1}
                        self.flashTimer = 0.15
                        break
                    end
                end
            end
        end
    end
end

return Minigame
