local Editor = require 'ui.editor'
local M = {}

-- Draws central yellow circle and three buttons; returns button rects
function M.draw(w, h)
    love.graphics.setFont(love.graphics.newFont(16))

    -- Big central yellow circle
    local circleDefault = { x = w / 2 - 100, y = h / 2 - 120, w = 200, h = 200 }
    local circleRect = Editor.track('menu.circle', circleDefault)
    local cX = circleRect.x + circleRect.w / 2
    local cY = circleRect.y + circleRect.h / 2
    local cR = math.min(circleRect.w, circleRect.h) / 2
    love.graphics.setColor(1, 1, 0)
    love.graphics.circle("fill", cX, cY, cR)
    love.graphics.setColor(0,0,0)
    love.graphics.setLineWidth(3)

    -- Top button: Green rounded rectangle
    local btn1 = Editor.track('menu.btn1', {
        x = cX - 110,
        y = cY - 35,
        w = 220,
        h = 28
    })
    love.graphics.setColor(0.3, 0.9, 0.3)
    love.graphics.rectangle("fill", btn1.x, btn1.y, btn1.w, btn1.h, 6, 6)
    love.graphics.setColor(0,0,0)
    love.graphics.printf("NE ME CLIQUE PAS", btn1.x, btn1.y + 6, btn1.w, "center")

    -- Middle button: Purple capsule
    local btn2 = Editor.track('menu.btn2', {
        x = cX - 90,
        y = cY + 5,
        w = 180,
        h = 28
    })
    love.graphics.setColor(0.8, 0.6, 1.0)
    love.graphics.rectangle("fill", btn2.x, btn2.y, btn2.w, btn2.h, btn2.h/2, btn2.h/2)
    love.graphics.setColor(0,0,0)
    love.graphics.printf("CLIQUE MOI FORT", btn2.x, btn2.y + 6, btn2.w, "center")

    -- Bottom button: Orange rounded rectangle
    local btn3 = Editor.track('menu.btn3', {
        x = cX - 130,
        y = cY + 40,
        w = 260,
        h = 28
    })
    love.graphics.setColor(1, 0.5, 0)
    love.graphics.rectangle("fill", btn3.x, btn3.y, btn3.w, btn3.h, 6, 6)
    love.graphics.setColor(0,0,0)
    love.graphics.printf("NE ME CLIQUE SURTOUT PAS", btn3.x, btn3.y + 6, btn3.w, "center")

    return {
        btn1 = btn1,
        btn2 = btn2,
        btn3 = btn3,
    }
end

return M
