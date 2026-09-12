local UIManager = require("ui/uimanager")
local FullScreenWidget = require("ui/widget/fullscreenwidget")
local CenterContainer = require("ui/widget/container/centercontainer")
local VerticalGroup = require("ui/widget/container/verticalgroup")
local HorizontalGroup = require("ui/widget/container/horizontalgroup")
local TextWidget = require("ui/widget/textwidget")
local Button = require("ui/widget/button")
local Screen = require("device").screen
local _ = require("gettext")

local PromodoApp = FullScreenWidget:extend{
    name = "PromodoApp",

    focus_time = 25 * 60,
    rest_time = 5 * 60,

    current_mode = "focus",
    is_running = false,
    end_time = 0,
    time_left = 25 * 60,
}

function PromodoApp:init()
    self.focus_time = self.focus_time or 25 * 60
    self.rest_time = self.rest_time or 5 * 60
    self.current_mode = "focus"
    self.is_running = false
    self.time_left = self.focus_time
    self.end_time = 0

    self:initUI()
    self:updateClock()

    FullScreenWidget.init(self)
end

function PromodoApp:initUI()
    self.mode_text = TextWidget:new{
        text = _("Focus"),
        face = Font:getFace("tfont", 45),
    }

    self.timer_text = TextWidget:new{
        text = self:formatTime(self.time_left),
        face = Font:getFace("tfont", 180),
    }

    self.status_text = TextWidget:new{
        text = _("Ready"),
        face = Font:getFace("tfont", 32),
    }

    self.start_button = Button:new{
        text = _("Start"),
        callback = function()
            self:startTimer()
        end,
    }

    self.pause_button = Button:new{
        text = _("Pause"),
        callback = function()
            self:pauseTimer()
        end,
    }

    self.reset_button = Button:new{
        text = _("Reset"),
        callback = function()
            self:resetTimer()
        end,
    }

    self.exit_button = Button:new{
        text = _("Exit"),
        callback = function()
            self:close()
        end,
    }

    self.buttons = HorizontalGroup:new{
        align = "center",
        self.start_button,
        self.pause_button,
        self.reset_button,
        self.exit_button,
    }

    self.content = VerticalGroup:new{
        align = "center",
        self.mode_text,
        self.timer_text,
        self.status_text,
        self.buttons,
    }

    self[1] = CenterContainer:new{
        dimen = Screen:getSize(),
        self.content,
    }
end

function PromodoApp:formatTime(seconds)
    seconds = math.max(0, math.floor(seconds))
    local minutes = math.floor(seconds / 60)
    local secs = seconds % 60
    return string.format("%02d:%02d", minutes, secs)
end

function PromodoApp:getDuration()
    if self.current_mode == "focus" then
        return self.focus_time
    end
    return self.rest_time
end

function PromodoApp:startTimer()
    if self.is_running then
        return
    end

    self.is_running = true
    self.end_time = os.time() + self.time_left
    self.status_text:setText(_("Running"))

    UIManager:nextTick(function()
        self:updateClock()
    end)
end

function PromodoApp:pauseTimer()
    if not self.is_running then
        return
    end

    self.time_left = math.max(0, self.end_time - os.time())
    self.is_running = false
    self.status_text:setText(_("Paused"))
    self:updateDisplay()
end

function PromodoApp:resetTimer()
    self.is_running = false
    self.time_left = self:getDuration()
    self.status_text:setText(_("Ready"))
    self:updateDisplay()
end

function PromodoApp:switchMode()
    if self.current_mode == "focus" then
        self.current_mode = "rest"
        self.mode_text:setText(_("Rest"))
    else
        self.current_mode = "focus"
        self.mode_text:setText(_("Focus"))
    end

    self.time_left = self:getDuration()
    self.is_running = false
    self.status_text:setText(_("Ready"))
    self:updateDisplay()
end

function PromodoApp:updateDisplay()
    self.timer_text:setText(self:formatTime(self.time_left))
    self.mode_text:setText(
        self.current_mode == "focus" and _("Focus") or _("Rest")
    )
end

function PromodoApp:updateClock()
    if not self.is_running then
        self:updateDisplay()
        return
    end

    self.time_left = math.max(0, self.end_time - os.time())
    self:updateDisplay()

    if self.time_left <= 0 then
        self.is_running = false
        self.status_text:setText(_("Completed"))
        self:switchMode()
        return
    end

    UIManager:scheduleIn(1, function()
        self:updateClock()
    end)
end

function PromodoApp:close()
    self.is_running = false
    UIManager:unschedule(self.updateClock, self)
    UIManager:close(self)
end

return PromodoApp
