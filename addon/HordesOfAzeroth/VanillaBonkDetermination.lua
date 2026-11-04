local L = VanillaBonkL
local UI = VanillaBonkUI

local ICON = "Interface\\Icons\\Spell_Holy_SealOfMight"
local SIZE = 30

local frame = CreateFrame("Button", "VanillaBonkDetermination", UIParent)
frame:SetWidth(SIZE)
frame:SetHeight(SIZE)
frame:SetPoint("TOPRIGHT", UIParent, "TOPRIGHT", -205, -110)
frame:Hide()

local icon = frame:CreateTexture(nil, "ARTWORK")
icon:SetAllPoints(frame)
icon:SetTexture(ICON)

local count = frame:CreateFontString(nil, "OVERLAY", "NumberFontNormal")
count:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -1, 1)

local state = { stacks = 0, percent = "0" }

frame:SetScript("OnEnter", function()
    GameTooltip:SetOwner(this, "ANCHOR_BOTTOMLEFT")
    GameTooltip:SetText(L["Determination"], 1, 1, 1)
    GameTooltip:AddLine(L("+{1}% damage and {1}% less damage taken.", state.percent), 1, 0.82, 0, 1)
    GameTooltip:AddLine(L["Grows each time you die. Ends when you clear Normal."], 0.6, 0.6, 0.6, 1)
    GameTooltip:Show()
end)
frame:SetScript("OnLeave", function()
    GameTooltip:Hide()
end)

local DETERMINATION_SPELL = 60001

local function Refresh()
    local stacks = UI.AuraStacks(DETERMINATION_SPELL, "HELPFUL")
    state.stacks = stacks
    if stacks > 0 then
        count:SetText(stacks > 1 and tostring(stacks) or "")
        frame:Show()
    else
        frame:Hide()
    end
end

local aura = CreateFrame("Frame")
aura:RegisterEvent("UNIT_AURA")
aura:SetScript("OnEvent", function()
    if arg1 == "player" then
        Refresh()
    end
end)

local handlers = {}
handlers["determinationpct"] = function(f)
    state.percent = f[2] or "0"
    Refresh()
end

UI.Listen(handlers)
