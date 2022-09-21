local options = {
    name = "PBL",
    handler = PBL,
    type = "group",
    args = {
        frame = {
            type = "execute",
            name = "Frame",
            func = "showFrame",
            order = 1,
        },
        icon = {
            type = "execute",
            name = "Icon",
            func = "CommandIcon",
            order = 2,
        },
        alerts = {
            type = "execute",
            name = "Alerts",
            func = "CommandAlerts",
            order = 3,
        },
        chatfilter = {
            type = "execute",
            name = "ChatFilter",
            func = "CommandChatFilter",
            order = 4,
        },
    },
}

LibStub("AceConfig-3.0"):RegisterOptionsTable("PBL", options)
