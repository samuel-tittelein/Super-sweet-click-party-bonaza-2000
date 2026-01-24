local TimeMatcher = {
    name = 'time_matcher',
    instruction = "SYNCHRONISE !"
}

function TimeMatcher:enter(difficulty)
    self.difficulty = difficulty or 1
    self.state = nil -- Reset state on entry

    -- Logic for difficulty
    -- Level 1: 3 rounds, no seconds
    -- Level 2: 4 rounds, no seconds (tighter time per round?)
    -- Level 3+: 4 rounds, WITH seconds

    if self.difficulty == 1 then
        self.totalRounds = 3
        self.useSeconds = false
        self.timeLimit = 20
    elseif self.difficulty == 2 then
        self.totalRounds = 4
        self.useSeconds = false
        self.timeLimit = 20
    else
        self.totalRounds = 4
        self.useSeconds = true
        self.timeLimit = 25
    end

    self.round = 1
    self.timer = self.timeLimit

    self.clickBonus = 10 + (difficulty * 5)

    -- Robust sound cleanup: Stop any existing ticking before starting a new source
    if self.snd_ticking then
        self.snd_ticking:stop()
    end

    -- Load and start sounds
    self.snd_ticking = love.audio.newSource("minigames/time_matcher/assets/clock_ticking.ogg", "static")
    self.snd_dong = love.audio.newSource("minigames/time_matcher/assets/dong.ogg", "static")

    self.snd_ticking:setLooping(true)
    self.snd_ticking:play()

    -- Unified font for labels and numbers
    self.font26 = love.graphics.newFont(26)
    self.font52 = love.graphics.newFont(52) -- Double size (26 * 2)

    -- Load Background
    self.bgImage = love.graphics.newImage("minigames/time_matcher/assets/fond.jpg")

    -- CONFIGURATION HORLOGES (Ajustez les positions ici)
    -- Alignez ces points avec le CENTRE de vos horloges sur l'image de fond.
    self.leftClockX = 436
    self.leftClockY = 290

    self.rightClockX = 833
    self.rightClockY = 290

    -- CONFIGURATION RAYON (Taille des aiguilles)
    self.clockRadius = 120

    self:nextRound()
end

function TimeMatcher:nextRound()
    if self.round > self.totalRounds then
        self.state = 'won'
        return
    end

    -- Generate target time (random H, M, S)
    self.targetH = math.random(1, 12)
    self.targetM = math.random(0, 11) * 5 -- discrete 5 min steps for target? Or fully random?
    -- "Match the one on the left" -> Usually clocks are clean.
    -- Let's do random 0-59 for harder matching
    self.targetM = math.random(0, 59)
    self.targetS = math.random(0, 59)

    -- Random current time (to be fixed by user)
    self.currentH = math.random(1, 12)
    self.currentM = math.random(0, 59)
    self.currentS = math.random(0, 59)

    -- Set state
    self.dragging = nil -- 'h', 'm', 's'
end

function TimeMatcher:update(dt)
    if self.state == 'won' then
        if self.snd_ticking then self.snd_ticking:stop() end
        return 'won'
    end
    if self.state == 'lost' then
        if self.snd_ticking then self.snd_ticking:stop() end
        return 'lost'
    end

    self.timer = self.timer - dt
    if self.timer <= 0 then
        self.state = 'lost'
        return 'lost'
    end

    -- Check Match
    local hMatch = self:isHourMatch()
    local mMatch = self:isMinuteMatch()
    local sMatch = true
    if self.useSeconds then
        sMatch = self:isSecondMatch()
    end

    if hMatch and mMatch and sMatch then
        -- Round matched!
        if self.snd_dong then
            self.snd_dong:stop()
            self.snd_dong:play()
        end

        self.round = self.round + 1
        if self.round > self.totalRounds then
            self.state = 'won'
            return 'won'
        else
            self:nextRound()
        end
    end
end

function TimeMatcher:isHourMatch()
    -- Use getAngleFromTime for BOTH to ensure consistent coordinate system (Trig 0 = Right)
    local targetAngle = self:getAngleFromTime(self.targetH, 12)
    local currentAngle = self:getAngleFromTime(self.currentH, 12)

    return self:anglesMatch(targetAngle, currentAngle, math.pi / 6) -- +/- 1 hour tolerance
end

function TimeMatcher:isMinuteMatch()
    local targetAngle = self:getAngleFromTime(self.targetM, 60)
    local currentAngle = self:getAngleFromTime(self.currentM, 60)
    return self:anglesMatch(targetAngle, currentAngle, math.pi / 15) -- +/- 2 minute tolerance
