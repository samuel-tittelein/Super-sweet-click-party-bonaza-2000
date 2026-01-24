-- items/balade_dans_les_bois/data.lua
local Item = {}

Item.name = "Balade Bois"
Item.price = 100
Item.bought = false
Item.image = love.graphics.newImage("items/balade_dans_les_bois/balade_dans_les_bois.png")

function Item:onBuy()
    gClickPower = gClickPower + 1
end

function Item:draw(x, y, scale)
    love.graphics.setColor(1, 1, 1)
    local imgScale = (20 * scale) / math.max(self.image:getWidth(), self.image:getHeight())
    love.graphics.draw(self.image, x, y, 0, imgScale, imgScale)
end

return Item
