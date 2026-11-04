local L = BonkGlueL;

BONK_CLASSES = {
	{ token = "WARRIOR", id = 1, name = "Warrior", display = L["hoa.ui.glue.warrior"], races = { "HUMAN", "DWARF", "NIGHTELF", "GNOME", "ORC", "SCOURGE", "TAUREN", "TROLL" } },
	{ token = "PALADIN", id = 2, name = "Paladin", display = L["hoa.ui.glue.paladin"], races = { "HUMAN", "DWARF" } },
	{ token = "HUNTER",  id = 3, name = "Hunter", display = L["hoa.ui.glue.hunter"],  races = { "DWARF", "NIGHTELF", "ORC", "TAUREN", "TROLL" } },
	{ token = "ROGUE",   id = 4, name = "Rogue", display = L["hoa.ui.glue.rogue"],   races = { "HUMAN", "DWARF", "NIGHTELF", "GNOME", "ORC", "SCOURGE", "TROLL" } },
	{ token = "PRIEST",  id = 5, name = "Priest", display = L["hoa.ui.glue.priest"],  races = { "HUMAN", "DWARF", "NIGHTELF", "SCOURGE", "TROLL" } },
	{ token = "SHAMAN",  id = 7, name = "Shaman", display = L["hoa.ui.glue.shaman"],  races = { "ORC", "TAUREN", "TROLL" } },
	{ token = "MAGE",    id = 8, name = "Mage", display = L["hoa.ui.glue.mage"],    races = { "HUMAN", "GNOME", "SCOURGE", "TROLL" } },
	{ token = "WARLOCK", id = 9, name = "Warlock", display = L["hoa.ui.glue.warlock"], races = { "HUMAN", "GNOME", "ORC", "SCOURGE" } },
	{ token = "DRUID",   id = 11, name = "Druid", display = L["hoa.ui.glue.druid"],   races = { "NIGHTELF", "TAUREN" } },
};

BONK_RACE_NAMES = {
	HUMAN = "Human", DWARF = "Dwarf", NIGHTELF = "Night Elf", GNOME = "Gnome",
	ORC = "Orc", SCOURGE = "Undead", TAUREN = "Tauren", TROLL = "Troll",
};

BONK_RACE_DISPLAY_NAMES = {
	HUMAN = L["hoa.ui.glue.human"], DWARF = L["hoa.ui.glue.dwarf"], NIGHTELF = L["hoa.ui.glue.night_elf"], GNOME = L["hoa.ui.glue.gnome"],
	ORC = L["hoa.ui.glue.orc"], SCOURGE = L["hoa.ui.glue.undead"], TAUREN = L["hoa.ui.glue.tauren"], TROLL = L["hoa.ui.glue.troll"],
};

BONK_CLASS_COLORS = {
	WARRIOR = { 0.78, 0.61, 0.43 }, PALADIN = { 0.96, 0.55, 0.73 }, HUNTER = { 0.67, 0.83, 0.45 },
	ROGUE = { 1.0, 0.96, 0.41 }, PRIEST = { 1.0, 1.0, 1.0 }, SHAMAN = { 0.0, 0.44, 0.87 },
	MAGE = { 0.41, 0.8, 0.94 }, WARLOCK = { 0.58, 0.51, 0.79 }, DRUID = { 1.0, 0.49, 0.04 },
};

BONK_CLASS_TOKENS = {};
BONK_CLASS_BY_ID = {};
for _, class in BONK_CLASSES do
	BONK_CLASS_BY_ID[class.id] = class.token;
	BONK_CLASS_TOKENS[class.name] = class.token;
	BONK_CLASS_TOKENS[class.token] = class.token;
end

BONK_IRONMAN_TIP = L["hoa.ui.glue.this_character_does_not_share_gold_or_unlocks_with_other_cha"];

local NUM_STAT_ROWS = 9;
local NUM_SPELL_ROWS = 7;
local NUM_SPECS = 3;
local NUM_CLASS_RACES = 8;
local ROW_STEP = 58;
local IRONMAN_NAME = "Ironmanmode";
local RACES_PER_ROW = 4;
local RACE_COLUMN_STEP = 70;
local RACE_ROW_STEP = 64;
local STARTER_TEXT_WIDTH = 176;
local STARTER_NAME_HEIGHT = 14;
local STARTER_LINE_HEIGHT = 12;

local XML_TEXTS = {
	BonkLoginTitle = L["hoa.ui.glue.hordes_of_azeroth_2"],
	BonkLoginConnectButton = L["hoa.ui.glue.connect"],
	BonkLoginQuitButton = L["hoa.ui.glue.quit"],
	BonkHeroTitle = L["hoa.ui.glue.hordes_of_azeroth"],
	BonkHeroSubtitle = L["hoa.ui.glue.choose_your_character"],
	BonkRaceNote = L["hoa.ui.glue.cosmetic_only_no_racial_bonuses"],
	BonkHeroRandomizeButton = L["hoa.ui.glue.randomize"],
	BonkHeroIronmanText = L["hoa.ui.glue.ironman_mode"],
	BonkClassRacesLabel = L["hoa.ui.glue.races"],
	BonkClassStarterLabel = L["hoa.ui.glue.starts_with"],
	BonkSpecNote = L["hoa.ui.glue.preview_only_you_choose_your_specialization_later"],
	BonkHeroRetireButton = L["hoa.ui.glue.delete_character"],
	BonkHeroNameLabel = L["hoa.ui.glue.name"],
	BonkHeroQuitButton = L["hoa.ui.glue.quit"],
	BonkHeroWipeButton = L["hoa.ui.glue.wipe_account"],
	BonkHeroBackButton = L["hoa.ui.glue.back"],
};

local CUSTOMIZE_LABELS = { L["hoa.ui.glue.skin_color"], L["hoa.ui.glue.face"], L["hoa.ui.glue.hair_style"], L["hoa.ui.glue.hair_color"], L["hoa.ui.glue.facial_hair"] };

local HAIR_STYLE_LABELS = { NORMAL = L["hoa.ui.glue.hair_style"], HORNS = L["hoa.ui.glue.horn_style"] };

local HAIR_COLOR_LABELS = { NORMAL = L["hoa.ui.glue.hair_color"], HORNS = L["hoa.ui.glue.horn_color"] };

local FACIAL_HAIR_LABELS = {
	EARRINGS = L["hoa.ui.glue.earrings"], FEATURES = L["hoa.ui.glue.facial_feature_features"], HAIR = L["hoa.ui.glue.hair"], MARKINGS = L["hoa.ui.glue.markings"],
	NORMAL = L["hoa.ui.glue.facial_hair"], PIERCINGS = L["hoa.ui.glue.piercings"], TUSKS = L["hoa.ui.glue.tusks"],
};

local function Flag(condition)
	if ( condition ) then
		return 1;
	end
	return nil;
end

