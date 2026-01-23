-- items/merveilles_des_profondeurs/data.lua
local Item = {}

Item.name = "Profondeurs"
Item.price = 100
Item.bought = false

function Item:onBuy()
    gClickPower = gClickPower + 1
end

function Item:draw(x, y, scale)
    love.graphics.setColor(0, 0, 0.5) -- Deep Blue
    love.graphics.rectangle("fill", x, y, 20 * scale, 20 * scale)
    love.graphics.setColor(1, 1, 1)   -- Bubbles
    love.graphics.circle("line", x + 5 * scale, y + 15 * scale, 2 * scale)
    love.graphics.circle("line", x + 12 * scale, y + 10 * scale, 3 * scale)
end

return Item
