PBL = LibStub("AceAddon-3.0"):NewAddon("Personal Black List", "AceConsole-3.0", "AceEvent-3.0", "AceComm-3.0")
local GLDataBroker = LibStub("LibDataBroker-1.1"):NewDataObject("PBL", {
    type = "data source",
    text = "PBL",
    icon = "Interface\\AddOns\\PersonalBlacklist\\media\\___newIcon.blp",
    OnTooltipShow = function(tooltip)
          tooltip:SetText("Personal Black List")
          tooltip:AddLine("Ban List", 1, 1, 1)
          tooltip:Show()
     end,
    OnClick = function() PBL:showFrame() end,

})
local icon = LibStub("LibDBIcon-1.0")
local L = LibStub("AceLocale-3.0"):GetLocale("PBL")

local defaults = {
    global = {
        banlist = {},
        blackList = {}
    },
    profile= {
        classes={
            "UNSPECIFIED",
            "DEATHKNIGHT",
            "DEMONHUNTER",
            "DRUID",
            "HUNTER",
            "MAGE",
            "MONK",
            "PALADIN",
            "PRIEST",
            "ROGUE",
            "SHAMAN",
            "WARLOCK",
            "WARRIOR"
        },
        categories={
            L["dropDownAll"],
            L["dropDownGuild"],
            L["dropDownRaid"],
            L["dropDownMythic"],
            L["dropDownPvP"],
            L["dropDownWorld"]
        },
        reasons={
            L["dropDownAll"],
            L["dropDownQuit"],
            L["dropDownToxic"],
            L["dropDownBadDPS"],
            L["dropDownBadHeal"],
            L["dropDownBadTank"],
            L["dropDownBadPlayer"],
            L["dropDownAFK"],
            L["dropDownNinja"],
            L["dropDownSpam"],
            L["dropDownScam"],
            L["dropDownRac"]
        },
        minimap = { hide = false, },
        chatfilter = { disabled = true, },
        ShowAlert = {
            ["LeaveAlert"] = false,
            ["count"] = 0,
            ["onparty"] = {},
        },
        
    }
}

function createBanItem(name,realm,classFile,category,reason)
    local unitobjtoban ={
        name = strupper(name),
        realm = strupper(realm),
        classFile = strupper(classFile),
        catIdx = tonumber(category),
        reaIdx = tonumber(reason),
    }
    return unitobjtoban
end

function PBL:OnInitialize()
    self.db = LibStub("AceDB-3.0"):New("PBLDB", defaults, true)
    self.optionsFrame = LibStub("AceConfigDialog-3.0"):AddToBlizOptions("PBL", "PBL")        
    icon:Register("PBL", GLDataBroker, self.db.profile.minimap)
    StaticPopupDialogs.CONFIRM_LEAVE_IGNORE = {
        text = "%s",
        button1 = L["confirmYesBtn"],
        button2 = L["confirmNoBtn"],
        OnAccept = function() C_PartyInfo.LeaveParty() end,
        whileDead = 1, hideOnEscape = 1, showAlert = 1,
    }
    
    if #PBL.db.global.banlist > 0 then        
        local index, value
        for index, value in ipairs(PBL.db.global.banlist) do
            local name,_,realm,_,classFile,_,category,_,reason = strsplit("$$",value)
            table.insert(PBL.db.global.blackList, createBanItem(name,realm,classFile,category,reason))
            
        end
        PBL.db.global.banlist = {}
    end    
end

PBL:RegisterChatCommand("pbl", "SlashPBLCommand")


function PBL:SlashPBLCommand(input)
    if not input or input:trim() == "" then
        --InterfaceOptionsFrame_OpenToCategory(self.optionsFrame)
        PBL:showFrame()
    elseif input:trim() =="config" then
        LibStub("AceConfigDialog-3.0"):Open("PBL")
    else
        LibStub("AceConfigCmd-3.0"):HandleCommand("pbl", "PBL", input)
    end
end

function PBL:CommandIcon()
    self.db.profile.minimap.hide = not self.db.profile.minimap.hide
    if self.db.profile.minimap.hide then
        icon:Hide("PBL")
    else
        icon:Show("PBL")
    end
end

function PBL:CommandChatFilter()
    self.db.profile.chatfilter.disabled = not self.db.profile.chatfilter.disabled
    if self.db.profile.chatfilter.disabled then
        PBL:Print("Chat filter disabled")
    else
        PBL:Print("Chat filter enabled")
    end
end

function PBL:CommandAlerts()
    self.db.profile.ShowAlert["LeaveAlert"] = not self.db.profile.ShowAlert["LeaveAlert"]
    if self.db.profile.ShowAlert["LeaveAlert"] then
        PBL:Print("Alerts disabled")
    else
        PBL:Print("Alerts enabled")
    end
end

function isbanned (tab, val)
    local index, value
    for index, value in ipairs(tab) do
        if value.name.."-"..value.realm == strupper(val) then
            return true, index
        end
    end
    return false, 0
end

function has_value (tab, val)
    local index, value
    for index, value in ipairs(tab) do
        if value == val then
            return true
        end
    end
    return false
