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

function ScarletUI:SetupTargetFrame(unitFramesModule)
    local playerFrame = unitFramesModule.playerFrame
    local targetFrame = unitFramesModule.targetFrame

    self:CreateMover(TargetFrame, targetFrame, function()
        return not targetFrame.mirrorPlayerFrame
    end)
    TargetFrame.buffsOnTop = targetFrame.buffsOnTop;
    TargetFrame:ClearAllPoints()

    if not targetFrame.mirrorPlayerFrame then
        TargetFrame:SetPoint(
                self.frameAnchors[targetFrame.frameAnchor],
                UIParent,
                self.frameAnchors[targetFrame.screenAnchor],
                targetFrame.x,
                targetFrame.y
        )
    else
        TargetFrame:SetPoint(
                self:OppositeFrameAnchor(playerFrame.frameAnchor),
                UIParent,
                self:OppositeFrameAnchor(playerFrame.screenAnchor),
                unitFramesModule.playerFrame.x * -1,
                unitFramesModule.playerFrame.y
        )
    end
end

function ScarletUI:SetupFocusFrame(unitFramesModule)
    local focusFrame = unitFramesModule.focusFrame

    if FocusFrame then
        self:CreateMover(FocusFrame, focusFrame)
        FocusFrame.buffsOnTop = focusFrame.buffsOnTop;
        FocusFrame:ClearAllPoints()
        FocusFrame:SetPoint(
                self.frameAnchors[focusFrame.frameAnchor],
                UIParent,
                self.frameAnchors[focusFrame.screenAnchor],
                focusFrame.x,
                focusFrame.y
        )
    end
end

function ScarletUI:SetupCastBar(unitFramesModule)
    local castBar = unitFramesModule.castBar

    if CastingBarFrame then
        CastingBarFrame.settingsKey = "castBar"
        self:CreateMover(CastingBarFrame, castBar)
        CastingBarFrame:SetMovable(true)
        CastingBarFrame:SetUserPlaced(true)
        CastingBarFrame:ClearAllPoints()
        CastingBarFrame:SetPoint(
                self.frameAnchors[castBar.frameAnchor],
                UIParent,
                self.frameAnchors[castBar.screenAnchor],
                castBar.x,
                castBar.y
        )
    end
end
