local SpaceInvader = {
    name = "space_invader",
    description = "Defeat the invaders!",
    clickBonus = 50 -- Bonus clicks on win
}

-- Game Constants
local PLAYER_WIDTH = 40
local PLAYER_HEIGHT = 30
local BULLET_SPEED = 600
local BULLET_WIDTH = 4
local BULLET_HEIGHT = 10
local ENEMY_WIDTH = 30
local ENEMY_HEIGHT = 30
local ENEMY_PADDING = 15
local ENEMY_SPEED_BASE = 50
local ENEMY_DROP_DISTANCE = 20

function SpaceInvader:enter(difficulty)
    self.difficulty = difficulty or 1
    
    -- Reset game state
    self.width = 800
    self.height = 450
    
    -- Player state
    self.playerX = self.width / 2
    self.playerY = self.height - PLAYER_HEIGHT - 10
    self.playerColor = {0, 1, 0.5} -- Neon Green
    
    -- Projectiles
    self.bullets = {}
    self.enemyBullets = {}
    self.particles = {}
    
    -- Enemies
    self.enemies = {}
    self.enemyDirection = 1
    self.enemySpeed = ENEMY_SPEED_BASE + (self.difficulty * 10)
    self.moveTimer = 0
    self.moveInterval = math.max(0.1, 1.0 - (self.difficulty * 0.1))
    
    self:spawnEnemies()
end

function SpaceInvader:spawnEnemies()
    local rows = 3 + math.floor(self.difficulty / 2)
    local cols = 8 + math.floor(self.difficulty / 2)
    
    -- Limit rows/cols to fit screen
    if rows > 6 then rows = 6 end
    if cols > 12 then cols = 12 end
    
    local startX = (self.width - (cols * (ENEMY_WIDTH + ENEMY_PADDING))) / 2
    local startY = 40
    
    for row = 1, rows do
        for col = 1, cols do
            table.insert(self.enemies, {
                x = startX + (col - 1) * (ENEMY_WIDTH + ENEMY_PADDING),
                y = startY + (row - 1) * (ENEMY_HEIGHT + ENEMY_PADDING),
                width = ENEMY_WIDTH,
                height = ENEMY_HEIGHT,
                color = {1, 0.2, 0.5} -- Neon Pink
            })
        end
    end
end

function SpaceInvader:update(dt)
    -- Update Bullets
    for i = #self.bullets, 1, -1 do
        local b = self.bullets[i]
        b.y = b.y - BULLET_SPEED * dt
        
        -- Remove if offscreen
        if b.y < -10 then
            table.remove(self.bullets, i)
        else
            -- Check collision with enemies
            for j = #self.enemies, 1, -1 do
                local e = self.enemies[j]
                if self:checkCollision(b, e) then
                    -- Hit!
                    table.remove(self.enemies, j)
                    table.remove(self.bullets, i)
                    self:spawnExplosion(e.x + e.width/2, e.y + e.height/2, {1, 0.2, 0.5})
                    break -- Bullet destroyed
                end
            end
        end
    end
    
    -- Update Particles
    for i = #self.particles, 1, -1 do
        local p = self.particles[i]
        p.life = p.life - dt
        p.x = p.x + p.dx * dt
        p.y = p.y + p.dy * dt
        p.alpha = p.alpha - dt * 2
        if p.life <= 0 then
            table.remove(self.particles, i)
        end
    end
    
    -- Update Enemies
    if #self.enemies == 0 then
        return 'won'
    end
    
    -- Move enemies together
    local hitEdge = false
    local lowestY = 0
    
    for _, e in ipairs(self.enemies) do
        e.x = e.x + self.enemyDirection * self.enemySpeed * dt
        lowestY = math.max(lowestY, e.y + e.height)
        
        if e.x <= 0 or e.x + e.width >= self.width then
            hitEdge = true
        end
        
        -- Check collision with player
        if self:checkCollision(self:getPlayerRect(), e) then
            return 'lost'
        end
    end
    
    if lowestY >= self.playerY then
        return 'lost'
    end
    
    if hitEdge then
        self.enemyDirection = -self.enemyDirection
        for _, e in ipairs(self.enemies) do
            e.y = e.y + ENEMY_DROP_DISTANCE
            -- Push back inside to prevent getting stuck
            if e.x <= 0 then e.x = 0 end
            if e.x + e.width >= self.width then e.x = self.width - e.width end
        end
    end
    
    return nil -- Continue playing
end

function SpaceInvader:draw()
    -- Draw Player
    love.graphics.setColor(self.playerColor)
    -- Simple ship shape
    love.graphics.polygon("fill", 
        self.playerX, self.playerY + PLAYER_HEIGHT, -- Bottom Left
        self.playerX + PLAYER_WIDTH, self.playerY + PLAYER_HEIGHT, -- Bottom Right
        self.playerX + PLAYER_WIDTH/2, self.playerY -- Top Center
    )
    
    -- Draw Bullets
    love.graphics.setColor(0, 1, 1) -- Cyan bullets
    for _, b in ipairs(self.bullets) do
        love.graphics.rectangle("fill", b.x, b.y, b.width, b.height)
    end
    
    -- Draw Enemies
    for _, e in ipairs(self.enemies) do
        love.graphics.setColor(e.color)
        -- Alien shape (simple rect for now, maybe with eyes?)
        love.graphics.rectangle("fill", e.x, e.y, e.width, e.height, 5, 5) -- Rounded rect
        
        -- Eyes
        love.graphics.setColor(0, 0, 0)
        love.graphics.circle("fill", e.x + 8, e.y + 10, 3)
        love.graphics.circle("fill", e.x + e.width - 8, e.y + 10, 3)
    end
    
    -- Draw Particles
    for _, p in ipairs(self.particles) do
        love.graphics.setColor(p.color[1], p.color[2], p.color[3], p.alpha)
        love.graphics.circle("fill", p.x, p.y, p.size)
    end
end

-- Mouse Inputs
function SpaceInvader:mousepressed(x, y, button)
    if button == 2 then -- Right Click
        self:shoot()
    end
end

function SpaceInvader:mousemoved(x, y, dx, dy)
    -- Player follows mouse X directly
    self.playerX = x - PLAYER_WIDTH / 2
    
    -- Clamp to screen
    if self.playerX < 0 then self.playerX = 0 end
    if self.playerX > self.width - PLAYER_WIDTH then self.playerX = self.width - PLAYER_WIDTH end
end

-- Helpers
function SpaceInvader:shoot()
    table.insert(self.bullets, {
        x = self.playerX + PLAYER_WIDTH / 2 - BULLET_WIDTH / 2,
        y = self.playerY,
        width = BULLET_WIDTH,
        height = BULLET_HEIGHT
    })
end

function SpaceInvader:checkCollision(a, b)
    return a.x < b.x + b.width and
           a.x + a.width > b.x and
           a.y < b.y + b.height and
           a.y + a.height > b.y
end

function SpaceInvader:getPlayerRect()
    return {
        x = self.playerX,
        y = self.playerY,
        width = PLAYER_WIDTH,
        height = PLAYER_HEIGHT
    }
end

function SpaceInvader:spawnExplosion(x, y, color)
    for i = 1, 10 do
        table.insert(self.particles, {
            x = x,
            y = y,
            dx = math.random(-100, 100),
            dy = math.random(-100, 100),
            life = 0.5,
            size = math.random(2, 5),
            alpha = 1,
            color = color
        })
    end
end

-- Pause/Resume needed?
function SpaceInvader:pause() end
function SpaceInvader:resume() end

return SpaceInvader
