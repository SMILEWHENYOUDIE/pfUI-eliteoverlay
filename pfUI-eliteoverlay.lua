pfUI:RegisterModule(
    "EliteOverlay",
    "vanilla:tbc",
    function()
        pfUI.gui.dropdowns.EliteOverlay_positions = {
            "left:" .. T["Left"],
            "right:" .. T["Right"],
            "off:" .. T["Disabled"]
        }

        pfUI.gui.dropdowns.EliteOverlayNameplate_positions = {
			"top:" .. T["Top"],
            "left:" .. T["Left"],
            "right:" .. T["Right"],
            "off:" .. T["Disabled"]
        }

        -- detect current addon path
        local addonpath
        local tocs = {"", "-master", "-tbc", "-wotlk"}
        for _, name in pairs(tocs) do
            local current = string.format("pfUI-eliteoverlay%s", name)
            local _, title = GetAddOnInfo(current)
            if title then
                addonpath = "Interface\\AddOns\\" .. current
                break
            end
        end

        if pfUI.gui.CreateGUIEntry then -- new pfUI
            pfUI.gui.CreateGUIEntry(
                T["Thirdparty"],
                T["Elite Overlay"],
                function()
                    pfUI.gui.CreateConfig(
                        pfUI.gui.UpdaterFunctions["target"],
                        T["Target position"],
                        C.EliteOverlay,
                        "position",
                        "dropdown",
                        pfUI.gui.dropdowns.EliteOverlay_positions
                    )
                    pfUI.gui.CreateConfig(
                        pfUI.gui.UpdaterFunctions["target"],
                        T["Nameplate position"],
                        C.EliteOverlayNameplate,
                        "position",
                        "dropdown",
                        pfUI.gui.dropdowns.EliteOverlayNameplate_positions
                    )
                end
            )
        else -- old pfUI
            pfUI.gui.tabs.thirdparty.tabs.EliteOverlay =
                pfUI.gui.tabs.thirdparty.tabs:CreateTabChild("EliteOverlay", true)
            pfUI.gui.tabs.thirdparty.tabs.EliteOverlay:SetScript(
                "OnShow",
                function()
                    if not this.setup then
                        local CreateConfig = pfUI.gui.CreateConfig
                        local update = pfUI.gui.update
                        this.setup = true
                    end
                end
            )
        end

        pfUI:UpdateConfig("EliteOverlay", nil, "position", "right")
        pfUI:UpdateConfig("EliteOverlayNameplate", nil, "position", "top")

        local HookRefreshUnit = pfUI.uf.RefreshUnit
        function pfUI.uf:RefreshUnit(unit, component)
            local pos = string.upper(C.EliteOverlay.position)
            local invert = C.EliteOverlay.position == "right" and 1 or -1
            local unitstr = (unit.label or "") .. (unit.id or "")

            local size = unit:GetHeight() * 3
            local elite = UnitClassification(unitstr)

            unit.dragonTop = unit.dragonTop or unit:CreateTexture(nil, "OVERLAY")
            unit.dragonBottom = unit.dragonBottom or unit:CreateTexture(nil, "OVERLAY")

            if unitstr == "" or C.EliteOverlay.position == "off" then
                unit.dragonTop:Hide()
                unit.dragonBottom:Hide()
            else
                unit.dragonTop:ClearAllPoints()
                unit.dragonTop:SetWidth(size)
                unit.dragonTop:SetHeight(size)
                unit.dragonTop:SetPoint(
                    "TOP" .. pos,
                    unit,
                    "TOP" .. pos,
                    invert == 1 and size * 0.2 or -size * 0.2,
                    size * 0.385
                )
                unit.dragonTop:SetParent(unit.hp.bar)

                unit.dragonBottom:ClearAllPoints()
                unit.dragonBottom:SetWidth(size)
                unit.dragonBottom:SetHeight(size)
                unit.dragonBottom:SetPoint(
                    "BOTTOM" .. pos,
                    unit,
                    "BOTTOM" .. pos,
                    invert == 1 and size * 0.2 or -size * 0.2,
                    size * 0.385
                )
                unit.dragonBottom:SetParent(unit.hp.bar)

                if elite == "worldboss" then
                    unit.dragonTop:SetTexture(addonpath .. "\\img\\TOP_GOLD_" .. pos)
                    unit.dragonTop:Show()
                    unit.dragonTop:SetVertexColor(.85, .15, .15, 1)
                    unit.dragonBottom:SetTexture(addonpath .. "\\img\\BOTTOM_GOLD_" .. pos)
                    unit.dragonBottom:Show()
                    unit.dragonBottom:SetVertexColor(.85, .15, .15, 1)
                elseif elite == "rareelite" then
                    unit.dragonTop:SetTexture(addonpath .. "\\img\\TOP_GOLD_" .. pos)
                    unit.dragonTop:Show()
                    unit.dragonTop:SetVertexColor(.75, .6, 0, 1)
                    unit.dragonBottom:SetTexture(addonpath .. "\\img\\BOTTOM_GOLD_" .. pos)
                    unit.dragonBottom:Show()
                    unit.dragonBottom:SetVertexColor(1, 1, 1, 1)
                elseif elite == "elite" then
                    unit.dragonTop:SetTexture(addonpath .. "\\img\\TOP_GOLD_" .. pos)
                    unit.dragonTop:Show()
                    unit.dragonBottom:SetTexture(addonpath .. "\\img\\BOTTOM_GOLD_" .. pos)
                    unit.dragonBottom:Show()
                    unit.dragonBottom:SetVertexColor(1, 1, 1, 1)
                elseif elite == "rare" then
                    unit.dragonTop:SetTexture(addonpath .. "\\img\\TOP_GRAY_" .. pos)
                    unit.dragonTop:Show()
                    unit.dragonTop:SetVertexColor(.8, .8, .8, 1)
                    unit.dragonBottom:SetTexture(addonpath .. "\\img\\BOTTOM_GRAY_" .. pos)
                    unit.dragonBottom:Show()
                    unit.dragonBottom:SetVertexColor(.8, .8, .8, 1)
                else
                    unit.dragonTop:Hide()
                    unit.dragonBottom:Hide()
                end
            end

            HookRefreshUnit(this, unit, component)
        end

        -- Nameplates
        local HookRefreshNameplate = pfUI.nameplates.OnDataChanged
        function pfUI.nameplates:OnDataChanged(plate)
            local pos = string.upper(C.EliteOverlayNameplate.position)
            local levelText = plate.level and plate.level:GetText() or ""
            local hasEliteSymbol =
                string.find(levelText, "R") or string.find(levelText, "R%+") or string.find(levelText, "%+") or
                string.find(levelText, "%?%?B")

            local size = 22
            local image = addonpath .. "\\img\\NAMEPLATE"

            -- X, Y Offsets
            local presetOffsets = {
                TOP 	= {	x = 0, 		y = 35	},
                LEFT 	= {	x = -26,	y = 15	},
                RIGHT 	= {	x = 26,		y = 0	}
            }

            plate.EliteOverlayNameplate = plate.EliteOverlayNameplate or plate.health:CreateTexture(nil, "OVERLAY")

            if C.EliteOverlayNameplate.position == "off" or not hasEliteSymbol then
                plate.EliteOverlayNameplate:Hide()
            else
                plate.EliteOverlayNameplate:SetTexture(image)

                if plate.EliteOverlayNameplate:GetTexture() then
                    plate.EliteOverlayNameplate:ClearAllPoints()
                    plate.EliteOverlayNameplate:SetWidth(size)
                    plate.EliteOverlayNameplate:SetHeight(size)

                    -- Position based on preset
                    local anchorPoint = pos == "TOP" and "TOP" or pos -- "TOP" or "LEFT"/"RIGHT"
                    plate.EliteOverlayNameplate:SetPoint(
                        anchorPoint,
                        plate.health,
                        anchorPoint,
                        presetOffsets[pos].x,
                        presetOffsets[pos].y
                    )
                    plate.EliteOverlayNameplate:SetParent(plate.health)
                    plate.EliteOverlayNameplate:Show()
                else
                    plate.EliteOverlayNameplate:Hide()
                end
            end

            HookRefreshNameplate(self, plate)
        end
    end
)
