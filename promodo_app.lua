-- promodo_app.lua
local UIManager = require("ui/uimanager")
local FullScreenWidget = require("ui/widget/fullscreenwidget")
local CenterContainer = require("ui/widget/container/centercontainer")
local VerticalGroup = require("ui/widget/verticalgroup")
local HorizontalGroup = require("ui/widget/horizontalgroup")
local TextWidget = require("ui/widget/textwidget")
local Button = require("ui/widget/button")
local Screen = require("device").screen

local PromodoApp = FullScreenWidget:extend{
    name = "PromodoApp",
    focus_time = 25 * 60, -- 25 دقيقة
    rest_time = 5 * 60,   -- 5 دقائق
    current_mode = "focus",
    is_running = false,
    end_time = 0,
    time_left = 25 * 60,
}

function PromodoApp:init()
    -- تصميم الـ HUD (الوقت والتاريخ) أعلى الشاشة
    self.time_label = TextWidget:new{
        text = os.date("%Y-%m-%d  |  %H:%M"),
        face = "font",
        bold = true,
        size = 32,
        alignment = "center",
    }

    -- تصميم حالة المؤقت
    self.status_label = TextWidget:new{
        text = "Focus Mode - وضع التركيز",
        face = "font",
        size = 45,
        alignment = "center",
    }

    -- تصميم العداد الرئيسي
    self.timer_label = TextWidget:new{
        text = "25:00",
        face = "font",
        bold = true,
        size = 180, -- خط ضخم للعداد
        alignment = "center",
    }

    -- أزرار التحكم
    self.start_btn = Button:new{
        text = "Start / Pause",
        bordersize = 2,
        padding = 20,
        callback = function() self:toggleTimer() end,
    }

    self.reset_btn = Button:new{
        text = "Reset",
        bordersize = 2,
        padding = 20,
        callback = function() self:resetTimer() end,
    }
    
    self.exit_btn = Button:new{
        text = "Exit",
        bordersize = 2,
        padding = 20,
        callback = function() 
            self:stopTick()
            UIManager:close(self) 
        end,
    }

    local controls = HorizontalGroup:new{
        align = "center",
        self.start_btn,
        self.reset_btn,
        self.exit_btn,
    }

    -- تجميع الواجهة في المنتصف
    self.layout = CenterContainer:new{
        dimen = Screen:getSize(),
        VerticalGroup:new{
            align = "center",
            self.time_label,
            TextWidget:new{ text = " ", size = 150 }, -- مساحة فارغة
            self.status_label,
            self.timer_label,
            TextWidget:new{ text = " ", size = 100 }, -- مساحة فارغة
            controls,
        }
    }
    
    self[1] = self.layout
    
    -- جدولة تحديث الشاشة الدقيق كل ثانية
    self.clock_action = function() self:updateClock() end
    UIManager:schedule(self.clock_action, 1)
end

function PromodoApp:toggleTimer()
    if self.is_running then
        -- إيقاف مؤقت
        self.is_running = false
        self.time_left = self.end_time - os.time()
    else
        -- بدء (استخدام os.time لضمان الدقة وتجنب الـ Drift)
        self.is_running = true
        self.end_time = os.time() + self.time_left
    end
    self:updateUI()
end

function PromodoApp:resetTimer()
    self.is_running = false
    if self.current_mode == "focus" then
        self.time_left = self.focus_time
    else
        self.time_left = self.rest_time
    end
    self:updateUI()
end

function PromodoApp:switchMode()
    if self.current_mode == "focus" then
        self.current_mode = "rest"
        self.time_left = self.rest_time
    else
        self.current_mode = "focus"
        self.time_left = self.focus_time
    end
    self.is_running = false
    self:updateUI()
end

function PromodoApp:updateClock()
    if self.is_running then
        local current = os.time()
        self.time_left = self.end_time - current
        
        if self.time_left <= 0 then
            self:switchMode()
            -- يمكن إضافة رسالة تنبيه هنا مستقبلاً
        end
    end
    self:updateUI()
    UIManager:schedule(self.clock_action, 1)
end

function PromodoApp:updateUI()
    -- تحديث النصوص
    local m = math.floor(math.abs(self.time_left) / 60)
    local s = math.abs(self.time_left) % 60
    self.timer_label:setText(string.format("%02d:%02d", m, s))
    
    self.time_label:setText(os.date("%Y-%m-%d  |  %H:%M"))
    
    if self.current_mode == "focus" then
        self.status_label:setText("Focus Mode - وضع التركيز")
    else
        self.status_label:setText("Rest Mode - وضع الاستراحة")
    end
    
    -- تحديث الشاشة
    UIManager:setDirty(self, "ui")
end

function PromodoApp:stopTick()
    UIManager:unschedule(self.clock_action)
end

return PromodoApp