local M = {}

-- Draws central yellow circle and three buttons; returns button rects
function M.draw(w, h)
    love.graphics.setFont(love.graphics.newFont(16))

    -- Big central yellow circle
    local cX, cY, cR = w/2, h/2 - 20, 100
    love.graphics.setColor(1, 1, 0)
    love.graphics.circle("fill", cX, cY, cR)
    love.graphics.setColor(0,0,0)
    love.graphics.setLineWidth(3)

    -- Top button: Green rounded rectangle
    local btn1X = cX - 110
    local btn1Y = cY - 35
    local btn1W = 220
    local btn1H = 28
    love.graphics.setColor(0.3, 0.9, 0.3)
    love.graphics.rectangle("fill", btn1X, btn1Y, btn1W, btn1H, 6, 6)
    love.graphics.setColor(0,0,0)
    love.graphics.printf("NE ME CLIQUE PAS", btn1X, btn1Y + 6, btn1W, "center")

    -- Middle button: Purple capsule
    local btn2X = cX - 90
    local btn2Y = cY + 5
    local btn2W = 180
    local btn2H = 28
    love.graphics.setColor(0.8, 0.6, 1.0)
    love.graphics.rectangle("fill", btn2X, btn2Y, btn2W, btn2H, btn2H/2, btn2H/2)
    love.graphics.setColor(0,0,0)
    love.graphics.printf("CLIQUE MOI FORT", btn2X, btn2Y + 6, btn2W, "center")

    -- Bottom button: Orange rounded rectangle
    local btn3X = cX - 130
    local btn3Y = cY + 40
    local btn3W = 260
    local btn3H = 28
    love.graphics.setColor(1, 0.5, 0)
    love.graphics.rectangle("fill", btn3X, btn3Y, btn3W, btn3H, 6, 6)
    love.graphics.setColor(0,0,0)
    love.graphics.printf("NE ME CLIQUE SURTOUT PAS", btn3X, btn3Y + 6, btn3W, "center")

    return {
        btn1 = {x = btn1X, y = btn1Y, w = btn1W, h = btn1H},
        btn2 = {x = btn2X, y = btn2Y, w = btn2W, h = btn2H},
        btn3 = {x = btn3X, y = btn3Y, w = btn3W, h = btn3H},
    }
end

return M