Bonk = {
	classIndex = 1,
	raceIndex = 1,
	sex = 1,
	specIndex = 1,
	customizing = nil,
	heroes = {},
	listLoaded = false,
	reuseList = false,
	creating = nil,
	wiping = nil,
	appliedRace = nil,
	classNamesLearned = false,
	createdClasses = {},
	unknownHero = nil,
	screen = nil,
	refreshing = false,
	sceneDirty = false,
	sceneDelay = 0,
	startPicked = false,
	loginTried = false,
	reachedServer = false,
};

function BonkLogin_Connect()
	if ( HOA_LOGIN_ACCOUNT ) then
		BONK_ACCOUNT = HOA_LOGIN_ACCOUNT;
		BONK_PASSWORD = HOA_LOGIN_PASSWORD;
	end
	local gate, coopAccount, coopPassword;
	if ( HoaCoop_GetGate ) then
		gate, coopAccount, coopPassword = HoaCoop_GetGate();
	end
	if ( gate ) then
		BonkLoginStatus:SetText(L["hoa.ui.glue.connecting_to_host"]);
		DefaultServerLogin(coopAccount, coopPassword);
		return;
	end
	BonkLoginStatus:SetText(L["hoa.ui.glue.connecting"]);
	DefaultServerLogin(BONK_ACCOUNT, BONK_PASSWORD);
end

local OriginalAccountLoginOnShow = AccountLogin_OnShow;
function AccountLogin_OnShow()
	OriginalAccountLoginOnShow();
	BonkHeroFrame:Hide();

	Bonk.listLoaded = false;
	Bonk.reuseList = false;
	Bonk.startPicked = false;
	Bonk.classIndex = 1;
	Bonk.raceIndex = 1;
	Bonk.specIndex = 1;
	Bonk.customizing = nil;
	Bonk.creating = nil;
	Bonk.wiping = nil;
	Bonk.heroes = {};

	if ( not BONK_ACCOUNT or not EULAAccepted() or not TOSAccepted() ) then
		BonkLoginFrame:Hide();
		return;
	end

	BonkLogin_Begin();
end

function BonkLogin_Begin()
	AccountLoginUI:Hide();
	AccountLoginAccountEdit:ClearFocus();
	AccountLoginPasswordEdit:ClearFocus();
	BonkLoginFrame:Show();
	BonkLoginStatus:SetText("");

	if ( not Bonk.loginTried ) then
		Bonk.loginTried = true;
		BonkLogin_Connect();
	end
end

local OriginalShowUserAgreements = AccountLogin_ShowUserAgreements;
function AccountLogin_ShowUserAgreements()
	OriginalShowUserAgreements();
	if ( BONK_ACCOUNT and EULAAccepted() and TOSAccepted() and not TOSFrame:IsVisible() and AccountLogin:IsVisible() ) then
		BonkLogin_Begin();
	end
end

local OriginalAccountLoginOnKeyDown = AccountLogin_OnKeyDown;
function AccountLogin_OnKeyDown()
	if ( not BonkLoginFrame:IsVisible() ) then
		OriginalAccountLoginOnKeyDown();
	elseif ( arg1 == "ENTER" ) then
		BonkLogin_Connect();
	elseif ( arg1 == "ESCAPE" ) then
		AccountLogin_Exit();
	elseif ( arg1 == "PRINTSCREEN" ) then
		Screenshot();
	end
end

local OriginalSetGlueScreen = SetGlueScreen;
function SetGlueScreen(name)
	Bonk.screen = name;
	if ( name ~= "charselect" and name ~= "charcreate" ) then
		BonkHeroFrame:Hide();
	end
	OriginalSetGlueScreen(name);
end

local OriginalCharacterSelectOnShow = CharacterSelect_OnShow;
function CharacterSelect_OnShow()
	Bonk.reachedServer = true;
	local requestList = GetCharacterListUpdate;
	if ( Bonk.reuseList and Bonk.listLoaded and not Bonk.creating ) then
		GetCharacterListUpdate = UpdateCharacterList;
	end
	Bonk.reuseList = false;
	OriginalCharacterSelectOnShow();
	GetCharacterListUpdate = requestList;

	CharacterSelectUI:Hide();
	BonkHeroFrame:Show();

	if ( not Bonk.listLoaded ) then
		Bonk.sceneDelay = 1.0;
	end
	BonkHero_Refresh();
end

local BONK_REALM_CATEGORY = 1;

local OriginalGlueParentOnEvent = GlueParent_OnEvent;
function GlueParent_OnEvent(event)
	if ( event == "GET_PREFERRED_REALM_INFO" and BONK_ACCOUNT ) then
		SetPreferredInfo(BONK_REALM_CATEGORY, nil, nil);
		return;
	end
	OriginalGlueParentOnEvent(event);
end

local OriginalCharacterSelectOnEvent = CharacterSelect_OnEvent;
function CharacterSelect_OnEvent()
	if ( event == "SUGGEST_REALM" and BONK_ACCOUNT ) then
		SetGlueScreen("charselect");
		ChangeRealm(arg1, arg2);
		return;
	end
	OriginalCharacterSelectOnEvent();
	if ( event == "CHARACTER_LIST_UPDATE" ) then
		BonkHero_OnCharacterList();
	elseif ( event == "UPDATE_SELECTED_CHARACTER" and Bonk.listLoaded ) then
		local hero = Bonk.heroes[BONK_CLASSES[Bonk.classIndex].token];
		if ( hero and arg1 ~= hero.index ) then
			Bonk.sceneDirty = true;
		end
	end
end

function CharacterSelect_OnKeyDown()
	BonkHero_OnKeyDown();
end

local OriginalCharacterCreateOnShow = CharacterCreate_OnShow;
function CharacterCreate_OnShow()
	OriginalCharacterCreateOnShow();
	CharacterCreateFrame:Hide();
	BonkHeroFrame:Show();
	if ( Bonk.unknownHero and BonkHero_LearnClassNames() ) then
		BonkHero_OnCharacterList();
	end
	Bonk.appliedRace = nil;
	BonkHero_ApplyNewHero();
end

function CharacterCreate_OnKeyDown()
	BonkHero_OnKeyDown();
end

