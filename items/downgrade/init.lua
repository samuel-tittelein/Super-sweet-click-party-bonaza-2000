local Item = {}

Item.name = "Level Down (D)"
Item.price = 100
Item.bought = false
Item.type = "consumable"
Item.key = "downgrade"

function Item:onBuy()
end

function Item:draw(x, y, scale)
    love.graphics.setColor(0, 0, 1)
    love.graphics.polygon("fill", x + 10, y + 20, x, y, x + 20, y)
end

return Item
