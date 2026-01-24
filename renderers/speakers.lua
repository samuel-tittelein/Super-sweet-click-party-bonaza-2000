local M = {}

local images = {
    boxLeft = nil,
    boxRight = nil,
    speakerBottom = nil,
    speakerTop = nil
}

function M.load()
    -- Load PNG assets from assets folder
    images.boxLeft = images.boxLeft or love.graphics.newImage('assets/box.png')
    images.boxRight = images.boxRight or love.graphics.newImage('assets/box2.png')
    images.speakerBottom = images.speakerBottom or love.graphics.newImage('assets/speaker.png')
    images.speakerTop = images.speakerTop or love.graphics.newImage('assets/speaker2.png')
end

-- Animation state for bass pulse
M.state = {
    timer = 0,
    interval = 0.5, -- seconds between size toggles
    pulseOn = false
}

function M.update(dt)
    local s = M.state
    s.timer = s.timer + dt
    if s.timer >= s.interval then
        s.timer = s.timer - s.interval
        s.pulseOn = not s.pulseOn
    end
end

local function drawImage(img, x, y, w, h)
    local iw, ih = img:getWidth(), img:getHeight()
    local sx = w / iw
    local sy = h / ih
    love.graphics.draw(img, x, y, 0, sx, sy)
end

function M.draw(x, y, width, height, mirror)
    mirror = mirror or false
    -- Ensure PNGs are drawn with their original colors
    love.graphics.setColor(1, 1, 1, 1)
    if not images.boxLeft then M.load() end

    -- Pick correct box sprite depending on side
    local boxImg = mirror and images.boxRight or images.boxLeft

    -- Draw the box scaled to given rect
    drawImage(boxImg, x, y, width, height)

    -- Draw two speaker circles inside the box: swap positions (top <-> bottom)
    local topImg = images.speakerBottom  -- large woofer now at top
    local botImg = images.speakerTop     -- small tweeter now at bottom

    -- Top speaker now larger (woofer); alternate between two sizes
    local tiw, tih = topImg:getWidth(), topImg:getHeight()
    local topBaseW = width * 0.62
    local topBaseH = height * 0.36
    local topFactor = M.state.pulseOn and 1.18 or 1.0
    local topW = topBaseW * topFactor
    local topH = topBaseH * topFactor
    local tsx = topW / tiw
    local tsy = topH / tih
    local topX = x + width * 0.5 - (tiw * tsx) / 2
    -- Center within the top half of the box
    local topY = y + height * 0.25 - (tih * tsy) / 2
    love.graphics.draw(topImg, topX, topY, 0, tsx, tsy)

    -- Bottom speaker now smaller (tweeter); alternate between two sizes
    local biw, bih = botImg:getWidth(), botImg:getHeight()
    local botBaseW = width * 0.44
    local botBaseH = height * 0.23
    local botFactor = M.state.pulseOn and 1.10 or 1.0
    local botW = botBaseW * botFactor
    local botH = botBaseH * botFactor
    local bsx = botW / biw
    local bsy = botH / bih
    local botX = x + width * 0.5 - (biw * bsx) / 2
    -- Center within the bottom half of the box
    local botY = y + height * 0.75 - (bih * bsy) / 2
    love.graphics.draw(botImg, botX, botY, 0, bsx, bsy)
end

return M