local OriginalGlueDialogOnEvent = GlueDialog_OnEvent;
function GlueDialog_OnEvent()
	local text = arg1;
	if ( event == "OPEN_STATUS_DIALOG" ) then
		text = arg2;
	end
	local success = text == CHAR_DELETE_SUCCESS or text == CHAR_CREATE_SUCCESS;
	local failed = not success and ((event == "OPEN_STATUS_DIALOG" and arg1 == "OKAY") or (event == "UPDATE_STATUS_DIALOG" and arg2));
	if ( Bonk.creating and failed ) then
		Bonk.creating = nil;
		BonkHero_SetStatus("");
	end
	local wipeRefused = Bonk.wiping and failed and Bonk.wiping.step == "create";
	if ( Bonk.wiping and failed ) then
		BonkHero_StopWipe(L["hoa.ui.glue.the_account_was_not_wiped"]);
	end
	OriginalGlueDialogOnEvent();

	local shown = GlueDialogText:GetText();
	local noServer = shown == RESPONSE_FAILED_TO_CONNECT or shown == LOGIN_FAILED or shown == LOGIN_SERVER_DOWN or shown == REALM_LIST_FAILED
		or shown == RESPONSE_DISCONNECTED or shown == DISCONNECTED;
	local accountGone = shown and (shown == LOGIN_UNKNOWN_ACCOUNT or shown == LOGIN_INCORRECT_PASSWORD or shown == LOGIN_NO_GAME_ACCOUNT);
	if ( accountGone and BonkCoop_IsJoined() and not BonkCoop.leaving ) then
		GlueDialog:Hide();
		BonkCoop_RefusedAtLogin(L["hoa.ui.glue.your_spot_in_the_host_s_game_is_no_longer_available_returnin"]);
	elseif ( noServer and BonkCoop_IsJoined() and not BonkCoop.leaving ) then
		BonkCoop_LostHost();
	elseif ( noServer and not Bonk.reachedServer ) then
		GlueDialogText:SetText(L["hoa.ui.glue.the_hordes_of_azeroth_server_isn_t_running_close_the_game_an"]);
		GlueDialogBackground:SetHeight(32 + GlueDialogText:GetHeight() + 8 + GlueDialogButton1:GetHeight() + 16);
		BonkLoginStatus:SetText("");
	elseif ( noServer ) then
		GlueDialogText:SetText(L["hoa.ui.glue.the_hordes_of_azeroth_server_stopped_restart_the_game_with_h"]);
		GlueDialogBackground:SetHeight(32 + GlueDialogText:GetHeight() + 8 + GlueDialogButton1:GetHeight() + 16);
		BonkLoginStatus:SetText("");
	elseif ( BonkCoop_IsJoined() and BonkCoop_RefusalNote(shown) ) then
		GlueDialog:Hide();
		BonkCoop_RefusedAtLogin(BonkCoop_RefusalNote(shown));
	elseif ( shown == CHAR_LOGIN_LOCKED_FOR_TRANSFER ) then
		GlueDialogText:SetText(L["hoa.ui.glue.this_character_is_in_a_co_op_party_leave_the_party_first"]);
		GlueDialogBackground:SetHeight(32 + GlueDialogText:GetHeight() + 8 + GlueDialogButton1:GetHeight() + 16);
	elseif ( wipeRefused ) then
		GlueDialogText:SetText(L["hoa.ui.glue.the_account_was_not_wiped_because_a_character_couldn_t_be_de"]);
		GlueDialogBackground:SetHeight(32 + GlueDialogText:GetHeight() + 8 + GlueDialogButton1:GetHeight() + 16);
	elseif ( Bonk.wiping and success and event == "UPDATE_STATUS_DIALOG" and arg2 ) then
		GlueDialog:Hide();
	end
end

local OriginalGlueDialogOnClick = GlueDialog_OnClick;
function GlueDialog_OnClick(index)
	local which = GlueDialog.which;
	OriginalGlueDialogOnClick(index);
	if ( Bonk.creating ) then
		Bonk.creating = nil;
		BonkHero_SetStatus("");
	end
	if ( Bonk.wiping and which ~= "BONK_WIPE" ) then
		BonkHero_StopWipe(L["hoa.ui.glue.wipe_stopped_some_characters_may_already_be_gone"]);
	end
end

GlueDialogTypes["BONK_QUIT"] = {
	text = L["hoa.ui.glue.quit_hordes_of_azeroth"],
	button1 = L["hoa.ui.glue.yes"],
	button2 = L["hoa.ui.glue.no"],
	OnAccept = function()
		QuitGame();
	end,
	OnCancel = function()
	end,
};

GlueDialogTypes["BONK_RETIRE"] = {
	text = "",
	button1 = L["hoa.ui.glue.yes"],
	button2 = L["hoa.ui.glue.no"],
	showAlert = 1,
	OnAccept = function()
		DeleteCharacter(GlueDialog.data);
	end,
	OnCancel = function()
	end,
};

GlueDialogTypes["BONK_WIPE"] = {
	text = L["hoa.ui.glue.are_you_sure_this_deletes_all_your_characters_and_all_accoun"],
	button1 = L["hoa.ui.glue.yes"],
	button2 = L["hoa.ui.glue.no"],
	showAlert = 1,
	OnAccept = function()
		BonkHero_StartWipe();
	end,
	OnCancel = function()
	end,
};

local function FormatGold(copper)
	copper = copper or 0;
	local gold = floor(copper / 10000);
	local silver = floor(mod(copper, 10000) / 100);
	local text = format("|cffeda55f%s|r", L("hoa.ui.glue.copper_coin_1_c", format("%d", mod(copper, 100))));
	if ( gold > 0 or silver > 0 ) then
		text = format("|cffc7c7cf%s|r ", L("hoa.ui.glue.silver_coin_1_s", format("%d", silver)))..text;
	end
	if ( gold > 0 ) then
		text = format("|cffffd700%s|r ", L("hoa.ui.glue.gold_coin_1_g", format("%d", gold)))..text;
	end
	return text;
end

local function FormatTime(seconds)
	seconds = seconds or 0;
	local hours = floor(seconds / 3600);
	local minutes = floor(mod(seconds, 3600) / 60);
	if ( hours > 0 ) then
		return format("%d:%02d:%02d", hours, minutes, mod(seconds, 60));
	end
	return format("%d:%02d", minutes, mod(seconds, 60));
end

local function CurrentClass()
	return BONK_CLASSES[Bonk.classIndex];
end

local function CurrentHero()
	return Bonk.heroes[CurrentClass().token];
end

local function NewHeroRace()
	return CurrentClass().races[Bonk.raceIndex];
end

local function HeroStats(hero)
	if ( BONK_STATS and BONK_STATS.heroes ) then
		return BONK_STATS.heroes[hero.name];
	end
	return nil;
end

local function SetTexCoords(texture, coords)
	texture:SetTexCoord(coords[1], coords[2], coords[3], coords[4]);
end

local function RaceIconCoords(race, sex)
	local gender = "MALE";
	if ( sex == 2 ) then
		gender = "FEMALE";
	end
	return RACE_ICON_TCOORDS[race.."_"..gender];
end

local function SexName(sex)
	if ( sex == 2 ) then
		return L["hoa.ui.glue.female"];
	end
	return L["hoa.ui.glue.male"];
end

local function SetClassColor(fontString, token)
	local color = BONK_CLASS_COLORS[token];
	fontString:SetTextColor(color[1], color[2], color[3]);
end

local function IsSelectable(class)
	return not class.locked or Bonk.heroes[class.token];
end

local function PlayableCount()
	local playable = 0;
	for _, class in BONK_CLASSES do
		if ( not class.locked ) then
			playable = playable + 1;
		end
	end
	return playable;
end

local function HeroCount()
	local count = 0;
	for _, class in BONK_CLASSES do
		if ( Bonk.heroes[class.token] ) then
			count = count + 1;
		end
	end
	return count;
