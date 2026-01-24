-- minigames/stocks-timing/init.lua
local Button = require 'utils.Button'

local Minigame = {
    instruction = "INVESTIS !"
}

function Minigame:enter(difficulty)
    self.difficulty = difficulty or 1
    self.won = false
    self.lost = false

    -- Timer settings
    self.timeLimit = 10
    self.timer = 0
    self.baseTime = 0

    -- Stock settings
    self.stockValue = 50
    self.stockHistory = {}
    self.maxHistory = 80

    -- Initialize history with starting value
    for i = 1, self.maxHistory do
        table.insert(self.stockHistory, self.stockValue)
    end

    -- Money based on difficulty: 200$ if < 1.5, 100$ if < 2.5, else 50$
    if self.difficulty < 1.5 then
        self.money = 200
    elseif self.difficulty < 2.5 then
        self.money = 100
    else
        self.money = 50
    end

    self.startingMoney = self.money
    self.sharesOwned = 0
    self.buyPrices = {} -- FIFO queue for tracking buy prices
    self.totalProfit = 0

    -- Stock update timing
    self.stockUpdateTimer = 0
    self.stockUpdateInterval = 0.05 -- Update stock every 0.05 seconds (faster)

    -- Difficulty affects frequency and noise (increased for 10s gameplay)
    self.frequency = 1.2 + self.difficulty * 0.5
    self.noiseMultiplier = self.difficulty * 0.8

    -- Click bonus for winning
    self.clickBonus = 30

    -- Create buttons
    local btnWidth = 120
    local btnHeight = 50
    local btnY = 600

    self.buyButton = Button.new("BUY", 400, btnY, btnWidth, btnHeight, function()
        self:buyStock()
    end)

    self.sellButton = Button.new("SELL", 760, btnY, btnWidth, btnHeight, function()
        self:sellStock()
    end)
end

function Minigame:buyStock()
    if self.money >= self.stockValue and not self.won and not self.lost then
        self.money = self.money - self.stockValue
        self.sharesOwned = self.sharesOwned + 1
        table.insert(self.buyPrices, self.stockValue)
    end
end

function Minigame:sellStock()
    if self.sharesOwned > 0 and not self.won and not self.lost then
        self.sharesOwned = self.sharesOwned - 1
        local buyPrice = table.remove(self.buyPrices, 1) -- FIFO
        local profit = self.stockValue - buyPrice
        self.totalProfit = self.totalProfit + profit
        self.money = self.money + self.stockValue
    end
end

function Minigame:update(dt)
    if self.won then return "won" end
    if self.lost then return "lost" end

    self.timer = self.timer + dt
    self.baseTime = self.baseTime + dt

    -- Update stock value periodically
    self.stockUpdateTimer = self.stockUpdateTimer + dt
    if self.stockUpdateTimer >= self.stockUpdateInterval then
        self.stockUpdateTimer = 0

        -- Calculate new stock value: base + sine wave + noise
        local sineValue = math.sin(self.baseTime * self.frequency) * 30
        local noise = (math.random() - 0.5) * 10 * self.noiseMultiplier
        self.stockValue = math.max(10, math.min(100, 50 + sineValue + noise))
        self.stockValue = math.floor(self.stockValue * 100) / 100 -- Round to 2 decimals

        -- Update history
        table.insert(self.stockHistory, self.stockValue)
        if #self.stockHistory > self.maxHistory then
            table.remove(self.stockHistory, 1)
        end
    end

    -- Check win/lose condition when time is up
    if self.timer >= self.timeLimit then
        -- Auto-sell remaining shares at current price
        while self.sharesOwned > 0 do
            self:sellStock()
        end

        -- Win condition: profit >= 10 * difficulty (adjusted for 10s gameplay)
        local targetProfit = 10 * self.difficulty
        if self.totalProfit >= targetProfit then
            self.won = true
            return "won"
        else
            self.lost = true
            return "lost"
        end
    end

    return nil
end

