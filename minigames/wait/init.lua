-- Minijeu "Attends le cactus"
-- Le joueur doit attendre 5 secondes sans cliquer pour gagner

local Minigame = {
    instruction = "ATTENDS !"
}

function Minigame:enter(difficulty)
    self.background = love.graphics.newImage("minigames/wait/assets/background.jpg")
    self.main = love.graphics.newImage("minigames/wait/assets/main.png")
    self.main_blesse = love.graphics.newImage("minigames/wait/assets/main_blesse.png")
    self.aie = love.audio.newSource("minigames/wait/assets/aie.ogg", "static")
    self.music = love.audio.newSource("minigames/wait/assets/bouclebatterieminimalistebaton-cropped.ogg", "stream")
    self.music:setLooping(true)
    self.music:play()
    self.state = "waiting"
    self.timer = 0
    self.winTime = 5
    self.handW, self.handH = self.main:getWidth(), self.main:getHeight()
    self.handX = (love.graphics.getWidth() - self.handW) / 2 + 100
    self.handY = love.graphics.getHeight() - self.handH - 285
    self.won = false
    self.lost = false
    self.lostTimer = 0 -- reset du lostTimer
end

function Minigame:update(dt)
    if self.state == "waiting" then
        self.lostTimer = 0 -- reset du lostTimer si retour à waiting
        self.timer = self.timer + dt
        if self.timer >= self.winTime then
            self.state = "won"
            self.won = true
        end
    end
    if self.state == "lost" then
        self.lost = true
        self.lostTimer = (self.lostTimer or 0) + dt
        if self.lostTimer >= 1 then -- délai d'1 seconde avant de retourner "lost"
            return "lost"
        end
    end
    if self.state == "won" then
        return "won"
    end
    return nil
end

function Minigame:mousepressed(x, y, button)
    if self.state == "waiting" and button == 1 then
        self.state = "lost"
        if self.aie then
            self.aie:stop()
            self.aie:play()
        end
    end
end

function Minigame:leave()
    if self.music then
        self.music:stop()
    end
end

function Minigame:draw()
    love.graphics.draw(self.background, 0, 0, 0, love.graphics.getWidth()/self.background:getWidth(), love.graphics.getHeight()/self.background:getHeight())
    if self.state == "lost" then
        love.graphics.draw(self.main_blesse, self.handX + self.handW/2, self.handY + self.handH/2, math.rad(-30), 1, 1, self.handW/2, self.handH/2)
    else
        love.graphics.draw(self.main, self.handX, self.handY)
    end
end

return Minigame
