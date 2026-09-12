local Dispatcher = require("dispatcher")
local UIManager = require("ui/uimanager")
local WidgetContainer = require("ui/widget/container/widgetcontainer")
local PromodoApp = require("promodo_app")
local _ = require("gettext")

local AdvancedPromodo = WidgetContainer:extend{
    name = "advanced_promodo",
}

function AdvancedPromodo:init()
    self:onDispatcherRegisterActions()
    self.ui.menu:registerToMainMenu(self)
end

function AdvancedPromodo:onDispatcherRegisterActions()
    Dispatcher:registerAction("advanced_promodo_action", {
        category = "none",
        event = "AdvancedPromodo",
        title = _("Advanced Pomodoro"),
        general = true,
    })
end

function AdvancedPromodo:addToMainMenu(menu_items)
    menu_items.advanced_promodo = {
        text = _("Advanced Pomodoro Timer"),
        sub_item_table = {
            {
                text = _("Open Timer"),
                callback = function()
                    local app = PromodoApp:new{}
                    UIManager:show(app)
                end,
            },
        },
    }
end

return AdvancedPromodo
