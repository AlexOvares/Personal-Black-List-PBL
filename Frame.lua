local AceGUI = LibStub("AceGUI-3.0")
local widgetContainer = ""
local widgetEvent = ""
local widgetGroup = ""
local drawWidget1 = ""
local sortIndex = 0
local sortDir = true
local frameShown = false

function PBL:refreshWidgetCore()
	self:refreshWidget(widgetContainer,widgetEvent,widgetGroup)
end

function PBL:refreshWidget(container, event, group)
    if(container ~= "") then
        container:ReleaseChildren()
        if group == "tab1" then
            drawWidget1(container)     
        end
    end
end

function PBL:createLabel(name,text,width,colorR, colorG, colorB)
    local label = AceGUI:Create("Label")
    label:SetText(text)
    label:SetColor(colorR, colorG, colorB)
    label:SetRelativeWidth(width)
    return label;
end

function PBL:createHeading(name,text)
    local heading = AceGUI:Create("Heading")
    heading:SetText(text)
    heading:SetFullWidth(true)
    return heading;
end

function PBL:createImg(file)
    local img = AceGUI:Create("Icon")
	img:SetImage(file)
	img:SetImageSize(50,50)
    img:SetFullWidth(false)
    return img;
end

function PBL:createRmvIcon(file)
    local img = AceGUI:Create("Icon")
	img:SetImage(file)
	img:SetImageSize(5,5)
    img:SetFullWidth(false)
    return img;
end

function PBL:createDropdown(opts, label, dbTable, width)
    local drop = {}
    drop = AceGUI:Create("Dropdown")
    drop:SetList(opts)
    drop:SetRelativeWidth(width)
    drop:SetValue(1)
    drop:SetLabel(label)
    drop:SetCallback("OnValueChanged", function(this, event, item)
        --self.db.profile.table[k][3] = item
        end
    )
    return drop;
end

function PBL:createRmvBtn(name,text,fullname,width)
    local btn = AceGUI:Create("Button") 
    btn:SetText(text)    
    btn:SetRelativeWidth(width)     
    btn:SetCallback("OnClick", function()
        local exist, i = isbanned(PBL.db.global.blackList, fullname)
        if exist then 
            PBL:rmvfromlist(fullname, i)
        end
        self:refreshWidgetCore()  
    end)
    return btn; 
end

function PBL:createSimpleGrp(width)
    local smpGrp = AceGUI:Create("SimpleGroup");
    smpGrp:SetRelativeWidth(width)

    return smpGrp;
end

function PBL:createBtn(name,text,width)
    local btn = AceGUI:Create("Button") 
    btn:SetText(text)    
    btn:SetRelativeWidth(width)   
    if(name == "delBtn") then
        btn:SetDisabled(true)
    end
    if(name == "addBtn" or name == "rmvBtn" ) then
        btn:SetCallback("OnClick",
            function()
                if(name == "addBtn") then
                    fullname = charInput:GetText()
                    classFile = self.db.profile.classes[claDrp:GetValue()]
                    reavalue = reaDrp:GetValue()
                    catvalue = catDrp:GetValue()
                    local partname = {strsplit("-",fullname)}
                    if partname[1] == nil or partname[2] == nil then
                        PBL:Print("Incorrect name format (name-realm)")
                    else
                        if not isbanned(PBL.db.global.blackList, fullname) then
                            PBL:addtolist(partname[1],partname[2],classFile,catvalue,reavalue)
                            self:refreshWidgetCore()
                        end
                    end
                end
            end)
    else
    	if(name == "nameBtn" or name == "classBtn" or name == "catBtn" or name == "reaBtn" or name=="delBtn") then
    		btn:SetCallback("OnClick",
    		function()
                if(name == "nameBtn") then
                	if sortIndex ~= 0 then
                		sortDir = true
                	else
                		sortDir = not sortDir
                	end
                	sortIndex = 0;
                    self:refreshWidget(widgetContainer,widgetEvent,widgetGroup)
                
                elseif(name == "classBtn") then
                	if sortIndex ~= 1 then
                		sortDir = true
                	else
                		sortDir = not sortDir
                	end
                    sortIndex = 1;
                    self:refreshWidget(widgetContainer,widgetEvent,widgetGroup)
                
                elseif(name == "catBtn") then
                	if sortIndex ~= 2 then
                		sortDir = true
                	else
                		sortDir = not sortDir
                	end
                    sortIndex = 2;
                    self:refreshWidget(widgetContainer,widgetEvent,widgetGroup)
                
                elseif(name == "reaBtn") then
                	if sortIndex ~= 3 then
                		sortDir = true
                	else
                		sortDir = not sortDir
                	end
                    sortIndex = 3;
                    self:refreshWidget(widgetContainer,widgetEvent,widgetGroup)
                elseif(name =="delBtn") then
                    self:clearlist()
                    self:refreshWidget(widgetContainer,widgetEvent,widgetGroup)
                end
                  
            end)
    	end
    end
    return btn;
