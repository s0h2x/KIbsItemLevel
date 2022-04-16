LoadAddOn("Blizzard_InspectUI");
LoadAddOn("LibItemUpgradeInfo-1.0");
local FontStrings = {};
local InspectFontStrings = {};
local ActiveFontStrings = {};
local Icons = {};
local InspectIcons = {};
local ActiveIcons = {};
local InspectAilvl;
local EnchantIcons = {};
local InspectEnchantIcons = {};
local ActiveEnchantIcons = {};
local ItemUpgradeInfo = LibStub("LibItemUpgradeInfo-1.0");
local ilvlFrame = CreateFrame("frame");
local iconSize = 12;
local iconOffset = 13;
local fontStyle = "SystemFont_Small";
local UpdateInProgress = false;
local UpdateInProgressInspect = false;
local ilvlPlayerFrame;
ilvlFrame:RegisterEvent("VARIABLES_LOADED");

-- Globals
KIL_UpdateInterval = 1.0;
KibsItemLevel_variablesLoaded = false;
KibsItemLevel_details = {
	name = "KibsItemLevel",
	frame = "ilvlFrame",
	optionsframe = "KibsItemLevelConfigFrame"
	};

local KibsItemLevelConfig_defaultOn = true;
local KibsItemLevelConfig_defaultUpgrades = false;
local KibsItemLevelConfig_defaultCharacter = true;
local KibsItemLevelConfig_defaultInspection = true;
local KibsItemLevelConfig_defaultColor = true;

local emptySockets = { ["Meta "]    = "INTERFACE/ITEMSOCKETINGFRAME/UI-EmptySocket-Meta",
                      ["Red "]     = "INTERFACE/ITEMSOCKETINGFRAME/UI-EmptySocket-Red",
                      ["Blue "]    = "INTERFACE/ITEMSOCKETINGFRAME/UI-EmptySocket-Blue",
					  ["Yellow "]  = "INTERFACE/ITEMSOCKETINGFRAME/UI-EmptySocket-Yellow",
					  ["Prismatic "]  = "INTERFACE/ITEMSOCKETINGFRAME/UI-EmptySocket-Prismatic",
                    } ;
					
local enchantableItems={ [ 1  ] = true,
						[ 2  ] = nil,
						[ 3  ] = true,
						[ 15 ] = true,
						[ 5  ] = true,
						[ 9  ] = true,
						[ 10 ] = true,
						[ 6  ] = nil,
						[ 7  ] = true,
						[ 8  ] = true,
						[ 11 ] = nil,
						[ 12 ] = nil,
						[ 13 ] = nil,
						[ 14 ] = nil,
						[ 16 ] = true,
						[ 17 ] = true, 
						[ 18 ] = true 
					};

function KibsItemLevel_OnLoad()
	createFontStrings();
	createInspectFontStrings();
end

function KIL_OnShow(self,...)
	if(KibsItemLevel_variablesLoaded)then
		if(KibsItemLevelConfig.Character) then
			UpdateInProgress = true;
			updatePlayer();
		end
	end
end

function updatePlayer()
	if (KibsItemLevelConfig.Character) then
		findItemInfo("player");
	end
end

function updateInspect()
	findItemInfo(InspectFrame.unit);
end

function KIL_OnUpdate(self, elapsed)
	self.TimeSinceLastUpdate = self.TimeSinceLastUpdate + elapsed;
	
	if(self.TimeSinceLastUpdate > KIL_UpdateInterval) then
		if not(UnitAffectingCombat("player")) then
			findItemInfo("player");
			print("Update");
		else
			print("In Combat");
		end
		self.TimeSinceLastUpdate = 0;
	end
	
end

local waitTable = {};
local waitFrame = nil;

