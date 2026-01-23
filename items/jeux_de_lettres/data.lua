-- items/jeux_de_lettres/data.lua
local Item = {}

Item.name = "Jeux de Lettres"
Item.price = 100
Item.bought = false

function Item:onBuy()
    gClickPower = gClickPower + 1
end

function Item:draw(x, y, scale)
    love.graphics.setColor(0.5, 0.5, 1) -- Light Blue
    love.graphics.rectangle("fill", x, y, 20 * scale, 20 * scale)
    love.graphics.setColor(0, 0, 0)
    love.graphics.print("A", x + 5 * scale, y + 2 * scale)
    love.graphics.setColor(1, 1, 1)
end

return Item
