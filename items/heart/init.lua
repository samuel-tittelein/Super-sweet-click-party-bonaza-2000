local Item = {}

Item.name = "Extra Life (H)"
Item.price = 50
Item.bought = false -- Not used for consumables logic but kept for struct
Item.type = "consumable"
Item.key = "heart"

function Item:onBuy()
    -- Logic handled in Shop for consumables
end

function Item:draw(x, y, scale)
    love.graphics.setColor(1, 0, 0)
    love.graphics.polygon("fill", x, y + 10, x + 10, y, x + 20, y + 10, x + 10, y + 20)
end

return Item