function KIL_wait(delay, func, ...)
  if(type(delay)~="number" or type(func)~="function") then
    return false;
  end
  if(waitFrame == nil) then
    waitFrame = CreateFrame("Frame","WaitFrame", UIParent);
    waitFrame:SetScript("onUpdate",function (self,elapse)
      local count = #waitTable;
      local i = 1;
      while(i<=count) do
        local waitRecord = tremove(waitTable,i);
        local d = tremove(waitRecord,1);
        local f = tremove(waitRecord,1);
        local p = tremove(waitRecord,1);
        if(d>elapse) then
          tinsert(waitTable,i,{d-elapse,f,p});
          i = i + 1;
        else
          count = count - 1;
          f(unpack(p));
        end
      end
    end);
  end
  tinsert(waitTable,{delay,func,{...}});
  return true;
end

function eventHandler(self,event,...)
	--print(UnitGroupRolesAssigned("target"));
	
	
	if(KibsItemLevelConfig.on)then
		if (event == "PLAYER_TARGET_CHANGED" and ilvlFrame.inspectVisible and KibsItemLevelConfig.Inspection) then
			if(InspectFrame.unit and InspectFrame.unit == "target") then
				updateInspect()
			end
		elseif(event ~= "PLAYER_TARGET_CHANGED" and KibsItemLevelConfig.Character) then
			
			if(UpdateInProgress == false) then
				UpdateInProgress = true;
				updatePlayer()
			
			end
		end
	end
end

--Register Event Handler
function setupEventHandler(self,event,...)
	if (event == "VARIABLES_LOADED") then
		KibsItemLevelFrame_VARIABLES_LOADED();
		ilvlFrame:RegisterEvent("PLAYER_EQUIPMENT_CHANGED");
		ilvlFrame:RegisterEvent("SOCKET_INFO_CLOSE");
		ilvlFrame:RegisterEvent("SOCKET_INFO_SUCCESS");
		ilvlFrame:RegisterEvent("SOCKET_INFO_UPDATE");
		ilvlFrame:RegisterEvent("PLAYER_ENTERING_WORLD");
		ilvlFrame:RegisterEvent("PLAYER_TARGET_CHANGED")
		InspectFrame:SetScript("OnShow", function(self) ilvlFrame.inspectVisible = true; updateInspect(); end)
		InspectFrame:SetScript("OnHide", function(self) ilvlFrame.inspectVisible = false; end)
		ilvlFrame:SetScript("OnEvent",eventHandler);
		KILFrame:SetScript("OnShow",KIL_OnShow);
		if(KibsItemLevelConfig.Character)then
			updatePlayer()
		end
	end
end
ilvlFrame:SetScript("OnEvent",setupEventHandler);

