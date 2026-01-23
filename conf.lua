function love.conf(t)
    t.window.title = "GameJam"
    t.window.width = 1280
    t.window.height = 720
    t.window.resizable = true
    t.window.minwidth = 800
    t.window.minheight = 600
    t.modules.physics = false -- We might use bump instead
    t.modules.audio = true
    t.modules.sound = true
end
