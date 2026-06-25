if not C_Timer then
    local timers = {}
    local timerFrame = CreateFrame("Frame", "TurboPlatesTimerFrame")

    local timerMethods = {}
    timerMethods.__index = timerMethods

    function timerMethods:Cancel()
        self.cancelled = true
    end

    function timerMethods:IsCancelled()
        return self.cancelled == true
    end

    local function UpdateTimer(timer, elapsed)
        if timer.cancelled then
            return true
        end

        timer.remaining = timer.remaining - elapsed
        if timer.remaining > 0 then
            return false
        end

        timer.callback(timer)

        if timer.cancelled or not timer.ticker then
            return true
        end

        if timer.iterations then
            timer.iterations = timer.iterations - 1
            if timer.iterations <= 0 then
                timer.cancelled = true
                return true
            end
        end

        timer.remaining = timer.duration
        return false
    end

    timerFrame:SetScript("OnUpdate", function(_, elapsed)
        for index = #timers, 1, -1 do
            if UpdateTimer(timers[index], elapsed) then
                table.remove(timers, index)
            end
        end

        if #timers == 0 then
            timerFrame:Hide()
        end
    end)
    timerFrame:Hide()

    local function CreateTimer(duration, callback, ticker, iterations)
        local timer = setmetatable({
            duration = duration and duration > 0 and duration or 0.01,
            remaining = duration and duration > 0 and duration or 0.01,
            callback = callback,
            ticker = ticker,
            iterations = iterations,
            cancelled = false,
        }, timerMethods)

        table.insert(timers, timer)
        timerFrame:Show()
        return timer
    end

    C_Timer = {}

    function C_Timer.After(duration, callback, fallbackCallback)
        if type(duration) ~= "number" then
            duration, callback = callback, fallbackCallback
        end

        CreateTimer(duration, callback, false)
    end

    function C_Timer.NewTimer(duration, callback, fallbackCallback)
        if type(duration) ~= "number" then
            duration, callback = callback, fallbackCallback
        end

        return CreateTimer(duration, callback, false)
    end

    function C_Timer.NewTicker(duration, callback, iterations, fallbackCallback)
        if type(duration) ~= "number" then
            duration, callback, iterations = callback, iterations, fallbackCallback
        end

        return CreateTimer(duration, callback, true, iterations)
    end

    _G.C_Timer = C_Timer
end
