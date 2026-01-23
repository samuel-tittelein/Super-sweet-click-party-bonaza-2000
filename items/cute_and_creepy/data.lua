-- items/cute_and_creepy/data.lua
local Item = {}

Item.name = "Cute & Creepy"
Item.price = 100
Item.bought = false

function Item:onBuy()
    gClickPower = gClickPower + 1
end

function Item:draw(x, y, scale)
    love.graphics.setColor(1, 0.5, 0.5) -- Pink
    love.graphics.circle("fill", x + 10 * scale, y + 10 * scale, 10 * scale)
    love.graphics.setColor(0, 0, 0)     -- Eyes
    love.graphics.points(x + 7 * scale, y + 8 * scale, x + 13 * scale, y + 8 * scale)
    love.graphics.setColor(1, 1, 1)
end

return Item
