ScarletUI.raidProfile = {
    useClassColors = true,
    displayBorder = false,
    displayPowerBar = true,
    displayOnlyDispellableDebuffs = true,
    displayMainTankAndAssist = false,
    healthText = 'perc',
    frameHeight = 46,
    frameWidth = 90,
}

function ScarletUI:SetupUnitFrames()
    local unitFramesModule = self.db.global.unitFramesModule
    if not unitFramesModule.enabled or self.lightWeightMode or self.retail then
        return
    end

    self:SetupPlayerFrame(unitFramesModule)
    self:SetupTargetFrame(unitFramesModule)
    self:SetupFocusFrame(unitFramesModule)
end

function ScarletUI:SetupPlayerFrame(unitFramesModule)
    local playerFrame = unitFramesModule.playerFrame
    if not playerFrame.move then
        return
    end

    self:CreateMover(PlayerFrame, playerFrame)
    PlayerFrame:SetMovable(true)
    PlayerFrame:SetUserPlaced(true)
    PlayerFrame:ClearAllPoints()
    PlayerFrame:SetPoint(
            self.frameAnchors[playerFrame.frameAnchor],
            UIParent,
            self.frameAnchors[playerFrame.screenAnchor],
            playerFrame.x,
            playerFrame.y
    )
end

function ScarletUI:SetupTargetFrame(unitFramesModule)
    local playerFrame = unitFramesModule.playerFrame
    local targetFrame = unitFramesModule.targetFrame
    if not targetFrame.move then
        return
    end

    self:CreateMover(TargetFrame, targetFrame)
    TargetFrame:SetMovable(true)
    TargetFrame:SetUserPlaced(true)
    TargetFrame:ClearAllPoints()
    TargetFrame.buffsOnTop = true
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
    if not focusFrame.move then
        return
    end

    if FocusFrame then
        FocusFrame:SetMovable(true)
        FocusFrame:SetUserPlaced(true)
        FocusFrame:ClearAllPoints()
        FocusFrame:SetPoint(
                self.frameAnchors[focusFrame.frameAnchor],
                UIParent,
                self.frameAnchors[focusFrame.screenAnchor],
                focusFrame.x,
                focusFrame.y
        )
        self:CreateMover(FocusFrame, focusFrame)
    end
end
