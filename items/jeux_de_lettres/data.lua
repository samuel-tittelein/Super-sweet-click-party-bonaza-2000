-- items/jeux_de_lettres/data.lua
local Item = {}

Item.name = "Jeux de Lettres"
Item.price = 100
Item.bought = false
Item.image = love.graphics.newImage("items/jeux_de_lettres/jeux_de_lettres.png")

function Item:onBuy()
    gClickPower = gClickPower + 1
end

function Item:draw(x, y, scale)
    love.graphics.setColor(1, 1, 1)
    local imgScale = (20 * scale) / math.max(self.image:getWidth(), self.image:getHeight())
    love.graphics.draw(self.image, x, y, 0, imgScale, imgScale)
end

return Item
