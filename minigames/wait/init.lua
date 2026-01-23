-- Minijeu "Attends le cactus"
-- Le joueur doit attendre 5 secondes sans cliquer pour gagner

local Minigame = {}

function Minigame:enter(difficulty)
    self.background = love.graphics.newImage("minigames/wait/assets/background.jpg")
    self.main = love.graphics.newImage("minigames/wait/assets/main.png")
    self.main_blesse = love.graphics.newImage("minigames/wait/assets/main_blesse.png")
    self.state = "waiting"
    self.timer = 0
    self.winTime = 5
    self.handW, self.handH = self.main:getWidth(), self.main:getHeight()
    self.handX = (love.graphics.getWidth() - self.handW) / 2 + 100
    self.handY = love.graphics.getHeight() - self.handH - 285
    self.won = false
    self.lost = false
end

function Minigame:update(dt)
    if self.state == "waiting" then
        self.timer = self.timer + dt
        if self.timer >= self.winTime then
            self.state = "won"
            self.won = true
            return "won"
        end
    end
    if self.state == "lost" then
        self.lost = true
        self.lostTimer = (self.lostTimer or 0) + dt
        if self.lostTimer >= 1 then -- délai d'1 seconde avant de retourner "lost"
        return "lost"
    end
    end
    return nil
end

function Minigame:mousepressed(x, y, button)
    if self.state == "waiting" and button == 1 then
        if x >= self.handX and x <= self.handX + self.handW and y >= self.handY and y <= self.handY + self.handH then
            self.state = "lost"
        end
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
