-- utils/Button.lua
local Button = {}
Button.__index = Button

function Button.new(text, x, y, w, h, callback)
    local self = setmetatable({}, Button)
    self.text = text
    self.x = x
    self.y = y
    self.w = w
    self.h = h
    self.callback = callback
    return self
end

function Button:draw()
    -- Simple rectangle with text
    love.graphics.setColor(0.8, 0.8, 0.8) -- Light gray bg
    love.graphics.rectangle("fill", self.x, self.y, self.w, self.h)

    love.graphics.setColor(0, 0, 0) -- Text color
    local font = love.graphics.getFont()
    local textW = font:getWidth(self.text)
    local textH = font:getHeight()

    love.graphics.print(self.text, self.x + (self.w - textW) / 2, self.y + (self.h - textH) / 2)
    love.graphics.setColor(1, 1, 1) -- Reset
end

function Button:clicked(x, y)
    if x >= self.x and x <= self.x + self.w and y >= self.y and y <= self.y + self.h then
        if self.callback then self.callback() end
        return true
    end
    return false
end

return Button
