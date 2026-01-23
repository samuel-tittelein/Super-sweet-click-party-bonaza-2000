-- items/balade_dans_les_bois/data.lua
local Item = {}

Item.name = "Balade Bois"
Item.price = 100
Item.bought = false

function Item:onBuy()
    gClickPower = gClickPower + 1
end

function Item:draw(x, y, scale)
    love.graphics.setColor(0, 0.5, 0) -- Green
    love.graphics.polygon("fill", x + 10 * scale, y, x, y + 20 * scale, x + 20 * scale, y + 20 * scale)
    love.graphics.setColor(1, 1, 1)
end

return Item