end

function TimeMatcher:isSecondMatch()
    local targetAngle = self:getAngleFromTime(self.targetS, 60)
    local currentAngle = self:getAngleFromTime(self.currentS, 60)
    return self:anglesMatch(targetAngle, currentAngle, math.pi / 15) -- +/- 2 second tolerance
end

function TimeMatcher:getAngleFromTime(val, max)
    -- Value to Angle (0 is 12 o'clock, clockwise)
    -- In Love2D/Trig: 0 is Right (3 o'clock).
    -- So 12 o'clock is -pi/2.
    -- Angle = (val / max) * 2pi - pi/2
    return (val / max) * 2 * math.pi - math.pi / 2
end

function TimeMatcher:anglesMatch(a1, a2, tolerance)
    local diff = math.abs(a1 - a2)
    -- Normalize to 0-2pi?
    -- Actually we need shortest distance on circle
    -- diff = (diff + pi) % 2pi - pi ...
    -- Simplified:
    diff = diff % (2 * math.pi)
    if diff > math.pi then diff = 2 * math.pi - diff end
    return diff < tolerance
end

function TimeMatcher:draw()
    local cx, cy = 640, 360 -- Center of Minigame Area (1280x720)

    -- Draw Background
    if self.bgImage then
        local sx = 1280 / self.bgImage:getWidth()
        local sy = 720 / self.bgImage:getHeight()
        love.graphics.setColor(1, 1, 1)
        love.graphics.draw(self.bgImage, 0, 0, 0, sx, sy)
    else
        love.graphics.setColor(1, 0.95, 0.8) -- Cream/Light Yellow
        love.graphics.rectangle("fill", 0, 0, 1280, 720)
    end

    -- Center positions for two clocks
    local leftX, leftY = self.leftClockX, self.leftClockY
    local rightX, rightY = self.rightClockX, self.rightClockY
    local radius = self.clockRadius

    -- Use unified font
    love.graphics.setFont(self.font52)

    -- Draw Timer (Left Center, Numbers Only, Chalk Effect)
    local timerText = string.format("%.1f", self.timer)
    love.graphics.setColor(1, 1, 1, 0.3) -- Faint chalk dust
    love.graphics.printf(timerText, 70 - 1, 280 - 1, 200, "left")
    love.graphics.printf(timerText, 70 + 2, 280 + 1, 200, "left")
    love.graphics.printf(timerText, 70 + 1, 280 - 2, 200, "left")
    love.graphics.setColor(1, 1, 1, 1) -- Main chalk stroke
    love.graphics.printf(timerText, 70, 280, 200, "left")

    -- Draw Rounds (Right Center, 1/3 format, Chalk Effect)
    local roundsText = string.format("%d/%d", self.round, self.totalRounds)
    love.graphics.setColor(1, 1, 1, 0.3) -- Faint chalk dust
    love.graphics.printf(roundsText, 985 - 1, 280 - 1, 200, "right")
    love.graphics.printf(roundsText, 985 + 2, 280 + 1, 200, "right")
    love.graphics.printf(roundsText, 985 + 1, 280 - 2, 200, "right")
    love.graphics.setColor(1, 1, 1, 1) -- Main chalk stroke
    love.graphics.printf(roundsText, 985, 280, 200, "right")

    -- Draw Clocks
    self:drawClock(leftX, leftY, radius, self.currentH, self.currentM, self.currentS, "YOUR TIME")
    self:drawClock(rightX, rightY, radius, self.targetH, self.targetM, self.targetS, "TARGET")
end

function TimeMatcher:drawClock(x, y, radius, h, m, s, label)
    -- Center point
    love.graphics.setColor(0, 0, 0)
    love.graphics.circle("fill", x, y, 6)

    -- Hands
    -- Hour hand: independent as requested
    local hAngle = (h % 12) * (math.pi / 6) - math.pi / 2

    love.graphics.setLineWidth(6)
    love.graphics.setColor(0, 0, 0) -- Hour (Black)
    love.graphics.line(x, y, x + math.cos(hAngle) * (radius * 0.45), y + math.sin(hAngle) * (radius * 0.45))

    -- Minute
    local mAngle = m * (math.pi / 30) - math.pi / 2
    love.graphics.setLineWidth(4)
    love.graphics.setColor(0, 0, 0) -- Minute (Black)
    love.graphics.line(x, y, x + math.cos(mAngle) * (radius * 0.7), y + math.sin(mAngle) * (radius * 0.7))

    -- Second
    if self.useSeconds then
        local sAngle = s * (math.pi / 30) - math.pi / 2
        love.graphics.setLineWidth(2)
        love.graphics.setColor(1, 0, 0)       -- Red Second hand
        love.graphics.line(x, y, x + math.cos(sAngle) * (radius * 0.9), y + math.sin(sAngle) * (radius * 0.9))
        love.graphics.circle("fill", x, y, 4) -- Red dot in center
    end
end

function TimeMatcher:mousepressed(x, y, button)
    if button == 1 then
        local cx, cy = self.leftClockX, self.leftClockY -- User interacts with Left Clock (YOUR TIME)
        local radius = self.clockRadius

        -- Calculate hand tip positions
        -- Hour
        local hAngle = (self.currentH % 12) * (math.pi / 6) - math.pi / 2
        local hx = cx + math.cos(hAngle) * (radius * 0.5)
        local hy = cy + math.sin(hAngle) * (radius * 0.5)

        -- Minute
        local mAngle = self.currentM * (math.pi / 30) - math.pi / 2
        local mx = cx + math.cos(mAngle) * (radius * 0.8)
        local my = cy + math.sin(mAngle) * (radius * 0.8)

        -- Second
        local sx, sy = -999, -999
        if self.useSeconds then
            local sAngle = self.currentS * (math.pi / 30) - math.pi / 2
            sx = cx + math.cos(sAngle) * (radius * 0.9)
            sy = cy + math.sin(sAngle) * (radius * 0.9)
        end

        -- Check distances to click
        local distH = math.sqrt((x - hx) ^ 2 + (y - hy) ^ 2)
        local distM = math.sqrt((x - mx) ^ 2 + (y - my) ^ 2)
        local distS = math.sqrt((x - sx) ^ 2 + (y - sy) ^ 2)

        local threshold = 40 -- fairly generous hit radius

        -- Prioritize: If multiple are close, maybe pick the one closest?
        -- Or prioritize Seconds > Minutes > Hours usually (since Seconds are outer/harder to grab)

        local bestDist = 9999
        local selection = nil

        if distH < threshold and distH < bestDist then
            bestDist = distH
            selection = 'h'
        end
        if distM < threshold and distM < bestDist then
            bestDist = distM
            selection = 'm'
        end
        if self.useSeconds and distS < threshold and distS < bestDist then
            bestDist = distS
            selection = 's'
        end

        if selection then
            self.dragging = selection
            self:updateHand(x, y)
        end
    end
end

function TimeMatcher:mousereleased(x, y, button)
    if button == 1 then
        self.dragging = nil
    end
end

function TimeMatcher:updateHand(x, y)
    if not self.dragging then return end

    local cx, cy = self.leftClockX, self.leftClockY
    local angle = math.atan2(y - cy, x - cx)
    -- Angle is -pi to pi. 0 is Right.
    -- Convert to clock value.
    -- 0 angle -> 3 o'clock (15 mins/seconds, 3 hours)
    -- -pi/2 -> 12 o'clock

    -- standard angle to 0-2pi starting at -pi/2?
    local clockAngle = angle + math.pi / 2
    if clockAngle < 0 then clockAngle = clockAngle + 2 * math.pi end
    -- Now 0 is 12 o'clock, growing clockwise.

    if self.dragging == 'h' then
        -- 0-2pi -> 1-12.99
        local val = (clockAngle / (2 * math.pi)) * 12
        if val == 0 then val = 12 end
        self.currentH = val
    elseif self.dragging == 'm' then
        -- 0-2pi -> 0-59.99
        local val = (clockAngle / (2 * math.pi)) * 60
        self.currentM = val
    elseif self.dragging == 's' then
        local val = (clockAngle / (2 * math.pi)) * 60
        self.currentS = val
    end
end

function TimeMatcher:mousemoved(x, y, dx, dy)
    if self.dragging then
        self:updateHand(x, y)
    end
end

function TimeMatcher:exit()
    if self.snd_ticking then
        self.snd_ticking:stop()
    end
end

function TimeMatcher:leave()
    if self.snd_ticking then
        self.snd_ticking:stop()
    end
    if self.snd_dong then
        self.snd_dong:stop()
    end
end

function TimeMatcher:pause()
    if self.snd_ticking then
        self.snd_ticking:pause()
    end
end

function TimeMatcher:resume()
    if self.snd_ticking then
        self.snd_ticking:play()
    end
end

return TimeMatcher