end

function mysplit (inputstr, sep)
    if sep == nil then
        sep = "%s"
    end
    local t={}
    local str
    for str in string.gmatch(inputstr, "([^"..sep.."]+)") do
        table.insert(t, str)
    end
    return t
end

function PBL:addtolist(name,realm,classFile,category,reason)
    local fullname = name.."-"..realm
    --local unitobjtoban = name.."$$"..realm.."$$"..classFile.."$$"..category.."$$"..reason
    local unitobjtoban = createBanItem(name,realm,classFile,category,reason)
    table.insert(PBL.db.global.blackList, unitobjtoban)
    PBL:Print("|cffff0000"..fullname.." Succesfully added to blacklist!")
end

function PBL:rmvfromlist(fullname, idx)
    table.remove(PBL.db.global.blackList, idx)
    PBL:Print("|cff008000"..fullname.." Removed from blacklist")
end

function PBL:clearlist()
    PBL.db.global.blackList = {}
end

local function blackListButton(self)
    local button = self.value;
    if ( button == "AddToPBL" ) then
        local dropdownFrame = UIDROPDOWNMENU_INIT_MENU
        local unit = dropdownFrame.unit
        local name = dropdownFrame.name
        local server = dropdownFrame.server
        local className,classFile,classID 
        if unit then
            className,classFile,classID = UnitClass(unit)
        -- elseif self.owner == "FRIEND" then
        --     if name == nil or name == "" or server == nil or server == "" then
        --         PBL:Print("cant read name or realm")
        --         return
        --     else
        --         --HOW TO RETRIEVE CLASS ON CHAT???????
        --         PBL:addtolist(name,server,"UNSPECIFIED",0,0)
        --         return
        --     end
        end
        if server==nil then
            local realm = GetRealmName()
            server=realm:gsub(" ","")
        end
        local fullname = name.."-"..server
        if (fullname ~= nil and fullname ~= "") or (name ~= nil and name ~= "" and server ~= nil and server ~= "" and self.owner == "FRIEND") then
            local exist, i = isbanned(PBL.db.global.blackList, fullname)
            if not classFile then
                classFile = "UNSPECIFIED"
            end
            if exist then
                PBL:rmvfromlist(fullname, i)
            else
                PBL:addtolist(name,server,classFile,1,1)
            end
            PBL:refreshWidgetCore()
        end    
    end
end

