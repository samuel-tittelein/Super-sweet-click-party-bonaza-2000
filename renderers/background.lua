local M = {}

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
end

return M
