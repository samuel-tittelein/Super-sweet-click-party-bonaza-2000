local M = {}

-- Images cache
local images = {
    logo = nil,
    btn1 = nil,
    btn2 = nil,
    btn3 = nil,
    settings = nil
}

-- Lazy load images
local function loadImages()
    if not images.logo then
        images.logo = love.graphics.newImage('assets/logo.png')
        images.btn1 = love.graphics.newImage('assets/ne_me_clique_pas.png')
        images.btn2 = love.graphics.newImage('assets/clique_moi_fort.png')
        images.btn3 = love.graphics.newImage('assets/ne_me_clique_surtout_pas.png')
        images.settings = love.graphics.newImage('assets/parametre.png')
    end
end

-- Draws logo, three buttons, and settings button; returns button rects
function M.draw(w, h, time)
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

    -- Draw rotating settings button (top right area)
    if images.settings then
        local settingsW, settingsH = images.settings:getWidth(), images.settings:getHeight()
        local settingsX = w - settingsW - 40
        local settingsY = 40
        
        local btnSettings = { x = settingsX, y = settingsY, w = settingsW, h = settingsH }
        
        -- Rotation animation
        local rotation = time * 1.5 -- Rotation speed
        
        love.graphics.push()
        love.graphics.translate(settingsX + settingsW / 2, settingsY + settingsH / 2)
        love.graphics.rotate(rotation)
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.draw(images.settings, -settingsW / 2, -settingsH / 2)
        love.graphics.pop()
        
        return {
            btn1 = btn1,
            btn2 = btn2,
            btn3 = btn3,
            btnSettings = btnSettings,
        }
    end

    return {
        btn1 = btn1,
        btn2 = btn2,
        btn3 = btn3,
    }
end

return M
