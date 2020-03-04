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
        GoodEPGP.menuFrame:Show()
        GoodEPGP.menuTabs:SelectTab(GoodEPGP.menuTabs.default)
    end
end

-- Add EP to raid after confirming with the player
function GoodEPGP:epToRaid()
    GoodEPGP:confirmDialog("Add EP to Raid", "How much EP would you like to award to the raid?", "isNumeric", "AddEPToRaid")
end

-- Generate a confirmation dialog
function GoodEPGP:confirmDialog(title, text, validateFunction, acceptFunction)
    local container = AceGUI:Create("Frame")
    container:SetTitle(title)
    container:SetWidth(300)
    container:SetHeight(100)
    container:SetLayout("Fill")
    
    local input = AceGUI:Create("EditBox")
    container:AddChild(input)
    input:SetLabel(text)
    input:SetMaxLetters(4)
    input:SetCallback("OnTextChanged", function(widget) 
        local enteredText = widget:GetText()
        if (GoodEPGP[validateFunction](GoodEPGP, enteredText)) then
            widget:DisableButton(false)
        else
            widget:DisableButton(true)
        end 
    end)
    input:SetCallback("OnEnterPressed", function(widget)
        local enteredText = widget:GetText()
        if (GoodEPGP[validateFunction](GoodEPGP, enteredText)) then
            GoodEPGP[acceptFunction](GoodEPGP, enteredText)
            container:Release()
        end
    end)
end

-- ===
-- === Validation functions
-- ===

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

-- ===
-- === Build out our menus
-- ===

-- Build the player menu
function GoodEPGP:BuildPlayerMenu()
    local playerHeading = AceGUI:Create("Heading")
    playerHeading:SetText("List Views")
    playerHeading:SetFullWidth(true)
    GoodEPGP.menuTabs:AddChild(playerHeading)

    local priceButton = AceGUI:Create("Button")
    priceButton:SetText("Price List")
    priceButton:SetCallback("OnClick", function()
        GoodEPGP:TogglePrices()
    end)

    local standingsButton = AceGUI:Create("Button")
    standingsButton:SetText("EPGP Standings")
    standingsButton:SetCallback("OnClick", function()
        GoodEPGP:ToggleStandings()
    end)

    -- Add the widget to our options frame
    GoodEPGP.menuTabs:AddChild(priceButton)
    GoodEPGP.menuTabs:AddChild(standingsButton)
end


-- Build the admin menu
function GoodEPGP:BuildAdminMenu()
    local adminHeading = AceGUI:Create("Heading")
    adminHeading:SetText("Award EP & GP")
    adminHeading:SetFullWidth(true)
    GoodEPGP.menuTabs:AddChild(adminHeading)

    local adminButtons = {
        {["name"] = "Assign EP to Raid", ["functionName"] = "epToRaid", ["enableFunction"] = "isInRaid"}
    }

    for key, button in pairs(adminButtons) do
        local adminButton = AceGUI:Create("Button")
        adminButton:SetText(button.name)
        adminButton:SetCallback("OnClick", function()
            GoodEPGP[button.functionName]()
        end)
        adminButton:SetDisabled(GoodEPGP[button.enableFunction]())

        GoodEPGP.menuTabs:AddChild(adminButton)
    end


end

-- Build configuration menu
function GoodEPGP:BuildConfigMenu() 

    -- Loop through our config options we'd like to display
    for key, value in pairs(GoodEPGP.configOptions) do
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

        -- Set our initial values by type, and callback
        if (value.type == "EditBox") then
            configWidget:SetText(GoodEPGP.config[value.key])
            configWidget:SetCallback("OnEnterPressed", function(widget)
                GoodEPGP.config[value.key] = widget:GetText()
                GoodEPGPConfig = GoodEPGP.config
            end)
        end
        if (value.type == "CheckBox") then
            configWidget:SetValue(GoodEPGP.config[value.key])
            configWidget:SetCallback("OnValueChanged", function(widget)
                GoodEPGP.config[value.key] = widget:GetValue()
                GoodEPGPConfig = GoodEPGP.config
            end)
        end

        -- Add the widget to our otpions frame
        GoodEPGP.menuTabs:AddChild(configWidget)
    end

end