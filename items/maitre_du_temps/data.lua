-- items/maitre_du_temps/data.lua
local Item = {}

Item.name = "Maitre Temps"
Item.price = 100
Item.bought = false

function Item:onBuy()
    gClickPower = gClickPower + 1
end

function Item:draw(x, y, scale)
    love.graphics.setColor(0.5, 0.5, 0.5)                                              -- Grey
    love.graphics.circle("line", x + 10 * scale, y + 10 * scale, 9 * scale)
    love.graphics.line(x + 10 * scale, y + 10 * scale, x + 10 * scale, y + 5 * scale)  -- Hand
    love.graphics.line(x + 10 * scale, y + 10 * scale, x + 14 * scale, y + 10 * scale) -- Hand
    love.graphics.setColor(1, 1, 1)
end

return Item
