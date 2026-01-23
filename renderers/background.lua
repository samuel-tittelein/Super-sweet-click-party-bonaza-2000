local M = {}

local images = {
    garlandLeft = nil,
    garlandRight = nil
}

function M.draw(w, h)
    -- White base
    love.graphics.setColor(1, 1, 1)
    love.graphics.rectangle("fill", 0, 0, w, h)

    -- Dotted paper texture
    love.graphics.setColor(0.9, 0.9, 0.9)
    local step = 24
    for yy = step, h - step, step do
        for xx = step, w - step, step do
            love.graphics.circle("fill", xx, yy, 2)
        end
    end

    -- Lazy-load garland images
    if not images.garlandLeft then
        images.garlandLeft = love.graphics.newImage('assets/guilande.png')
        images.garlandRight = love.graphics.newImage('assets/guilande2.png')
    end

    -- Draw garlands in top corners (left: guilande.png, right: guilande2.png)
    love.graphics.setColor(1, 1, 1, 1)
    local function drawScaled(img, x, y, targetW)
        local iw, ih = img:getWidth(), img:getHeight()
        local sx = targetW / iw
        love.graphics.draw(img, x, y, 0, sx, sx)
        return iw * sx, ih * sx
    end

    local targetW = w * 0.38
    local leftW, leftH = drawScaled(images.garlandLeft, 0, 0, targetW)
    drawScaled(images.garlandRight, w - targetW, 0, targetW)
end

return M
