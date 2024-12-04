local IS_RETAIL = (WOW_PROJECT_ID == WOW_PROJECT_MAINLINE)

local BOOKTYPE_PET = BOOKTYPE_PET or Enum.SpellBookSpellBank.Pet
local GetSpellBookItemName = GetSpellBookItemName or C_SpellBook.GetSpellBookItemName

local GetActionInfo = _G.GetActionInfo
if (not IS_RETAIL) then
	-- Wrapper for GetActionInfo to make it behave in classic as it does in retail.
	GetActionInfo = function(slot)
		local actionType, id = _G.GetActionInfo(slot)
		return actionType, GetMacroSpell(id), nil
	end
end

local function GetPetSpellBookSlot(spellNameOrID)
	local spellInfo = C_Spell.GetSpellInfo(spellNameOrID)
	if (spellInfo) then
		local i = 1
		while (true) do
			local spellName, _, spellID = GetSpellBookItemName(i, BOOKTYPE_PET)
			if (not spellName) then
				break
			elseif (spellName == spellInfo.name) then
				return spellInfo.spellID
			end
			i = i + 1
		end
	end
	return nil
end

local ActionButton_ShowAutoCastOverlay
if (IS_RETAIL) then
	-- Retail
	ActionButton_ShowAutoCastOverlay = function(button, show)
		button.AutoCastOverlay:SetShown(show)
	end
else
	-- Classic
	ActionButton_ShowAutoCastOverlay = function(button, show)
		button.AutoCastable:SetShown(show)
	end
end

local ActionButton_ShowAutoCastEnabled
if (IS_RETAIL) then
	-- Retail
	ActionButton_ShowAutoCastEnabled = function(button, isEnabled)
		button.AutoCastOverlay:ShowAutoCastEnabled(isEnabled)
	end
else
	-- Classic
	ActionButton_ShowAutoCastEnabled = function(button, isEnabled)
		button.AutoCastShine:SetShown(isEnabled)
		if (isEnabled) then
			AutoCastShine_AutoCastStart(button.AutoCastShine)
		else
			AutoCastShine_AutoCastStop(button.AutoCastShine)
		end
	end
end

local function ActionButton_UpdateFlash(button)
    local actionType, id, subType = GetActionInfo(button.action)
	if (actionType == "macro" and id and (subType == nil or subType == "pet")) then
        local autoCastable, autoCastState

		local petSpellSlot = GetPetSpellBookSlot(id)
		if (petSpellSlot) then
			autoCastable, autoCastState = C_Spell.GetSpellAutoCast(petSpellSlot, BOOKTYPE_PET)
		end

		ActionButton_ShowAutoCastOverlay(button, autoCastable)
		ActionButton_ShowAutoCastEnabled(button, autoCastState)
	end
end

-- Initialization
if (IS_RETAIL) then
	local buttonNames = {
		"ActionButton",
		"MultiBarBottomLeftButton",
		"MultiBarBottomRightButton",
		"MultiBarLeftButton",
		"MultiBarRightButton",
		"MultiBar5Button",
		"MultiBar6Button",
		"MultiBar7Button",
	}
	for i = 1, #buttonNames do
		for j = 1, NUM_ACTIONBAR_BUTTONS do
			hooksecurefunc(_G[buttonNames[i]..j], "UpdateFlash", ActionButton_UpdateFlash)
		end
	end
else
	hooksecurefunc("ActionButton_UpdateFlash", ActionButton_UpdateFlash)
end