end

function BonkHero_SetStatus(text)
	BonkHeroStatus:SetText(text);
end

function BonkHero_OnLoad()
	for index, class in BONK_CLASSES do
		local row = getglobal("BonkCharRow"..index);
		row:SetPoint("TOPLEFT", "BonkListPanel", "TOPLEFT", 20, -50 - (index - 1) * ROW_STEP);
		SetTexCoords(getglobal(row:GetName().."Icon"), CLASS_ICON_TCOORDS[class.token]);
	end

	for index = 1, NUM_STAT_ROWS do
		getglobal("BonkHeroStat"..index):SetPoint("TOPLEFT", "BonkHeroRecordFrame", "TOPLEFT", 0, -(index - 1) * 22);
	end

	BonkClassStarterName:SetWidth(STARTER_TEXT_WIDTH);
	BonkClassStarterName:SetHeight(STARTER_NAME_HEIGHT);
	BonkClassStarterLine:SetWidth(STARTER_TEXT_WIDTH);
	BonkClassStarterLine:SetHeight(STARTER_LINE_HEIGHT);

	BonkHeroGenderButton1Icon:SetTexCoord(0, 0.5, 0, 1.0);
	BonkHeroGenderButton2Icon:SetTexCoord(0.5, 1.0, 0, 1.0);
	BonkHeroGenderButton1Label:SetText(L["hoa.ui.glue.male"]);
	BonkHeroGenderButton2Label:SetText(L["hoa.ui.glue.female"]);
	BonkRaceBoxCaption:SetText(L["hoa.ui.glue.race"]);
	BonkGenderBoxCaption:SetText(L["hoa.ui.glue.gender"]);
	BonkFeatureBoxCaption:SetText(L["hoa.ui.glue.features"]);
	BonkListPanelTitle:SetText(L["hoa.ui.glue.characters"]);
	BonkAppearPanelTitle:SetText(L["hoa.ui.glue.appearance"]);

	for name, text in XML_TEXTS do
		getglobal(name):SetText(text);
	end

	BonkHero_UpdateCount();
end

function BonkHero_UpdateCount()
	BonkListCount:SetText(L("hoa.ui.glue.1_of_2_classes_created", HeroCount(), PlayableCount()));
end

function BonkHero_ToggleIronman()
	Bonk.ironman = BonkHeroIronman:GetChecked() and true or nil;
	if ( Bonk.ironman ) then
		PlaySound("igMainMenuOptionCheckBoxOn");
	else
		PlaySound("igMainMenuOptionCheckBoxOff");
	end
end

function BonkHero_CustomizeLabel(id)
	return CUSTOMIZE_LABELS[id] or getglobal("CHAR_CUSTOMIZATION"..id.."_DESC");
end

function BonkHero_ShowIronmanTip(owner)
	BonkHero_ShowTip(owner, L["hoa.ui.glue.ironman_mode"], BONK_IRONMAN_TIP);
end

function BonkHero_ShowTip(owner, title, text)
	BonkTipTitle:SetText(title);
	BonkTipText:SetText(text);
	BonkTip:SetHeight(BonkTipTitle:GetHeight() + BonkTipText:GetHeight() + 24);
	BonkTip:ClearAllPoints();
	if ( owner:GetLeft() and owner:GetLeft() > GlueParent:GetWidth() / 2 ) then
		BonkTip:SetPoint("BOTTOMRIGHT", owner, "TOPLEFT", 0, 0);
	else
		BonkTip:SetPoint("BOTTOMLEFT", owner, "TOPRIGHT", 0, 0);
	end
	BonkTip:Show();
end

function BonkHero_ShowSpellTip(frame)
	if ( frame.spell ) then
		BonkHero_ShowTip(frame, frame.spell.name, frame.spell.tip);
	end
end

function BonkHero_ShowRaceTip(frame)
	if ( frame.race ) then
		BonkHero_ShowTip(frame, BONK_RACE_DISPLAY_NAMES[frame.race], "");
	end
end

local function HeroClassToken(name, className)
	if ( not name ) then
		return nil;
	end
	local created = Bonk.createdClasses[strlower(name)];
	if ( created ) then
		return created;
	end
	local stats = BONK_STATS and BONK_STATS.heroes and BONK_STATS.heroes[name];
	if ( stats and BONK_CLASS_BY_ID[stats.class] ) then
		return BONK_CLASS_BY_ID[stats.class];
	end
	return BONK_CLASS_TOKENS[className];
end

function BonkHero_ReadHeroes()
	Bonk.heroes = {};
	local unknown;
	for index = 1, GetNumCharacters() do
		local name, race, class, level, zone, fileString, gender = GetCharacterInfo(index);
		local classToken = HeroClassToken(name, class);
		if ( name and not (classToken and fileString) ) then
			unknown = name.." ("..tostring(class)..", "..tostring(fileString)..")";
		end
		if ( name and classToken and fileString and not Bonk.heroes[classToken] ) then
			local sex = 1;
			if ( gender and gender ~= 0 ) then
				sex = 2;
			end
			Bonk.heroes[classToken] = { index = index, name = name, race = strupper(fileString), level = level, sex = sex };
		end
	end
	Bonk.unknownHero = unknown;
	if ( unknown and Bonk.classNamesLearned ) then
		BonkHero_SetStatus(L("hoa.ui.glue.could_not_read_the_class_of_1", unknown));
	end
end

local function LearnClassesOfSelectedRace()
	local classes = { GetClassesForRace() };
	for i = 1, getn(classes) / 2 do
		local name = classes[i * 2 - 1];
		local token = strupper(classes[i * 2] or "");
		if ( name and BONK_CLASS_TOKENS[token] == token ) then
			BONK_CLASS_TOKENS[name] = token;
		end
	end
end

function BonkHero_LearnClassNames()
	if ( Bonk.classNamesLearned ) then
		return false;
	end
	Bonk.classNamesLearned = true;
	local races = { GetAvailableRaces() };
	local savedRace = GetSelectedRace();
	local savedClass = GetSelectedClass();
	for i = 1, getn(races) / 2 do
		SetSelectedRace(i);
		SetCharacterRace(i);
		LearnClassesOfSelectedRace();
	end
	if ( savedRace and savedRace > 0 ) then
		SetSelectedRace(savedRace);
		SetCharacterRace(savedRace);
		local classes = { GetClassesForRace() };
		for i = 1, getn(classes) / 2 do
			if ( classes[i * 2 - 1] == savedClass ) then
				SetSelectedClass(i);
				break;
			end
		end
	end
	return true;
end

local function SelectClassToken(classToken)
	for index, class in BONK_CLASSES do
		if ( class.token == classToken ) then
			Bonk.classIndex = index;
		end
	end
end

function BonkHero_AccountKey()
	return strupper(BONK_ACCOUNT or "");
end

