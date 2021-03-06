local AceGUI = LibStub("AceGUI-3.0")

-- Attempt to create our options frame
function GoodEPGP:CreateMenuFrame()
    -- Don't create it if it already exists
    if (GoodEPGP.menuFrame ~= nil) then
        return
    end

    -- Create the parent frame
    GoodEPGP.menuFrame = AceGUI:Create("Frame")
    GoodEPGP.menuFrame:SetTitle("GoodEPGP Menu")
    GoodEPGP.menuFrame:SetLayout("Fill")

	-- Allows closing hitting ESC
	_G["GoodEPGP_Menu"] = GoodEPGP.menuFrame
	table.insert(UISpecialFrames, "GoodEPGP_Menu")

end

function GoodEPGP:CreateMenuTabs()
    GoodEPGP.menuTabs = AceGUI:Create("TabGroup")
    GoodEPGP.menuTabs:SetLayout("List")

    -- Only offer the admin tab to players who can use it.
    if (CanEditOfficerNote()) then
        GoodEPGP.menuTabs.tabData = {
            {["text"] = "Admin Functions", ["value"] = "admin"},
            {["text"] = "Player Functions", ["value"] = "player"},
            {["text"] = "Configuration", ["value"] = "config"},
        }
        GoodEPGP.menuTabs.default = "admin"
    else
        GoodEPGP.menuTabs.tabData = {
            {["text"] = "Player Functions", ["value"] = "player"},
            {["text"] = "Configuration", ["value"] = "config"},
        }
        GoodEPGP.menuTabs.default = "player"
    end

    -- Set up our menu tabs
    GoodEPGP.menuTabs:SetTabs(GoodEPGP.menuTabs.tabData)
    GoodEPGP.menuTabs:SetCallback("OnGroupSelected", function(container, event, group)
        container:ReleaseChildren()
        if (group == "player") then
            GoodEPGP:BuildPlayerMenu()
        elseif (group == "admin") then
            GoodEPGP:BuildAdminMenu()
        elseif (group == "config") then
            GoodEPGP:BuildConfigMenu()
        end
		GoodEPGP.menuFrame:SetStatusText("")
    end)
    GoodEPGP.menuFrame:AddChild(GoodEPGP.menuTabs)

    -- Hide our frame by default
    GoodEPGP.menuFrame:Hide()
end

-- Show our options menu
function GoodEPGP:ToggleMenuFrame()
    if (GoodEPGP.menuFrame:IsVisible()) then
        GoodEPGP.menuFrame:Hide()
    else
		if (GoodEPGP.pricesFrame ~= nil and GoodEPGP.pricesFrame:IsVisible()) then
			GoodEPGP:TogglePrices()
		end
		if (GoodEPGP.standingsFrame:IsVisible()) then
			GoodEPGP:ToggleStandings()
		end
        GoodEPGP.menuFrame:Show()
        GoodEPGP.menuTabs:SelectTab(GoodEPGP.menuTabs.default)
    end
	GoodEPGP.menuFrame:SetStatusText("")
end

-- Add EP to raid after confirming with the player
function GoodEPGP:AssignRaidEP()
    GoodEPGP:InputDialog("Add EP to Raid", "How much EP would you like to award to the raid?", "AddEPToRaid")
end

-- Create a confirmation dialog to make sure we want to decay
function GoodEPGP:DecayEPGP()
    GoodEPGP:ConfirmAction("Are you sure you want to decay EPGP?", function()
        GoodEPGP:Decay()
    end, function()
        -- Do nothing
    end)
end

-- Dialog to assign player EP
function GoodEPGP:AssignPlayerEP()
    GoodEPGP:InputDialog("Add EP to Player", "How much EP would you like to award?", "AddEPToPlayer", true)
end

-- Dialog to assign player GP
function GoodEPGP:AssignPlayerGP()
    GoodEPGP:InputDialog("Add GP to Player", "How much GP would you like to award?", "AddGPToPlayer", true)
end