--local PopUpMenu = CreateFrame("Frame","PopUpMenuFrame")
--PopUpMenu:SetScript("OnEvent", function() hooksecurefunc("UnitPopup_OnClick", blackListButton) end)
--PopUpMenu:RegisterEvent("PLAYER_LOGIN")
--local PopupUnits = {}
--UnitPopupButtons["AddToPBL"] = { text = "Add/Remove to PBL", }
--local i, j, UPMenus
--for i,UPMenus in pairs(UnitPopupMenus) do
--    for j=1, #UPMenus do
--        if UPMenus[j] == "INSPECT" then
--            PopupUnits[#PopupUnits + 1] = i
--            pos = j + 1
--            table.insert( UnitPopupMenus[i] ,pos , "AddToPBL" )
--            break
--        end
--    end
--end

local TestDropdownMenuList = {"PLAYER","RAID_PLAYER","PARTY","FRIEND",}

function Assignfunchook(dropdownMenu, which, unit, name, userData, ...)
    if UIDROPDOWNMENU_MENU_LEVEL > 1 then
        return
    end
    if not has_value(TestDropdownMenuList,which) then
        return
    end
    local selfname = UnitName("player")
    local realm = GetRealmName()
    if which == "FRIEND" and name == selfname.."-"..realm then
        return
    end
    local info = UIDropDownMenu_CreateInfo()
    info.text = "Add/Remove to PBL"
    info.owner = which
    info.notCheckable = 1
    info.func = blackListButton
    info.colorCode = "|cffff0000"
    info.value = "AddToPBL"
    UIDropDownMenu_AddButton(info)
end

hooksecurefunc("UnitPopup_ShowMenu", Assignfunchook)


GameTooltip:HookScript("OnTooltipSetUnit", function(self)
    local name, unit = self:GetUnit()
    if UnitIsPlayer(unit) and not UnitIsUnit(unit, "player") and not UnitIsUnit(unit, "party") then
        local name, realm = UnitName(unit)
        if realm == nil then
            realm=GetRealmName()
            realm=realm:gsub(" ","");
        end
        fullname = name .. "-" .. realm;
        if isbanned(PBL.db.global.blackList, fullname) then
            self:AddLine("Blacklisted! (PBL)", 1, 0, 0, true)	
        end
    end
end)

local hooked = { }

local function OnLeaveHook(self)
		GameTooltip:Hide();
end

hooksecurefunc("LFGListApplicationViewer_UpdateResults", function(self)
    local buttons = self.ScrollFrame.buttons
    local i, j
	for i = 1, #buttons do
		local button = buttons[i]
		if not hooked[button] then
			if button.applicantID and button.Members then
				for j = 1, #button.Members do
					local b = button.Members[j]
					if not hooked[b] then
						hooked[b] = 1
						b:HookScript("OnEnter", function()
							local appID = button.applicantID;
							local name = C_LFGList.GetApplicantMemberInfo(appID, 1);
							if not string.match(name, "-") then
								local realm = GetRealmName();
								realm=realm:gsub(" ","");
								fullname = name.."-"..realm;
							end
							if isbanned(PBL.db.global.blackList, fullname) then			
								GameTooltip:AddLine("Blacklisted! (PBL)",1,0,0,true);
								GameTooltip:Show();
							end
						end)
						b:HookScript("OnLeave", OnLeaveHook)
					end
				end
			end
		end
	end
end)



function PBL:gru_eventhandler()
    local aux = false
    local latestGroupMembers = GetNumGroupMembers()
    if self.db.profile.ShowAlert["count"] == latestGroupMembers then
        return
    elseif self.db.profile.ShowAlert["count"] > latestGroupMembers then
        self.db.profile.ShowAlert["count"] = latestGroupMembers
        local name,realm="";
        self.db.profile.ShowAlert["onparty"] = {}
        for l=1, latestGroupMembers do
            if latestGroupMembers < 6 then
                name,realm = UnitName("party".. l)
            else
                name,realm = UnitName("raid".. l)
            end
            if name then
                if (not realm) or (realm == " ") or (realm == "") then realm = GetRealmName(); realm=realm:gsub(" ",""); end
                local fullname = name.."-"..realm
                if fullname ~= nil or fullname ~= "" then
                    local exist, i = isbanned(PBL.db.global.blackList, fullname)
                    if exist == true then
                        table.insert(self.db.profile.ShowAlert["onparty"], fullname)               
                    end
                end
            end
        end


        return
    elseif self.db.profile.ShowAlert["count"] == latestGroupMembers then
        return
    end

    local pjs = {};
    local name,realm="";
    local i
    for i=1, latestGroupMembers do
        if latestGroupMembers < 6 then
            name,realm = UnitName("party".. i)
        else
            name,realm = UnitName("raid".. i)
        end
        if name then
            if (not realm) or (realm == " ") or (realm == "") then realm = GetRealmName(); realm=realm:gsub(" ",""); end
            local fullname = name.."-"..realm            
            if fullname ~= nil or fullname ~= "" then
                local exist, i = isbanned(PBL.db.global.blackList, fullname)
                local exist2, j = has_value(PBL.db.profile.ShowAlert["onparty"], fullname)
                if exist == true then
                    if exist2 == false then
                        PBL:Print("|cffff0000".."Here is",fullname,"who is in your BlackList")
                        table.insert(self.db.profile.ShowAlert["onparty"], fullname)  
                        aux = true
                    end
                    pjs[table.getn(pjs) + 1] = fullname
                    self.db.profile.ShowAlert["count"] = latestGroupMembers                 
                end
            end
        end
    end

    if self.db.profile.ShowAlert["LeaveAlert"] == false and aux == true then
        if table.getn(pjs) ~= 0 then          
            local text = "", j
            for j=1, table.getn(pjs) do
                text = text..pjs[j].."\n"
            end
            if table.getn(pjs) > 1 then
                text = text..L["confirmMultipleTxt"]
            else
                text = text..L["confirmSingleTxt"]
            end
            StaticPopup_Show("CONFIRM_LEAVE_IGNORE", text);
        end
    end
end

PBL:RegisterEvent("GROUP_ROSTER_UPDATE", "gru_eventhandler")

local function myChatFilter(self, event, msg, author, ...)
    if PBL.db.profile.chatfilter.disabled then
        return false
    end 
    local category = ""
    local exist, i = isbanned(PBL.db.global.blackList, author)
    if exist then
        local banObj = PBL.db.global.blackList[i]
        local categorystr = PBL.db.profile.categories[tonumber(banObj.catIdx)]
        local reasonstr = PBL.db.profile.reasons[tonumber(banObj.reaIdx)]
        if exist then
            --DEFAULT_CHAT_FRAME:AddMessage(tostring(categorystr))
            if banObj.catIdx ~= 1 then
                category=" w "..tostring(categorystr)
            end
            return false, "|cffff3030[PBL:"..tostring(reasonstr)..category.."]|cffff7f7f "..msg, author, ...
        end
    end
    return false
 end
 
 ChatFrame_AddMessageEventFilter("CHAT_MSG_CHANNEL", myChatFilter)
 ChatFrame_AddMessageEventFilter("CHAT_MSG_SAY", myChatFilter)
 ChatFrame_AddMessageEventFilter("CHAT_MSG_YELL", myChatFilter)
 ChatFrame_AddMessageEventFilter("CHAT_MSG_WHISPER", myChatFilter)
 ChatFrame_AddMessageEventFilter("CHAT_MSG_RAID", myChatFilter)
 ChatFrame_AddMessageEventFilter("CHAT_MSG_PARTY", myChatFilter)
 ChatFrame_AddMessageEventFilter("CHAT_MSG_GUILD", myChatFilter)
 ChatFrame_AddMessageEventFilter("CHAT_MSG_INSTANCE", myChatFilter)
