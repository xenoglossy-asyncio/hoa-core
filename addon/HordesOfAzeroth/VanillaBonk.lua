local L = VanillaBonkL
local UI = VanillaBonkUI
local ICON_PATH = "Interface\\Icons\\"
local FONT = VanillaBonkUI.FONT

local VB = {
    tiers = {},
    pendingTiers = {},
    offer = {},
    inRun = false,
}
VanillaBonkRun = VB

local function Split(text, separator)
    local fields = {}
    local start = 1
    while true do
        local found = strfind(text, separator, start, true)
        if not found then
            tinsert(fields, strsub(text, start))
            return fields
        end
        tinsert(fields, strsub(text, start, found - 1))
        start = found + 1
    end
end

VB.Split = Split

local function Command(text)
    SendChatMessage(".bonk " .. text, "SAY")
end
VB.Command = Command

local function FormatTime(seconds)
    seconds = tonumber(seconds) or 0
    return format("%d:%02d", floor(seconds / 60), mod(seconds, 60))
end
VB.FormatTime = FormatTime

local function FormatGold(copper)
    copper = tonumber(copper) or 0
    local gold = floor(copper / 10000)
    local silver = floor(mod(copper, 10000) / 100)
    local text = format(L["hoa.addon.cffeda55f_dc_r"], mod(copper, 100))
    if silver > 0 or gold > 0 then
        text = format(L["hoa.addon.cffc7c7cf_ds_r"], silver) .. text
    end
    if gold > 0 then
        text = format(L["hoa.addon.cffffd700_dg_r"], gold) .. text
    end
    return text
end
VB.FormatGold = FormatGold

local function Notice(text)
    UIErrorsFrame:AddMessage(text, 1.0, 0.82, 0.0, 1.0, 5)
end
VB.Notice = Notice

local function SetFont(fontString, size, flags)
    fontString:SetFont(FONT, size, flags or "OUTLINE")
end
VB.SetFont = SetFont

local function DialogBackdrop(frame)
    frame:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true, tileSize = 32, edgeSize = 32,
        insets = { left = 11, right = 12, top = 12, bottom = 11 },
    })
end

local hiddenBars = CreateFrame("Frame")
hiddenBars:Hide()

for index = 1, 12 do
    getglobal("ActionButton" .. index):SetParent(hiddenBars)
end
for _, name in ipairs({ "BonusActionBarFrame", "ShapeshiftBarFrame", "MultiBarBottomLeft", "MultiBarBottomRight",
        "MultiBarRight", "MultiBarLeft", "ActionBarUpButton", "ActionBarDownButton" }) do
    local frame = getglobal(name)
    if frame then
        frame:SetParent(hiddenBars)
    end
end
for _, name in ipairs({ "MainMenuBarTexture0", "MainMenuBarTexture1", "MainMenuBarTexture2", "MainMenuBarTexture3",
        "MainMenuBarLeftEndCap", "MainMenuBarRightEndCap", "MainMenuBarPageNumber" }) do
    local region = getglobal(name)
    if region then
        region:Hide()
    end
end

UseAction = function() end

local RARITIES = {
    [0] = { name = L["hoa.addon.common"], r = 1, g = 1, b = 1 },
    [1] = { name = L["hoa.addon.uncommon"], r = 0.12, g = 1, b = 0 },
    [2] = { name = L["hoa.addon.rare"], r = 0, g = 0.44, b = 0.87 },
    [3] = { name = L["hoa.addon.epic"], r = 0.64, g = 0.21, b = 0.93 },
    [4] = { name = L["hoa.addon.legendary"], r = 1, g = 0.5, b = 0 },
}

local function RarityText(rarity, text)
    local color = RARITIES[rarity] or RARITIES[0]
    return format("|cff%02x%02x%02x%s|r", color.r * 255, color.g * 255, color.b * 255, text)
end

UI.Module("buffTimers"):Listen({
    VARIABLES_LOADED = function()
        SHOW_BUFF_DURATIONS = "1"
    end,
})

local offerFrame = CreateFrame("Frame", "VanillaBonkOffer", UIParent)
offerFrame:SetAllPoints(UIParent)
offerFrame:SetFrameStrata("DIALOG")
offerFrame:EnableMouse(false)
offerFrame:Hide()

offerFrame.dim = offerFrame:CreateTexture(nil, "BACKGROUND")
offerFrame.dim:SetTexture("Interface\\AddOns\\HordesOfAzeroth\\Textures\\OfferVignette")
offerFrame.dim:SetPoint("TOPLEFT", WorldFrame, "TOPLEFT", -2, 2)
offerFrame.dim:SetPoint("BOTTOMRIGHT", WorldFrame, "BOTTOMRIGHT", 2, -2)

offerFrame.chrome = CreateFrame("Frame", nil, offerFrame)
offerFrame.chrome:SetAllPoints(offerFrame)

offerFrame.title = offerFrame.chrome:CreateFontString(nil, "OVERLAY")
offerFrame.title:SetFont(VanillaBonkUI.TITLE_FONT, 46, "OUTLINE")
offerFrame.title:SetPoint("CENTER", offerFrame, "CENTER", 0, 230)
offerFrame.title:SetTextColor(1, 0.82, 0)

offerFrame.subtitle = offerFrame.chrome:CreateFontString(nil, "OVERLAY")
SetFont(offerFrame.subtitle, 13, "")
offerFrame.subtitle:SetShadowColor(0, 0, 0, 1)
offerFrame.subtitle:SetShadowOffset(1, -1)
offerFrame.subtitle:SetPoint("CENTER", offerFrame, "CENTER", 0, 186)
offerFrame.subtitle:SetTextColor(0.9, 0.83, 0.64)
offerFrame.subtitle:SetText(L["hoa.addon.choose_an_upgrade"])

for side = 1, 2 do
    local line = offerFrame.chrome:CreateTexture(nil, "ARTWORK")
    line:SetTexture(VanillaBonkUI.FLAT)
    line:SetWidth(60)
    line:SetHeight(1)
    if side == 1 then
        line:SetPoint("RIGHT", offerFrame.subtitle, "LEFT", -12, 0)
        line:SetGradientAlpha("HORIZONTAL", 1, 0.82, 0, 0, 1, 0.82, 0, 0.7)
    else
        line:SetPoint("LEFT", offerFrame.subtitle, "RIGHT", 12, 0)
        line:SetGradientAlpha("HORIZONTAL", 1, 0.82, 0, 0.7, 1, 0.82, 0, 0)
    end
end

offerFrame.hint = offerFrame.chrome:CreateFontString(nil, "OVERLAY")
SetFont(offerFrame.hint, 11, "")
offerFrame.hint:SetShadowColor(0, 0, 0, 1)
offerFrame.hint:SetShadowOffset(1, -1)
offerFrame.hint:SetPoint("CENTER", offerFrame, "CENTER", 0, -206)
offerFrame.hint:SetTextColor(0.78, 0.78, 0.78)

offerFrame.cards = {}
offerFrame.cardDrop = 0
offerFrame.MAX_GROWTH = 120

local BANISH_RED = { 1, 0.25, 0.2 }

offerFrame.banishEscape = CreateFrame("Frame", "VanillaBonkBanishEscape", UIParent)
offerFrame.banishEscape:SetWidth(1)
offerFrame.banishEscape:SetHeight(1)
offerFrame.banishEscape:Hide()
tinsert(UISpecialFrames, "VanillaBonkBanishEscape")

function VB.IsBanishTarget(card)
    local option = VB.offer[card.index]
    return offerFrame.banishing and option ~= nil and option.banishable
end

local function SetBanishMode(on)
    on = on and true or false
    offerFrame.banishing = on
    offerFrame.banishWarned = nil
    for _, card in ipairs(offerFrame.cards) do
        if card:IsShown() and card.lineColor then
            local target = VB.IsBanishTarget(card)
            if target then
                card:SetBackdropBorderColor(BANISH_RED[1], BANISH_RED[2], BANISH_RED[3])
                card.line:SetBackdropBorderColor(BANISH_RED[1], BANISH_RED[2], BANISH_RED[3], 1)
                card.art:SetVertexColor(1, 0.55, 0.5)
                card.highlight:SetVertexColor(1, 0.3, 0.25)
            else
                local color = card.lineColor
                local border = card.borderColor
                local shade = on and 0.45 or 1
                card:SetBackdropBorderColor(border[1], border[2], border[3])
                card.line:SetBackdropBorderColor(color[1], color[2], color[3], color[4])
                card.art:SetVertexColor(shade, shade, shade)
                card.highlight:SetVertexColor(1, 1, 1)
            end
            if GetMouseFocus() == card then
                if target then
                    card.line:SetBackdropBorderColor(1, 0.1, 0.05, 1)
                else
                    card.line:SetBackdropBorderColor(1, 0.82, 0, 1)
                end
            end
        end
    end
    if offerFrame.banish then
        offerFrame.banish:SetText(on and L["hoa.addon.cancel"] or (L("hoa.addon.cffff6060banish_1_r", VB.banishes or 0)))
    end
    offerFrame.hint:SetText(on and L["hoa.addon.cffff6060click_a_card_to_banish_it_or_press_escape_to_cancel"] or "")
    if on then
        offerFrame.banishEscape:Show()
    else
        offerFrame.banishEscape:Hide()
    end
end

offerFrame.banishEscape:SetScript("OnHide", function()
    if not this:IsShown() and offerFrame.banishing then
        SetBanishMode(false)
    end
end)

local function Pick(index)
    if not VB.offer[index] or (VB.picking and GetTime() - (VB.pickingAt or 0) < 3) then
        return
    end
    VB.picking = true
    VB.pickingAt = GetTime()
    VB.pickedIndex = index
    Command((VB.offerSource == "ley" and "leypick " or "pick ") .. index)
end

local function Banish(index)
    if not VB.offer[index] or VB.picking or (VB.banishes or 0) < 1 or VB.offerSource == "ley" then
        return
    end
    if not VB.offer[index].banishable then
        if offerFrame.banishWarned then
            return
        end
        offerFrame.banishWarned = true
        UIErrorsFrame:AddMessage(L["hoa.addon.you_can_t_banish_an_upgrade_you_already_have"], 1, 0.1, 0.1, 1)
        return
    end
    VB.picking = true
    VB.pickingAt = GetTime()
    SetBanishMode(false)
    Command("banish " .. index)
end

local function ToggleBanish()
    if offerFrame.banishing then
        SetBanishMode(false)
    elseif not VB.picking and (VB.banishes or 0) > 0 and VB.offerSource ~= "ley" then
        SetBanishMode(true)
    end
end

local function Reroll()
    if VB.picking or (VB.rerolls or 0) < 1 then
        return
    end
    VB.picking = true
    VB.pickingAt = GetTime()
    Command("reroll")
end

local function Skip()
    if VB.picking or (VB.skips or 0) < 1 then
        return
    end
    VB.picking = true
    VB.pickingAt = GetTime()
    Command("pass")
end

local function Lock(index)
    if not VB.offer[index] or VB.picking or VB.offerSource ~= "chest" then
        return
    end
    Command("lock " .. index)
end

offerFrame.skip = VanillaBonkUI.SliceButton(CreateFrame("Button", nil, offerFrame.chrome, "UIPanelButtonTemplate"))
offerFrame.skip:SetWidth(120)
offerFrame.skip:SetHeight(24)
offerFrame.skip:SetScript("OnClick", Skip)

offerFrame.reroll = VanillaBonkUI.SliceButton(CreateFrame("Button", nil, offerFrame.chrome, "UIPanelButtonTemplate"))
offerFrame.reroll:SetWidth(120)
offerFrame.reroll:SetHeight(24)
offerFrame.reroll:SetScript("OnClick", Reroll)