function BonkHero_OnCharacterList()
	if ( BONK_STATS_ACCOUNTS ) then
		BONK_STATS = BONK_STATS_ACCOUNTS[BonkHero_AccountKey()];
	end
	BonkHero_ReadHeroes();

	if ( Bonk.wiping ) then
		Bonk.listLoaded = true;
		if ( Bonk.wiping.step == "create" ) then
			BonkHero_FinishWipe();
		else
			Bonk.wiping.sent = nil;
			Bonk.wiping.wait = BONK_WIPE_GAP;
			BonkHero_UpdateRoster();
		end
		return;
	end

	if ( Bonk.creating and Bonk.creating.ironmanSent ) then
		Bonk.creating.ironmanSent = nil;
		BonkHero_CreateCharacter();
		return;
	end

	if ( Bonk.unknownHero and not Bonk.classNamesLearned and Bonk.screen == "charselect" ) then
		SetGlueScreen("charcreate");
		return;
	end

	if ( Bonk.creating ) then
		local hero = Bonk.heroes[Bonk.creating.class];
		if ( hero ) then
			Bonk.creating = nil;
			Bonk.customizing = nil;
			BonkHeroNameEdit:SetText("");
			BonkHero_EnterWorld(hero);
			return;
		end
	end

	Bonk.listLoaded = true;
	local count = GetNumCharacters();
	if ( not Bonk.startPicked and count > 0 ) then
		Bonk.startPicked = true;
		local start;
		for index = 1, count do
			if ( BONK_STATS and BONK_STATS.lastHero and GetCharacterInfo(index) == BONK_STATS.lastHero ) then
				start = index;
			end
		end
		if ( not start and CharacterSelect.selectedIndex and CharacterSelect.selectedIndex > 0 and CharacterSelect.selectedIndex <= count ) then
			start = CharacterSelect.selectedIndex;
		end
		if ( not start ) then
			start = 1;
		end
		local name, race, class = GetCharacterInfo(start);
		local classToken = HeroClassToken(name, class);
		if ( classToken ) then
			SelectClassToken(classToken);
		end
	end

	BonkHero_Refresh();
end

function BonkHero_Refresh()
	if ( Bonk.refreshing ) then
		return;
	end
	Bonk.refreshing = true;
	if ( CurrentHero() ) then
		Bonk.customizing = nil;
	end
	BonkHero_UpdateRoster();
	BonkHero_UpdateInfo();
	BonkHero_UpdateCount();
	BonkHero_UpdateControls();
	Bonk.refreshing = false;

	Bonk.sceneDirty = true;
end

function BonkHero_UpdateRoster()
	for index, class in BONK_CLASSES do
		local row = getglobal("BonkCharRow"..index);
		local icon = getglobal(row:GetName().."Icon");
		local name = getglobal(row:GetName().."Name");
		local sub = getglobal(row:GetName().."Sub");
		local hero = Bonk.heroes[class.token];
		if ( index == Bonk.classIndex ) then
			getglobal(row:GetName().."Selected"):Show();
		else
			getglobal(row:GetName().."Selected"):Hide();
		end
		if ( hero ) then
			local stats = HeroStats(hero) or {};
			icon:SetVertexColor(1.0, 1.0, 1.0);
			name:SetText(hero.name);
			name:SetTextColor(1.0, 0.82, 0);
			sub:SetText(L("hoa.ui.glue.mastery_1_2_3", format("%d", stats.mastery or 0), BONK_RACE_DISPLAY_NAMES[hero.race] or "", class.display));
			sub:SetTextColor(1.0, 1.0, 1.0);
		elseif ( class.locked ) then
			icon:SetVertexColor(0.25, 0.25, 0.25);
			name:SetText(class.display);
			name:SetTextColor(0.4, 0.4, 0.4);
			sub:SetText(L["hoa.ui.glue.locked"]);
			sub:SetTextColor(0.4, 0.4, 0.4);
		else
			icon:SetVertexColor(0.4, 0.4, 0.4);
			name:SetText(class.display);
			name:SetTextColor(0.55, 0.55, 0.55);
			sub:SetText(L("hoa.ui.glue.create_a_1", class.display));
			sub:SetTextColor(0.5, 0.5, 0.5);
		end
	end
end

function BonkHero_UpdateControls()
	local hero = CurrentHero();
	if ( hero ) then
		BonkHeroPlayButton:SetText(L["hoa.ui.glue.play"]);
	elseif ( Bonk.customizing ) then
		BonkHeroPlayButton:SetText(L["hoa.ui.glue.create"]);
	else
		BonkHeroPlayButton:SetText(L("hoa.ui.glue.create_1", CurrentClass().display));
	end

	if ( Bonk.customizing ) then
		BonkListPanel:Hide();
		BonkAppearPanel:Show();
		BonkHeroNameEdit:Show();
		BonkHeroQuitButton:Hide();
		BonkHeroWipeButton:Hide();
		BonkHeroBackButton:Show();
		BonkHeroSubtitle:SetText(L("hoa.ui.glue.create_your_1", CurrentClass().display));
		BonkHeroPreview:SetText("");
	else
		BonkAppearPanel:Hide();
		BonkListPanel:Show();
		BonkHeroNameEdit:Hide();
		BonkHeroNameEdit:ClearFocus();
		BonkHeroBackButton:Hide();
		BonkHeroQuitButton:Show();
		BonkHeroWipeButton:Show();
		BonkHeroSubtitle:SetText(L["hoa.ui.glue.choose_your_character"]);
		if ( hero ) then
			BonkHeroPreview:SetText("");
		else
			BonkHeroPreview:SetText(L("hoa.ui.glue.preview_1", BONK_RACE_DISPLAY_NAMES[NewHeroRace()]));
		end
	end
end

local function ShowSpellRow(row, spell, tag)
	row.spell = spell;
	getglobal(row:GetName().."Icon"):SetTexture(spell.icon);
	getglobal(row:GetName().."Name"):SetText(spell.name);
	getglobal(row:GetName().."Line"):SetText(spell.line);
	local tagText = getglobal(row:GetName().."Tag");
	if ( tagText ) then
		tagText:SetText(tag or "");
	end
	row:Show();
end

