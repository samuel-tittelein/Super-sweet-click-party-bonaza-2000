local M = {}

-- Images cache
local images = {
    logo = nil,
    btn1 = nil,
    btn2 = nil,
    btn3 = nil
}

-- Lazy load images
local function loadImages()
    if not images.logo then
        images.logo = love.graphics.newImage('assets/logo.png')
        images.btn1 = love.graphics.newImage('assets/ne_me_clique_pas.png')
        images.btn2 = love.graphics.newImage('assets/clique_moi_fort.png')
        images.btn3 = love.graphics.newImage('assets/ne_me_clique_surtout_pas.png')
    end
end

-- Draws logo and three buttons; returns button rects
function M.draw(w, h)
    loadImages()

    -- Draw logo at top center (scaled down to 50%)
    if images.logo then
        local logoW, logoH = images.logo:getWidth(), images.logo:getHeight()
        local logoScale = 0.5
        local scaledW = logoW * logoScale
        local scaledH = logoH * logoScale
        local logoX = w / 2 - scaledW / 2
        local logoY = 20
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.draw(images.logo, logoX, logoY, 0, logoScale, logoScale)
    end

    -- Calculate button positions (centered, vertically spaced)
    local btn1W, btn1H = images.btn1:getWidth(), images.btn1:getHeight()
    local btn2W, btn2H = images.btn2:getWidth(), images.btn2:getHeight()
    local btn3W, btn3H = images.btn3:getWidth(), images.btn3:getHeight()

    local centerX = w / 2
    local startY = 420
    local spacing = 90

    local btn1X = centerX - btn1W / 2
    local btn1Y = startY
    local btn1 = { x = btn1X, y = btn1Y, w = btn1W, h = btn1H }

    local btn2X = centerX - btn2W / 2
    local btn2Y = startY + spacing
    local btn2 = { x = btn2X, y = btn2Y, w = btn2W, h = btn2H }

    local btn3X = centerX - btn3W / 2
    local btn3Y = startY + spacing * 2
    local btn3 = { x = btn3X, y = btn3Y, w = btn3W, h = btn3H }

    -- Draw buttons
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.draw(images.btn1, btn1X, btn1Y)
    love.graphics.draw(images.btn2, btn2X, btn2Y)
    love.graphics.draw(images.btn3, btn3X, btn3Y)

    return {
        btn1 = btn1,
        btn2 = btn2,
        btn3 = btn3,
    }
end

return M
