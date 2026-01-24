local SpaceInvader = {
    name = "space_invader",
    description = "Defeat the invaders!",
    clickBonus = 50, -- Bonus clicks on win
    instruction = "TIRE !"
}

-- Game Constants
local PLAYER_WIDTH = 60
local PLAYER_HEIGHT = 60
local BULLET_SPEED = 800
local BULLET_WIDTH = 12
local BULLET_HEIGHT = 25
local ENEMY_WIDTH = 60
local ENEMY_HEIGHT = 60
local ENEMY_PADDING = 20
local ENEMY_SPEED_BASE = 70
-- Reduce drop distance to give player more time as sprites might be larger visually
local ENEMY_DROP_DISTANCE = 20

function SpaceInvader:enter(difficulty)
    self.difficulty = difficulty or 1
    
    -- Load Assets
    local assetPath = "minigames/space_invader/assets/"
    
    -- Protective loading for images
    local function loadImage(path)
        if love.filesystem.getInfo(path) then
             return love.graphics.newImage(path)
        end
        return nil
    end

    self.imgPlayer = loadImage(assetPath .. "spaceship.png")
    self.imgEnemy = loadImage(assetPath .. "alien.png")
    self.imgBullet = loadImage(assetPath .. "shoot.png") 

    -- Load Audio
    local function loadAudio(path, type)
        if love.filesystem.getInfo(path) then
            return love.audio.newSource(path, type)
        end
        return nil
    end

    self.sndMusic = loadAudio(assetPath .. "space_ambiance.ogg", "stream")
    self.sndShoot = loadAudio(assetPath .. "spaceship_attack.ogg", "static")
    self.sndExplosion = loadAudio(assetPath .. "death_alien.ogg", "static")
    
    if self.sndMusic then
        self.sndMusic:setLooping(true)
        self.sndMusic:setVolume(0.5)
        self.sndMusic:play()
    end

    -- Reset game state
    -- Use 1280x720 as internal resolution to match GameLoop scaling
    self.width = 1280
    self.height = 720
    self.timer = 10 -- 10 seconds limit
    
    -- Player state
    self.playerX = self.width / 2
    self.playerY = self.height - PLAYER_HEIGHT - 20
    
    -- Projectiles
    self.bullets = {}
    self.particles = {}
    
    -- Enemies
    self.enemies = {}
    self.enemyDirection = 1
    self.enemySpeed = ENEMY_SPEED_BASE + (self.difficulty * 10)
    
    self:spawnEnemies()
    
    -- Background Stars
    self.stars = {}
    -- Cover a large area to ensure full screen coverage
    for i = 1, 400 do
        table.insert(self.stars, {
            x = math.random(-500, self.width + 500),
            y = math.random(-500, self.height + 500),
            size = math.random(2, 5), -- Bigger stars for higher res
            alpha = math.random(50, 255) / 255
        })
    end
end

function SpaceInvader:spawnEnemies()
    -- Base grid: 3 rows, 6 cols scaling
    -- Difficulty effects
    local rows = 3 + math.ceil(self.difficulty * 0.5) 
    local cols = 6 + math.ceil(self.difficulty * 0.8)
    
    -- Caps to fit screen (1280x720)
    -- Max height: 6 rows * 80px = 480px (leaving space)
    -- Max width: 14 cols * 80px = 1120px
    if rows > 6 then rows = 6 end
    if cols > 14 then cols = 14 end
    
    local startX = (self.width - (cols * (ENEMY_WIDTH + ENEMY_PADDING))) / 2
    local startY = 60
    
    for row = 1, rows do
        for col = 1, cols do
            table.insert(self.enemies, {
                x = startX + (col - 1) * (ENEMY_WIDTH + ENEMY_PADDING),
                y = startY + (row - 1) * (ENEMY_HEIGHT + ENEMY_PADDING),
                width = ENEMY_WIDTH,
                height = ENEMY_HEIGHT,
                color = {1, 1, 1} -- White tint for sprites
            })
        end
    end
end