function BonkHero_UpdateClassInfo(class, sex)
	local info = BONK_CLASS_INFO[class.token];
	BonkClassFrame:Show();
	if ( not info ) then
		BonkClassBlurb:SetText("");
		return;
	end

	BonkClassBlurb:SetText(info.blurb);

	for index = 1, NUM_CLASS_RACES do
		local frame = getglobal("BonkClassRace"..index);
		local race = class.races[index];
		if ( race ) then
			frame.race = race;
			SetTexCoords(getglobal(frame:GetName().."Icon"), RaceIconCoords(race, sex));
			frame:Show();
		else
			frame:Hide();
		end
	end

	if ( info.starter ) then
		ShowSpellRow(BonkClassStarter, info.starter);
		BonkClassStarterLabel:Show();
	else
		BonkClassStarter:Hide();
		BonkClassStarterLabel:Hide();
	end

	local specCount = getn(info.specs);
	if ( Bonk.specIndex > specCount ) then
		Bonk.specIndex = 1;
	end
	for index = 1, NUM_SPECS do
		local button = getglobal("BonkSpecButton"..index);
		local spec = info.specs[index];
		if ( spec ) then
			getglobal(button:GetName().."Icon"):SetTexture(spec.icon);
			local label = getglobal(button:GetName().."Label");
			label:SetText(spec.name);
			if ( index == Bonk.specIndex ) then
				label:SetTextColor(1.0, 0.82, 0);
				getglobal(button:GetName().."Icon"):SetVertexColor(1.0, 1.0, 1.0);
			else
				label:SetTextColor(0.78, 0.75, 0.68);
				getglobal(button:GetName().."Icon"):SetVertexColor(0.6, 0.6, 0.6);
			end
			button:SetChecked(Flag(index == Bonk.specIndex));
			button:Show();
		else
			button:Hide();
		end
	end

	local spec = info.specs[Bonk.specIndex];
	local rows = 0;
	if ( spec ) then
		BonkClassSpecText:SetText(spec.text);
		for _, spell in ipairs(spec.spells) do
			if ( rows < NUM_SPELL_ROWS ) then
				rows = rows + 1;
				ShowSpellRow(getglobal("BonkSpellRow"..rows), spell);
			end
		end
	else
		BonkClassSpecText:SetText("");
	end
	for _, spell in ipairs(info.shared) do
		if ( rows < NUM_SPELL_ROWS ) then
			rows = rows + 1;
			ShowSpellRow(getglobal("BonkSpellRow"..rows), spell, L["hoa.ui.glue.every_spec"]);
		end
	end
	for index = rows + 1, NUM_SPELL_ROWS do
		getglobal("BonkSpellRow"..index):Hide();
	end
end

function BonkHero_UpdateInfo()
	local class = CurrentClass();
	local hero = CurrentHero();
	SetTexCoords(BonkInfoIcon, CLASS_ICON_TCOORDS[class.token]);

	if ( hero ) then
		BonkInfoPanelTitle:SetText(L["hoa.ui.glue.stats"]);
		BonkHeroName:SetText(hero.name);
		SetClassColor(BonkHeroName, class.token);
		local stats = HeroStats(hero) or {};
		local detail;
		if ( stats.ironman ) then
			detail = L("hoa.ui.glue.mastery_1_2_3_ironman", format("%d", stats.mastery or 0), BONK_RACE_DISPLAY_NAMES[hero.race] or "", class.display);
		else
			detail = L("hoa.ui.glue.mastery_1_2_3", format("%d", stats.mastery or 0), BONK_RACE_DISPLAY_NAMES[hero.race] or "", class.display);
		end
		BonkHeroDetail:SetText(detail);
		BonkHeroRetireButton:Show();
		BonkClassFrame:Hide();
		BonkHeroRecordFrame:Show();
		BonkHero_UpdateRecord(hero);
		return;
	end

	if ( Bonk.raceIndex > getn(class.races) ) then
		Bonk.raceIndex = 1;
	end
	BonkInfoPanelTitle:SetText(L["hoa.ui.glue.class"]);
	BonkHeroName:SetText(class.display);
	SetClassColor(BonkHeroName, class.token);
	if ( Bonk.customizing ) then
		BonkHeroDetail:SetText(BONK_RACE_DISPLAY_NAMES[NewHeroRace()].." - "..SexName(Bonk.sex));
	else
		BonkHeroDetail:SetText(L["hoa.ui.glue.cff808080not_created_yet_r"]);
	end
	BonkHeroRetireButton:Hide();
	BonkHeroRecordFrame:Hide();
	BonkHero_UpdateClassInfo(class, Bonk.sex);
	BonkHero_UpdateAppearance(class);
end

function BonkHero_UpdateAppearance(class)
	BonkHeroIronman:SetChecked(Flag(Bonk.ironman));
	local raceCount = getn(class.races);
	local rows = ceil(raceCount / RACES_PER_ROW);
	for index = 1, 8 do
		local button = getglobal("BonkHeroRaceButton"..index);
		local race = class.races[index];
		if ( race ) then
			local rowIndex = floor((index - 1) / RACES_PER_ROW);
			local inRow = RACES_PER_ROW;
			if ( rowIndex == rows - 1 ) then
				inRow = raceCount - rowIndex * RACES_PER_ROW;
			end
			local column = mod(index - 1, RACES_PER_ROW);
			local x = (column - (inRow - 1) / 2) * RACE_COLUMN_STEP;
			button:ClearAllPoints();
			button:SetPoint("TOP", "BonkRaceBox", "TOP", x, -10 - rowIndex * RACE_ROW_STEP);
			local icon = getglobal(button:GetName().."Icon");
			icon:SetTexture("Interface\\Glues\\CharacterCreate\\UI-CharacterCreate-Races");
			SetTexCoords(icon, RaceIconCoords(race, Bonk.sex));
			getglobal(button:GetName().."Label"):SetText(BONK_RACE_DISPLAY_NAMES[race]);
			button:SetChecked(Flag(index == Bonk.raceIndex));
			button:Show();
		else
			button:Hide();
		end
	end
	BonkRaceBox:SetHeight(rows * RACE_ROW_STEP + 10);
	BonkHeroGenderButton1:SetChecked(Flag(Bonk.sex == 1));
	BonkHeroGenderButton2:SetChecked(Flag(Bonk.sex == 2));
end

function BonkLevelName(level)
	level = tonumber(level) or 0;
	if ( level <= 0 ) then
		return "-";
	elseif ( level <= 4 ) then
		return L("hoa.ui.glue.level_name_1_2", L["hoa.ui.glue.normal"], level);
	elseif ( level <= 9 ) then
		return L("hoa.ui.glue.level_name_1_2", L["hoa.ui.glue.heroic"], level - 4);
	end
	return L("hoa.ui.glue.level_name_1_2", L["hoa.ui.glue.mythic"], level - 9);
end

local function FormatPlayed(seconds)
	if ( not seconds or seconds <= 0 ) then
		return "-";
	end
	local hours = floor(seconds / 3600);
	local minutes = floor(mod(seconds, 3600) / 60);
	if ( hours > 0 ) then
		return L("hoa.ui.glue.hours_and_minutes_1_h_2_m", hours, minutes);
	end
	return L("hoa.ui.glue.minutes_1_m", minutes);
end

local function SetStatRow(index, label, value)
	getglobal("BonkHeroStat"..index.."Label"):SetText(label);
	getglobal("BonkHeroStat"..index.."Value"):SetText(value);
end