function Minigame:draw()
    -- Dark background
    love.graphics.setColor(0.1, 0.1, 0.18)
    love.graphics.rectangle("fill", 0, 0, 1280, 720)

    -- Draw title
    love.graphics.setColor(1, 1, 1)
    love.graphics.printf("STOCK TRADING", 0, 20, 1280, "center")
    love.graphics.printf("Get Stocks", 0, 50, 1280, "center")

    -- Draw graph area
    local graphX = 100
    local graphY = 80
    local graphW = 1080
    local graphH = 400

    -- Graph background
    love.graphics.setColor(0.15, 0.15, 0.25)
    love.graphics.rectangle("fill", graphX, graphY, graphW, graphH)

    -- Graph border
    love.graphics.setColor(0.3, 0.3, 0.4)
    love.graphics.setLineWidth(2)
    love.graphics.rectangle("line", graphX, graphY, graphW, graphH)

    -- Draw grid lines
    love.graphics.setColor(0.25, 0.25, 0.35)
    love.graphics.setLineWidth(1)
    for i = 1, 4 do
        local y = graphY + (graphH / 5) * i
        love.graphics.line(graphX, y, graphX + graphW, y)
    end

    -- Draw price labels
    love.graphics.setColor(0.6, 0.6, 0.7)
    love.graphics.print("$100", graphX - 40, graphY - 5)
    love.graphics.print("$50", graphX - 35, graphY + graphH / 2 - 5)
    love.graphics.print("$10", graphX - 30, graphY + graphH - 10)

    -- Draw stock line
    love.graphics.setColor(0.2, 0.9, 0.3)
    love.graphics.setLineWidth(2)

    local points = {}
    for i, value in ipairs(self.stockHistory) do
        local x = graphX + ((i - 1) / (self.maxHistory - 1)) * graphW
        -- Map value (10-100) to graph height (graphY + graphH to graphY)
        local y = graphY + graphH - ((value - 10) / 90) * graphH
        table.insert(points, x)
        table.insert(points, y)
    end

    if #points >= 4 then
        love.graphics.line(points)
    end

    -- Draw current value indicator
    local currentY = graphY + graphH - ((self.stockValue - 10) / 90) * graphH
    love.graphics.setColor(1, 1, 0)
    love.graphics.circle("fill", graphX + graphW, currentY, 8)

    -- Draw info panel
    local infoY = 500
    love.graphics.setColor(1, 1, 1)

    -- Current stock value
    love.graphics.setColor(1, 1, 0)
    love.graphics.printf(string.format("Stock Value: $%.2f", self.stockValue), 0, infoY, 1280, "center")

    -- Stats row
    love.graphics.setColor(1, 1, 1)
    local statsY = infoY + 35
    love.graphics.printf(string.format("Money: $%.2f", self.money), 100, statsY, 300, "left")
    love.graphics.printf(string.format("Shares: %d", self.sharesOwned), 500, statsY, 280, "center")
    love.graphics.printf(string.format("Profit: $%.2f", self.totalProfit), 880, statsY, 300, "right")

    -- Target profit and time
    local targetProfit = 10 * self.difficulty
    local timeLeft = math.max(0, self.timeLimit - self.timer)

    if self.totalProfit >= targetProfit then
        love.graphics.setColor(0.2, 1, 0.3)
    else
        love.graphics.setColor(1, 0.5, 0.3)
    end
    love.graphics.printf(string.format("Target: $%.0f", targetProfit), 100, statsY + 30, 300, "left")

    love.graphics.setColor(1, 1, 1)
    love.graphics.printf(string.format("Time: %.1fs", timeLeft), 880, statsY + 30, 300, "right")

    -- Draw buttons with custom colors
    -- Buy button (green)
    love.graphics.setColor(0.2, 0.7, 0.3)
    love.graphics.rectangle("fill", self.buyButton.x, self.buyButton.y, self.buyButton.w, self.buyButton.h)
    love.graphics.setColor(1, 1, 1)
    local font = love.graphics.getFont()
    local textW = font:getWidth(self.buyButton.text)
    local textH = font:getHeight()
    love.graphics.print(self.buyButton.text, self.buyButton.x + (self.buyButton.w - textW) / 2, self.buyButton.y + (self.buyButton.h - textH) / 2)

    -- Sell button (red)
    love.graphics.setColor(0.8, 0.2, 0.2)
    love.graphics.rectangle("fill", self.sellButton.x, self.sellButton.y, self.sellButton.w, self.sellButton.h)
    love.graphics.setColor(1, 1, 1)
    textW = font:getWidth(self.sellButton.text)
    love.graphics.print(self.sellButton.text, self.sellButton.x + (self.sellButton.w - textW) / 2, self.sellButton.y + (self.sellButton.h - textH) / 2)

    -- Difficulty indicator
    love.graphics.setColor(0.6, 0.6, 0.7)
    love.graphics.printf(string.format("Difficulty: %.1f", self.difficulty), 0, 680, 1280, "center")
end

function Minigame:keypressed(key)
    -- Optional keyboard controls
    if key == 'b' then
        self:buyStock()
    elseif key == 's' then
        self:sellStock()
    end
end

function Minigame:mousepressed(x, y, button)
    if button == 1 then
        self.buyButton:clicked(x, y)
        self.sellButton:clicked(x, y)
    end
end

return Minigame
