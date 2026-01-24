local Button = require 'utils.Button'
local Slider = require 'utils.Slider'
local Dropdown = require 'utils.Dropdown'
local SettingsMenu = {}

function SettingsMenu:enter(params)
    self.buttons = {}
    self.components = {}
    self.font40 = love.graphics.newFont(40)
    self.font24 = love.graphics.newFont(24)
    local w, h = 1280, 720

    -- Volume Slider
    self.volumeSlider = Slider.new(w / 2 - 150, 250, 300, 40, 0, 1, gVolume, function(val)
        gVolume = val
        gApplySettings()
    end)
    table.insert(self.components, self.volumeSlider)

    -- Display Mode Dropdown
    local options = {
        { id = 'windowed',   label = 'Fenêtré' },
        { id = 'fullscreen', label = 'Plein Écran (Étiré)' },
        { id = 'borderless', label = 'Plein Écran sans Bordure' }
    }
    local currentIdx = 1
    for i, opt in ipairs(options) do
        if opt.id == gDisplayMode then currentIdx = i end
    end

    self.displayDropdown = Dropdown.new(w / 2 - 150, 380, 300, 50, options, currentIdx, function(id)
        gDisplayMode = id
        gApplySettings()
    end)
    table.insert(self.components, self.displayDropdown)

    -- Back Button
    table.insert(self.buttons, Button.new("Retour", w / 2 - 100, h - 100, 200, 50, function()
        gStateMachine:pop()
    end))
end

function SettingsMenu:update(dt)
end

function SettingsMenu:draw()
    love.graphics.setColor(0.1, 0.1, 0.2) -- Setting-ish bg
    love.graphics.rectangle("fill", 0, 0, 1280, 720)

    love.graphics.setColor(1, 1, 1)
    love.graphics.setFont(self.font40)
    love.graphics.printf("PARAMÈTRES", 0, 100, 1280, "center")

    love.graphics.setFont(self.font24)
    love.graphics.printf("Volume Global", 0, 210, 1280, "center")
    love.graphics.printf("Mode d'Affichage", 0, 340, 1280, "center")

    -- Order matters for dropdown (draw last to be on top)
    for _, btn in ipairs(self.buttons) do
        btn:draw()
    end

    -- Draw volume slider
    self.volumeSlider:draw()

    -- Draw dropdown last
    self.displayDropdown:draw()
end

function SettingsMenu:mousepressed(x, y, button)
    -- Handle dropdown first (it might overlap)
    if self.displayDropdown:mousepressed(x, y, button) then return end

    if self.volumeSlider:mousepressed(x, y, button) then return end

    for _, btn in ipairs(self.buttons) do
        btn:clicked(x, y)
    end
end

function SettingsMenu:mousereleased(x, y, button)
    self.volumeSlider:mousereleased(x, y, button)
end

function SettingsMenu:mousemoved(x, y, dx, dy)
    self.volumeSlider:mousemoved(x, y, dx, dy)
end

function SettingsMenu:keypressed(key)
    if key == 'escape' then
        gStateMachine:change('menu')
    end
end

return SettingsMenu
