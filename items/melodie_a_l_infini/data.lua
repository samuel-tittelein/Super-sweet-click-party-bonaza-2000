-- items/melodie_a_l_infini/data.lua
local Item = {}

Item.name = "Melodie Infini"
Item.price = 100
Item.bought = false

function Item:onBuy()
    gClickPower = gClickPower + 1
end

function Item:draw(x, y, scale)
    love.graphics.setColor(1, 0, 1) -- Purple
    love.graphics.print("♪", x + 5 * scale, y + 5 * scale)
    love.graphics.setColor(1, 1, 1)
end

return Item
