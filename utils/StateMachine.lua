-- utils/StateMachine.lua
local StateMachine = {}
StateMachine.__index = StateMachine

function StateMachine.new(states)
    local self = setmetatable({}, StateMachine)
    self.states = states or {} -- Table of state instances
    self.stack = {}            -- Stack of active states
    return self
end

function StateMachine:change(stateName, params)
    -- Exit current state
    if #self.stack > 0 then
        if self.stack[#self.stack].exit then
            self.stack[#self.stack]:exit()
        end
        self.stack[#self.stack] = nil -- Pop
    end

    self:push(stateName, params)
end

function StateMachine:push(stateName, params)
    local state = self.states[stateName]
    assert(state, "State " .. stateName .. " does not exist")
    if state.enter then
        state:enter(params)
    end
    table.insert(self.stack, state)
end

function StateMachine:pop()
    if #self.stack > 0 then
        if self.stack[#self.stack].exit then
            self.stack[#self.stack]:exit()
        end
        table.remove(self.stack)
    end
    -- If stack not empty, resume previous? optional
    if #self.stack > 0 then
        if self.stack[#self.stack].resume then
            self.stack[#self.stack]:resume()
        end
    end
end

function StateMachine:update(dt)
    if #self.stack > 0 then
        if self.stack[#self.stack].update then
            self.stack[#self.stack]:update(dt)
        end
    end
end

function StateMachine:draw()
    -- Draw all states in stack (for transparency/overlays)
    for _, state in ipairs(self.stack) do
        if state.draw then
            state:draw()
        end
    end
end

function StateMachine:keypressed(key)
    if #self.stack > 0 then
        if self.stack[#self.stack].keypressed then
            self.stack[#self.stack]:keypressed(key)
        end
    end
end

function StateMachine:mousepressed(x, y, button)
    if #self.stack > 0 then
        if self.stack[#self.stack].mousepressed then
            self.stack[#self.stack]:mousepressed(x, y, button)
        end
    end
end

return StateMachine