--Create Config Panel
function KibsItemLevelFrame_VARIABLES_LOADED()
	if(KibsItemLevel_variablesLoaded)then
		return;
	end
	KibsItemLevel_variablesLoaded = true;
	if (KibsItemLevelConfig == nil) then
		KibsItemLevelConfig = {};
	end
	
	if (KibsItemLevelConfig.on == nil) then
		KibsItemLevelConfig.on = KibsItemLevelConfig_defaultOn;
	end
	if (KibsItemLevelConfig.upgrades == nil) then
		KibsItemLevelConfig.upgrades = KibsItemLevelConfig_defaultUpgrades;
	end
	if (KibsItemLevelConfig.Character == nil) then
		KibsItemLevelConfig.Character = KibsItemLevelConfig_defaultCharacter;
	end
	if (KibsItemLevelConfig.Inspection == nil) then
		KibsItemLevelConfig.Inspection = KibsItemLevelConfig_defaultInspection;
	end
	
	local ConfigPanel = CreateFrame("Frame", "KibsItemLevelConfigPanel", UIParent);
	ConfigPanel.name = "Kibs Item Level";
	
	local b = CreateFrame("CheckButton","Enabled",ConfigPanel,"UICheckButtonTemplate");
	b:SetPoint("TOPLEFT",ConfigPanel,"TOPLEFT",15,-15);
	b:SetChecked(KibsItemLevelConfig.on);
	_G[b:GetName() .. "Text"]:SetText("Enable Kibs Item Level");
	b:SetScript("OnClick", function(self, button, isDown) if ( self:GetChecked() ) then KibsItemLevelConfig.on = true; cleanUp(); else KibsItemLevelConfig.on = false; cleanUp(); end end)
	
	local b1 = CreateFrame("CheckButton","Upgrades",ConfigPanel,"UICheckButtonTemplate");
	b1:SetPoint("TOPLEFT",b,"BOTTOMLEFT",0,0);
	b1:SetChecked(KibsItemLevelConfig.upgrades);
	_G[b1:GetName() .. "Text"]:SetText("Show upgrades, e.g. (4/4)");
	b1:SetScript("OnClick", function(self, button, isDown) if ( self:GetChecked() ) then KibsItemLevelConfig.upgrades = true; cleanUp(); else KibsItemLevelConfig.upgrades = false; cleanUp(); end end)
	
	local b2 = CreateFrame("CheckButton","Char",ConfigPanel,"UICheckButtonTemplate");
	b2:SetPoint("TOPLEFT",b1,"BOTTOMLEFT",0,0);
	b2:SetChecked(KibsItemLevelConfig.Character);
	_G[b2:GetName() .. "Text"]:SetText("Show on Character Sheet");
	b2:SetScript("OnClick", function(self, button, isDown) if ( self:GetChecked() ) then KibsItemLevelConfig.Character = true; cleanUp(); else KibsItemLevelConfig.Character = false; cleanUp(); end end)
	
	local b3 = CreateFrame("CheckButton","Insp",ConfigPanel,"UICheckButtonTemplate");
	b3:SetPoint("TOPLEFT",b2,"BOTTOMLEFT",0,0);
	b3:SetChecked(KibsItemLevelConfig.Inspection);
	_G[b3:GetName() .. "Text"]:SetText("Show on Inspection Frame");
	b3:SetScript("OnClick", function(self, button, isDown) if ( self:GetChecked() ) then KibsItemLevelConfig.Inspection = true; cleanUp(); else KibsItemLevelConfig.Inspection = false; cleanUp(); end end)
	
	
	cleanUp();
	
	InterfaceOptions_AddCategory(ConfigPanel);
end

function cleanUp()
	
	--No need to clean up anymore. It is now done per-item when needed.

	--for i = 1, 17 do
		--if(FontStrings[i])then
			--FontStrings[i]:SetText("");
			--EnchantIcons[i].texture:SetAlpha(0.0);
			--EnchantIcons[i]:SetScript("OnEnter",nil);
			
			--InspectFontStrings[i]:SetText("");
			--InspectEnchantIcons[i].texture:SetAlpha(0.0);
			--InspectEnchantIcons[i]:SetScript("OnEnter",nil);
			
		--	local slotID = (i - 1) * 3 + 1;
		--	for j = slotID, slotID + 2 do
				--Icons[j].texture:SetAlpha(0.0);
				--Icons[j]:SetScript("OnEnter",nil);
				--InspectIcons[j].texture:SetAlpha(0.0);
				--InspectIcons[j]:SetScript("OnEnter",nil);
		--	end
		--end
	--end
	
	eventHandler(self,"PLAYER_EQUIPMENT_CHANGED");
end

