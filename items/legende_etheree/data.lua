-- items/legende_etheree/data.lua
local Item = {}

Item.name = "Legende Etheree"
Item.price = 100
Item.bought = false

function Item:onBuy()
    gClickPower = gClickPower + 1
end

function Item:draw(x, y, scale)
    love.graphics.setColor(0.8, 0.8, 1, 0.5) -- Ghostly Blue
    love.graphics.circle("fill", x + 10 * scale, y + 10 * scale, 8 * scale)
    love.graphics.setColor(1, 1, 1)
end

return Item
