local M = {}

function M.draw(x, y, width, height, mirror)
    mirror = mirror or false

    -- Trapezoid body (lavender / pink)
    local tilt = mirror and -12 or 12
    local body = {
        x,            y,
        x + width,    y + 10,
        x + width + tilt, y + height,
        x - 10,       y + height - 8
    }
    love.graphics.setColor(0.88, 0.76, 1.0) -- Lavender
    love.graphics.polygon("fill", body)

    -- Offset black outline for sticker effect
    love.graphics.setColor(0, 0, 0)
    love.graphics.setLineWidth(3)
    local outline = {}
    for i = 1, #body, 2 do
        outline[i]   = body[i] + 3
        outline[i+1] = body[i+1] + 2
    end
    love.graphics.polygon("line", outline)

    -- Magenta side (depth)
    love.graphics.setColor(1, 0, 0.8)
    if mirror then
        love.graphics.polygon("fill",
            x + width, y + 10,
            x + width + 18, y + 18,
            x + width + tilt + 8, y + height - 20,
            x + width + tilt, y + height
        )
    else
        love.graphics.polygon("fill",
            x - 10, y,
            x - 28, y + 18,
            x - 22, y + height - 60,
            x - 10, y + height - 8
        )
    end
    love.graphics.setColor(0, 0, 0)
    love.graphics.setLineWidth(2)

    -- Woofers (two bright yellow circles) with offset outlines
    local cx = x + width/2 + (mirror and -2 or 2)
    local rOuter = 68
    local rInner = 42
    local topY = y + height/3
    local botY = y + (2*height)/3

    -- Top woofer
    love.graphics.setColor(1, 1, 0)
    love.graphics.circle("fill", cx, topY, rOuter)
    love.graphics.setColor(0, 0, 0)
    love.graphics.circle("line", cx + 3, topY + 2, rOuter)
    love.graphics.setColor(1, 1, 0)
    love.graphics.circle("fill", cx, topY, rInner)
    love.graphics.setColor(0, 0, 0)
    love.graphics.circle("line", cx + 2, topY + 3, rInner)

    -- Bottom woofer
    love.graphics.setColor(1, 1, 0)
    love.graphics.circle("fill", cx, botY, rOuter)
    love.graphics.setColor(0, 0, 0)
    love.graphics.circle("line", cx + 3, botY + 2, rOuter)
    love.graphics.setColor(1, 1, 0)
    love.graphics.circle("fill", cx, botY, rInner)
    love.graphics.setColor(0, 0, 0)
    love.graphics.circle("line", cx + 2, botY + 3, rInner)

    -- Decorative rectangles above left speaker only
    if not mirror then
        local deco = {
            {x = x + width/2 - 40, y = y - 40, w = 22, h = 44, color = {1,1,0}},
            {x = x + width/2 + 10, y = y - 30, w = 28, h = 36, color = {1,0.5,0}},
            {x = x + width/2 + 52, y = y - 18, w = 26, h = 32, color = {0.5,1,0}}
        }
        for i, d in ipairs(deco) do
            love.graphics.push()
            love.graphics.translate(d.x, d.y)
            love.graphics.rotate((i-2) * 0.2)
            love.graphics.setColor(d.color[1], d.color[2], d.color[3])
            love.graphics.rectangle("fill", -d.w/2, -d.h/2, d.w, d.h)
            love.graphics.setColor(0,0,0)
            love.graphics.rectangle("line", -d.w/2+3, -d.h/2+2, d.w, d.h)
            love.graphics.pop()
        end
    end
end

return M
