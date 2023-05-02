PBL = LibStub("AceAddon-3.0"):NewAddon("Personal Black List", "AceConsole-3.0", "AceEvent-3.0", "AceComm-3.0")
local GLDataBroker = LibStub("LibDataBroker-1.1"):NewDataObject("PBL", {
    type = "data source",
    text = "PBL",
    icon = "Interface\\AddOns\\PersonalBlacklist\\media\\___newIcon.blp",
    OnTooltipShow = function(tooltip)
          tooltip:SetText("Personal Blacklist")
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
            "WARRIOR",
            "EVOKER",
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

-- --------------------------------------------------------------------------
-- Create Ban Item
-- --------------------------------------------------------------------------
-- Create item to add to blacklist.
-- TODO: Refactor to potentially use a class instead of a table.
--       Potentially move to Utils.lua
-- --------------------------------------------------------------------------

function createBanItem(name,realm,classFile,category,reason,pnote)
    local unitobjtoban = {
        name = strupper(name),
        realm = strupper(realm),
        classFile = strupper(classFile),
        catIdx = tonumber(category),
        reaIdx = tonumber(reason),
        note = ""
    }

    if pnote == "" then
      unitobjtoban.note = "N/A"
    else
      unitobjtoban.note = pnote
    end
    
    return unitobjtoban
end

-- --------------------------------------------------------------------------
-- General Addon Structure
-- --------------------------------------------------------------------------
-- OnInitialize, etc.
-- --------------------------------------------------------------------------

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

-- --------------------------------------------------------------------------
-- Chat Commands
-- --------------------------------------------------------------------------
-- Insert blacklist information into unit tooltips.
-- TODO: Refactor and potentially move to its own Options.lua module.
--       Rename ChatFilter to "ChatPrefix" or something more fitting.
-- --------------------------------------------------------------------------

PBL:RegisterChatCommand("pbl", "SlashPBLCommand")

-- Opens the main PBL frame.
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

-- Toggles the minimap icon.
function PBL:CommandIcon()
    self.db.profile.minimap.hide = not self.db.profile.minimap.hide
    if self.db.profile.minimap.hide then
        icon:Hide("PBL")
    else
        icon:Show("PBL")
    end
end

-- Toggles the chat prefix.
function PBL:CommandChatFilter()
    self.db.profile.chatfilter.disabled = not self.db.profile.chatfilter.disabled
    if self.db.profile.chatfilter.disabled then
        PBL:Print("Chat filter disabled")
    else
        PBL:Print("Chat filter enabled")
    end
end

-- Toggles popup alerts.
function PBL:CommandAlerts()
    self.db.profile.ShowAlert["LeaveAlert"] = not self.db.profile.ShowAlert["LeaveAlert"]
    if self.db.profile.ShowAlert["LeaveAlert"] then
        PBL:Print("Alerts disabled")
    else
        PBL:Print("Alerts enabled")
    end
end

-- --------------------------------------------------------------------------
-- Utils - isbanned
-- --------------------------------------------------------------------------
-- Check if a given name exists in the blacklist.
-- TODO: Potentially move to Utils.lua
--       Rename to be more fitting - isBlacklisted()
-- --------------------------------------------------------------------------

function isbanned (tab, val)
    local index, value
    for index, value in ipairs(tab) do
        if value.name.."-"..value.realm == strupper(val) then
            return true, index
        end
    end
    return false, 0
end

-- --------------------------------------------------------------------------
-- Utils - has_value
-- --------------------------------------------------------------------------
-- Returns true if a value exists in a table.
-- TODO: Potentially move to Utils.lua
--       Rename to be more fitting - hasValue()
-- --------------------------------------------------------------------------

function has_value (tab, val)
    local index, value
    for index, value in ipairs(tab) do
        if value == val then
            return true
        end
    end
    return false
end

-- --------------------------------------------------------------------------
-- Utils - getClassIdx
-- --------------------------------------------------------------------------
-- Returns the class index for storage and reference.
-- TODO: Potentially move to Utils.lua
--       Rename to be more fitting - hasValue()
--       Not necessary? Store global list instead or grab class from unitInfo
-- --------------------------------------------------------------------------

function getClassIdx(tab, val)
    local index, value
    for index, value in ipairs(tab) do
        if value == val then
          return index
        end
    end
    return 0
end

-- --------------------------------------------------------------------------
-- Utils - has_value
-- --------------------------------------------------------------------------
-- Custom string split.
-- TODO: Potentially move to Utils.lua
--       Not used anywhere in code. Remove?
-- --------------------------------------------------------------------------

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

-- --------------------------------------------------------------------------
-- Utils - rmvfromlist
-- --------------------------------------------------------------------------
-- Removes a user from the blacklist.
-- TODO: Potentially move to Utils.lua
--       Rename to be more fitting - removeBlacklistEntry() or unblacklistPlayer()
-- --------------------------------------------------------------------------

function PBL:rmvfromlist(fullname, idx)
    table.remove(PBL.db.global.blackList, idx)
    PBL:Print("|cff008000"..fullname.." Removed from blacklist")
end

-- --------------------------------------------------------------------------
-- Utils - addtolist
-- --------------------------------------------------------------------------
-- Adds a user to the blacklist.
-- TODO: Potentially move to Utils.lua
--       Rename to be more fitting - addBlacklistEntry() or blacklistPlayer()
-- --------------------------------------------------------------------------

function PBL:addtolist(name,realm,classFile,category,reason,note)
    local fullname = name.."-"..realm
    --local unitobjtoban = name.."$$"..realm.."$$"..classFile.."$$"..category.."$$"..reason..note
    local unitobjtoban = createBanItem(name,realm,classFile,category,reason,note)

    local banned, idx = isbanned(PBL.db.global.blackList, fullname)
    if banned then
      -- PBL:rmvfromlist(fullname, idx)
      -- table.insert(PBL.db.global.blackList, unitobjtoban)
      PBL.db.global.blackList[idx] = unitobjtoban
      PBL:Print("|cffff0000"..fullname.."'s entry has been successfully edited!")
    else
      table.insert(PBL.db.global.blackList, unitobjtoban)
      PBL:Print("|cffff0000"..fullname.." succesfully added to blacklist!")
    end
end

-- --------------------------------------------------------------------------
-- Utils - clearlist
-- --------------------------------------------------------------------------
-- Completely wipes the blacklist.
-- TODO: Potentially move to Utils.lua
--       Rename to be more fitting - wipeBlacklist()
-- --------------------------------------------------------------------------

function PBL:clearlist()
    PBL.db.global.blackList = {}
end

-- --------------------------------------------------------------------------
-- Utils - blackListButton
-- --------------------------------------------------------------------------
-- Adds/removes a user from context menus.
-- TODO: Potentially move to Utils.lua
--       Rename to be more fitting - blacklistFromContext()
--       Refactor for optimization.
--           Potential for taint here - consider another way?
-- --------------------------------------------------------------------------

local function blackListButton(self)
    local button = self.value;
    if ( button == "AddToPBL" ) then
        local dropdownFrame = UIDROPDOWNMENU_INIT_MENU
        local unit = dropdownFrame.unit
        local name = dropdownFrame.name
        local server = dropdownFrame.server
        local className,classFile,classID
        local note = "Added from unitframe."
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
                PBL:addtolist(name,server,classFile,1,1,note)
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

-- --------------------------------------------------------------------------
-- Unit Tooltips
-- --------------------------------------------------------------------------
-- Insert blacklist information into unit tooltips.
-- --------------------------------------------------------------------------

-- util for generating blacklisted str in format "Category (Reason) - Note"
local function getBlacklistedStr(p)
	local category = PBL.db.profile.categories[tonumber(p.catIdx)]
	local reason = PBL.db.profile.reasons[tonumber(p.reaIdx)]
	local note = p.note

	local blacklistedStr
	if category ~= "All" and reason ~= "All" then
		blacklistedStr = string.format("%s (%s) - %s", category, reason, note)
	elseif category ~= "All" then
		blacklistedStr = string.format("%s - %s", category, note)
	elseif reason ~= "All" then
		blacklistedStr = string.format("%s - %s", reason, note)
	else
		blacklistedStr = note
	end

	return blacklistedStr
end

-- util for adding blacklisted line to tooltip
local function addBlacklistedStr(tooltip, name)
	if not name:find("-") then
		local realm = GetRealmName()
		realm=realm:gsub(" ", "");
		name = name .. "-" .. realm;
	end
	local banned, idx = isbanned(PBL.db.global.blackList, name)
	local p = PBL.db.global.blackList[idx];
	if banned then
		blacklistedStr = getBlacklistedStr(p)
		tooltip:AddDoubleLine(WrapTextInColorCode("Blacklisted:", "FFFF0000"), WrapTextInColorCode(blacklistedStr, "FFFFFFFF"));
	end
end

-- util for grabbing object owner
local function GetObjOwnerName(self)
	local owner, owner_name = self:GetOwner();
	if owner then
		owner_name = owner:GetName();
		if not owner_name then
			owner_name = owner:GetDebugName();
		end
	end
	return owner, owner_name;
end

-- hook for GameTooltip's PostCall
do
	local ttDone = nil;
	TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Unit, function()
		if ttDone==true then return end
		ttDone = true;
		local self = GameTooltip
		local name, unit = self:GetUnit();
		if not unit then
			local mf = GetMouseFocus();
			if mf and mf.unit then
				unit = mf.unit;
			end
		end
		name = UnitName(unit)
		addBlacklistedStr(self, name);
	end);

	GameTooltip:HookScript("OnTooltipCleared", function(self)
		ttDone = nil
	end)
end

-- hook for GameTooltip's SetText
hooksecurefunc(GameTooltip,"SetText",function(self,name)
	local owner, owner_name = GetObjOwnerName(self);
	if owner_name then
		if owner_name:find("^LFGListFrame%.ApplicationViewer%.ScrollBox%.ScrollTarget%.[a-z0-9]*%.Member[0-9]*") then
			-- GroupFinder > ApplicantViewer > Tooltip
			local button = owner:GetParent();
			if button and button.applicantID and owner.memberIdx then
				local fullname = C_LFGList.GetApplicantMemberInfo(button.applicantID, owner.memberIdx);
				addBlacklistedStr(self, fullname);
			end
		elseif owner_name:find("^QuickJoinFrame%.ScrollBox%.ScrollTarget") then
            local _SOCIAL_QUEUE_COMMUNITIES_HEADER_FORMAT = SOCIAL_QUEUE_COMMUNITIES_HEADER_FORMAT:gsub("%(","%%("):gsub("%)","%%)"):gsub("%%s","(.*)");
			local fullname = name:match(_SOCIAL_QUEUE_COMMUNITIES_HEADER_FORMAT);
			if fullname then
				addBlacklistedStr(self, fullname);
			end
		end
	end
end);

-- hook for GameTooltip's AddLine 
hooksecurefunc(GameTooltip,"AddLine",function(self,text)
    if text ~= nil then
		local owner, owner_name = GetObjOwnerName(self);
		if owner_name then
			if owner_name:find("^LFGListFrame%.SearchPanel%.ScrollBox%.ScrollTarget%.[a-z0-9]*") then
				-- GroupFinder > SearchResult > Tooltip
				local _LFG_LIST_TOOLTIP_LEADER = gsub(LFG_LIST_TOOLTIP_LEADER,"%%s","(.+)");
				local leaderName = text:match(_LFG_LIST_TOOLTIP_LEADER);
				if leaderName then
					addBlacklistedStr(self, leaderName);
				end
			elseif owner_name:find("^QuickJoinFrame%.ScrollBox%.ScrollTarget") and owner.entry and owner.entry.guid then
				local leaderName = text:match(LFG_LIST_TOOLTIP_LEADER:gsub("%%s","(.*)"));
				if leaderName then
					addBlacklistedStr(self, leaderName);
				end
			end
		end     
    end
end);

-- hook for Groupfinder applicants
hooksecurefunc("LFGListApplicationViewer_UpdateApplicantMember", function(member, id, index)
	local name,_,_,_,_,_,_,_,_,_,relationship = C_LFGList.GetApplicantMemberInfo(id, index);
	if name then
		local banned, idx = isbanned(PBL.db.global.blackList,name)
		if banned then
			member.Name:SetText("|cffFF0000BAN |r"..member.Name:GetText());
		end
	end
end);

-- --------------------------------------------------------------------------
-- LFG Tooltips
-- --------------------------------------------------------------------------
-- Returns true if a value exists in a table.
-- TODO: Completely broken due to 10.0.0/2 changes.
--       Find another workaround or fall back to chat notifications instead.
-- --------------------------------------------------------------------------

-- local hooked = { }

-- local function OnLeaveHook(self)
-- 		GameTooltip:Hide();
-- end

-- -- ADD BAN TO LFG
-- hooksecurefunc("LFGListApplicationViewer_UpdateResults", function(self)
--     local buttons = self.ScrollFrame.buttons
--     local i, j
-- 	for i = 1, #buttons do
-- 		local button = buttons[i]
-- 		if not hooked[button] then
-- 			if button.applicantID and button.Members then
-- 				for j = 1, #button.Members do
-- 					local b = button.Members[j]
-- 					if not hooked[b] then
-- 						hooked[b] = 1
-- 						b:HookScript("OnEnter", function()
-- 							local appID = button.applicantID;
-- 							local name = C_LFGList.GetApplicantMemberInfo(appID, 1);
-- 							if not string.match(name, "-") then
-- 								local realm = GetRealmName();
-- 								realm=realm:gsub(" ","");
-- 								fullname = name.."-"..realm;
-- 							end

--                             local banned, idx = isbanned(PBL.db.global.blackList, fullname)
--                             local p = PBL.db.global.blackList[idx]
-- 							if banned then
--                                 local banStr = PBL.db.profile.categories[tonumber(p.catIdx)] .. " (" .. PBL.db.profile.reasons[tonumber(p.reaIdx)] .. ")" .. " - " .. p.note
--                                 GameTooltip:AddLine("\nBlacklisted (PBL): |cffFFFFFF" .. banStr .. "|r", 1, 0, 0, true)
--                                 GameTooltip:AddLine(" ")
-- 								GameTooltip:Show();
-- 							end
-- 						end)
-- 						b:HookScript("OnLeave", OnLeaveHook)
-- 					end
-- 				end
-- 			end
-- 		end
-- 	end
-- end)

-- Pseudocode for Temp. Fix:
-- Hook into LFG_LIST_APPLICANT_LIST_UPDATED
-- If LFG_LIST_APPLICANT_LIST_UPDATED == true, true:
--     LFG_LIST_APPLICANT_UPDATED returns new applicantID
--     C_LFGList.GetApplicantInfo(applicantID) returns table {applicantID, pendingApplicationStatus, numMembers, isNew, ...}
--        isNew returns true if applicant has not applied to the group before.
--     C_LFGList.GetApplicants() returns a table of applicantID. Can get memberIndex from this.
--        Grab table. Get index where table[applicantID] = applicantID (from LFG_LIST_APPLICANT_UPDATED or GetApplicantInfo())
--     C_LFGList.GetApplicantMemberInfo(applicantID, memberIndex) returns table {name, class, ...}

-- --------------------------------------------------------------------------
-- Event Handler - Group Join/Leave
-- --------------------------------------------------------------------------
-- Handles checking for blacklist entries when users join a group.
-- TODO: Refactor for optimization.
--       Rename to be more fitting - OnGroupChange() or eh_GroupChange()
-- --------------------------------------------------------------------------

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

-- --------------------------------------------------------------------------
-- Chat Filter
-- --------------------------------------------------------------------------
-- Adds a prefix to messages from blacklisted users.
-- TODO: Potentially move to Modules.lua
--       Rename to be more fitting - chatPrefix()
-- --------------------------------------------------------------------------

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