offerFrame.banish = VanillaBonkUI.SliceButton(CreateFrame("Button", nil, offerFrame.chrome, "UIPanelButtonTemplate"))
offerFrame.banish:SetWidth(120)
offerFrame.banish:SetHeight(24)
offerFrame.banish:SetScript("OnClick", ToggleBanish)

do
    local KEY_PROMPT_BUTTONS = { skip = "VANILLABONK_SKIP", reroll = "VANILLABONK_REROLL", banish = "VANILLABONK_BANISH" }

    local function RefreshKeyPrompt(button)
        local text = VanillaBonkUI.BindingText and VanillaBonkUI.BindingText(button.keyCommand) or ""
        button.keyPrompt:SetText(text)
    end

    function offerFrame.RefreshKeyPrompts()
        for name in pairs(KEY_PROMPT_BUTTONS) do
            RefreshKeyPrompt(offerFrame[name])
        end
    end

    for name, command in pairs(KEY_PROMPT_BUTTONS) do
        local button = offerFrame[name]
        button.keyCommand = command
        button.keyPrompt = VanillaBonkUI.Text(button, 11, VanillaBonkUI.NUMBER_FONT, "OUTLINE")
        button.keyPrompt:SetPoint("RIGHT", button, "RIGHT", -8, 0)
        button.keyPrompt:SetTextColor(0.85, 0.85, 0.85)
        local show = button:GetScript("OnShow")
        button:SetScript("OnShow", function()
            if show then
                show()
            end
            RefreshKeyPrompt(this)
        end)
    end

    UI.Module("offerKeyPrompts"):OnBindings(offerFrame.RefreshKeyPrompts)
end

local CardArt = VanillaBonkUI.CardArt

local CARD_HEIGHT = 300
local DAMAGE_ROW_HEIGHT = 14
local DAMAGE_ROW_GAP = 4
local DAMAGE_ARROW_SIZE = 12
local DAMAGE_ARROW = "Interface\\MoneyFrame\\Arrow-Right-Up"
local STAT_BLOCK = { labelSize = 10, valueSize = 16, step = 40, arrowGap = 4 }