function findItemInfo(who)
	if not (who) then
		return
	end
	
	if (who == "player") then
		ActiveFontStrings = FontStrings;
		ActiveIcons = Icons;
		ActiveEnchantIcons = EnchantIcons;
		UpdateInProgress = false;
	else
		ActiveFontStrings = InspectFontStrings;
		ActiveIcons = InspectIcons;
		ActiveEnchantIcons = InspectEnchantIcons;
		UpdateInProgressInspect = false;
	end
	
	local tilvl = 0;
	local numItems = 16;
	
	GameTooltip:Hide();
	
	for i = 1, 18 do
		
		if (ActiveFontStrings[i]) then
			local itemlink = GetInventoryItemLink(who,i)
			
			if (itemlink) then
			
				if(i == 17) then
					numItems = numItems + 1;
				end
				
				GameTooltip:SetOwner(ilvlFrame,"CENTER");
				GameTooltip:SetHyperlink(itemlink);
				
				--Find Enchants
				if(enchantableItems[i]) then
					getEnchant(itemlink, i);
				end
				
				--Find Gems
				findSockets(who,i);
				
				--Find ilvl
				local upgrade, max, delta = ItemUpgradeInfo:GetItemUpgradeInfo(itemlink)
				local ilvl = ItemUpgradeInfo:GetUpgradedItemLevel(itemlink)
				if not(ilvl) then 
					ilvl = 0;
				end
				
				if (ilvl == 1) then
					ilvl = findHeirloomilvl();
				end
				
				if (upgrade and KibsItemLevelConfig.upgrades) then
					ActiveFontStrings[i]:SetText(ilvl .." ("..upgrade.."/"..max..")")
				else
					ActiveFontStrings[i]:SetText(ilvl)
				end
				
				if(ilvl)then
					tilvl = tilvl + ilvl;
				end
				
			else
				if(FontStrings[i])then
					ActiveFontStrings[i]:SetText("");
					if (enchantableItems[i]) then
						ActiveEnchantIcons[i].texture:SetAlpha(0.0);
						ActiveEnchantIcons[i]:SetScript("OnEnter",nil);
					end
					local slotID = (i - 1) * 3 + 1;
					for j = slotID, slotID + 2 do
						ActiveIcons[j].texture:SetAlpha(0.0);
						ActiveIcons[j]:SetScript("OnEnter",nil);
					end
				end
			end
		end
	end
	
	if(who ~= "player") then
		InspectAilvl:SetText("ilvl: "..math.floor((tilvl / numItems) * 100) * 0.01);
	else
		ilvlPlayerFrame:SetText("ilvl: ".. math.floor((tilvl / numItems) * 100) * 0.01);
	end
	
	GameTooltip:Hide();
end

function getEnchant(itemlink, i)

	local found, _, ItemSubString = string.find(ItemLink, "^|c%x+|H(.+)|h%[.*%]");
	local ItemSubStringTable = {}

	for v in string.gmatch(ItemSubString, "[^:]+") do tinsert(ItemSubStringTable, v); end
	ItemSubString = ItemSubStringTable[2]..":"..ItemSubStringTable[3], ItemSubStringTable[2]
	local StringStart, StringEnd = string.find(ItemSubString, ":") 
	ItemSubString = string.sub(ItemSubString, StringStart + 1)
	hasEnchant = ItemSubString ~= "0"
	
	--Did we find any enchants?
	if hasEnchant then
		ActiveEnchantIcons[i].texture:SetTexture("INTERFACE/ICONS/INV_Jewelry_Talisman_08");
		ActiveEnchantIcons[i].texture:SetVertexColor(1.0, 1.0, 1.0, 1)
	else
		ActiveEnchantIcons[i].texture:SetVertexColor(1.0, 0.2, 0.2, 0.5)
	end
	
end

function findHeirloomilvl()
	local line = "";
	for i = 2, GameTooltip:NumLines() do
		line = _G[GameTooltip:GetName().."TextLeft"..i];
		if (line) then
			line = line:GetText();
			if (line) then
				if(line:match("Item Level")) then
					return tonumber(line:match("%d+"));
				end
			end
		end
	end	

end

