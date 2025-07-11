pfUI:RegisterModule("EliteOverlay", "vanilla:tbc", function()
  -- =============================================
  -- CONFIGURATION SETTINGS
  -- =============================================
  
  -- Dropdown options for unit frame dragon positioning
  pfUI.gui.dropdowns.EliteOverlay_positions = {
    "left:" .. T["Left"],   -- Display on the left side
    "right:" .. T["Right"], -- Display on the right side
    "off:" .. T["Disabled"] -- Disable the overlay
  }

  -- Dropdown options for nameplate dragon positioning
  pfUI.gui.dropdowns.EliteOverlayNameplate_positions = {
    "top:" .. T["Top"],     -- Display above the nameplate
    "left:" .. T["Left"],   -- Display on the left side
    "right:" .. T["Right"], -- Display on the right side
    "off:" .. T["Disabled"] -- Disable the overlay
  }

  -- =============================================
  -- ADDON PATH DETECTION
  -- =============================================
  
  -- Detect the correct addon path (supports different versions like -master, -tbc, -wotlk)
  local addonpath
  local tocs = { "", "-master", "-tbc", "-wotlk" }
  for _, name in pairs(tocs) do
    local current = string.format("pfUI-eliteoverlay%s", name)
    local _, title = GetAddOnInfo(current)
    if title then
      addonpath = "Interface\\AddOns\\" .. current
      break
    end
  end

  -- =============================================
  -- GUI CONFIGURATION (SETTINGS MENU)
  -- =============================================
  
  -- Create GUI settings (for newer pfUI versions)
  if pfUI.gui.CreateGUIEntry then
    pfUI.gui.CreateGUIEntry(
      T["Thirdparty"], T["Elite Overlay"], function()
        -- Dropdown for unit frame dragon position
        pfUI.gui.CreateConfig(
          pfUI.gui.UpdaterFunctions["target"], 
          T["Target: Dragon display position"], 
          C.EliteOverlay, "position", "dropdown", 
          pfUI.gui.dropdowns.EliteOverlay_positions
        )
        
        -- Dropdown for nameplate dragon position
        pfUI.gui.CreateConfig(
          pfUI.gui.UpdaterFunctions["target"], 
          T["Nameplates: Skull display position"], 
          C.EliteOverlayNameplate, "position", "dropdown", 
          pfUI.gui.dropdowns.EliteOverlayNameplate_positions
        )
      end
    )
  else -- Fallback for older pfUI versions
    pfUI.gui.tabs.thirdparty.tabs.EliteOverlay = pfUI.gui.tabs.thirdparty.tabs:CreateTabChild("EliteOverlay", true)
    pfUI.gui.tabs.thirdparty.tabs.EliteOverlay:SetScript("OnShow", function()
      if not this.setup then
        local CreateConfig = pfUI.gui.CreateConfig
        local update = pfUI.gui.update
        this.setup = true
      end
    end)
  end

  -- Set default position to right
  pfUI:UpdateConfig("EliteOverlay", nil, "position", "right")

  -- =============================================
  -- UNIT FRAME OVERLAY (DRAGON ICONS)
  -- =============================================
  
  -- Hook into the unit frame refresh function
  local HookRefreshUnit = pfUI.uf.RefreshUnit
  function pfUI.uf:RefreshUnit(unit, component)
    local pos = string.upper(C.EliteOverlay.position)  -- "LEFT" or "RIGHT"
    local invert = C.EliteOverlay.position == "right" and 1 or -1  -- Positioning modifier
    local unitstr = (unit.label or "") .. (unit.id or "")  -- e.g., "target", "focus"
    local size = unit:GetHeight() * 3  -- Scale dragon size based on frame height

    -- Create or reuse textures for the dragon icons
    unit.dragonTop = unit.dragonTop or unit:CreateTexture(nil, "OVERLAY")
    unit.dragonBottom = unit.dragonBottom or unit:CreateTexture(nil, "OVERLAY")

    -- Hide if disabled or invalid unit
    if unitstr == "" or C.EliteOverlay.position == "off" then
      unit.dragonTop:Hide()
      unit.dragonBottom:Hide()
    else
      -- Position the top dragon icon
      unit.dragonTop:ClearAllPoints()
      unit.dragonTop:SetWidth(size)
      unit.dragonTop:SetHeight(size)
      unit.dragonTop:SetPoint("TOP" .. pos, unit, "TOP" .. pos, invert == 1 and size * 0.2 or -size * 0.2, size * 0.385)
      unit.dragonTop:SetParent(unit.hp.bar)

      -- Position the bottom dragon icon
      unit.dragonBottom:ClearAllPoints()
      unit.dragonBottom:SetWidth(size)
      unit.dragonBottom:SetHeight(size)
      unit.dragonBottom:SetPoint("BOTTOM" .. pos, unit, "BOTTOM" .. pos, invert * size / 5.2, -size / 2.98)
      unit.dragonBottom:SetParent(unit.hp.bar)

      -- Apply different dragon styles based on unit classification
      local elite = UnitClassification(unitstr)
      if elite == "worldboss" then        -- Red dragons for world bosses
        unit.dragonTop:SetVertexColor(.85, .15, .15, 1)
        unit.dragonTop:SetTexture(addonpath .. "\\img\\TOP_GOLD_" .. pos)
        unit.dragonTop:Show()
        unit.dragonBottom:SetVertexColor(.85, .15, .15, 1)
        unit.dragonBottom:SetTexture(addonpath .. "\\img\\BOTTOM_GOLD_" .. pos)
        unit.dragonBottom:Show()
      elseif elite == "rareelite" then    -- Cyan dragons for rare elites
        unit.dragonTop:SetVertexColor(.8, 1, 1, 1)
        unit.dragonTop:SetTexture(addonpath .. "\\img\\TOP_GOLD_" .. pos)
        unit.dragonTop:Show()
        unit.dragonBottom:SetVertexColor(.8, 1, 1, 1)
        unit.dragonBottom:SetTexture(addonpath .. "\\img\\BOTTOM_GOLD_" .. pos)
        unit.dragonBottom:Show()
      elseif elite == "elite" then        -- Gold dragons for elites
        unit.dragonTop:SetVertexColor(1, 1, 1, 1)
        unit.dragonTop:SetTexture(addonpath .. "\\img\\TOP_GOLD_" .. pos)
        unit.dragonTop:Show()
        unit.dragonBottom:SetVertexColor(1, .6, 0, 1)
        unit.dragonBottom:SetTexture(addonpath .. "\\img\\BOTTOM_GOLD_" .. pos)
        unit.dragonBottom:Show()
      elseif elite == "rare" then         -- Gray dragons for rares
        unit.dragonTop:SetVertexColor(.8, .8, .8, 1)
        unit.dragonTop:SetTexture(addonpath .. "\\img\\TOP_GRAY_" .. pos)
        unit.dragonTop:Show()
        unit.dragonBottom:SetVertexColor(.8, .8, .8, 1)
        unit.dragonBottom:SetTexture(addonpath .. "\\img\\BOTTOM_GRAY_" .. pos)
        unit.dragonBottom:Show()
      else                                -- Hide for normal units
        unit.dragonTop:Hide()
        unit.dragonBottom:Hide()
      end
    end
    HookRefreshUnit(this, unit, component)  -- Call original function
  end

  -- =============================================
  -- NAMEPLATE OVERLAY (SKULL ICON)
  -- =============================================
  
  -- Set default nameplate position to right
  pfUI:UpdateConfig("EliteOverlayNameplate", nil, "position", "top")

  -- Hook into nameplate updates
  local HookRefreshNameplate = pfUI.nameplates.OnDataChanged
  function pfUI.nameplates:OnDataChanged(plate)
    local pos = string.upper(C.EliteOverlayNameplate.position)  -- "TOP", "LEFT", "RIGHT"
    local invert = C.EliteOverlay.position == "right" and 1 or -1
    local levelText = plate.level and plate.level:GetText() or ""  -- e.g., "63+", "??B"
	local isCasting = plate.castbar and plate.castbar:IsShown()
	local isRightPosition = C.EliteOverlayNameplate.position == "right"
    local size = 16  -- Fixed size for nameplate icons
    local texture = addonpath .. "\\img\\SKULL_GRAY"  -- Shared texture path

    -- Predefined offsets for different positions
    local presetOffsets = {
      TOP = { x = 0, y = 32 },    -- Above the nameplate
      LEFT = { x = -25, y = 13 }, -- Left side
      RIGHT = { x = 10, y = 0 }   -- Right side
    }

    -- Detect elite status from level text
    local elite
    if string.find(levelText, "??B") then
      elite = "worldboss"
    elseif string.find(levelText, "R+") then
      elite = "rareelite"
    elseif string.find(levelText, "+") then
      elite = "elite"
    elseif string.find(levelText, "R") == 1 then
      elite = "rare"
    end

    -- Create or reuse nameplate texture
    plate.EliteOverlayNameplate = plate.EliteOverlayNameplate or plate.health:CreateTexture(nil, "OVERLAY")

    -- Hide if disabled or not elite
    if C.EliteOverlayNameplate.position == "off" or not elite or (isCasting and isRightPosition) then
      plate.EliteOverlayNameplate:Hide()
    else
      -- Position the nameplate icon
      plate.EliteOverlayNameplate:ClearAllPoints()
      plate.EliteOverlayNameplate:SetWidth(size)
      plate.EliteOverlayNameplate:SetHeight(size)
      local anchorPoint = pos == "TOP" and "TOP" or pos  -- "TOP", "LEFT", or "RIGHT"
      plate.EliteOverlayNameplate:SetPoint(anchorPoint, plate.health, anchorPoint, presetOffsets[pos].x, presetOffsets[pos].y)
      plate.EliteOverlayNameplate:SetParent(plate.health)

      -- Apply color based on elite status
      if elite == "worldboss" then
        plate.EliteOverlayNameplate:SetVertexColor(.85, .15, .15, 1)  -- Red
        plate.EliteOverlayNameplate:SetTexture(texture)
        plate.EliteOverlayNameplate:Show()
      elseif elite == "rareelite" then
        plate.EliteOverlayNameplate:SetVertexColor(1, 1, 1, 1)  -- Gray
        plate.EliteOverlayNameplate:SetTexture(texture)
        plate.EliteOverlayNameplate:Show()
      elseif elite == "elite" then
        plate.EliteOverlayNameplate:SetVertexColor(.9, .7, 0, 1)  -- Gold
        plate.EliteOverlayNameplate:SetTexture(texture)
        plate.EliteOverlayNameplate:Show()
      elseif elite == "rare" then
        plate.EliteOverlayNameplate:SetVertexColor(.8, .8, .8, 1)  -- Darker Gray
        plate.EliteOverlayNameplate:SetTexture(texture)
        plate.EliteOverlayNameplate:Show()
      else
        plate.EliteOverlayNameplate:Hide()
      end
    end
    HookRefreshNameplate(this, plate)  -- Call original function
  end
end)