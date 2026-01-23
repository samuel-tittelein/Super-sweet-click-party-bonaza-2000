-- items/golden_cursor/data.lua
local Item = {}

Item.name = "Golden Cursor"
Item.price = 50
Item.bought = false

function Item:onBuy()
    gClickPower = gClickPower + 3
end

function Item:draw(x, y, scale)
    love.graphics.setColor(1, 1, 0) -- Yellow
    -- Draw a simple cursor shape (triangle)
    love.graphics.polygon("fill", x, y, x, y + 20 * scale, x + 15 * scale, y + 15 * scale)
    love.graphics.setColor(1, 1, 1)
end

return Item