-- Generate a confirmation dialog
function GoodEPGP:InputDialog(title, text, acceptFunction, includePlayers)
    GoodEPGP.inputDialogFrame = AceGUI:Create("Dialog")
    GoodEPGP.inputDialogFrame:SetTitle(title)
    GoodEPGP.inputDialogFrame:SetWidth(300)
    GoodEPGP.inputDialogFrame:SetHeight(200)
    GoodEPGP.inputDialogFrame:SetLayout("Flow")

    if (includePlayers) then
        GoodEPGP.dialogDropdown = AceGUI:Create("Dropdown")
        GoodEPGP.dialogDropdown:SetFullWidth(true)
        GoodEPGP.dialogDropdown.guildRoster = GoodEPGP:GetGuildRoster()
        GoodEPGP.dialogDropdown:SetLabel("Player")
        GoodEPGP.dialogDropdown:SetList(GoodEPGP.dialogDropdown.guildRoster)
        GoodEPGP.inputDialogFrame:AddChild(GoodEPGP.dialogDropdown)
    end

    GoodEPGP.dialogInput = AceGUI:Create("EditBox")
    GoodEPGP.dialogInput:SetFullWidth(true)
    GoodEPGP.dialogInput:DisableButton(true)
    GoodEPGP.dialogInput:SetLabel(text)
    GoodEPGP.dialogInput:SetMaxLetters(4)
	GoodEPGP.inputDialogFrame:AddChild(GoodEPGP.dialogInput)
    GoodEPGP.inputDialogFrame:SetCallback("OnAccept", function()
        local amount = tostring(GoodEPGP.dialogInput:GetText())
        local player = nil
        if (includePlayers) then
            player = GoodEPGP.dialogDropdown.guildRoster[GoodEPGP.dialogDropdown:GetValue()]
        end
        GoodEPGP[acceptFunction](GoodEPGP, amount, player)
        GoodEPGP.inputDialogFrame:Release()
    end)

end

-- Add EP to player
function GoodEPGP:AddEPToPlayer(amount, player)
    GoodEPGP:AddEPByName(player, amount)
end

-- Add GP to player
function GoodEPGP:AddGPToPlayer(amount, player)
    GoodEPGP:AddGPByName(player, amount)
end

-- ========================
-- === Validation functions
-- ========================

-- Verify a number is numeric
function GoodEPGP:isNumeric(value)
    if (tonumber(value) ~= nil) then
        return true
    else
        return false
    end
end

-- Verify player is in a raid
function GoodEPGP:isInRaid()
    if (IsInRaid()) then
        return false
    else
        return true
    end
end

-- =======================
-- === Build out our menus
-- =======================

-- Build the player menu
function GoodEPGP:BuildPlayerMenu()
    local playerHeading = AceGUI:Create("Heading")
    playerHeading:SetText("GoodEPGP Price List")
    playerHeading:SetFullWidth(true)
    GoodEPGP.menuTabs:AddChild(playerHeading)

	-- Create the Prices Button
    local priceButton = AceGUI:Create("Button")
    priceButton:SetText("Price List")
    priceButton:SetCallback("OnClick", function()
        GoodEPGP:TogglePrices()
    end)

    -- Create the Standings Button
    local standingsButton = AceGUI:Create("Button")
    standingsButton:SetText("EPGP Standings")
    standingsButton:SetCallback("OnClick", function()
        GoodEPGP:ToggleStandings()
    end)

	-- Create the SetSpec Dropdown
	local playerSpecDropdown = AceGUI:Create("Dropdown")
	playerSpecDropdown:SetLabel("Current Talent Specification")
	local index = GoodEPGP:GetMembersGuildIndex(UnitName("player"))
	local class = select(1, UnitClass("player"))
	local gMemNote = select(7, GetGuildRosterInfo(index))
	local gMemSpec = GoodEPGP:UCFirst(select(1, strsplit(":", gMemNote)))
	local playersSpecs = GoodEPGP:ValidSpecsByClass(class)
	local validCurrentSpec = GoodEPGP:ValidSpecsByClass(class, gMemSpec)
	playerSpecDropdown:SetList(playersSpecs)

	-- Member has a spec set
	if validCurrentSpec then
		for i = 1, #playersSpecs do
			if gMemSpec == playersSpecs[i] then
				playerSpecDropdown:SetValue(i)
				break
			end
		end

	-- Member has no spec set
	else
		playerSpecDropdown:SetText("Select Your Spec")
	end
	playerSpecDropdown:SetCallback("OnValueChanged", function(widget)
		local selectedSpec = playersSpecs[widget:GetValue()];
		GoodEPGP:CancelAllTimers()
		GoodEPGP:SetSpec(UnitName("player"), selectedSpec)
	end)

    -- Add the widgets to our options frame
    GoodEPGP.menuTabs:AddChild(priceButton)
    GoodEPGP.menuTabs:AddChild(cacheButton)
    GoodEPGP.menuTabs:AddChild(standingsButton)
	GoodEPGP.menuTabs:AddChild(playerSpecDropdown)