function BonkHero_UpdateRecord(hero)
	local stats = HeroStats(hero) or {};
	local runs = stats.runs or 0;

	SetStatRow(1, L["hoa.ui.glue.runs"], runs);
	SetStatRow(2, L["hoa.ui.glue.time_played"], FormatPlayed(stats.played));
	SetStatRow(3, L["hoa.ui.glue.best_level"], BonkLevelName(stats.bestLevel));
	SetStatRow(4, L["hoa.ui.glue.longest_run"], stats.bestTime and FormatTime(stats.bestTime) or "-");
	SetStatRow(5, L["hoa.ui.glue.enemies_slain"], stats.kills or 0);
	SetStatRow(6, L["hoa.ui.glue.gold_earned"], FormatGold(stats.goldEarned));
	if ( stats.items and stats.items > 0 ) then
		SetStatRow(7, L["hoa.ui.glue.gear"], L("hoa.ui.glue.1_items_item_level_2", stats.items, stats.itemLevel or 0));
	else
		SetStatRow(7, L["hoa.ui.glue.gear"], "-");
	end
	SetStatRow(8, L["hoa.ui.glue.gear_value"], FormatGold(stats.gearValue));
	if ( stats.ironman ) then
		SetStatRow(9, L["hoa.ui.glue.gold"], FormatGold(stats.gold));
		BonkHeroStat9:Show();
	else
		BonkHeroStat9:Hide();
	end

	if ( not HeroStats(hero) ) then
		BonkHeroRecordNote:SetText(L("hoa.ui.glue.these_stats_update_when_1_logs_out", hero.name));
	elseif ( runs == 0 ) then
		BonkHeroRecordNote:SetText(L("hoa.ui.glue.1_has_not_done_a_run_yet", hero.name));
	else
		BonkHeroRecordNote:SetText("");
	end
end

function BonkHero_UpdateScene()
	if ( not Bonk.listLoaded or Bonk.creating or Bonk.wiping ) then
		return;
	end

	local hero = CurrentHero();
	if ( hero ) then
		if ( Bonk.screen ~= "charselect" ) then
			Bonk.reuseList = true;
			SetGlueScreen("charselect");
			CharacterSelect_SelectCharacter(hero.index, 1);
		elseif ( CharacterSelect.selectedIndex ~= hero.index ) then
			CharacterSelect_SelectCharacter(hero.index, 1);
		end
	elseif ( Bonk.screen ~= "charcreate" ) then
		SetGlueScreen("charcreate");
	else
		BonkHero_ApplyNewHero();
	end
end

function BonkHero_ApplyNewHero()
	if ( CurrentHero() ) then
		return;
	end
	local class = CurrentClass();
	local race = NewHeroRace();

	local races = { GetAvailableRaces() };
	local raceId;
	for i = 1, getn(races) / 2 do
		if ( strupper(races[i * 2]) == race ) then
			raceId = i;
		end
	end
	if ( not raceId ) then
		return;
	end

	if ( Bonk.appliedRace ~= race ) then
		Bonk.appliedRace = race;
		SetSelectedRace(raceId);
		SetCharacterRace(raceId);
	end
	if ( GetSelectedSex() ~= Bonk.sex ) then
		SetCharacterGender(Bonk.sex);
	end

	local classes = { GetClassesForRace() };
	for i = 1, getn(classes) / 2 do
		if ( strupper(classes[i * 2]) == class.token ) then
			SetSelectedClass(i);
			SetCharacterClass(i);
		end
	end
	BonkHero_UpdateCustomization();
end

function BonkHero_UpdateCustomization()
	local hair = GetHairCustomization();
	BonkHeroLook3Text:SetText(HAIR_STYLE_LABELS[hair] or getglobal("HAIR_"..hair.."_STYLE"));
	BonkHeroLook4Text:SetText(HAIR_COLOR_LABELS[hair] or getglobal("HAIR_"..hair.."_COLOR"));
	local facialHair = GetFacialHairCustomization();
	if ( facialHair == "NONE" ) then
		BonkHeroLook5:Hide();
	else
		BonkHeroLook5Text:SetText(FACIAL_HAIR_LABELS[facialHair] or getglobal("FACIAL_HAIR_"..facialHair));
		BonkHeroLook5:Show();
	end
end

function BonkHero_SelectClass(index)
	local class = BONK_CLASSES[index];
	if ( not IsSelectable(class) ) then
		PlaySound("igMainMenuOptionCheckBoxOff");
		BonkHero_SetStatus(L("hoa.ui.glue.the_1_is_not_available_yet", class.display));
		BonkHero_UpdateRoster();
		return;
	end
	PlaySound("gsCharacterCreationClass");
	if ( not Bonk.creating and not Bonk.wiping and not Bonk.customizing and index ~= Bonk.classIndex ) then
		Bonk.classIndex = index;
		Bonk.raceIndex = 1;
		Bonk.specIndex = 1;
		BonkHero_SetStatus("");
	end
	BonkHero_Refresh();
end

function BonkHero_SelectSpec(index)
	PlaySound("igMainMenuOptionCheckBoxOn");
	Bonk.specIndex = index;
	BonkHero_UpdateInfo();
end

function BonkHero_SelectRace(index)
	PlaySound("gsCharacterCreationClass");
	if ( not Bonk.creating ) then
		Bonk.raceIndex = index;
		BonkHero_SetStatus("");
	end
	BonkHero_Refresh();
end

function BonkHero_SelectSex(sex)
	PlaySound("gsCharacterCreationClass");
	if ( not Bonk.creating and not Bonk.wiping ) then
		Bonk.sex = sex;
	end
	BonkHero_Refresh();
end

function BonkHero_Randomize()
	PlaySound("gsCharacterCreationLook");
	if ( Bonk.screen == "charcreate" ) then
		RandomizeCharCustomization();
		BonkHero_UpdateCustomization();
	end
end

function BonkHero_CreateCharacter()
	PlaySound("gsCharacterCreationCreateChar");
	local name = BonkHeroNameEdit:GetText();
	if ( Bonk.creating ) then
		Bonk.createdClasses[strlower(name)] = Bonk.creating.class;
	end
	CreateCharacter(name);
end

function BonkHero_EnterWorld(hero)
	BonkHero_SetStatus(L["hoa.ui.glue.entering_the_world"]);
	CharacterSelect_SelectCharacter(hero.index, 1);
	PlaySound("gsCharacterSelectionEnterWorld");
	EnterWorld();
end

function BonkHero_StartCustomizing()
	PlaySound("gsCharacterSelectionCreateNew");
	Bonk.customizing = true;
	BonkHero_SetStatus("");
	BonkHero_Refresh();
	BonkHeroNameEdit:SetFocus();
end

function BonkHero_Back()
	if ( not Bonk.customizing or Bonk.creating ) then
		return;
	end
	PlaySound("gsCharacterCreationCancel");
	Bonk.customizing = nil;
	BonkHero_SetStatus("");
	BonkHero_Refresh();
end

