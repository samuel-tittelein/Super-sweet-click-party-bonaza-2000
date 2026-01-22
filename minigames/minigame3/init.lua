local Minigame = {}

function Minigame:enter(difficulty)
    self.color = {math.random(), math.random(), math.random()}
    self.timer = 0
    self.won = false
    self.lost = false
    self.difficulty = difficulty or 1
end

function Minigame:update(dt)
    self.timer = self.timer + dt
    if self.won then return "won" end
    if self.lost then return "lost" end
    return nil
end

function Minigame:draw()
    love.graphics.setColor(self.color); love.graphics.rectangle("fill", 0, 0, 1280, 720)
    love.graphics.setColor(1, 1, 1)
    love.graphics.printf("Template Game 3", 0, 300, 1280, "center")
    love.graphics.printf("Difficulty: " .. self.difficulty, 0, 350, 1280, "center")
    love.graphics.printf("Press 'z' to Win, 'x' to Lose", 0, 400, 1280, "center")
end

function Minigame:keypressed(key)
    if key == 'z' then self.won = true end
    if key == 'x' then self.lost = true end
end

return Minigame