function findSockets(who,slot)
	
	local itemLink = GetInventoryItemLink(who,slot);
	local _, _, Color, Ltype, itemID = string.find(itemLink, "|?c?f?f?(%x*)|?H?([^:]*):?(%d+):?(%d*):?(%d*):?(%d*):?(%d*):?(%d*):?(%-?%d*):?(%-?%d*):?(%d*):?(%d*)|?h?%[?([^%[%]]*)%]?|?h?|?r?")

	if (itemID) then
		--SOCKETS
		local _,cleanItemLink = GetItemInfo(itemID);
		if (cleanItemLink) then
			GameTooltip:ClearLines();
			GameTooltip:SetOwner(ilvlFrame,"CENTER");
			GameTooltip:SetHyperlink(cleanItemLink);
			local line;
			local texturePath;
			local GemSocketID = (slot - 1) * 3 + 1;
			local sockets = GemSocketID;
			
			for i = 1, 3 do
				ActiveIcons[i+GemSocketID-1].texture:SetAlpha(0.0);						
			end
			
			for i = 2, GameTooltip:NumLines() do
				line = _G[GameTooltip:GetName().."TextLeft"..i];
				if (line) then
					line = line:GetText();
					if (line) then
						if(line:find("Socket")) then
							texturePath = emptySockets[line:sub(1, line:find("Socket") - 1)];
							if (texturePath) then
								ActiveIcons[sockets].texture:SetTexture(""..texturePath);
								ActiveIcons[sockets].texture:SetAlpha(1.0);
								sockets = sockets + 1;
							end
						end
						--else if(line:find("Touched\"")) then --UNCOMMENT TO SUPPORT SHA-TOUCHED SOCKETS
							--ActiveIcons[sockets].texture:SetTexture("INTERFACE/ITEMSOCKETINGFRAME/UI-EMPTYSOCKET-HYDRAULIC");
							--ActiveIcons[sockets].texture:SetAlpha(1.0);
							--sockets = sockets + 1;
						--end
					end
				end
			end
			
			--GEMS
			for i = 1, 3 do
				local _, itemLink = GetItemGem(GetInventoryItemLink(who,slot),i);
				if (itemLink) then
					ActiveIcons[i+GemSocketID-1].texture:SetTexture(GetItemIcon(itemLink));
					ActiveIcons[i+GemSocketID-1].texture:SetAlpha(1.0);
					ActiveIcons[i+GemSocketID-1]:SetScript("OnEnter",function(s,m)
						GameTooltip:SetOwner(UIParent, "ANCHOR_CURSOR");
						GameTooltip:SetHyperlink(itemLink);
						GameTooltip:Show(); 
						end);
					ActiveIcons[i+GemSocketID-1]:SetScript("OnLeave",function(s,m)
						GameTooltip:Hide(); 
						end);
				end
			end
		end
	end
	
end

--Create Font Strings and Icons
function createFontStrings()
	local kids = { CharacterHeadSlot, CharacterNeckSlot, CharacterShoulderSlot, CharacterShirtSlot, CharacterChestSlot, CharacterWaistSlot, CharacterLegsSlot, CharacterFeetSlot, CharacterWristSlot, CharacterHandsSlot,
	 CharacterFinger0Slot, CharacterFinger1Slot, CharacterTrinket0Slot, CharacterTrinket1Slot, CharacterBackSlot, CharacterMainHandSlot, CharacterSecondaryHandSlot, CharacterRangedSlot };
	for i = 1, 18 do
		if not (i == 4) then --exclude 4 , shirt
			FontStrings[i] = kids[i]:CreateFontString("KILFrame_"..i, "OVERLAY", fontStyle)
			FontStrings[i]:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE")
			--FontStrings[i]:SetParent(PaperDollItemsFrame)
			FontStrings[i]:SetText("")
			FontStrings[i]:SetPoint("CENTER", kids[i], 0, -1)
			
			
			local offset = 0;
			
			if(enchantableItems[i]) then
						
				EnchantIcons[i] = CreateFrame("Frame","EnchantIcon"..i,kids[i]);
				EnchantIcons[i]:SetPoint("TOPLEFT", kids[i], 1, -1);
				EnchantIcons[i]:SetSize(iconSize,iconSize);
						
				local texture = EnchantIcons[i]:CreateTexture("EnchantIconTex"..i,"OVERLAY");
				texture:SetAllPoints();
				EnchantIcons[i].texture = texture;
				EnchantIcons[i].texture:SetTexture("INTERFACE/ICONS/INV_Jewelry_Talisman_08");
				EnchantIcons[i].texture:SetAlpha(0.0);
			end
			
			local iconSlotID = (i-1) * 3 + 1;
			for j = iconSlotID, iconSlotID + 2 do
				Icons[j] = CreateFrame("Frame","GemIcon"..j,kids[i]);
				Icons[j]:SetPoint("BOTTOMLEFT", kids[i], 1 + offset, 1);
				Icons[j]:SetSize(iconSize,iconSize);
				local texture = Icons[j]:CreateTexture("GemIconTex"..j,"OVERLAY");
				texture:SetAllPoints();
				Icons[j].texture = texture;
				Icons[j].texture:SetTexture(emptySockets["Prismatic "]);
				Icons[j].texture:SetAlpha(0.0);
				offset = offset + iconOffset;
			end
		end
	end	

	ilvlPlayerFrame = CharacterModelFrame:CreateFontString("KIL_ilvlPlayer", "OVERLAY", fontStyle)
	ilvlPlayerFrame:SetFont("Fonts\\FRIZQT__.TTF", 14, "OUTLINE")
	ilvlPlayerFrame:SetPoint("BOTTOMRIGHT",PaperDollFrame,"TOPRIGHT",-82,-263)
	ilvlPlayerFrame:SetText("ilvl: 0")
