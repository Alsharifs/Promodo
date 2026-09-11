-- main.lua
local Dispatcher = require("dispatcher")
local Widget = require("ui/widget/widget")
local PromodoApp = require("advanced_promodo.koplugin/promodo_app")
local _ = require("gettext")

local AdvancedPromodo = Widget:extend{
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
        title = _("Advanced Promodo"),
        general = true,
    })
end

function AdvancedPromodo:addToMainMenu(menu_items)
    menu_items.advanced_promodo = {
        text = _("Advanced Promodo Timer"),
        sub_item_table = {
            {
                text = _("Open Timer"),
                callback = function()
                    local UIManager = require("ui/uimanager")
                    -- إطلاق الإضافة كشاشة مستقلة بالكامل
                    local app = PromodoApp:new{}
                    UIManager:show(app)
                    return true
                end,
            }
        }
    }
end

return AdvancedPromodo