-- items/chasse_aux_tresors/data.lua
local Item = {}

Item.name = "Chasse Tresors"
Item.price = 100
Item.bought = false

function Item:onBuy()
    gClickPower = gClickPower + 1
end

function Item:draw(x, y, scale)
    love.graphics.setColor(0.6, 0.4, 0.2) -- Brown
    love.graphics.rectangle("fill", x, y + 5 * scale, 20 * scale, 15 * scale)
    love.graphics.setColor(1, 1, 0)       -- Lock
    love.graphics.rectangle("fill", x + 8 * scale, y + 8 * scale, 4 * scale, 4 * scale)
    love.graphics.setColor(1, 1, 1)
end

return Item
