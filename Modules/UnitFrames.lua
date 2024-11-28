function ScarletUI:SetupUnitFrames()
    local unitFramesModule = self.db.global.unitFramesModule
    if not unitFramesModule.enabled or self.lightWeightMode or self.retail then
        return
    end

    self:SetupPlayerFrame(unitFramesModule)
    self:SetupTargetFrame(unitFramesModule)
    self:SetupFocusFrame(unitFramesModule)
    self:SetupCastBar(unitFramesModule)
end

function ScarletUI:SetupPlayerFrame(unitFramesModule)
    local playerFrame = unitFramesModule.playerFrame
    local mover = self:CreateMover(PlayerFrame, playerFrame)

    if playerFrame.move then
        PlayerFrame:ClearAllPoints()
        PlayerFrame:SetPoint(
                self.frameAnchors[playerFrame.frameAnchor],
                UIParent,
                self.frameAnchors[playerFrame.screenAnchor],
                playerFrame.x,
                playerFrame.y
        )

        mover:HookScript("OnMouseUp", function()
            ScarletUI:SetupTargetFrame(unitFramesModule)
        end)
    end

    if playerFrame.hide then
        PlayerFrame:UnregisterAllEvents()
        PlayerFrame:SetParent(self.hideFrameContainer)
    end
end

function ScarletUI:SetupTargetFrame(unitFramesModule)
    local playerFrame = unitFramesModule.playerFrame
    local targetFrame = unitFramesModule.targetFrame

    TARGET_FRAME_BUFFS_ON_TOP = targetFrame.buffsOnTop;
    TargetFrame_UpdateBuffsOnTop();

    hooksecurefunc("TargetFrame_UpdateBuffsOnTop", function()
        targetFrame.buffsOnTop = TARGET_FRAME_BUFFS_ON_TOP;
    end)

    if targetFrame.move then
        if not targetFrame.mirrorPlayerFrame then
            TargetFrame:ClearAllPoints()
            TargetFrame:SetPoint(
                    self.frameAnchors[targetFrame.frameAnchor],
                    UIParent,
                    self.frameAnchors[targetFrame.screenAnchor],
                    targetFrame.x,
                    targetFrame.y
            )
        else
            TargetFrame:ClearAllPoints()
            TargetFrame:SetPoint(
                    self:OppositeFrameAnchor(playerFrame.frameAnchor),
                    UIParent,
                    self:OppositeFrameAnchor(playerFrame.screenAnchor),
                    unitFramesModule.playerFrame.x * -1,
                    unitFramesModule.playerFrame.y
            )
        end
    end

    self:CreateMover(TargetFrame, targetFrame, function()
        return not targetFrame.mirrorPlayerFrame
    end)

    if targetFrame.hide then
        TargetFrame:UnregisterAllEvents()
        TargetFrame:SetParent(self.hideFrameContainer)
    end
end

function ScarletUI:SetupFocusFrame(unitFramesModule)
    local focusFrame = unitFramesModule.focusFrame

    if FocusFrame then
        FOCUS_FRAME_BUFFS_ON_TOP = focusFrame.buffsOnTop;
        FocusFrame_UpdateBuffsOnTop();

        hooksecurefunc("FocusFrame_UpdateBuffsOnTop", function()
            focusFrame.buffsOnTop = FOCUS_FRAME_BUFFS_ON_TOP;
        end)

        if focusFrame.move then
            FocusFrame:ClearAllPoints()
            FocusFrame:SetPoint(
                    self.frameAnchors[focusFrame.frameAnchor],
                    UIParent,
                    self.frameAnchors[focusFrame.screenAnchor],
                    focusFrame.x,
                    focusFrame.y
            )
        end

        self:CreateMover(FocusFrame, focusFrame)
    end

    if focusFrame.hide then
        FocusFrame:UnregisterAllEvents()
        FocusFrame:SetParent(self.hideFrameContainer)
    end
end

function ScarletUI:SetupCastBar(unitFramesModule)
    local castBar = unitFramesModule.castBar

    if CastingBarFrame then
        if castBar.move then
            CastingBarFrame:ClearAllPoints()
            CastingBarFrame:SetPoint(
                    self.frameAnchors[castBar.frameAnchor],
                    UIParent,
                    self.frameAnchors[castBar.screenAnchor],
                    castBar.x,
                    castBar.y
            )
        end

        CastingBarFrame.settingsKey = "castBar"
        self:CreateMover(CastingBarFrame, castBar)

        if castBar.hide then
            CastingBarFrame:UnregisterAllEvents()
            CastingBarFrame:SetParent(self.hideFrameContainer)
        end
    end
end