function SpaceInvader:update(dt)
    -- Update Timer
    self.timer = self.timer - dt
    if self.timer <= 0 then
        return 'lost'
    end

    -- Update Bullets
    for i = #self.bullets, 1, -1 do
        local b = self.bullets[i]
        b.y = b.y - BULLET_SPEED * dt
        
        -- Remove if offscreen
        if b.y < -50 then
            table.remove(self.bullets, i)
        else
            -- Check collision with enemies
            for j = #self.enemies, 1, -1 do
                local e = self.enemies[j]
                if self:checkCollision(b, e) then
                    -- Hit!
                    table.remove(self.enemies, j)
                    table.remove(self.bullets, i)
                    if self.sndExplosion then
                        self.sndExplosion:stop()
                        self.sndExplosion:play()
                    end
                    self:spawnExplosion(e.x + e.width/2, e.y + e.height/2, {0.5, 1, 0.5})
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
            if e.x <= 0 then e.x = 0 end
            if e.x + e.width >= self.width then e.x = self.width - e.width end
        end
    end
    
    return nil
end

function SpaceInvader:draw()
    -- Draw Background Stars with Scissor Disabled
    local ox, oy, ow, oh = love.graphics.getScissor()
    love.graphics.setScissor() -- Disable scissor to draw everywhere
    
    love.graphics.setColor(1, 1, 1)
    for _, star in ipairs(self.stars) do
        love.graphics.setColor(1, 1, 1, star.alpha)
        love.graphics.circle("fill", star.x, star.y, star.size)
    end
    love.graphics.setColor(1, 1, 1, 1)
    
    love.graphics.setScissor(ox, oy, ow, oh) -- Restore scissor

    -- Ensure images are loaded before using them
    local function drawSprite(img, x, y, w, h)
        if img then
             -- Calculate scale to fit width/height
             local sw = w / img:getWidth()
             local sh = h / img:getHeight()
             love.graphics.draw(img, x, y, 0, sw, sh)
        else
             -- Fallback rect
             love.graphics.rectangle("fill", x, y, w, h)
        end
    end

    -- Draw Player
    drawSprite(self.imgPlayer, self.playerX, self.playerY, PLAYER_WIDTH, PLAYER_HEIGHT)
    
    -- Draw Bullets
    for _, b in ipairs(self.bullets) do
        drawSprite(self.imgBullet, b.x, b.y, b.width, b.height)
    end
    
    -- Draw Enemies
    for _, e in ipairs(self.enemies) do
        drawSprite(self.imgEnemy, e.x, e.y, e.width, e.height)
    end
    
    -- Draw Particles
    for _, p in ipairs(self.particles) do
        love.graphics.setColor(p.color[1], p.color[2], p.color[3], p.alpha)
        love.graphics.circle("fill", p.x, p.y, p.size)
    end
    love.graphics.setColor(1, 1, 1)
    
    -- Draw Timer
    love.graphics.setColor(1, 0, 0)
    love.graphics.printf("TIME: " .. math.ceil(self.timer), 0, 10, self.width, "center")
    love.graphics.setColor(1, 1, 1)
end

function SpaceInvader:mousepressed(x, y, button)
    if button == 2 then -- Right Click
        self:shoot()
    end
end

function SpaceInvader:mousemoved(x, y, dx, dy)
    self.playerX = x - PLAYER_WIDTH / 2
    if self.playerX < 0 then self.playerX = 0 end
    if self.playerX > self.width - PLAYER_WIDTH then self.playerX = self.width - PLAYER_WIDTH end
end

function SpaceInvader:shoot()
    if self.sndShoot then
        self.sndShoot:stop()
        self.sndShoot:play()
    end

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

function SpaceInvader:leave()
    if self.sndMusic then
        self.sndMusic:stop()
    end
end

function SpaceInvader:pause()
    if self.sndMusic then
        self.sndMusic:pause()
    end
end

function SpaceInvader:resume()
    if self.sndMusic then
        self.sndMusic:play()
    end
end

return SpaceInvader