end


-- Build the admin menu
function GoodEPGP:BuildAdminMenu()
    local adminHeading = AceGUI:Create("Heading")
    adminHeading:SetText("Award EP & GP")
    adminHeading:SetFullWidth(true)
    GoodEPGP.menuTabs:AddChild(adminHeading)

    local adminButtons = {
        {["name"] = "Assign EP to Raid", ["functionName"] = "AssignRaidEP", ["enableFunction"] = "isInRaid"},
        {["name"] = "Assign EP to Player", ["functionName"] = "AssignPlayerEP"},
        {["name"] = "Assign GP to Player", ["functionName"] = "AssignPlayerGP"},
        {["name"] = "Decay EP & GP", ["functionName"] = "DecayEPGP"}
    }

    for key, button in pairs(adminButtons) do
        local adminButton = AceGUI:Create("Button")
        adminButton:SetText(button.name)
        adminButton:SetCallback("OnClick", function()
            GoodEPGP[button.functionName]()
        end)
        if (button.enableFunction ~= nil) then
            adminButton:SetDisabled(GoodEPGP[button.enableFunction]())
        end

        GoodEPGP.menuTabs:AddChild(adminButton)
    end
end

-- Build configuration menu
function GoodEPGP:BuildConfigMenu()

    local configOptions = {}

    -- Our options menu
    if (CanEditOfficerNote()) then
        configOptions = {
            {["type"] = "Heading", ["text"] = "Admin Config"},
            {["key"] = "trigger", ["type"] = "EditBox", ["label"] = "GoodEPGP Trigger", ["default"] = "!gep"},
            {["key"] = "decayPercent", ["type"] = "EditBox", ["label"] = "Decay Percentage", ["default"] = ".1"},
            {["key"] = "minGP", ["type"] = "EditBox", ["label"] = "Minimum GP", ["default"] = "100"},
            {["type"] = "Heading", ["text"] = "Debug"},
            {["key"] = "debugEnabled", ["type"] = "CheckBox", ["label"] = "Debug Mode", ["default"] = "true"},
            {["type"] = "Heading", ["text"] = "Minimap Icon"},
            {["key"] = "show", ["type"] = "CheckBox", ["label"] = "Show Minimap Icon", ["default"] = "true"},
        }
    else
        configOptions = {
            {["type"] = "Heading", ["text"] = "Debug"},
            {["key"] = "debugEnabled", ["type"] = "CheckBox", ["label"] = "Debug Mode", ["default"] = "true"},
            {["type"] = "Heading", ["text"] = "Minimap Icon"},
            {["key"] = "show", ["type"] = "CheckBox", ["label"] = "Show Minimap Icon", ["default"] = "true"},
        }
    end

    -- Loop through our config options we'd like to display
    for key, value in pairs(configOptions) do
        local configWidget = AceGUI:Create(value.type)
        if (value.label ~= nil) then
            configWidget:SetLabel(value.label)
        end
        if (value.description ~= nil) then
            configWidget:SetDescription(value.description)
        end
        if (value.text ~= nil) then
            configWidget:SetText(value.text)
        end
        configWidget:SetFullWidth(true)

        -- Set our initial values by type, and callback (global)
        if (value.type == "EditBox") then
            configWidget:SetText(GoodEPGP.config[value.key])
            configWidget:SetCallback("OnEnterPressed", function(widget)
                GoodEPGP.config[value.key] = widget:GetText()
                GoodEPGPConfig = GoodEPGP.config
            end)
        end
        if (value.key ~= "show" and value.type == "CheckBox") then
            configWidget:SetValue(GoodEPGP.config[value.key])
            configWidget:SetCallback("OnValueChanged", function(widget)
                GoodEPGP.config[value.key] = widget:GetValue()
                GoodEPGPConfig = GoodEPGP.config
            end)
        end

		-- Set minimap icon visibility (per character)
		if (value.key == "show" and value.type == "CheckBox") then
            configWidget:SetValue(GoodEPGPMiniMapPos[value.key])
            configWidget:SetCallback("OnValueChanged", function(widget)
                GoodEPGPMiniMapPos[value.key] = widget:GetValue()
				GoodEPGP:MinimapIconToggle()
            end)
		end

        -- Add the widget to our otpions frame
        GoodEPGP.menuTabs:AddChild(configWidget)
    end

end