end


local function safecall(func, ...)
	if func then
		return xpcall(func, errorhandler, ...)
	end
end

local function safelayoutcall(object, func, ...)
	layoutrecursionblock = true
	object[func](object, ...)
	layoutrecursionblock = nil
end
local math_max = math.max




-- Create the frame container
function PBL:showFrame()
    local DrawGroup1 = function (container)
        -- createImg receives (path, size, fullWidth)
        --local logo = self:createImg("Interface\\AddOns\\PersonalBlacklist\\media\\___newIcon.blp")
        --container:AddChild(logo);

        scroll = AceGUI:Create("ScrollFrame")
        scroll:SetFullWidth(true)
        scroll:SetFullHeight(true)        
        scroll:SetLayout("Flow")

        container:AddChild(scroll);

        scorelistWidget = scroll;

        -- createHeading receives (name,text)
        local topHeading = self:createHeading("banControl","Add New Player ( Format Name-Realm )")
        scroll:AddChild(topHeading)

        -- createHeader control (input & dropdowns)
        charInput = AceGUI:Create("EditBox");
        charInput:SetRelativeWidth(0.36);       

        local addBtn = self:createBtn("addBtn","ADD",0.10);
        --local empS = self:createSimpleGrp(1)

        -- createDropdown receives (listOfOptions, label, width)
        catDrp = self:createDropdown(self.db.profile.categories, "CATEGORY", "categories", 0.18);
        reaDrp = self:createDropdown(self.db.profile.reasons, "REASON", "reasons", 0.18);
        claDrp = self:createDropdown(self.db.profile.classes, "CLASS", "classes", 0.18);
        
        scroll:AddChild(charInput);
        scroll:AddChild(addBtn);
        --scroll:AddChild(empS);

        scroll:AddChild(catDrp);
        scroll:AddChild(reaDrp);
        scroll:AddChild(claDrp);
 
        -- createHeading receives (name,text)
        local heading = self:createHeading("banList","BAN LIST")
        scroll:AddChild(heading)

        -- createBtn receives (name,text,RelativeWidth)
        local nameBtn = self:createBtn("nameBtn","NAME",0.38)
        local classBtn = self:createBtn("classBtn","CLASS",0.22)
        local catBtn = self:createBtn("catBtn","CATEGORY",0.16)
        local reaBtn = self:createBtn("reaBtn","REASON",0.16)
        local delBtn = self:createBtn("delBtn","",0.08)

        scroll:AddChild(nameBtn)
        scroll:AddChild(classBtn)
        scroll:AddChild(catBtn)
        scroll:AddChild(reaBtn)
        scroll:AddChild(delBtn)
     
        local namelist = {}
        local classlist = {}
        local catlist = {}
        local realist = {}
        local rmvBtns = {}

        local sortedKeys = self:getKeysSortedByValue(self.db.global.blackList, 
        	function(a, b)
        		if sortDir then
        			return a < b 
        		else
        			return b < a
        		end
        	end,
        	sortIndex)
        i = 0

        for _, k in ipairs(sortedKeys) do
            v = self.db.global.blackList[k]         

            --CHAR NAME
            local colorAux = self:setClassColor(v.classFile)
            
            namelist[i] = AceGUI:Create("InteractiveLabel")
            
            if(v.classFile ~="UNSPECIFIED" and v.classFile ~= "" and v.classFile ~= nil) then
                namelist[i]:SetImage("Interface\\GLUES\\CHARACTERCREATE\\UI-CHARACTERCREATE-CLASSES",unpack(CLASS_ICON_TCOORDS[v.classFile]))
            end

            namelist[i]:SetText(v.name.."-"..v.realm)
            namelist[i]:SetColor(colorAux[1], colorAux[2], colorAux[3])
            namelist[i]:SetRelativeWidth(0.38)
            namelist[i]:SetHighlight(0.5,0.5,0.5,0)
           
            scroll:AddChild(namelist[i])

            --CLASSES -- createLabel receives (name,text,RelativeWidth,colorR,colorG,colorB)
            classlist[i] = AceGUI:Create("InteractiveLabel")
            classlist[i]:SetText(v.classFile)
            classlist[i]:SetColor(colorAux[1], colorAux[2], colorAux[3])
            classlist[i]:SetRelativeWidth(0.22)
            classlist[i]:SetHighlight(0.5,0.5,0.5,0)

            scroll:AddChild(classlist[i])

            --CATEGORIES
            catlist[i] = self:createLabel("categorytext_",self.db.profile.categories[tonumber(v.catIdx)],0.16,colorAux[1],colorAux[2],colorAux[3])
            scroll:AddChild(catlist[i])

            --REASONS
            realist[i] = self:createLabel("reason_",self.db.profile.reasons[tonumber(v.reaIdx)],0.16,colorAux[1],colorAux[2],colorAux[3])
            scroll:AddChild(realist[i])

            --REMOVE BTNS
            rmvBtns[i] = self:createRmvBtn("rmvBtn","X",v.name.."-"..v.realm,0.08);
            scroll:AddChild(rmvBtns[i])

            --local line = AceGUI:Create("Heading")
            --line:SetFullWidth(true)

            --scroll:AddChild(line)

            i = i + 1
        end
     
    end

    local DrawGroup2 = function (container)        
        -- createHeading receives (name,text)
        local heading = self:createHeading("creditsInf_","CREDITS")
        container:AddChild(heading)

        -- createLabel receives (name,text,RelativeWidth,colorR,colorG,colorB,x,y)
        local raid1 = self:createLabel("racreditsInf_id_","Authors / Creators\n",1,1,0.82,0)
        local raid2 = self:createLabel("creditsInf_","Xyløns & Theomel @ Quel'Thalas US \n\n",1,1,1,1)
        local raid3 = self:createLabel("creditsInf_","Translations\n",1,1,0.82,0)
        local raid4 = self:createLabel("creditsInf_","Spanish: Kauto @ Quel'Thalas US\nGerman: SkylineHero @ CurseForge\n\n",1,1,1,1)
        local raid5 = self:createLabel("creditsInf_","Special Thanks!\n",1,1,0.82,0)
        local raid6 = self:createLabel("creditsInf_","Testers: Guilds <Paradøx> & <Incarnate> Ragnaros US & Guild <Born To Wipe> Quel'Thalas US\n",1,1,1,1)
        local raid8 = self:createLabel("creditsInf_","Делюбовь @ Howling fjord RU\n",1,1,1,1)
        local raid9 = self:createLabel("creditsInf_","Pantyphoon @ CurseForge\n",1,1,1,1)


        container:AddChild(raid1)
        container:AddChild(raid2)
        container:AddChild(raid3)
        container:AddChild(raid4)
        container:AddChild(raid5)
        container:AddChild(raid6)
        container:AddChild(raid8)
        container:AddChild(raid9)

    end

    local SelectGroup = function (container, event, group)

        widgetContainer = container
        widgetEvent = event
        widgetGroup = group

        container:ReleaseChildren()

        if group == "tab1" then
           DrawGroup1(container)
        elseif group == "tab2" then
           DrawGroup2(container)
        end

    end

    if frameShown then
        return
    end

    frameShown = true

    AceGUI:RegisterLayout("Custom_Layout",
    function(content, children)
        if children[1] then
            children[1].frame:Show()
			--children[1].frame:ClearAllPoints()
            children[1].frame:SetPoint("TOPRIGHT", content, 40,28)
            
		end
		if children[2] then
			children[2]:SetWidth(content:GetWidth() or 0)
			children[2]:SetHeight(content:GetHeight() or 0)
			children[2].frame:ClearAllPoints()
			children[2].frame:SetAllPoints(content)
			children[2].frame:Show()
			safecall(content.obj.LayoutFinished, content.obj, nil, children[2].frame:GetHeight())
        end
        
	end)

    local frame = AceGUI:Create("Frame")
    frame:SetTitle("Personal Black List (PBL) V3.5")
    frame:SetCallback("OnClose",
        function(widget) 
            AceGUI:Release(widget)
            frameShown = false             
        end)
    frame:SetLayout("Custom_Layout")

    local tabContainer = AceGUI:Create("TabGroup") 
    tabContainer:SetLayout("Flow")

    tabContainer:SetTabs({{value="tab1",text="Ban List"},{value="tab2",text="Credits"}})

    tabContainer:SetCallback("OnGroupSelected", SelectGroup)
    tabContainer:SelectTab("tab1")
    local logo = self:createImg("Interface\\AddOns\\PersonalBlacklist\\media\\pbl_02bx256.blp");
    frame:AddChild(logo);  
    frame:AddChild(tabContainer)

    drawWidget1 = DrawGroup1;
    
 
