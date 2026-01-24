-- utils/Slider.lua
local Slider = {}
Slider.__index = Slider

function Slider.new(x, y, w, h, min, max, initial, callback)
    local self = setmetatable({}, Slider)
    self.x = x
    self.y = y
    self.w = w
    self.h = h
    self.min = min
    self.max = max
    self.value = initial
    self.callback = callback
    self.isDragging = false
    self.handleRadius = 15
    return self
end

function Slider:updateValueFromMouse(mx)
    local relativeX = mx - self.x
    local ratio = math.min(1, math.max(0, relativeX / self.w))
    self.value = self.min + ratio * (self.max - self.min)
    if self.callback then self.callback(self.value) end
end

function Slider:draw()
    -- Draw bar
    love.graphics.setColor(0.3, 0.3, 0.3)
    love.graphics.rectangle("fill", self.x, self.y + self.h / 2 - 2, self.w, 4, 2, 2)

    -- Draw progress bar part
    local ratio = (self.value - self.min) / (self.max - self.min)
    love.graphics.setColor(0.2, 0.6, 0.8)
    love.graphics.rectangle("fill", self.x, self.y + self.h / 2 - 2, self.w * ratio, 4, 2, 2)

    -- Draw handle
    local hx = self.x + self.w * ratio
    local hy = self.y + self.h / 2
    love.graphics.setColor(0.8, 0.8, 0.8)
    if self.isDragging then
        love.graphics.setColor(1, 1, 1)
    end
    love.graphics.circle("fill", hx, hy, self.handleRadius)
    love.graphics.setColor(0, 0, 0)
    love.graphics.circle("line", hx, hy, self.handleRadius)
end

function Slider:mousepressed(x, y, button)
    if button == 1 then
        -- Check handle or bar
        local hx = self.x + self.w * ((self.value - self.min) / (self.max - self.min))
        local hy = self.y + self.h / 2
        local dist = math.sqrt((x - hx) ^ 2 + (y - hy) ^ 2)

        if dist < self.handleRadius or (x >= self.x and x <= self.x + self.w and y >= self.y and y <= self.y + self.h) then
            self.isDragging = true
            self:updateValueFromMouse(x)
            return true
        end
    end
    return false
end

function Slider:mousereleased(x, y, button)
    if button == 1 then
        self.isDragging = false
    end
end

function Slider:mousemoved(x, y, dx, dy)
    if self.isDragging then
        self:updateValueFromMouse(x)
    end
end

return Slider
