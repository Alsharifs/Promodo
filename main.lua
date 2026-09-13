local Dispatcher = require("dispatcher")
local UIManager = require("ui/uimanager")
local WidgetContainer = require("ui/widget/container/widgetcontainer")
local CenterContainer = require("ui/widget/container/centercontainer")
local VerticalGroup = require("ui/widget/verticalgroup")
local ButtonTable = require("ui/widget/buttontable")
local TextBoxWidget = require("ui/widget/textboxwidget")
local VerticalSpan = require("ui/widget/verticalspan")
local Font = require("ui/font")
local Screen = require("device").screen
local InputContainer = require("ui/widget/container/inputcontainer")
local FrameContainer = require("ui/widget/container/framecontainer")
local Blitbuffer = require("ffi/blitbuffer")
local GestureRange = require("ui/gesturerange")
local Geom = require("ui/geometry")
local T = require("ffi/util").template
local _ = require("gettext")

-- ==========================================
-- PomodoroApp Display 
-- ==========================================
local PomodoroApp = InputContainer:extend{
    name = "PomodoroApp",
}

function PomodoroApp:init()
    self.app_mode = "pomodoro" -- "pomodoro" or "stopwatch"
    
    -- Pomodoro defaults (in seconds)
    self.focus_time = 25 * 60
    self.rest_time = 5 * 60
    self.pomodoro_state = "focus" -- "focus" or "rest"
    
    -- State tracking
    self.is_running = false
    self.end_time = 0          -- For Pomodoro countdown
    self.stopwatch_start = 0   -- For Stopwatch count-up start time
    self.stopwatch_paused_elapsed = 0
    self.time_left = self.focus_time

    self.covers_fullscreen = true
    self.modal = true

    self.ges_events = {
        TapClose = {
            GestureRange:new{
                ges = "tap",
                range = Geom:new{x=0, y=0, w=Screen:getWidth(), h=Screen:getHeight()}
            }
        }
    }

    -- Top Header for current system clock time
    self.header_widget = TextBoxWidget:new{
        text = os.date("%H:%M"),
        face = Font:getFace("cfont", 26),
        width = Screen:getWidth(),
        alignment = "center",
    }

    self.time_widget = TextBoxWidget:new{
        text = self:formatTime(self.time_left),
        face = Font:getFace("cfont", 130),
        width = Screen:getWidth(),
        height = math.floor(Screen:getHeight() * 0.35),
        alignment = "center",
        bold = true,
    }

    self.status_widget = TextBoxWidget:new{
        text = _("Pomodoro - Focus (Ready)"),
        face = Font:getFace("cfont", 26),
        width = Screen:getWidth(),
        alignment = "center",
    }

    self[1] = self:render()
    UIManager:setDirty(nil, "full")
end

function PomodoroApp:onShow()
    UIManager:setDirty(nil, "full")
    self:autoRefresh()
end

function PomodoroApp:onCloseWidget()
    UIManager:unschedule(self.autoRefresh, self)
end

function PomodoroApp:formatTime(seconds)
    seconds = math.max(0, math.floor(seconds))
    local minutes = math.floor(seconds / 60)
    local secs = seconds % 60
    return string.format("%02d:%02d", minutes, secs)
end

function PomodoroApp:startTimer()
    if self.is_running then return end
    self.is_running = true
    if self.app_mode == "pomodoro" then
        self.end_time = os.time() + self.time_left
    else
        self.stopwatch_start = os.time() - self.stopwatch_paused_elapsed
    end
    self:updateDisplay()
end

function PomodoroApp:pauseTimer()
    if not self.is_running then return end
    if self.app_mode == "pomodoro" then
        self.time_left = math.max(0, self.end_time - os.time())
    else
        self.stopwatch_paused_elapsed = os.time() - self.stopwatch_start
    end
    self.is_running = false
    self:updateDisplay()
end

function PomodoroApp:resetTimer()
    self.is_running = false
    if self.app_mode == "pomodoro" then
        if self.pomodoro_state == "focus" then
            self.time_left = self.focus_time
        else
            self.time_left = self.rest_time
        end
    else
        self.stopwatch_paused_elapsed = 0
        self.time_left = 0
    end
    self:updateDisplay()
end

function PomodoroApp:adjustFocus(delta)
    self.focus_time = math.max(5 * 60, math.min(180 * 60, self.focus_time + delta))
    if self.app_mode == "pomodoro" and self.pomodoro_state == "focus" and not self.is_running then
        self.time_left = self.focus_time
    end
    self:updateDisplay()
end

function PomodoroApp:adjustRest(delta)
    self.rest_time = math.max(1 * 60, math.min(60 * 60, self.rest_time + delta))
    if self.app_mode == "pomodoro" and self.pomodoro_state == "rest" and not self.is_running then
        self.time_left = self.rest_time
    end
    self:updateDisplay()
end

function PomodoroApp:toggleAppMode()
    self.is_running = false
    if self.app_mode == "pomodoro" then
        self.app_mode = "stopwatch"
        self.stopwatch_paused_elapsed = 0
        self.time_left = 0
    else
        self.app_mode = "pomodoro"
        self.pomodoro_state = "focus"
        self.time_left = self.focus_time
    end
    self:updateDisplay()