function BonkHero_Play()
	if ( Bonk.creating or Bonk.wiping or not Bonk.listLoaded ) then
		return;
	end

	local hero = CurrentHero();
	if ( hero ) then
		BonkHero_EnterWorld(hero);
		return;
	end

	if ( not Bonk.customizing ) then
		BonkHero_StartCustomizing();
		return;
	end

	if ( Bonk.screen ~= "charcreate" ) then
		return;
	end
	if ( BonkHeroNameEdit:GetText() == "" ) then
		BonkHero_SetStatus(L["hoa.ui.glue.enter_a_name_for_your_character"]);
		BonkHeroNameEdit:SetFocus();
		return;
	end

	BonkHeroNameEdit:ClearFocus();
	Bonk.creating = { class = CurrentClass().token };
	BonkHero_SetStatus(L["hoa.ui.glue.creating_your_character"]);
	if ( Bonk.ironman ) then
		Bonk.creating.ironmanSent = true;
		CreateCharacter(IRONMAN_NAME);
		return;
	end
	BonkHero_CreateCharacter();
end

function BonkHero_Retire()
	local hero = CurrentHero();
	if ( not hero or Bonk.creating or Bonk.wiping ) then
		return;
	end
	PlaySound("gsCharacterSelectionDelCharacter");
	GlueDialog_Show("BONK_RETIRE", L("hoa.ui.glue.delete_1_your_2_this_permanently_deletes_the_character_and_t", hero.name, CurrentClass().display), hero.index);
end

BONK_WIPE_GAP = 0.3;
local WIPE_NAME = "Wipeaccount";
local WIPE_ASK_AGAIN = 3;
local WIPE_TIMEOUT = 15;

function BonkHero_Wipe()
	if ( Bonk.creating or Bonk.wiping or not Bonk.listLoaded ) then
		return;
	end
	PlaySound("gsCharacterSelectionDelCharacter");
	GlueDialog_Show("BONK_WIPE");
end

function BonkHero_StartWipe()
	Bonk.wiping = { step = "delete", wait = 0 };
	Bonk.customizing = nil;
	BonkHeroNameEdit:ClearFocus();
	BonkHero_SetStatus(L["hoa.ui.glue.wiping_the_account"]);
end

function BonkHero_StopWipe(text)
	Bonk.wiping = nil;
	BonkHero_SetStatus(text);
	BonkHero_Refresh();
end

function BonkHero_FinishWipe()
	Bonk.wiping = nil;
	BONK_STATS = { gold = 0, lastHero = "", heroes = {} };
	BONK_STATS_ACCOUNTS = BONK_STATS_ACCOUNTS or {};
	BONK_STATS_ACCOUNTS[BonkHero_AccountKey()] = BONK_STATS;
	Bonk.classIndex = 1;
	Bonk.raceIndex = 1;
	Bonk.specIndex = 1;
	BonkHeroNameEdit:SetText("");
	BonkHero_Refresh();
	BonkHero_SetStatus(L["hoa.ui.glue.cff20ff20account_wiped_r_every_character_and_all_progress_ar"]);
end

function BonkHero_UpdateWipe(elapsed)
	local wipe = Bonk.wiping;
	if ( wipe.sent ) then
		wipe.sentFor = wipe.sentFor + elapsed;
		if ( wipe.sent == "delete" and not wipe.askedAgain and wipe.sentFor > WIPE_ASK_AGAIN ) then
			wipe.askedAgain = true;
			GetCharacterListUpdate();
		elseif ( wipe.sentFor > WIPE_TIMEOUT ) then
			BonkHero_StopWipe(L["hoa.ui.glue.the_server_didn_t_answer_so_the_account_was_not_wiped"]);
		end
		return;
	end
	wipe.wait = wipe.wait - elapsed;
	if ( wipe.wait > 0 ) then
		return;
	end

	local count = GetNumCharacters();
	if ( count > 0 ) then
		if ( count == 1 ) then
			BonkHero_SetStatus(L["hoa.ui.glue.wiping_the_account_1_character_left"]);
		else
			BonkHero_SetStatus(L("hoa.ui.glue.wiping_the_account_1_characters_left", count));
		end
		wipe.sent = "delete";
		wipe.sentFor = 0;
		wipe.askedAgain = nil;
		DeleteCharacter(1);
		return;
	end

	if ( Bonk.screen ~= "charcreate" ) then
		SetGlueScreen("charcreate");
		wipe.wait = BONK_WIPE_GAP;
		return;
	end
	BonkHero_SetStatus(L["hoa.ui.glue.wiping_the_account"]);
	wipe.step = "create";
	wipe.sent = "create";
	wipe.sentFor = 0;
	CreateCharacter(WIPE_NAME);
end

function BonkHero_Quit()
	PlaySound("gsTitleQuit");
	GlueDialog_Show("BONK_QUIT");
end

function BonkHero_StepClass(direction)
	if ( Bonk.customizing ) then
		return;
	end
	local count = getn(BONK_CLASSES);
	local index = Bonk.classIndex;
	for step = 1, count do
		index = mod(index - 1 + direction + count, count) + 1;
		if ( IsSelectable(BONK_CLASSES[index]) ) then
			BonkHero_SelectClass(index);
			return;
		end
	end
end

function BonkHero_StepRace(direction)
	if ( not Bonk.customizing ) then
		return;
	end
	local count = getn(CurrentClass().races);
	BonkHero_SelectRace(mod(Bonk.raceIndex - 1 + direction + count, count) + 1);
end

function BonkHero_OnKeyDown()
	if ( arg1 == "ESCAPE" ) then
		if ( Bonk.customizing ) then
			BonkHero_Back();
		else
			BonkHero_Quit();
		end
	elseif ( arg1 == "ENTER" ) then
		BonkHero_Play();
	elseif ( arg1 == "UP" ) then
		BonkHero_StepClass(-1);
	elseif ( arg1 == "DOWN" ) then
		BonkHero_StepClass(1);
	elseif ( arg1 == "LEFT" ) then
		BonkHero_StepRace(-1);
	elseif ( arg1 == "RIGHT" ) then
		BonkHero_StepRace(1);
	elseif ( arg1 == "PRINTSCREEN" ) then
		Screenshot();
	end
end

function BonkHero_OnMouseDown(button)
	if ( Bonk.screen == "charcreate" ) then
		CharacterCreateFrame_OnMouseDown(button);
	else
		CharacterSelectFrame_OnMouseDown(button);
	end
end

function BonkHero_OnMouseUp(button)
	CharacterCreateFrame_OnMouseUp(button);
	CharacterSelectFrame_OnMouseUp(button);
end

function BonkHero_OnUpdate(elapsed)
	if ( Bonk.wiping ) then
		BonkHero_UpdateWipe(elapsed or 0);
	end
	if ( Bonk.sceneDelay > 0 ) then
		Bonk.sceneDelay = Bonk.sceneDelay - (elapsed or 0);
	elseif ( Bonk.sceneDirty and (Bonk.screen == "charselect" or Bonk.screen == "charcreate") ) then
		Bonk.sceneDirty = false;
		BonkHero_UpdateScene();
	end

	if ( Bonk.screen == "charcreate" ) then
		CharacterCreateFrame_OnUpdate();
	else
		CharacterSelectFrame_OnUpdate();
	end
end
