-- items/legende_etheree/data.lua
local Item = {}

Item.name = "Legende Etheree"
Item.price = 100
Item.bought = false
Item.image = love.graphics.newImage("items/legende_etheree/legende_etheree.jpg")

function Item:onBuy()
    gClickPower = gClickPower + 1
end

function Item:draw(x, y, scale)
    love.graphics.setColor(1, 1, 1)
    local imgScale = (20 * scale) / math.max(self.image:getWidth(), self.image:getHeight())
    love.graphics.draw(self.image, x, y, 0, imgScale, imgScale)
end

return Item