end

function PomodoroApp:update()
    -- Always update system clock header at the top
    if self.header_widget then
        local current_time_str = os.date("%H:%M")
        if self.header_widget.text ~= current_time_str then
            self.header_widget:setText(current_time_str)
            self[1] = self:render()
            UIManager:setDirty(self, "ui")
        end
    end

    if self.is_running then
        if self.app_mode == "pomodoro" then
            self.time_left = math.max(0, self.end_time - os.time())
            if self.time_left <= 0 then
                self.is_running = false
                if self.pomodoro_state == "focus" then
                    self.pomodoro_state = "rest"
                    self.time_left = self.rest_time
                else
                    self.pomodoro_state = "focus"
                    self.time_left = self.focus_time
                end
            end
        else
            -- Stopwatch count-up mode
            self.time_left = os.time() - self.stopwatch_start
        end
        self:updateDisplay()
    end
end

function PomodoroApp:autoRefresh()
    self:update()
    UIManager:scheduleIn(1, self.autoRefresh, self)
end

function PomodoroApp:updateDisplay()
    local txt = self:formatTime(self.time_left)
    if self.time_widget.text ~= txt then
        self.time_widget:setText(txt)
    end

    local status_str = ""
    if self.app_mode == "pomodoro" then
        local state_name = (self.pomodoro_state == "focus" and _("Focus") or _("Rest"))
        local run_state = (self.is_running and _("Running") or _("Paused/Ready"))
        status_str = T(_("Pomodoro: %1 (%2) [F:%3m R:%4m]"), state_name, run_state, math.floor(self.focus_time/60), math.floor(self.rest_time/60))
    else
        local run_state = (self.is_running and _("Running") or _("Paused/Ready"))
        status_str = T(_("Stopwatch (Count-up) (%1)"), run_state)
    end
    self.status_widget:setText(status_str)

    self[1] = self:render()
    UIManager:setDirty(self, "ui")
end

function PomodoroApp:render()
    local s = Screen:getSize()

    local start_pause_text = self.is_running and _("Pause") or _("Start")
    local mode_name_btn = (self.app_mode == "pomodoro") and _("Switch to Stopwatch") or _("Switch to Pomodoro")

    local row1 = {
        { text = start_pause_text, callback = function() 
            if self.is_running then self:pauseTimer() else self:startTimer() end 
        end },
        { text = _("Reset"), callback = function() self:resetTimer() end },
    }

    local row2, row3, row4
    if self.app_mode == "pomodoro" then
        row2 = {
            { text = _("Focus +5"), callback = function() self:adjustFocus(5 * 60) end },
            { text = _("Focus -5"), callback = function() self:adjustFocus(-5 * 60) end },
        }
        row3 = {
            { text = _("Rest +5"), callback = function() self:adjustRest(5 * 60) end },
            { text = _("Rest -5"), callback = function() self:adjustRest(-5 * 60) end },
        }
        row4 = {
            { text = mode_name_btn, callback = function() self:toggleAppMode() end },
            { text = _("Exit"), callback = function() 
                self:onCloseWidget()
                UIManager:close(self) 
            end },
        }
        self.buttons = ButtonTable:new{
            width = math.floor(s.w * 0.9),
            buttons = { row1, row2, row3, row4 },
        }
    else
        row2 = {
            { text = mode_name_btn, callback = function() self:toggleAppMode() end },
            { text = _("Exit"), callback = function() 
                self:onCloseWidget()
                UIManager:close(self) 
            end },
        }
        self.buttons = ButtonTable:new{
            width = math.floor(s.w * 0.9),
            buttons = { row1, row2 },
        }
    end

    local content = VerticalGroup:new{
        align = "center",
        VerticalSpan:new{ height = math.floor(s.h * 0.02) },
        self.header_widget,
        VerticalSpan:new{ height = math.floor(s.h * 0.04) },
        self.time_widget,
        VerticalSpan:new{ height = math.floor(s.h * 0.02) },
        self.status_widget,
        VerticalSpan:new{ height = math.floor(s.h * 0.03) },
        self.buttons,
    }

    return FrameContainer:new{
        background = Blitbuffer.COLOR_WHITE,
        dimen = s,
        CenterContainer:new{ dimen = s, content },
    }
end

-- ==========================================
-- Main Plugin Container
-- ==========================================
local Pomodoro = WidgetContainer:extend{
    name = "pomodoro",
}

function Pomodoro:init()
    self:onDispatcherRegisterActions()
    self.ui.menu:registerToMainMenu(self)
end

function Pomodoro:onDispatcherRegisterActions()
    Dispatcher:registerAction("pomodoro_action", {
        category = "none",
        event = "Pomodoro",
        title = _("Pomodoro"),
        general = true,
    })
end

function Pomodoro:onPomodoro()
    local app = PomodoroApp:new{}
    UIManager:show(app)
    return true
end

function Pomodoro:addToMainMenu(menu_items)
    menu_items.pomodoro = {
        text = _("Pomodoro Timer"),
        sub_item_table = {
            {
                text = _("Open Timer"),
                callback = function()
                    local app = PomodoroApp:new{}
                    UIManager:show(app)
                end,
            },
        },
    }
end

return Pomodoro