end

function PBL:setClassColor(class)
    -- 1-Warrior , 2-Paladin , 3-Hunter , 4-Rogue , 5-Priest , 6-Shaman, 7-Mage, 8-Warlock, 9-Monk, 10-Druid, 11-Demon Hunter, 12- Death Knight 
    local claColor={
        ["UNSPECIFIED"]={0.62,0.62,0.62},
        ["WARRIOR"]={0.78,0.61,0.43},
        ["PALADIN"]={0.96,0.55,0.73},
        ["HUNTER"]={0.67,0.83,0.45},
        ["ROGUE"]={1.00,0.96,0.41},
        ["PRIEST"]={1,1,1},
        ["SHAMAN"]={0.00,0.44,0.87},
        ["MAGE"]={0.25,0.78,0.92},
        ["WARLOCK"]={0.53,0.53,0.93},
        ["MONK"]={0.00,1.00,0.59},
        ["DRUID"]={1.00,0.49,0.04},
        ["DEMONHUNTER"]={0.64,0.19,0.79},
        ["DEATHKNIGHT"]={0.77,0.12,0.23}
    }
    return claColor[class]
end

function PBL:getKeysSortedByValue(tbl, sortFunction, value)
	local keys = {}
	for key in pairs(tbl) do
		table.insert(keys, key)
	end
    if value == 0 then
        table.sort(keys, function(a, b)
            return sortFunction(tbl[a].name, tbl[b].name)
        end)
	elseif value == 1 then
		table.sort(keys, function(a, b)
			return sortFunction(tbl[a].classFile, tbl[b].classFile)
        end)
    elseif value == 2 then
		table.sort(keys, function(a, b)
			return sortFunction(tbl[a].catIdx, tbl[b].catIdx)
        end)
    elseif value == 3 then
		table.sort(keys, function(a, b)
			return sortFunction(tbl[a].reaIdx, tbl[b].reaIdx)
        end)
    end
  	return keys
end