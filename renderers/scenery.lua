local M = {}

M.state = {
    bars = nil,
    groundY = nil,
    barWidth = 60, -- wider bars
    gap = 0,       -- no gap so bars are contiguous
    maxHeight = nil,
}

function M.init(w, h)
    M.state.groundY = math.floor(h * 2/3)
    M.state.maxHeight = math.floor(h * 0.5)
    local available = w
    local bw, gap = M.state.barWidth, M.state.gap
    local count = math.ceil(available / (bw + gap))
    M.state.bars = {}
    for i = 1, count do
        local x = (i - 1) * (bw + gap)
        local phase = love.math.random() * 2 * math.pi
        local freqBase = 0.9 + love.math.random() * 1.1
        M.state.bars[i] = { x = x, h = 30, phase = phase, freqBase = freqBase }
    end
end

function M.update(dt)
    if not M.state.bars then return end
    local t = love.timer.getTime()
    local maxH = M.state.maxHeight
    for i, b in ipairs(M.state.bars) do
        -- dynamic frequency and amplitude modulation per bar
        local dynFreq = b.freqBase + 0.5 * math.sin(t * 0.5 + i * 0.3)
        local modAmp = 0.6 + 0.4 * math.sin(t * 0.7 + i * 1.1)
        -- combine multiple waves for energetic feel
        local raw = (math.sin(t * dynFreq + b.phase)
                  + math.sin(t * (dynFreq * 1.7) + b.phase * 1.3)
                  + math.sin(t * (dynFreq * 0.9) - b.phase * 0.6)) / 3
        local wave = (raw * 0.5 + 0.5) * modAmp -- 0..1
        local base = 12
        local target = base + wave * (maxH - base)
        -- stronger smoothing for snappy movement
        b.h = b.h + (target - b.h) * math.min(1, dt * 12)
    end
end

-- Draw ground and animated cyan equalizer bars
function M.draw(w, h)
    local groundY = M.state.groundY or math.floor(h * 2/3)

    -- Lime green ground
    love.graphics.setColor(0.5, 1, 0)
    love.graphics.rectangle("fill", 0, groundY, w, h - groundY)

    -- Cyan/Turquoise equalizer bars rising from ground
    if M.state.bars then
        love.graphics.setColor(0, 1, 1)
        for _, b in ipairs(M.state.bars) do
            love.graphics.rectangle("fill", b.x, groundY - b.h, M.state.barWidth, b.h)
        end
    end
end

return M