end

--Create Font Strings and Icons for the Inspection Window
function createInspectFontStrings()
	local kids = { InspectHeadSlot, InspectNeckSlot, InspectShoulderSlot, InspectShirtSlot, InspectChestSlot, InspectWaistSlot, InspectLegsSlot, InspectFeetSlot, InspectWristSlot, InspectHandsSlot,
	InspectFinger0Slot, InspectFinger1Slot, InspectTrinket0Slot, InspectTrinket1Slot, InspectBackSlot, InspectMainHandSlot, InspectSecondaryHandSlot, InspectRangedSlot };
	for i = 1, 18 do
		if not (i == 4) then --exclude 4, shirt
			InspectFontStrings[i] = kids[i]:CreateFontString("KILFrame_"..i, "OVERLAY", fontStyle)
			InspectFontStrings[i]:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE")
			InspectFontStrings[i]:SetText("")
			InspectFontStrings[i]:SetPoint("CENTER", kids[i], 0, -1)
			
			
			local offset = 0;
			
			if(enchantableItems[i]) then
				--Offset gems to make space for enchants;
				offset = iconOffset
						
				InspectEnchantIcons[i] = CreateFrame("Frame","EnchantIcon"..i,kids[i]);
				InspectEnchantIcons[i]:SetPoint("TOPLEFT", kids[i], 1, -1);
				InspectEnchantIcons[i]:SetSize(iconSize,iconSize);
						
				local texture = InspectEnchantIcons[i]:CreateTexture("EnchantIconTex"..i,"OVERLAY");
				texture:SetAllPoints();
				InspectEnchantIcons[i].texture = texture;
				InspectEnchantIcons[i].texture:SetTexture("INTERFACE/ICONS/INV_Jewelry_Talisman_08");
				InspectEnchantIcons[i].texture:SetAlpha(0.0);
			end
			
			local iconSlotID = (i-1) * 3 + 1;
			for j = iconSlotID, iconSlotID + 2 do
				InspectIcons[j] = CreateFrame("Frame","GemIcon"..j,kids[i]);
				InspectIcons[j]:SetPoint("BOTTOMLEFT", kids[i], 1, 1);
				InspectIcons[j]:SetSize(iconSize,iconSize);
				local texture = InspectIcons[j]:CreateTexture("GemIconTex"..j,"OVERLAY");
				texture:SetAllPoints();
				InspectIcons[j].texture = texture;
				InspectIcons[j].texture:SetTexture(emptySockets["Prismatic "]);
				InspectIcons[j].texture:SetAlpha(0.0);
				
				offset = offset + iconOffset;
			end
		end
	end	
	
	InspectAilvl = InspectPaperDollFrame:CreateFontString("KILFrame_Inspect_Ailvl", "OVERLAY", fontStyle);
	InspectAilvl:SetFont("Fonts\\FRIZQT__.TTF", 14, "OUTLINE");
	InspectAilvl:SetText("ilvl: 0");
	InspectAilvl:SetPoint("BOTTOMRIGHT",InspectPaperDollFrame,"TOPRIGHT",-40,-430)
	
end



