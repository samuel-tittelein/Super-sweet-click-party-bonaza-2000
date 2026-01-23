-- items/informatique_et_etoile/data.lua
local Item = {}

Item.name = "Info & Etoile"
Item.price = 100
Item.bought = false

function Item:onBuy()
    gClickPower = gClickPower + 1
end

function Item:draw(x, y, scale)
    love.graphics.setColor(0, 0, 0.2) -- Dark blue
    love.graphics.rectangle("fill", x, y, 20 * scale, 20 * scale)
    love.graphics.setColor(1, 1, 0)   -- Yellow Star
    love.graphics.print("*", x + 5 * scale, y + 5 * scale)
    love.graphics.setColor(1, 1, 1)
end

return Item
