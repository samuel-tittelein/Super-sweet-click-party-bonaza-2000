-- items/fete_des_clics/data.lua
local Item = {}

Item.name = "Fete Clics"
Item.price = 100
Item.bought = false

function Item:onBuy()
    gClickPower = gClickPower + 1
end

function Item:draw(x, y, scale)
    love.graphics.setColor(1, 0, 0) -- Red
    love.graphics.print("!", x + 8 * scale, y + 5 * scale)
    love.graphics.setColor(1, 1, 0) -- Confetti
    love.graphics.points(x + 5 * scale, y + 5 * scale, x + 15 * scale, y + 15 * scale)
    love.graphics.setColor(1, 1, 1)
end

return Item