local STONE_BORDER = { edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border", edgeSize = 24 }
local DARKMOON_CLOTH = "World\\ENVIRONMENT\\DOODAD\\Carnival\\bm_Carnie_tarp01"
local DARKMOON_BANNER = "World\\ENVIRONMENT\\DOODAD\\Carnival\\Darkmoon_Banner01"
local MAX_CARDS = 6
local KEYWORD_ALIASES = {
    [L["hoa.addon.chill"]] = { L["hoa.addon.chilled"] },
    [L["hoa.addon.frozen"]] = { L["hoa.addon.freezes"], L["hoa.addon.freeze"], L["hoa.addon.shatter"] },
    [L["hoa.addon.hunter_s_mark"]] = { L["hoa.addon.marked"] },
    [L["hoa.addon.poison"]] = { L["hoa.addon.poisoned"] },
    [L["hoa.addon.bleed"]] = { L["hoa.addon.bleeding"] },
    [L["hoa.addon.dazed"]] = { L["hoa.addon.dazes"], L["hoa.addon.daze"] },
}
VB.keywords = {}

local function IsLetter(char)
    return char ~= "" and strfind(char, "%a") ~= nil
end

local function KeywordTerms()
    if VB.keywordTerms then
        return VB.keywordTerms
    end
    local terms = {}
    for id, keyword in pairs(VB.keywords) do
        tinsert(terms, { text = keyword.name, id = id })
        for _, alias in ipairs(KEYWORD_ALIASES[keyword.name] or {}) do
            tinsert(terms, { text = alias, id = id })
        end
    end
    for _, term in ipairs(VB.statTerms or {}) do
        tinsert(terms, term)
    end
    table.sort(terms, function(a, b) return strlen(a.text) > strlen(b.text) end)
    VB.keywordTerms = terms
    return terms
end

local HTML_ESCAPES = { ["&"] = "&amp;", ["<"] = "&lt;", [">"] = "&gt;" }

local function MatchKeyword(text, pos, terms)
    if IsLetter(strsub(text, pos - 1, pos - 1)) then
        return nil
    end
    for _, term in ipairs(terms) do
        local stop = pos + strlen(term.text) - 1
        if strsub(text, pos, stop) == term.text and not IsLetter(strsub(text, stop + 1, stop + 1)) then
            local wholeLabel = pos == 1 and stop == strlen(text)
            if not term.stat or wholeLabel or strfind(strsub(text, max(1, pos - 2), pos - 1), "^[%d%%] $") then
                return term, stop
            end
        end
    end
end

VB.keywordColors = {
    [L["hoa.addon.chill"]] = { 0.41, 0.8, 0.94 },
    [L["hoa.addon.frozen"]] = { 0.41, 0.8, 0.94 },
    [L["hoa.addon.burning"]] = { 1, 0.71, 0.24 },
    [L["hoa.addon.fire_vulnerability"]] = { 1, 0.49, 0.1 },
    [L["hoa.addon.bleed"]] = { 1, 0.33, 0.33 },
    [L["hoa.addon.poison"]] = { 0.4, 0.85, 0.3 },
    [L["hoa.addon.nature_vulnerability"]] = { 0.25, 0.78, 0.71 },
    [L["hoa.addon.static"]] = { 0.25, 0.78, 0.71 },
    [L["hoa.addon.decay"]] = { 0.7, 0.55, 1 },
    [L["hoa.addon.shadow_vulnerability"]] = { 0.7, 0.55, 1 },
    [L["hoa.addon.sunder_armor"]] = { 0.78, 0.61, 0.43 },
    [L["hoa.addon.dazed"]] = { 0.78, 0.61, 0.43 },
    [L["hoa.addon.hunter_s_mark"]] = { 0.78, 0.61, 0.43 },
}

function VB.KeywordRGB(id)
    if VB.statTips and VB.statTips[id] then
        return 1, 1, 1
    end
    local keyword = VB.keywords[id]
    local color = keyword and VB.keywordColors[keyword.name]
    if color then
        return color[1], color[2], color[3]
    end
    return 0.41, 0.8, 0.94
end

function VB.TermColor(term)
    local r, g, b = VB.KeywordRGB(term.id)
    return format("|cff%02x%02x%02x", floor(r * 255 + 0.5), floor(g * 255 + 0.5), floor(b * 255 + 0.5))
end

local function KeywordHtml(text)
    local terms = KeywordTerms()
    local pieces, links = {}, {}
    local pos, length = 1, strlen(text)
    while pos <= length do
        local char = strsub(text, pos, pos)
        if char == "|" then
            local size = strsub(text, pos + 1, pos + 1) == "c" and 10 or 2
            tinsert(pieces, strsub(text, pos, pos + size - 1))
            pos = pos + size
        elseif char == "\n" then
            tinsert(pieces, "<br/>")
            pos = pos + 1
        else
            local term, stop = MatchKeyword(text, pos, terms)
            if term then
                tinsert(pieces, VB.TermColor(term) .. '<a href="bonkkw:' .. term.id .. '">' .. term.text .. "</a>|r")
                tinsert(links, term.id)
                pos = stop + 1
            else
                tinsert(pieces, HTML_ESCAPES[char] or char)
                pos = pos + 1
            end
        end
    end
    return '<html><body><p align="center">' .. table.concat(pieces) .. "</p></body></html>", links
end

local function FindKeyword(text)
    local terms = KeywordTerms()
    for pos = 1, strlen(text) do
        local term, stop = MatchKeyword(text, pos, terms)
        if term then
            return term, pos, stop
        end
    end
end

local function ColorKeywords(text)
    local terms = KeywordTerms()
    local pieces = {}
    local pos, length = 1, strlen(text)
    while pos <= length do
        local term, stop = MatchKeyword(text, pos, terms)
        if term then
            tinsert(pieces, VB.TermColor(term) .. term.text .. "|r")
            pos = stop + 1
        else
            tinsert(pieces, strsub(text, pos, pos))
            pos = pos + 1
        end
    end
    return table.concat(pieces)
end

function VanillaBonkUI.InspectShown()
    return VanillaBonkShop:IsShown() and VB.shop ~= nil and VB.shop.inspect == true
end

function VanillaBonkUI.HideInspect()
    VanillaBonkShop:Hide()
end

function VanillaBonkUI.InRun()
    return VB.inRun
end

function VanillaBonkUI.HasKeywordTip(id)
    return id ~= nil and ((VB.statTips and VB.statTips[id]) or VB.keywords[id]) ~= nil
end

function VanillaBonkUI.FillKeywordTip(tooltip, id)
    local stat = VB.statTips and VB.statTips[id]
    if stat then
        tooltip:AddLine(stat.name, 1, 1, 1)
        tooltip:AddLine(stat.text, 1, 0.82, 0, 1)
        return
    end
    local keyword = VB.keywords[id]
    tooltip:AddLine(keyword.name, VB.KeywordRGB(id))
    tooltip:AddLine(keyword.description, 1, 1, 1, 1)
end

local function ShowKeywordTooltip(id, owner)
    if not VanillaBonkUI.HasKeywordTip(id) then
        return
    end
    GameTooltip:SetOwner(owner, "ANCHOR_TOP")
    VanillaBonkUI.FillKeywordTip(GameTooltip, id)
    GameTooltip:Show()
end

local function HighlightCard(card)
    if VB.IsBanishTarget(card) then
        card.line:SetBackdropBorderColor(1, 0.1, 0.05, 1)
    else
        card.line:SetBackdropBorderColor(1, 0.82, 0, 1)
    end
end

local function UnhighlightCard(card)
    if VB.IsBanishTarget(card) then
        card.line:SetBackdropBorderColor(BANISH_RED[1], BANISH_RED[2], BANISH_RED[3], 1)
        return
    end
    local color = card.lineColor
    card.line:SetBackdropBorderColor(color[1], color[2], color[3], color[4])
end

local function ClickCard(card, button)
    if button == "RightButton" then
        if offerFrame.banishing then
            SetBanishMode(false)
        end
    elseif offerFrame.banishing then
        Banish(card.index)
    else
        Pick(card.index)
    end
end

local KEYWORD_HOVER_MIN_FRAMES = 2
local KEYWORD_HOVER_MAX_FRAMES = 120
local function UnderlineKeyword(hover, width)
    local dotWidth, dotStep = 2, 4
    hover.dots = hover.dots or {}
    local count = floor((width - dotWidth) / dotStep) + 1
    local r, g, b = VB.KeywordRGB(hover.keyword)
    for index = 1, count do
        local dot = hover.dots[index]
        if not dot then
            dot = hover:CreateTexture(nil, "OVERLAY")
            dot:SetTexture(VanillaBonkUI.FLAT)
            dot:SetWidth(dotWidth)
            dot:SetHeight(1)
            hover.dots[index] = dot
        end
        dot:SetVertexColor(r, g, b, 0.85)
        dot:ClearAllPoints()
        dot:SetPoint("BOTTOMLEFT", hover, "BOTTOMLEFT", (index - 1) * dotStep, 0)
        dot:Show()
    end
    for index = count + 1, table.getn(hover.dots) do
        hover.dots[index]:Hide()
    end
end

local function ReadingOrder(a, b)
    local aTop, bTop = a:GetTop(), b:GetTop()
    if math.abs(aTop - bTop) > 2 then
        return aTop > bTop
    end
    return a:GetLeft() < b:GetLeft()
end

local function KeywordSpans(html)
    local spans = {}
    for _, span in ipairs({ html:GetChildren() }) do
        if span:IsShown() and span:GetLeft() and span:GetTop() then
            span:EnableMouse(false)
            tinsert(spans, span)
        end
    end
    table.sort(spans, ReadingOrder)
    return spans
end

local function CreateKeywordHover(card, index, parent)
    local hover = CreateFrame("Button", nil, parent or card)
    hover:SetFrameLevel(card.description:GetFrameLevel() + 2)
    hover:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    hover.card = card
    hover:SetScript("OnEnter", function()
        HighlightCard(this.card)
        ShowKeywordTooltip(this.keyword, this)
    end)
    hover:SetScript("OnLeave", function()
        GameTooltip:Hide()
        if not MouseIsOver(this.card) then
            UnhighlightCard(this.card)
        end
    end)
    hover:SetScript("OnClick", function()
        ClickCard(this.card, arg1)
    end)
    if index then
        card.hovers[index] = hover
    end
    return hover
end

local function PlaceKeywordHovers(card, spans)
    local html = card.description
    for index, span in ipairs(spans) do
        local hover = card.hovers[index] or CreateKeywordHover(card, index)
        hover:ClearAllPoints()
        hover:SetPoint("TOPLEFT", html, "TOPLEFT", span:GetLeft() - html:GetLeft(), span:GetTop() - html:GetTop())
        hover:SetWidth(span:GetWidth())
        hover:SetHeight(span:GetHeight())
        hover.keyword = card.descriptionLinks and card.descriptionLinks[index]
        UnderlineKeyword(hover, span:GetWidth())
        hover:Show()
    end
    for index = table.getn(spans) + 1, table.getn(card.hovers) do
        card.hovers[index]:Hide()
    end
end

local function SetKeywordText(card)
    for _, hover in ipairs(card.hovers) do
        hover:Hide()
    end
    card.description:SetText(card.descriptionHtml or "")
    card.description.hoverFrames = 0
end

local function UpdateKeywordHovers(html)
    local links = table.getn(html.card.descriptionLinks or {})
    if links == 0 then
        html.hoverFrames = nil
        return
    end
    html.hoverFrames = html.hoverFrames + 1
    if html.hoverFrames < KEYWORD_HOVER_MIN_FRAMES then
        return
    end
    local spans = KeywordSpans(html)
    if table.getn(spans) >= links then
        html.hoverFrames = nil
        PlaceKeywordHovers(html.card, spans)
    elseif html.hoverFrames >= KEYWORD_HOVER_MAX_FRAMES then
        html.hoverFrames = nil
    end
end

local function RebuildKeywordLinks(card)
    if card.descriptionHtml then
        SetKeywordText(card)
    end
end

for index = 1, MAX_CARDS do
    local card = CreateFrame("Button", nil, offerFrame)
    card:SetHeight(CARD_HEIGHT)
    card:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    card.index = index

    card.art = card:CreateTexture(nil, "BACKGROUND")
    card.art:SetPoint("TOPLEFT", card, "TOPLEFT", 9, -9)
    card.art:SetPoint("BOTTOMRIGHT", card, "BOTTOMRIGHT", -9, 9)
    card.shade = card:CreateTexture(nil, "BORDER")
    card.shade:SetAllPoints(card.art)
    VanillaBonkUI.Shade(card.shade, 0.95, 0.1)

    card:SetBackdrop(STONE_BORDER)
    card.line = CreateFrame("Frame", nil, card)
    card.line:SetPoint("TOPLEFT", card, "TOPLEFT", 8, -8)
    card.line:SetPoint("BOTTOMRIGHT", card, "BOTTOMRIGHT", -8, 8)
    card.line:SetBackdrop({ edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 1 })

    card.slot = VanillaBonkUI.Slot(card, 56, "Frame")
    card.slot:SetPoint("TOP", card, "TOP", 0, -34)
    card.glow = card.slot:CreateTexture(nil, "OVERLAY")
    card.glow:SetTexture("Interface\\Buttons\\UI-ActionButton-Border")
    card.glow:SetBlendMode("ADD")
    card.glow:SetWidth(96)
    card.glow:SetHeight(96)
    card.glow:SetPoint("CENTER", card.slot, "CENTER", 0, 0)

    card.crest = card:CreateTexture(nil, "ARTWORK")
    card.crest:SetTexture(DARKMOON_BANNER)
    card.crest:SetTexCoord(8 / 256, 182 / 256, 16 / 256, 190 / 256)
    card.crest:SetWidth(116)
    card.crest:SetHeight(116)
    card.crest:SetPoint("TOP", card, "TOP", 0, -32)
    card.crest:Hide()
    card.eye = VanillaBonkUI.Ring(card, 52, true)
    card.eye:SetPoint("CENTER", card.crest, "CENTER", 0, 0)
    card.eye.icon = VanillaBonkUI.RingArt(card.eye, "")
    card.eye:Hide()

    card.key = VanillaBonkUI.Ring(card, 28)
    card.key:SetPoint("TOPLEFT", card, "TOPLEFT", 13, -13)
    card.key.text = VanillaBonkUI.Text(card.key, 13)
    card.key.text:SetPoint("CENTER", card.key, "CENTER", 0, 0)
    card.key.text:SetTextColor(1, 0.82, 0)
    card.key.text:SetText(index)

    card.name = VanillaBonkUI.Text(card, 17)
    card.name:SetPoint("TOP", card, "TOP", 0, -104)
    card.name:SetJustifyH("CENTER")

    card.level = VanillaBonkUI.Text(card, 11)
    card.level:SetPoint("TOP", card.name, "BOTTOM", 0, -4)
    card.level:SetTextColor(0.85, 0.85, 0.85)

    card.divider = card:CreateTexture(nil, "ARTWORK")
    card.divider:SetTexture(VanillaBonkUI.FLAT)
    card.divider:SetHeight(1)
    card.divider:SetPoint("TOPRIGHT", card.level, "BOTTOM", 0, -11)
    card.divider:SetGradientAlpha("HORIZONTAL", 1, 0.82, 0, 0, 1, 0.82, 0, 0.75)
    card.dividerRight = card:CreateTexture(nil, "ARTWORK")
    card.dividerRight:SetTexture(VanillaBonkUI.FLAT)
    card.dividerRight:SetHeight(1)
    card.dividerRight:SetPoint("TOPLEFT", card.level, "BOTTOM", 0, -11)
    card.dividerRight:SetGradientAlpha("HORIZONTAL", 1, 0.82, 0, 0.75, 1, 0.82, 0, 0)

    card.count = VanillaBonkUI.Text(card, 11)
    card.count:SetPoint("TOPRIGHT", card, "TOPRIGHT", -16, -17)
    card.count:SetTextColor(0.85, 0.85, 0.85)

    card.measure = VanillaBonkUI.Text(card, 13)
    card.measure:SetPoint("TOPLEFT", card, "TOPLEFT", 0, 0)
    card.measure:SetJustifyH("CENTER")
    card.measure:SetTextColor(0, 0, 0, 0)
    card.measure:SetShadowColor(0, 0, 0, 0)

    card.damage = CreateFrame("Frame", nil, card)
    card.damage:SetHeight(DAMAGE_ROW_HEIGHT)
    card.damage.label = VanillaBonkUI.Text(card.damage, 12)
    card.damage.label:SetTextColor(0.85, 0.85, 0.85)
    card.damage.before = VanillaBonkUI.Text(card.damage, 12)
    card.damage.before:SetTextColor(0.6, 0.6, 0.6)
    card.damage.strike = card.damage:CreateTexture(nil, "OVERLAY")
    card.damage.strike:SetTexture(VanillaBonkUI.FLAT)
    card.damage.strike:SetVertexColor(0.75, 0.75, 0.75)
    card.damage.strike:SetHeight(1)
    card.damage.strike:SetPoint("LEFT", card.damage.before, "LEFT", 0, 0)
    card.damage.arrow = card.damage:CreateTexture(nil, "ARTWORK")
    card.damage.arrow:SetTexture(DAMAGE_ARROW)
    card.damage.arrow:SetWidth(DAMAGE_ARROW_SIZE)
    card.damage.arrow:SetHeight(DAMAGE_ARROW_SIZE)
    card.damage.after = VanillaBonkUI.Text(card.damage, 12)
    card.damage.after:SetTextColor(0.13, 1, 0.13)
    card.damage:Hide()

    card.description = CreateFrame("SimpleHTML", nil, card)
    card.description:SetPoint("TOP", card.divider, "BOTTOMRIGHT", 0, -10)
    card.description:SetFont("P", FONT, 13, "")
    card.description:SetTextColor("P", 1, 0.82, 0)
    card.description:SetShadowColor("P", 0, 0, 0, 1)
    card.description:SetShadowOffset("P", 1, -1)
    card.description.card = card
    card.hovers = {}
    card.description:SetScript("OnUpdate", function()
        if this.hoverFrames then
            UpdateKeywordHovers(this)
        end
    end)

    card.highlight = card:CreateTexture(nil, "HIGHLIGHT")
    card.highlight:SetTexture("Interface\\Buttons\\UI-Panel-Button-Highlight")
    card.highlight:SetBlendMode("ADD")
    card.highlight:SetTexCoord(0, 0.625, 0, 0.6875)
    card.highlight:SetAlpha(0.35)
    card.highlight:SetAllPoints(card.art)

    card:SetScript("OnClick", function()
        ClickCard(this, arg1)
    end)
    card:SetScript("OnEnter", function()
        HighlightCard(this)
    end)
    card:SetScript("OnLeave", function()
        UnhighlightCard(this)
    end)

    card.lock = VanillaBonkUI.SliceButton(CreateFrame("Button", nil, card, "UIPanelButtonTemplate"))
    card.lock:SetWidth(80)
    card.lock:SetHeight(20)
    card.lock:SetPoint("BOTTOM", card, "BOTTOM", 0, 18)
    card.lock.index = index
    card.lock:SetScript("OnClick", function()
        Lock(this.index)
    end)

    offerFrame.cards[index] = card
end

local OFFER_POP = 0.24
local OFFER_STAGGER = 0.05
local OFFER_CLOSE = 0.18
local OFFER_DIM = 1
local GARBAGE_DUE = 0.75

local function CollectGarbageIfDue()
    local used, threshold = gcinfo()
    if used and threshold and threshold > 0 and used >= threshold * GARBAGE_DUE then
        collectgarbage()
    end
end

local function EaseOut(t)
    t = 1 - t
    return 1 - t * t * t
end

local function EaseBack(t)
    t = t - 1
    return 1 + 2.70158 * t * t * t + 1.70158 * t * t
end

local function Progress(t, start, length)
    return min(1, max(0, (t - start) / length))
end

offerFrame.SIDE_SCALE = 0.5
offerFrame.SIDE_BOTTOM = 140
offerFrame.SIDE_BUTTON_STEP = 28

local function PlaceCard(card, scale, alpha, rise)
    card:SetAlpha(alpha)
    card.alphaNow = alpha
    card:ClearAllPoints()
    if offerFrame.side then
        local sideScale = scale * offerFrame.SIDE_SCALE
        card:SetScale(sideScale)
        card:SetPoint("BOTTOM", UIParent, "BOTTOM", card.x * offerFrame.SIDE_SCALE / sideScale, (offerFrame.SIDE_BOTTOM + rise * offerFrame.SIDE_SCALE) / sideScale)
        return
    end
    card:SetScale(scale)
    card:SetPoint("CENTER", offerFrame, "CENTER", card.x / scale, (16 - offerFrame.cardDrop + rise) / scale)
end

function offerFrame.ApplySideChrome()
    offerFrame.title:ClearAllPoints()
    offerFrame.subtitle:ClearAllPoints()
    if offerFrame.side then
        offerFrame.title:Hide()
        offerFrame.subtitle:SetPoint("TOP", UIParent, "BOTTOM", 0, offerFrame.SIDE_BOTTOM - 6)
        offerFrame.dim:Hide()
        offerFrame.hint:Hide()
        return
    end
    offerFrame.title:SetPoint("CENTER", offerFrame, "CENTER", 0, 230)
    offerFrame.title:Show()
    offerFrame.subtitle:SetPoint("CENTER", offerFrame, "CENTER", 0, 186)
    offerFrame.dim:Show()
    offerFrame.hint:Show()
end

local CHOICE_KEYS = {
    ["1"] = "VANILLABONK_CHOICE1", ["2"] = "VANILLABONK_CHOICE2", ["3"] = "VANILLABONK_CHOICE3",
    ["4"] = "VANILLABONK_CHOICE4", ["5"] = "VANILLABONK_CHOICE5", ["6"] = "VANILLABONK_CHOICE6",
    ["R"] = "VANILLABONK_REROLL", ["X"] = "VANILLABONK_SKIP", ["B"] = "VANILLABONK_BANISH",
}
BINDING_HEADER_VANILLABONK = L["hoa.addon.hordes_of_azeroth"]
for index = 1, 6 do
    setglobal("BINDING_NAME_VANILLABONK_CHOICE" .. index, L("hoa.addon.choose_card_1", index))
end
BINDING_NAME_VANILLABONK_REROLL = L["hoa.addon.reroll_cards"]
BINDING_NAME_VANILLABONK_SKIP = L["hoa.addon.skip_cards"]
BINDING_NAME_VANILLABONK_BANISH = L["hoa.addon.banish_card"]

local function GiveBackChoiceKeys()
    if not VanillaBonkChoiceKeys or (VanillaBonkGlyphs and VanillaBonkGlyphs.open) then
        return
    end
    for key, action in pairs(VanillaBonkChoiceKeys) do
        if action ~= "" then
            SetBinding(key, action)
        else
            SetBinding(key)
        end
    end
    VanillaBonkChoiceKeys = nil
end

local function TakeChoiceKeys()
    if VanillaBonkChoiceKeys then
        return
    end
    local before = {}
    for key, action in pairs(CHOICE_KEYS) do
        before[key] = GetBindingAction(key) or ""
        SetBinding(key, action)
    end
    VanillaBonkChoiceKeys = before
    offerFrame.RefreshKeyPrompts()
end

VanillaBonk_TakeChoiceKeys = TakeChoiceKeys
VanillaBonk_GiveBackChoiceKeys = GiveBackChoiceKeys

function VanillaBonk_ChoiceKey(key)
    if VanillaBonkMenu and VanillaBonkMenu:IsShown() then
        return
    end
    local index = tonumber(key)
    if index and VanillaBonk_GlyphKey and VanillaBonk_GlyphKey(index) then
        return
    end
    if key == "R" and VanillaBonk_GlyphReroll and VanillaBonk_GlyphReroll() then
        return
    end
    if not offerFrame.open then
        return
    end
    if index and offerFrame.banishing then
        Banish(index)
    elseif index then
        Pick(index)
    elseif key == "R" then
        Reroll()
    elseif key == "X" then
        Skip()
    elseif key == "B" then
        ToggleBanish()
    end
end

UI.Module("choiceKeys"):Listen({
    VARIABLES_LOADED = GiveBackChoiceKeys,
    PLAYER_LOGOUT = GiveBackChoiceKeys,
})

local CARD_TEXT_WIDTH = 220
local function LayoutDamageRow(card, option, hasLock)
    local row = card.damage
    local after = option and option.damageAfter or ""
    if after == "" then
        row:Hide()
        return 0
    end
    local before = option.damageBefore or ""
    local label = option.damageLabel or ""
    if label == "" then
        label = L["hoa.addon.damage_2"]
    end
    row.label:SetText(label ~= "" and label .. ":" or "")
    row.before:SetText(before)
    row.after:SetText(after)
    local changed = before ~= ""
    local labelWidth = label ~= "" and row.label:GetStringWidth() + DAMAGE_ROW_GAP or 0
    local beforeWidth = changed and row.before:GetStringWidth() or 0
    local arrowWidth = changed and DAMAGE_ARROW_SIZE + 2 * DAMAGE_ROW_GAP or 0
    local total = labelWidth + beforeWidth + arrowWidth + row.after:GetStringWidth()
    if labelWidth > 0 and total > card:GetWidth() - 16 then
        row.label:SetText("")
        total = total - labelWidth
        labelWidth = 0
    end
    row:SetWidth(total)
    row:ClearAllPoints()
    row:SetPoint("BOTTOM", card, "BOTTOM", 0, hasLock and 46 or 18)
    row.label:ClearAllPoints()
    row.label:SetPoint("LEFT", row, "LEFT", 0, 0)
    row.before:ClearAllPoints()
    row.before:SetPoint("LEFT", row, "LEFT", labelWidth, 0)
    row.strike:SetWidth(max(1, beforeWidth))
    row.arrow:ClearAllPoints()
    row.arrow:SetPoint("LEFT", row, "LEFT", labelWidth + beforeWidth + DAMAGE_ROW_GAP, 0)
    row.after:ClearAllPoints()
    row.after:SetPoint("LEFT", row, "LEFT", labelWidth + beforeWidth + arrowWidth, 0)
    if changed then
        row.before:Show()
        row.strike:Show()
        row.arrow:Show()
    else
        row.before:Hide()
        row.strike:Hide()
        row.arrow:Hide()
    end
    row:Show()
    return DAMAGE_ROW_HEIGHT + DAMAGE_ROW_GAP
end

local function FitCardText(card, width, darkmoon, hasLock, damageRoom)
    local scale = min(1, width / CARD_TEXT_WIDTH)
    card.name:SetFont(FONT, max(12, floor(17 * scale + 0.5)))
    card.name:SetWidth(width - 28)
    card.level:SetFont(FONT, max(9, floor(11 * scale + 0.5)))
    card.level:SetWidth(width - 20)
    card.count:SetFont(FONT, max(9, floor(11 * scale + 0.5)))
    card.description:SetWidth(width - 36)
    card.measure:SetWidth(width - 36)
    card.measure:SetText(card.descriptionText or "")

    local top = darkmoon and 158 or 104
    local used = top + card.name:GetHeight() + 4 + card.level:GetHeight() + 11 + 1 + 10
    local room = offerFrame.cardHeight - used - (hasLock and 46 or 18) - (damageRoom or 0)
    local size = max(10, floor(13 * scale + 0.5))
    while size > 9 do
        card.measure:SetFont(FONT, size)
        local needed = card.measure:GetHeight()
        if not needed or needed == 0 or needed <= room then
            break
        end
        size = size - 1
    end
    card.measure:SetFont(FONT, size)
    card.overflow = max(0, (card.measure:GetHeight() or 0) - room)
    card.description:SetFont("P", FONT, size, "")
    card.description:SetHeight(max(room, 12))
    card.descriptionHtml, card.descriptionLinks = KeywordHtml(card.descriptionText or "")
    SetKeywordText(card)
    return room
end

local function GetStatBlock(card, index)
    card.stats = card.stats or {}
    local block = card.stats[index]
    if block then
        return block
    end
    block = CreateFrame("Frame", nil, card)
    block.label = VanillaBonkUI.Text(block, STAT_BLOCK.labelSize)
    block.label:SetTextColor(0.65, 0.65, 0.65)
    block.label:SetJustifyH("CENTER")
    block.label:SetPoint("TOP", block, "TOP", 0, 0)
    block.before = VanillaBonkUI.Text(block, STAT_BLOCK.valueSize)
    block.before:SetTextColor(0.6, 0.6, 0.6)
    block.arrow = block:CreateTexture(nil, "ARTWORK")
    block.arrow:SetTexture(DAMAGE_ARROW)
    block.after = VanillaBonkUI.Text(block, STAT_BLOCK.valueSize)
    block.after:SetTextColor(0.13, 1, 0.13)
    block.measure = VanillaBonkUI.Text(block, STAT_BLOCK.labelSize)
    block.measure:SetTextColor(0, 0, 0, 0)
    block.measure:SetShadowColor(0, 0, 0, 0)
    block.measure:SetPoint("TOPLEFT", block, "TOPLEFT", 0, 0)
    block.hover = CreateKeywordHover(card, nil, block)
    card.stats[index] = block
    return block
end

local function HideStats(card, from)
    if not card.stats then
        return
    end
    for index = from, getn(card.stats) do
        card.stats[index]:Hide()
    end
end

function STAT_BLOCK.PlaceKeyword(block, label, size)
    local hover = block.hover
    local term, start = FindKeyword(label)
    if not term then
        hover:Hide()
        return
    end
    block.measure:SetFont(FONT, size)
    block.measure:SetText(strsub(label, 1, start - 1))
    local prefix = start > 1 and block.measure:GetStringWidth() or 0
    block.measure:SetText(term.text)
    local word = block.measure:GetStringWidth()
    hover:ClearAllPoints()
    hover:SetPoint("TOPLEFT", block, "TOP", prefix - block.label:GetStringWidth() / 2, 0)
    hover:SetWidth(word)
    hover:SetHeight(size + 2)
    hover.keyword = term.id
    UnderlineKeyword(hover, word)
    hover:Show()
end

local function LayoutStats(card, stats, width, room)
    local scale = min(1, width / CARD_TEXT_WIDTH)
    local count = getn(stats)
    local labelSize = max(8, floor(STAT_BLOCK.labelSize * scale + 0.5))
    local step = min(floor(STAT_BLOCK.step * scale + 0.5), floor(room / max(1, count)))
    local valueSize = max(10, min(floor(STAT_BLOCK.valueSize * scale + 0.5), step - labelSize - 8))
    local arrowSize = floor(valueSize * 0.8 + 0.5)
    for index, stat in ipairs(stats) do
        local block = GetStatBlock(card, index)
        block:SetWidth(width - 20)
        block:SetHeight(step)
        block:ClearAllPoints()
        block:SetPoint("TOP", card.divider, "BOTTOMRIGHT", 0, -8 - (index - 1) * step)
        block.label:SetFont(FONT, labelSize)
        block.label:SetWidth(width - 24)
        block.label:SetText(ColorKeywords(stat.label))
        STAT_BLOCK.PlaceKeyword(block, stat.label, labelSize)
        block.before:SetFont(FONT, valueSize)
        block.after:SetFont(FONT, valueSize)
        local capped = stat.before == stat.after
        block.before:SetText(capped and L("hoa.addon.1_max", stat.before) or stat.before)
        block.after:SetText(capped and "" or stat.after)
        block.arrow:SetWidth(arrowSize)
        block.arrow:SetHeight(arrowSize)
        local total = block.before:GetStringWidth()
        if capped then
            block.arrow:Hide()
        else
            block.arrow:Show()
            total = total + arrowSize + 2 * STAT_BLOCK.arrowGap + block.after:GetStringWidth()
        end
        block.before:ClearAllPoints()
        block.before:SetPoint("TOPLEFT", block, "TOP", -total / 2, -(block.label:GetHeight() + 3))
        block.arrow:ClearAllPoints()
        block.arrow:SetPoint("LEFT", block.before, "RIGHT", STAT_BLOCK.arrowGap, 0)
        block.after:ClearAllPoints()
        block.after:SetPoint("LEFT", block.arrow, "RIGHT", STAT_BLOCK.arrowGap, 0)
        block:Show()
    end
    HideStats(card, count + 1)
end

function offerFrame.FitCard(card, option, width, hasLock)
    local darkmoon = option.kind == "c"
    if not darkmoon then
        VanillaBonkUI.TalentArtCoords(card.art, width - 18, offerFrame.cardHeight - 18)
    end
    if option.stats and getn(option.stats) > 0 then
        card.descriptionText = ""
        card.damage:Hide()
        LayoutStats(card, option.stats, width, FitCardText(card, width, darkmoon, hasLock, 0))
    else
        HideStats(card, 1)
        card.descriptionText = option.description
        FitCardText(card, width, darkmoon, hasLock, LayoutDamageRow(card, option, hasLock))
    end
end

function offerFrame.GrowCardsToFit(width, hasLock)
    local grow = 0
    for index, card in ipairs(offerFrame.cards) do
        if VB.offer[index] then
            grow = max(grow, card.overflow or 0)
        end
    end
    grow = min(ceil(grow), offerFrame.MAX_GROWTH)
    if grow > 0 then
        offerFrame.cardHeight = CARD_HEIGHT + grow
        for index, card in ipairs(offerFrame.cards) do
            local option = VB.offer[index]
            if option then
                card:SetHeight(offerFrame.cardHeight)
                offerFrame.FitCard(card, option, width, hasLock)
            end
        end
    end
    offerFrame.cardDrop = grow / 2
    for index, card in ipairs(offerFrame.cards) do
        if VB.offer[index] and not card.pop then
            PlaceCard(card, 1, 1, 0)
        end
    end
    offerFrame.hint:SetPoint("CENTER", offerFrame, "CENTER", 0, -206 - grow)
    return grow
end

function offerFrame.Subtitle()
    if VB.offerSource == "ley" then
        return L["hoa.addon.choose_a_blessing"]
    end
    local cards, upgrades = 0, 0
    for _, option in ipairs(VB.offer) do
        if option.kind == "c" then
            cards = cards + 1
        else
            upgrades = upgrades + 1
        end
    end
    if cards > 0 and upgrades > 0 then
        return L["hoa.addon.choose_a_reward"]
    end
    return cards > 0 and L["hoa.addon.choose_a_darkmoon_card"] or L["hoa.addon.choose_an_upgrade"]
end

local function ShowOffer(level)
    if offerFrame.anim and offerFrame.anim.mode == "close" then
        offerFrame.deferred = { level = level }
        return
    end
    local fresh = not offerFrame.open
    offerFrame.side = VB.sideOffers and true or false
    offerFrame.SIDE_SCALE = VanillaBonkUI.SideScale(0.5)
    offerFrame.ApplySideChrome()
    if not fresh and not offerFrame.anim then
        offerFrame.anim = { mode = "pop", t = 0 }
    end

    if VB.offerSource == "chest" then
        offerFrame.title:SetText(L["hoa.addon.chest"])
    elseif VB.offerSource == "ley" then
        offerFrame.title:SetText(L["hoa.addon.ley_line"])
    else
        offerFrame.title:SetText(L("hoa.addon.level_1", level))
    end
    offerFrame.subtitle:SetText(offerFrame.Subtitle())

    local count = getn(VB.offer)
    local gap = count <= 3 and 20 or 12
    local width = count <= 3 and 220 or (count == 4 and 200 or 180)
    width = min(width, floor((UIParent:GetWidth() - 40 - (count - 1) * gap) / max(1, count)))
    local left = -((count * width + (count - 1) * gap) / 2) + width / 2
    local hasLock = VB.offerSource == "chest"
    offerFrame.cardHeight = CARD_HEIGHT

    for index, card in ipairs(offerFrame.cards) do
        local option = VB.offer[index]
        if option then
            card:SetWidth(width)
            card:SetHeight(CARD_HEIGHT)
            card.x = left + (index - 1) * (width + gap)
            local look = option.name .. option.icon .. option.newLevel .. (option.rarity or "")
            if fresh then
                card.pop = 0.08 + (index - 1) * OFFER_STAGGER
                PlaceCard(card, 0.8, 0, -24)
            elseif card.look ~= look or not card:IsShown() then
                card.pop = offerFrame.anim.t
                PlaceCard(card, 0.8, 0, -24)
            elseif not card.pop then
                PlaceCard(card, 1, 1, 0)
            end
            card.look = look
            card.divider:SetWidth((width - 48) / 2)
            card.dividerRight:SetWidth((width - 48) / 2)

            local darkmoon = option.kind == "c"
            if darkmoon then
                card.art:SetTexture(DARKMOON_CLOTH)
                card.art:SetTexCoord(0, 1, 0, 1)
                VanillaBonkUI.Shade(card.shade, 0.95, 0.4)
                card.slot:Hide()
                card.crest:Show()
                card.eye.icon:SetTexture(ICON_PATH .. option.icon)
                card.eye:Show()
                card.name:SetPoint("TOP", card, "TOP", 0, -158)
            else
                card.art:SetTexture("Interface\\TalentFrame\\" .. CardArt(option.icon) .. "-TopLeft")
                VanillaBonkUI.Shade(card.shade, 0.95, 0.1)
                card.slot:Show()
                card.crest:Hide()
                card.eye:Hide()
                card.name:SetPoint("TOP", card, "TOP", 0, -104)
            end
            card.slot.icon:SetTexture(ICON_PATH .. option.icon)
            card.name:SetText(option.name)

            local rarity = option.kind == "e" and 4 or option.rarity
            local color = rarity and RARITIES[rarity]
            if color then
                card.name:SetTextColor(color.r, color.g, color.b)
                card.lineColor = { color.r, color.g, color.b, 0.9 }
                card.glow:SetVertexColor(color.r, color.g, color.b)
                card.glow:Show()
            else
                card.name:SetTextColor(1, 1, 1)
                card.lineColor = { 0.85, 0.75, 0.5, 0.35 }
                card.glow:Hide()
            end
            local rarityName = option.rarity and RARITIES[option.rarity] and RarityText(option.rarity, RARITIES[option.rarity].name)
            if option.kind == "e" then
                card.level:SetText(L("hoa.addon.1_evolution", RarityText(4, L["hoa.addon.legendary"])))
            elseif option.kind == "ley" then
                card.level:SetText(rarityName and L("hoa.addon.1_blessing", rarityName) or L["hoa.addon.blessing"])
            elseif option.kind == "c" then
                card.level:SetText(rarityName and L("hoa.addon.1_darkmoon_card", rarityName) or L["hoa.addon.darkmoon_card_2"])
            elseif option.newLevel == 1 then
                card.level:SetText(option.kind == "p" and L["hoa.addon.cff20ff20new_passive_r"] or L["hoa.addon.cff20ff20new_spell_r"])
            elseif option.kind == "p" then
                card.level:SetText(rarityName and L("hoa.addon.1_passive", rarityName) or L["hoa.addon.passive"])
            else
                card.level:SetText(rarityName and L("hoa.addon.1_spell", rarityName) or L["hoa.addon.spell"])
            end
            if option.kind == "ley" or option.kind == "e" then
                card.count:SetText("")
            elseif option.kind == "c" and option.maxLevel > 1 then
                card.count:SetText(L("hoa.addon.1_2_copies", option.newLevel, option.maxLevel))
            elseif option.kind == "c" and option.newLevel > 1 then
                card.count:SetText(L("hoa.addon.1_copies", option.newLevel))
            elseif option.maxLevel > 1 then
                card.count:SetText(L("hoa.addon.rank_1_2_2", option.newLevel, option.maxLevel))
            elseif option.newLevel > 1 then
                card.count:SetText(L("hoa.addon.rank_1", option.newLevel))
            else
                card.count:SetText("")
            end
            card.line:SetBackdropBorderColor(card.lineColor[1], card.lineColor[2], card.lineColor[3], card.lineColor[4])
            card.borderColor = color and { color.r, color.g, color.b } or { 1, 1, 1 }
            card:SetBackdropBorderColor(card.borderColor[1], card.borderColor[2], card.borderColor[3])
            offerFrame.FitCard(card, option, width, hasLock)
            if hasLock then
                card.lock:SetText(option.locked and L["hoa.addon.locked"] or L["hoa.addon.lock"])
                card.lock:Show()
            else
                card.lock:Hide()
            end
            card:Show()
        else
            card.pop = nil
            card.look = nil
            card:Hide()
        end
    end

    local grow = offerFrame.GrowCardsToFit(width, hasLock)
    local canBanish = (VB.banishes or 0) > 0 and VB.offerSource ~= "ley"

    local buttons = {}
    if (VB.rerolls or 0) > 0 then
        offerFrame.reroll:SetText(L("hoa.addon.reroll_1", VB.rerolls))
        tinsert(buttons, offerFrame.reroll)
    else
        offerFrame.reroll:Hide()
    end
    if canBanish then
        tinsert(buttons, offerFrame.banish)
    else
        offerFrame.banish:Hide()
    end
    if (VB.skips or 0) > 0 then
        offerFrame.skip:SetText(L("hoa.addon.skip_1", VB.skips))
        tinsert(buttons, offerFrame.skip)
    else
        offerFrame.skip:Hide()
    end
    local total = getn(buttons) * 120 + (getn(buttons) - 1) * 12
    local sideEdge = (count * width + (count - 1) * gap) * offerFrame.SIDE_SCALE / 2 + 8
    local leftY, rightY = offerFrame.SIDE_BOTTOM, offerFrame.SIDE_BOTTOM
    for index, button in ipairs(buttons) do
        button:ClearAllPoints()
        if not offerFrame.side then
            button:SetPoint("CENTER", offerFrame, "CENTER", -total / 2 + 60 + (index - 1) * 132, -170 - grow)
        elseif button == offerFrame.skip then
            button:SetPoint("BOTTOMLEFT", UIParent, "BOTTOM", sideEdge, rightY)
            rightY = rightY + offerFrame.SIDE_BUTTON_STEP
        else
            button:SetPoint("BOTTOMRIGHT", UIParent, "BOTTOM", -sideEdge, leftY)
            leftY = leftY + offerFrame.SIDE_BUTTON_STEP
        end
        button:Show()
    end

    VB.picking = false
    VB.pickedIndex = nil
    SetBanishMode(false)
    if fresh then
        CollectGarbageIfDue()
        PlaySound("LEVELUP")
        offerFrame.open = true
        TakeChoiceKeys()
        offerFrame.anim = { mode = "open", t = 0, dimFrom = offerFrame.dimAlpha or 0 }
        offerFrame.chrome:SetAlpha(0)
        offerFrame.dim:SetVertexColor(0, 0, 0, OFFER_DIM * (offerFrame.dimAlpha or 0))
    end
    offerFrame:Show()
end

local function AnimateOffer(frame, elapsed)
    local anim = frame.anim
    anim.t = anim.t + elapsed
    local t = anim.t

    if anim.mode == "close" then
        local e = Progress(t, 0, OFFER_CLOSE)
        if not frame.deferred then
            frame.dimAlpha = anim.dimFrom * (1 - e)
            frame.dim:SetVertexColor(0, 0, 0, OFFER_DIM * frame.dimAlpha)
        end
        frame.chrome:SetAlpha(anim.chromeFrom * (1 - e))
        for _, card in ipairs(frame.cards) do
            if card:IsShown() then
                if card.index == VB.pickedIndex then
                    PlaceCard(card, 1 + 0.08 * EaseOut(e), card.closeFrom * (1 - e), 6 * e)
                else
                    PlaceCard(card, 1 - 0.06 * e, card.closeFrom * max(0, 1 - e * 1.5), -12 * e)
                end
            end
        end
        if e >= 1 then
            frame.anim = nil
            local deferred = frame.deferred
            frame.deferred = nil
            if deferred then
                ShowOffer(deferred.level)
            else
                frame:Hide()
            end
        end
        return
    end

    local busy = false
    if anim.mode == "open" then
        frame.dimAlpha = anim.dimFrom + (1 - anim.dimFrom) * EaseOut(Progress(t, 0, 0.2))
        frame.dim:SetVertexColor(0, 0, 0, OFFER_DIM * frame.dimAlpha)
        local header = EaseOut(Progress(t, 0.04, 0.26))
        frame.chrome:SetAlpha(header)
        frame.title:SetPoint("CENTER", frame, "CENTER", 0, 230 + 16 * (1 - header))
        busy = header < 1
    end
    for _, card in ipairs(frame.cards) do
        if card.pop then
            local p = Progress(t, card.pop, OFFER_POP)
            PlaceCard(card, 0.8 + 0.2 * EaseBack(p), min(1, p * 2), -24 * (1 - EaseOut(p)))
            if p >= 1 then
                card.pop = nil
                RebuildKeywordLinks(card)
            else
                busy = true
            end
        end
    end
    if not busy then
        frame.anim = nil
    end
end

offerFrame:SetScript("OnUpdate", function()
    if this.anim then
        AnimateOffer(this, arg1)
    end
end)

offerFrame:SetScript("OnShow", function()
    if this.open then
        TakeChoiceKeys()
    end
    for _, card in ipairs(this.cards) do
        if card:IsShown() and not card.pop then
            RebuildKeywordLinks(card)
        end
    end
end)

offerFrame:SetScript("OnHide", function()
    GiveBackChoiceKeys()
    if this:IsShown() then
        return
    end
    SetBanishMode(false)
    this.anim = nil
    this.open = false
    this.deferred = nil
    this.dimAlpha = 0
end)

local function CloseOffer()
    if not offerFrame:IsShown() or not offerFrame.open then
        return
    end
    GiveBackChoiceKeys()
    SetBanishMode(false)
    offerFrame:EnableMouse(false)
    offerFrame.open = false
    offerFrame.anim = { mode = "close", t = 0, dimFrom = offerFrame.dimAlpha or 1, chromeFrom = offerFrame.chrome:GetAlpha() }
    for _, card in ipairs(offerFrame.cards) do
        card.pop = nil
        card.closeFrom = card.alphaNow or 1
    end
end

local results = CreateFrame("Frame", "VanillaBonkResults", UIParent)
results:SetWidth(360)
results:SetHeight(210)
results:SetPoint("CENTER", UIParent, "CENTER", 0, 100)
results:SetFrameStrata("DIALOG")
DialogBackdrop(results)
results:Hide()

results.title = results:CreateFontString(nil, "OVERLAY")
SetFont(results.title, 26)
results.title:SetPoint("TOP", results, "TOP", 0, -24)

results.body = results:CreateFontString(nil, "OVERLAY")
SetFont(results.body, 13, "")
results.body:SetPoint("TOP", results.title, "BOTTOM", 0, -14)
results.body:SetJustifyH("CENTER")

results.close = VanillaBonkUI.SliceButton(CreateFrame("Button", nil, results, "UIPanelButtonTemplate"))
results.close:SetWidth(100)
results.close:SetHeight(22)
results.close:SetPoint("BOTTOM", results, "BOTTOM", 0, 18)
results.close:SetText(L["hoa.addon.close"])
results.close:SetScript("OnClick", function()
    results:Hide()
end)

function VB.TakeOverGossip(pending)
    if VB.gossipFrame and VB.gossipFrame ~= pending.frame then
        VB.gossipFrame.gossipClosed = true
        VB.gossipFrame:Hide()
    end
    VB.gossipFrame = pending.frame
    pending.refresh()
    pending.frame:Show()
end

function VB.HideBlizzardGossipKeepingItOpen()
    local onHide = GossipFrame:GetScript("OnHide")
    GossipFrame:SetScript("OnHide", nil)
    HideUIPanel(GossipFrame)
    GossipFrame:SetScript("OnHide", onHide)
end

local function ReplaceNextGossip(frame, npc, refresh)
    local pending = { frame = frame, npc = npc, refresh = refresh }
    if GossipFrame:IsShown() and VanillaBonkUI.TalkingTo(npc) then
        VB.gossipPending = nil
        VB.HideBlizzardGossipKeepingItOpen()
        VB.TakeOverGossip(pending)
        return
    end
    VB.gossipPending = pending
end
VB.ReplaceNextGossip = ReplaceNextGossip

local function GossipWindowHidden(frame)
    if VB.gossipFrame == frame then
        VB.gossipFrame = nil
        if not frame.gossipClosed then
            CloseGossip()
        end
    end
    frame.gossipClosed = nil
end
VB.GossipWindowHidden = GossipWindowHidden

local BlizzardGossipOnEvent = GossipFrame_OnEvent
function GossipFrame_OnEvent()
    if event == "GOSSIP_SHOW" then
        local pending = VB.gossipPending
        VB.gossipPending = nil
        if pending and VanillaBonkUI.TalkingTo(pending.npc) then
            VB.TakeOverGossip(pending)
            return
        end
    elseif event == "GOSSIP_CLOSED" and VB.gossipFrame then
        VB.gossipFrame.gossipClosed = true
        VB.gossipFrame:Hide()
    end
    BlizzardGossipOnEvent()
end

local UI = VanillaBonkUI

local ARENA_WIDTH, ARENA_HEIGHT = 920, 660
local STARTER_SIZE, STARTER_STEP = 28, 34

local arena = UI.GoldWindow("VanillaBonkArena", ARENA_WIDTH, ARENA_HEIGHT)
arena:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
arena.title:SetText(L["hoa.addon.run_master"])

local content = CreateFrame("Frame", nil, arena)
content:SetAllPoints(arena)
content:SetFrameLevel(arena:GetFrameLevel() + 2)
arena.content = content

arena.hero = UI.Text(content, 12)
arena.hero:SetPoint("TOPRIGHT", arena, "TOPRIGHT", -36, -20)
arena.hero:SetJustifyH("RIGHT")

local LOADOUT_X, LOADOUT_TOP, LOADOUT_WIDTH = 22, 252, 214
local LOADOUT_GREY = { 0.51, 0.49, 0.44 }

arena.loadoutDivider = UI.Divider(content, LOADOUT_WIDTH)
arena.loadoutDivider:SetPoint("TOPLEFT", arena, "TOPLEFT", LOADOUT_X, -(LOADOUT_TOP - 14))
arena.loadoutLabel = UI.Text(content, 11)
arena.loadoutLabel:SetPoint("TOPLEFT", arena, "TOPLEFT", LOADOUT_X, -LOADOUT_TOP)
arena.loadoutLabel:SetTextColor(1, 0.82, 0)
arena.loadoutLabel:SetText(L["hoa.addon.loadout"])

arena.challengesLabel = UI.Text(content, 10)
arena.challengesLabel:SetPoint("TOPLEFT", arena, "TOPLEFT", LOADOUT_X, -(LOADOUT_TOP + 84))
arena.challengesLabel:SetTextColor(LOADOUT_GREY[1], LOADOUT_GREY[2], LOADOUT_GREY[3])
arena.challengesLabel:SetText(L["hoa.addon.dark_fortunes"])
arena.challenges = UI.Text(content, 10)
arena.challenges:SetPoint("TOPRIGHT", arena, "TOPLEFT", LOADOUT_X + LOADOUT_WIDTH, -(LOADOUT_TOP + 84))
arena.challenges:SetWidth(120)
arena.challenges:SetJustifyH("RIGHT")

arena.perksLabel = UI.Text(content, 10)
arena.perksLabel:SetTextColor(LOADOUT_GREY[1], LOADOUT_GREY[2], LOADOUT_GREY[3])
arena.perksLabel:SetText(L["hoa.addon.perks"])
arena.perks = UI.Text(content, 10)
arena.perks:SetPoint("TOPRIGHT", arena.challenges, "BOTTOMRIGHT", 0, -5)
arena.perks:SetWidth(140)
arena.perks:SetJustifyH("RIGHT")
arena.perksLabel:SetPoint("LEFT", arena, "LEFT", LOADOUT_X, 0)
arena.perksLabel:SetPoint("TOP", arena.perks, "TOP", 0, 0)

arena.pauseCheck = CreateFrame("CheckButton", "VanillaBonkArenaPause", content, "UICheckButtonTemplate")
arena.pauseCheck:SetWidth(22)
arena.pauseCheck:SetHeight(22)
arena.pauseCheck:SetPoint("LEFT", arena, "LEFT", LOADOUT_X - 4, 0)
arena.pauseCheck:SetPoint("TOP", arena.perks, "BOTTOM", 0, -6)
arena.pauseCheck.label = UI.Text(arena.pauseCheck, 10)
arena.pauseCheck.label:SetPoint("LEFT", arena.pauseCheck, "RIGHT", 2, 0)
arena.pauseCheck.label:SetTextColor(LOADOUT_GREY[1], LOADOUT_GREY[2], LOADOUT_GREY[3])
arena.pauseCheck.label:SetText(L["hoa.addon.pause_on_rewards"])
arena.pauseCheck:SetScript("OnClick", function()
    PlaySound("igMainMenuOptionCheckBoxOn")
    UI.SetOption("pauseOnChoices", this:GetChecked() and true or false)
end)
UI.Hover(arena.pauseCheck, function()
    GameTooltip:SetOwner(this, "ANCHOR_RIGHT")
    GameTooltip:SetText(L["hoa.addon.pause_on_rewards"], 1, 1, 1)
    GameTooltip:AddLine(L["hoa.addon.when_disabled_rewards_appear_at_the_bottom_of_the_screen_and"], 1, 0.82, 0, 1)
    GameTooltip:Show()
end)

VB.starters = {}
VB.pendingStarters = {}

local function ChosenStarter()
    for _, option in ipairs(VB.starters) do
        if option.chosen then
            return option
        end
    end
end

local function ShowStarterTooltip(owner, option)
    if not option then
        return
    end
    GameTooltip:SetOwner(owner, "ANCHOR_RIGHT")
    if option.unlocked then
        GameTooltip:AddLine(option.name, 1, 0.82, 0)
    else
        GameTooltip:AddLine(option.name, 0.6, 0.6, 0.6)
    end
    GameTooltip:AddLine(option.description, 1, 1, 1, 1)
    if option.chosen then
        GameTooltip:AddLine(L["hoa.addon.your_runs_start_with_this_spell"], 0.25, 1, 0.25, 1)
    elseif option.unlocked then
        GameTooltip:AddLine(L["hoa.addon.click_to_make_this_your_starter_spell"], 1, 0.82, 0, 1)
    else
        GameTooltip:AddLine(option.hint, 1, 0.3, 0.3, 1)
    end
    GameTooltip:Show()
end

local function ChooseStarter(option)
    if not option or option.chosen or not option.unlocked or VB.inRun then
        return
    end
    PlaySound("igMainMenuOptionCheckBoxOn")
    Command("starter " .. option.id)
end

local function SetStarterIcon(texture, option)
    texture:SetTexture(ICON_PATH .. (option and option.icon ~= "" and option.icon or "INV_Misc_QuestionMark"))
    SetDesaturation(texture, option and not option.unlocked)
end

local starterBox = CreateFrame("Frame", nil, content)
starterBox:SetPoint("TOPLEFT", arena, "TOPLEFT", LOADOUT_X, -(LOADOUT_TOP + 26))
starterBox:SetWidth(LOADOUT_WIDTH)
starterBox:SetHeight(48)
starterBox.label = UI.Text(starterBox, 10)
starterBox.label:SetPoint("TOPLEFT", starterBox, "TOPLEFT", 0, 0)
starterBox.label:SetTextColor(LOADOUT_GREY[1], LOADOUT_GREY[2], LOADOUT_GREY[3])
starterBox.label:SetText(L["hoa.addon.starter_spell"])
starterBox.name = UI.Text(starterBox, 11)
starterBox.name:SetJustifyH("LEFT")
starterBox.slots = {}

local function StarterSlot(index)
    local slot = starterBox.slots[index]
    if not slot then
        slot = CreateFrame("Button", nil, starterBox)
        slot:SetWidth(STARTER_SIZE)
        slot:SetHeight(STARTER_SIZE)
        slot:SetPoint("TOPLEFT", starterBox, "TOPLEFT", (index - 1) * STARTER_STEP, -16)
        slot:SetBackdrop({ edgeFile = UI.FLAT, edgeSize = 1 })
        slot.icon = slot:CreateTexture(nil, "ARTWORK")
        slot.icon:SetPoint("TOPLEFT", slot, "TOPLEFT", 1, -1)
        slot.icon:SetPoint("BOTTOMRIGHT", slot, "BOTTOMRIGHT", -1, 1)
        UI.CropIcon(slot.icon)
        slot:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square", "ADD")
        slot:SetScript("OnClick", function() ChooseStarter(this.option) end)
        UI.Hover(slot, function() ShowStarterTooltip(this, this.option) end)
        slot.glow = slot:CreateTexture(nil, "OVERLAY")
        slot.glow:SetTexture("Interface\\Buttons\\UI-ActionButton-Border")
        slot.glow:SetBlendMode("ADD")
        slot.glow:SetVertexColor(1, 0.82, 0)
        slot.glow:SetWidth(STARTER_SIZE * 1.8)
        slot.glow:SetHeight(STARTER_SIZE * 1.8)
        slot.glow:SetPoint("CENTER", slot, "CENTER", 0, 0)
        starterBox.slots[index] = slot
    end
    return slot
end

local function RefreshStarters()
    if getn(VB.starters) == 0 then
        starterBox:Hide()
        return
    end
    for _, slot in ipairs(starterBox.slots) do
        slot:Hide()
    end
    local chosen = ChosenStarter()
    local last
    for index, option in ipairs(VB.starters) do
        local slot = StarterSlot(index)
        slot.option = option
        SetStarterIcon(slot.icon, option)
        if option.chosen then
            slot.icon:SetVertexColor(1, 1, 1)
            slot:SetBackdropBorderColor(1, 0.82, 0, 1)
            slot.glow:Show()
        else
            slot.icon:SetVertexColor(0.6, 0.6, 0.6)
            slot:SetBackdropBorderColor(0, 0, 0, 1)
            slot.glow:Hide()
        end
        slot:Show()
        last = slot
    end
    starterBox.name:ClearAllPoints()
    starterBox.name:SetPoint("LEFT", last, "RIGHT", 10, 0)
    starterBox.name:SetText(chosen and chosen.name or "")
    starterBox:Show()
end

arena.button = UI.Button(content, 140, L["hoa.addon.start_run"], function()
    local tier = arena.tier
    if not tier or not tier.unlocked or VB.inRun or not VanillaBonkRunMaster.CanStart(tier) then
        return
    end
    Command("start " .. VanillaBonkRunMaster.StartArgs(tier))
    arena:Hide()
end)
arena.button:SetWidth(262)
arena.button:SetHeight(38)
arena.button:SetPoint("TOPLEFT", arena, "TOPLEFT", 560 + (ARENA_WIDTH - 22 - 560 - 262) / 2, -(ARENA_HEIGHT - 62))
arena.button:SetText("")
arena.button.label = UI.Text(arena.button, 15)
arena.button.label:SetPoint("CENTER", arena.button, "CENTER", 0, 0)
arena.button.label:SetTextColor(1, 0.82, 0)

arena:SetScript("OnShow", function()
    PlaySound("igCharacterInfoOpen")
    arena.title:SetText(UnitExists("npc") and UnitName("npc") or L["hoa.addon.run_master"])
    local _, classToken = UnitClass("player")
    local color = RAID_CLASS_COLORS and RAID_CLASS_COLORS[classToken]
    local name = UnitName("player") or ""
    if color then
        name = format("|cff%02x%02x%02x%s|r", color.r * 255, color.g * 255, color.b * 255, name)
    end
    arena.hero:SetText(name .. "|cffffffff, " .. (UI.PlayerClassName() or "") .. "|r")
end)

arena:SetScript("OnHide", function()
    PlaySound("igCharacterInfoClose")
    GossipWindowHidden(arena)
end)

local ShowArenaDetail

ShowArenaDetail = function(tier)
    arena.tier = tier
    RefreshStarters()
    if GetNumPartyMembers() > 0 then
        arena.pauseCheck:Hide()
    else
        arena.pauseCheck:SetChecked(UI.Option("pauseOnChoices", true))
        arena.pauseCheck:Show()
    end
    VanillaBonkRunMaster.Show(tier)
    if not tier.unlocked then
        arena.button.label:SetText(L["hoa.addon.locked"])
        arena.button:Disable()
    elseif not VanillaBonkRunMaster.CanStart(tier) then
        arena.button.label:SetText(L["hoa.addon.start_run"])
        arena.button:Disable()
    else
        arena.button.label:SetText(L["hoa.addon.start_run"])
        arena.button:Enable()
    end
end

local RefreshArena

RefreshArena = function()
    local selected
    for _, tier in ipairs(VB.tiers) do
        if tier.id == VB.arenaSelected then
            selected = tier
        end
    end
    if not selected then
        for _, tier in ipairs(VB.tiers) do
            if tier.unlocked or not selected then
                selected = tier
            end
        end
        VB.arenaSelected = selected and selected.id
    end

    VanillaBonkRunMaster.SetTiers(VB.tiers, VB.arenaSelected, function(tier)
        VB.arenaSelected = tier.id
        RefreshArena()
    end)
    if selected then
        ShowArenaDetail(selected)
    end

    local info = VB.arenaInfo or {}
    if info.challenges and info.challenges ~= "" then
        local lines = ""
        for _, name in ipairs(UI.Split(info.challenges, ",")) do
            local trimmed = gsub(name, "^%s+", "")
            if trimmed ~= "" then
                lines = lines .. (lines ~= "" and ", " or "") .. trimmed
            end
        end
        arena.challenges:SetText("|cffffffff" .. lines .. "|r |cffffe873" .. L("hoa.addon.1_gold", info.goldBonus or 0) .. "|r")
    else
        arena.challenges:SetText(L["hoa.addon.cff9d9d9dnone_r"])
    end
    if info.perks and info.perks ~= "" then
        arena.perks:SetText("|cffffffff" .. gsub(info.perks, ", ", "\n") .. "|r")
    else
        arena.perks:SetText(L["hoa.addon.cff9d9d9dnone_yet_r"])
    end
end

StaticPopupDialogs["VANILLABONK_LEAVE_RUN"] = {
    text = L["hoa.addon.end_this_run_it_counts_as_a_defeat_you_keep_the_gold_and_dar"],
    button1 = YES,
    button2 = NO,
    OnAccept = function()
        Command("stop")
    end,
    timeout = 0,
    whileDead = 1,
}

SLASH_VANILLABONK1 = "/bonk"
SlashCmdList["VANILLABONK"] = function(message)
    if message == "stop" then
        Command("stop")
    elseif VB.inRun then
        StaticPopup_Show("VANILLABONK_LEAVE_RUN")
    elseif arena:IsShown() then
        arena:Hide()
    else
        VB.arenaRequested = true
        Command("hello " .. UI.Language())
    end
end

local handlers = {}
VB.handlers = handlers

handlers["kwd"] = function(f)
    local id = tonumber(f[2])
    if not id then
        return
    end
    VB.keywords[id] = { name = f[3] or "", icon = f[4] or "", description = f[5] or "" }
    VB.keywordTerms = nil
end

handlers["npcname"] = function(f)
    UI.npcNames[f[2]] = f[3]
    UI.npcNames[f[3]] = f[2]
end

handlers["arena"] = function(f)
    VB.arenaInfo = { goldBonus = tonumber(f[4]) or 0, challenges = f[5] or "", perks = f[6] or "" }
    VB.arenaNpc = f[2] == "1" and f[3] or nil
end

handlers["tier"] = function(f)
    local maps = {}
    for _, item in ipairs(Split(f[10] or "", ",")) do
        if item ~= "" then
            local parts = Split(item, ":")
            tinsert(maps, { icon = parts[1] or "", name = parts[2] or parts[1], type = parts[3], reward = tonumber(parts[4] or ""), key = parts[5] or "" })
        end
    end
    local dungeons = {}
    for _, item in ipairs(Split(f[13] or "", ",")) do
        local parts = Split(item, ":")
        if parts[1] and parts[1] ~= "" then
            tinsert(dungeons, { key = parts[1], icon = parts[2] or "", name = parts[3] or parts[1], open = parts[4] == "1" })
        end
    end
    tinsert(VB.pendingTiers, { id = f[2], key = f[3], name = f[4], unlocked = f[5] == "1", hint = f[6] or "", best = tonumber(f[7]) or 0,
        description = f[8] or "", art = f[9] or "", maps = maps, levels = tonumber(f[11] or "") or 0, open = tonumber(f[12] or "") or 0,
        dungeons = dungeons, details = f[14] or "", firstLevel = tonumber(f[15] or "") })
end

handlers["tiermap"] = function(f)
    local tier = VB.pendingTiers[table.getn(VB.pendingTiers)]
    if not tier or tier.id ~= f[2] or not f[3] or f[3] == "" then
        return
    end
    local parts = Split(f[3], ":")
    tinsert(tier.maps, { icon = parts[1] or "", name = parts[2] or parts[1], type = parts[3], reward = tonumber(parts[4] or ""), key = parts[5] or "" })
end

handlers["starter"] = function(f)
    tinsert(VB.pendingStarters, { id = f[2], icon = f[3] or "", name = f[4] or "", unlocked = f[5] == "1", chosen = f[6] == "1",
        hint = f[7] or "", description = f[8] or "" })
end

handlers["starterend"] = function()
    VB.starters = VB.pendingStarters
    VB.pendingStarters = {}
    if arena:IsShown() then
        RefreshStarters()
    end
end

handlers["tierend"] = function()
    VB.tiers = VB.pendingTiers
    VB.pendingTiers = {}
    if VB.arenaNpc then
        ReplaceNextGossip(arena, VB.arenaNpc, RefreshArena)
        VB.arenaNpc = nil
    elseif arena:IsShown() then
        RefreshArena()
    elseif VB.arenaRequested then
        VB.arenaRequested = nil
        RefreshArena()
        arena:Show()
    end
end

local combatLogQuiet = false

local function IsCombatLogGroup(group)
    return strsub(group, 1, 7) == "COMBAT_" or strsub(group, 1, 6) == "SPELL_"
end

local function SetCombatLogQuiet(quiet)
    if quiet == combatLogQuiet or not ChatTypeGroup then
        return
    end
    combatLogQuiet = quiet
    for index = 1, NUM_CHAT_WINDOWS do
        local chat = getglobal("ChatFrame" .. index)
        if chat then
            if quiet then
                for group, chatEvents in pairs(ChatTypeGroup) do
                    if IsCombatLogGroup(group) then
                        for _, chatEvent in ipairs(chatEvents) do
                            chat:UnregisterEvent(chatEvent)
                        end
                    end
                end
            elseif chat.messageTypeList then
                for _, group in ipairs(chat.messageTypeList) do
                    if IsCombatLogGroup(group) and ChatTypeGroup[group] then
                        for _, chatEvent in ipairs(ChatTypeGroup[group]) do
                            chat:RegisterEvent(chatEvent)
                        end
                    end
                end
            end
        end
    end
end

UI.ListenHoa({
    HOA_RUN_START = function(start)
        VB.inRun = true
        SetCombatLogQuiet(true)
        VB.duration = tonumber(start.duration_s) or 0
        results:Hide()
        arena:Hide()
        if VB.shop then
            VB.shop:Hide()
        end
    end,
    HOA_RUN_STATE = function()
        VB.inRun = true
        SetCombatLogQuiet(true)
    end,
})

handlers["offer"] = function(f)
    VB.offer = {}
    VB.offerLevel = f[2]
    VB.offerSource = f[4]
    VB.rerolls = tonumber(f[5]) or 0
    VB.banishes = tonumber(f[6]) or 0
    VB.skips = tonumber(f[7]) or 0
end

handlers["opt"] = function(f)
    local description = gsub(f[8] or "", "|n", "\n")
    if f[3] == "c" then
        description = gsub(description, "%s*You hold %d+%.?$", "")
    end
    VB.offer[tonumber(f[2])] = {
        kind = f[3],
        newLevel = tonumber(f[4]) or 1,
        maxLevel = tonumber(f[5]) or 0,
        name = f[6],
        icon = f[7],
        description = description,
        rarity = tonumber(f[9] or ""),
        locked = f[10] == "1",
        damageBefore = f[11] or "",
        damageAfter = f[12] or "",
        damageLabel = f[13] or "",
        banishable = f[14] ~= "0",
        stats = {},
    }
end

handlers["ostat"] = function(f)
    local option = VB.offer[tonumber(f[2])]
    if option then
        tinsert(option.stats, { label = f[3] or "", before = f[4] or "", after = f[5] or "" })
    end
end

handlers["offerend"] = function()
    ShowOffer(VB.offerLevel)
end

handlers["picked"] = function()
    VB.offer = {}
    CloseOffer()
end

handlers["leyoffer"] = function()
    VB.offer = {}
    VB.offerLevel = nil
    VB.offerSource = "ley"
    VB.rerolls, VB.banishes, VB.skips = 0, 0, 0
end

handlers["leyopt"] = function(f)
    local index = tonumber(f[2] or "")
    if not index then
        return
    end
    local card = f[7] == "c"
    VB.offer[index] = {
        kind = card and "c" or "ley",
        newLevel = card and tonumber(f[8] or "") or 1,
        maxLevel = card and tonumber(f[9] or "") or 0,
        name = f[3] or "",
        icon = f[4] or "",
        description = card and gsub(f[5] or "", "%s*You hold %d+%.?$", "") or (f[5] or ""),
        rarity = tonumber(f[6] or ""),
    }
end

handlers["leyofferend"] = function()
    ShowOffer(nil)
end

handlers["leyofferclose"] = function()
    VB.offer = {}
    CloseOffer()
end

UI.ListenHoa({
    HOA_CODEX = function(entry)
        if entry.kind ~= "kwd" then
            return
        end
        local f = { false, entry.kind }
        for _, part in ipairs(Split(entry.line or "", "~")) do
            tinsert(f, part)
        end
        handlers[entry.kind](f)
    end,
    HOA_STATS = function(stats)
        handlers["stats"]({ false, stats.in_run and "1" or "0", stats.caps, stats.after_caps })
    end,
    HOA_GEAR = function(gear)
        handlers["gear"]({ false, tostring(gear.id), gear.stats })
    end,
    HOA_GEAR_END = function()
        handlers["gearend"]()
    end,
    HOA_ARENA = function(arena)
        handlers["arena"]({
            false, arena.npc_present and "1" or "0", arena.npc, arena.gold_bonus, arena.challenges, arena.perks,
        })
    end,
    HOA_TIER = function(tier)
        handlers["tier"]({
            false, tostring(tier.id), tier.key, tier.name, tier.unlocked and "1" or "0", tier.hint, tier.best,
            tier.description, tier.art, tier.maps, tier.levels, tier.open_level, tier.dungeons, tier.details,
            tier.first_level,
        })
    end,
    HOA_TIER_END = function()
        handlers["tierend"]()
    end,
    HOA_SHOP_OPEN = function(shop)
        local kind = tostring(shop.kind)
        if kind == FORTUNE_SHOP then
            handlers["shop"]({
                false, kind, shop.open and "1" or "0", shop.npc, shop.currency, shop.balance, shop.gates,
                shop.coop_guest and "1" or "0",
            })
        else
            handlers["shop"]({
                false, kind, shop.open and "1" or "0", shop.npc, shop.currency, shop.balance, shop.level, shop.xp,
                shop.xp_next, shop.max_level, shop.earned, shop.from_quests, shop.class_name, shop.points_per_row,
                shop.inspect and "1" or "0",
            })
        end
    end,
    HOA_SHOP_TREE = function(tree)
        handlers["tree"]({ false, tostring(tree.id), tree.name, tree.background, tree.spent })
    end,
    HOA_MASTERY_TREE = function(tree)
        handlers["tree"]({ false, tostring(tree.id), tree.name, tree.background, tree.layout, tree.gates, tree.spent })
    end,
    HOA_SHOP_NODE = function(node)
        handlers["node"]({
            false, tostring(node.tree), tostring(node.id), node.row, node.column, node.icon, node.rank, node.max_rank,
            node.cost, tostring(node.required_id), node.required_rank, node.toggle and "1" or "0",
            node.enabled and "1" or "0", node.name, node.description, node.locked and "1" or "0", node.quest,
            node.value_per_rank, node.refund, node.quest_description, node.rank_lock,
        })
    end,
    HOA_MASTERY_NODE = function(node)
        handlers["node"]({
            false, tostring(node.tree), tostring(node.id), node.row, node.column, node.icon, node.rank, node.max_rank,
            node.cost, tostring(node.required_id), node.required_rank, "0", "0", node.name, node.description, "0", "",
            node.value_per_rank, node.refund, node.shape, node.position, node.parents, node.excludes,
        })
    end,
    HOA_MASTERY_PRESETS = function(presets)
        handlers["presets"]({ false, presets.active, presets.points_1, presets.points_2, presets.points_3 })
    end,
    HOA_MASTERY_PRESET_RANKS = function(ranks)
        handlers["presetranks"]({ false, ranks.preset, ranks.ranks })
    end,
    HOA_SHOP_END = function()
        handlers["shopend"]()
    end,
    HOA_SHOP_CLOSE = function()
        handlers["shopclose"]()
    end,
    HOA_STARTER = function(starter)
        handlers["starter"]({
            false, tostring(starter.id), starter.icon, starter.name, starter.unlocked and "1" or "0",
            starter.chosen and "1" or "0", starter.hint, starter.description,
        })
    end,
    HOA_STARTER_END = function()
        handlers["starterend"]()
    end,
    HOA_NPC_NAME = function(name)
        handlers["npcname"]({ false, name.name, name.npc_name })
    end,
    HOA_MESSAGE = function(message)
        handlers["msg"]({ false, message.text })
    end,
    HOA_FIND = function(find)
        handlers["find"]({ false, find.text })
    end,
    HOA_SHARD = function()
        handlers["shard"]()
    end,
    HOA_VALOR = function()
        handlers["valor"]()
    end,
    HOA_OFFER_OPEN = function(offer)
        handlers["offer"]({ false, offer.level, offer.count, offer.source, offer.rerolls, offer.banishes, offer.skips })
    end,
    HOA_OFFER_OPTION = function(option)
        handlers["opt"]({
            false, tostring(option.index), option.kind, option.new_level, option.max_level, option.name, option.icon,
            option.description, option.rarity, option.locked and "1" or "0", option.damage_before, option.damage_after,
            option.damage_label, option.banishable and "1" or "0",
        })
    end,
    HOA_OFFER_STAT = function(stat)
        handlers["ostat"]({ false, tostring(stat.index), stat.label, stat.before, stat.after })
    end,
    HOA_OFFER_END = function()
        handlers["offerend"]()
    end,
    HOA_OFFER_CLOSED = function()
        handlers["picked"]()
    end,
    HOA_LEY_OPEN = function()
        handlers["leyoffer"]()
    end,
    HOA_LEY_OPTION = function(option)
        handlers["leyopt"]({
            false, tostring(option.index), option.name, option.icon, option.description, option.rarity, option.kind,
            option.new_level, option.max_level,
        })
    end,
    HOA_LEY_END = function()
        handlers["leyofferend"]()
    end,
    HOA_LEY_CLOSED = function()
        handlers["leyofferclose"]()
    end,
})

UI.ListenHoa({
    HOA_COOP_NO_PAUSE = function(state)
        VB.sideOffers = state.no_pause and true or false
    end,
    HOA_RUN_END = function(ending)
        VB.inRun = false
        VB.sideOffers = false
        if VanillaBonkUI.InspectShown() and VB.shop then
            VB.shop:Hide()
        end
        SetCombatLogQuiet(false)
        VB.offer = {}
        offerFrame:Hide()
        if ending.victory then
            results.title:SetText(L["hoa.addon.cffffd100victory_r"])
            PlaySound("QUESTCOMPLETED")
        elseif ending.went_home then
            results.title:SetText(L["hoa.addon.cff20ff20run_complete_r"])
            PlaySound("QUESTCOMPLETED")
        else
            results.title:SetText(L["hoa.addon.cffff3030defeated_r"])
        end
        results.body:SetText(L("hoa.addon.reached_stage_1_in_2", ending.stage or "1", FormatTime(ending.seconds)) .. "\n" ..
            L("hoa.addon.kills_1_level_2", ending.kills, ending.player_level) .. "\n" ..
            L("hoa.addon.gold_earned_1", FormatGold(ending.gold)) .. "\n" ..
            L("hoa.addon.darkmoon_tickets_cffc080ff_1_r", ending.shards or "0") .. "\n\n" ..
            L["hoa.addon.cffaaaaaareturning_to_the_inn_r"])
        results:Show()
    end,
})

handlers["msg"] = function(f)
    Notice(f[2])
end

handlers["find"] = function(f)
    UIErrorsFrame:AddMessage(f[2], 0.3, 0.8, 1.0, 1.0, 10)
    PlaySound("igQuestListComplete")
end

handlers["shard"] = function()
    PlaySound("LOOTWINDOWCOINSOUND")
end

handlers["valor"] = function()
    PlaySound("LOOTWINDOWCOINSOUND")
end

local shieldBar = CreateFrame("StatusBar", "VanillaBonkShieldBar", PlayerFrame)
shieldBar:SetAllPoints(PlayerFrameHealthBar)
shieldBar:SetFrameLevel(PlayerFrameHealthBar:GetFrameLevel() + 1)
VanillaBonkUI.DressShield(shieldBar)
shieldBar:Hide()
VB.shield = 0

local function RefreshShield()
    local maxHealth = UnitHealthMax("player")
    if VB.shield <= 0 or not maxHealth or maxHealth <= 0 then
        shieldBar:Hide()
        return
    end
    shieldBar:SetValue(min(1, VB.shield / maxHealth))
    shieldBar:Show()
end

UI.ListenHoa({
    HOA_AURA_VALUE = function(spellId, value)
        if tonumber(spellId) == HOA_AURA_IDS.shield then
            VB.shield = tonumber(value) or 0
            RefreshShield()
        end
    end,
})

UI.Module("shieldEvents"):Listen({
    UNIT_MAXHEALTH = function(unit)
        if unit == "player" then
            RefreshShield()
        end
    end,
})

UI.Module("enterWorld"):OnEnterWorld(function()
    VB.lastMoney = GetMoney()
    if not VB.helloSent then
        VB.helloSent = true
        Command("hello " .. UI.Language())
    end
end)
UI.Module("enterWorld"):OnMoney(function()
    VB.PlayPurchaseSound()
    if VB.shop and VB.shop:IsShown() then
        VB.RefreshShop()
    end
end)

function UI.NavPrompt(box, primary, second)
    box.navButtons = { primary, second }
    UI.navPrompts = UI.navPrompts or {}
    tinsert(UI.navPrompts, box)
end
