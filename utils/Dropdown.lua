-- utils/Dropdown.lua
local Dropdown = {}
Dropdown.__index = Dropdown

function Dropdown.new(x, y, w, h, options, currentIdx, callback)
    local self = setmetatable({}, Dropdown)
    self.x = x
    self.y = y
    self.w = w
    self.h = h
    self.options = options -- { {id='...', label='...'}, ... }
    self.currentIdx = currentIdx or 1
    self.callback = callback
    self.isOpen = false
    return self
end

function Dropdown:draw()
    -- Current selection box
    love.graphics.setColor(0.8, 0.8, 0.8)
    love.graphics.rectangle("fill", self.x, self.y, self.w, self.h)
    love.graphics.setColor(0, 0, 0)
    love.graphics.rectangle("line", self.x, self.y, self.w, self.h)

    local currentText = self.options[self.currentIdx].label
    local font = love.graphics.getFont()
    love.graphics.print(currentText, self.x + 10, self.y + (self.h - font:getHeight()) / 2)

    -- Arrow
    local arrowSize = 10
    local ax = self.x + self.w - 20
    local ay = self.y + self.h / 2
    if self.isOpen then
        love.graphics.polygon("fill", ax - arrowSize / 2, ay + arrowSize / 4, ax + arrowSize / 2, ay + arrowSize / 4, ax,
            ay - arrowSize / 4)
    else
        love.graphics.polygon("fill", ax - arrowSize / 2, ay - arrowSize / 4, ax + arrowSize / 2, ay - arrowSize / 4, ax,
            ay + arrowSize / 4)
    end

    -- Options list
    if self.isOpen then
        love.graphics.push("all")
        -- Draw on top
        for i, opt in ipairs(self.options) do
            local oy = self.y + i * self.h
            love.graphics.setColor(0.9, 0.9, 0.9)
            if i == self.currentIdx then
                love.graphics.setColor(0.7, 0.8, 1.0)
            end
            love.graphics.rectangle("fill", self.x, oy, self.w, self.h)
            love.graphics.setColor(0, 0, 0)
            love.graphics.rectangle("line", self.x, oy, self.w, self.h)
            love.graphics.print(opt.label, self.x + 10, oy + (self.h - font:getHeight()) / 2)
        end
        love.graphics.pop()
    end
end

function Dropdown:mousepressed(x, y, button)
    if button == 1 then
        if self.isOpen then
            -- Check options
            for i, opt in ipairs(self.options) do
                local oy = self.y + i * self.h
                if x >= self.x and x <= self.x + self.w and y >= oy and y <= oy + self.h then
                    self.currentIdx = i
                    self.isOpen = false
                    if self.callback then self.callback(opt.id, i) end
                    return true
                end
            end
            -- Clicked outside but was open? Close it.
            self.isOpen = false
            return true
        else
            -- Check main box
            if x >= self.x and x <= self.x + self.w and y >= self.y and y <= self.y + self.h then
                self.isOpen = true
                return true
            end
        end
    end
    return false
end

return Dropdown
