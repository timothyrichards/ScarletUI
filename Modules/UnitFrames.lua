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
        PlayerFrame:SetScale(playerFrame.scale)

        if not self.playerFrameEvenRegistered then
            self.playerFrameEvenRegistered = true

            mover:HookScript("OnMouseUp", function()
                ScarletUI:SetupTargetFrame(unitFramesModule)
            end)

            hooksecurefunc(PlayerFrame, "StopMovingOrSizing", function(_)
                if not PlayerFrame.mover.isMoving then
                    local point, _, relativePoint, offsetX, offsetY = PlayerFrame:GetPoint()

                    playerFrame.frameAnchor = ScarletUI:GetArrayIndex(ScarletUI.frameAnchors, point)
                    playerFrame.screenAnchor = ScarletUI:GetArrayIndex(ScarletUI.frameAnchors, relativePoint)
                    playerFrame.x = offsetX
                    playerFrame.y = offsetY

                    ScarletUI:RefreshMoverOptions()
                    ScarletUI:SetupTargetFrame(unitFramesModule)
                end
            end)
        end
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

    if not self.targetFrameEventRegistered then
        self.targetFrameEventRegistered = true

        hooksecurefunc(TargetFrame, "StopMovingOrSizing", function(_)
            if not TargetFrame.mover.isMoving then
                local point
                local relativePoint
                local offsetX
                local offsetY

                if not targetFrame.mirrorPlayerFrame then
                    point, _, relativePoint, offsetX, offsetY = TargetFrame:GetPoint()
                else
                    point = self:OppositeFrameAnchor(playerFrame.frameAnchor)
                    relativePoint = self:OppositeFrameAnchor(playerFrame.screenAnchor)
                    offsetX = playerFrame.x * -1
                    offsetY = playerFrame.y

                    ScarletUI:SetupTargetFrame(unitFramesModule)
                end

                targetFrame.frameAnchor = ScarletUI:GetArrayIndex(ScarletUI.frameAnchors, point)
                targetFrame.screenAnchor = ScarletUI:GetArrayIndex(ScarletUI.frameAnchors, relativePoint)
                targetFrame.x = offsetX
                targetFrame.y = offsetY

                ScarletUI:RefreshMoverOptions()
            end
        end)

        hooksecurefunc("TargetFrame_UpdateBuffsOnTop", function()
            targetFrame.buffsOnTop = TARGET_FRAME_BUFFS_ON_TOP;
        end)
    end

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
            TargetFrame:SetScale(targetFrame.scale)
        else
            TargetFrame:ClearAllPoints()
            TargetFrame:SetPoint(
                    self:OppositeFrameAnchor(playerFrame.frameAnchor),
                    UIParent,
                    self:OppositeFrameAnchor(playerFrame.screenAnchor),
                    playerFrame.x * -1,
                    playerFrame.y
            )
            TargetFrame:SetScale(playerFrame.scale)
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

        if not self.focusFrameEventRegistered then
            self.focusFrameEventRegistered = true

            hooksecurefunc(FocusFrame, "StopMovingOrSizing", function(_)
                if not FocusFrame.mover.isMoving then
                    local point, _, relativePoint, offsetX, offsetY = FocusFrame:GetPoint()

                    focusFrame.frameAnchor = ScarletUI:GetArrayIndex(ScarletUI.frameAnchors, point)
                    focusFrame.screenAnchor = ScarletUI:GetArrayIndex(ScarletUI.frameAnchors, relativePoint)
                    focusFrame.x = offsetX
                    focusFrame.y = offsetY

                    ScarletUI:RefreshMoverOptions()
                    ScarletUI:SetupTargetFrame(unitFramesModule)
                end
            end)

            hooksecurefunc("FocusFrame_UpdateBuffsOnTop", function()
                focusFrame.buffsOnTop = FOCUS_FRAME_BUFFS_ON_TOP;
            end)
        end

        if focusFrame.move then
            FocusFrame:ClearAllPoints()
            FocusFrame:SetPoint(
                    self.frameAnchors[focusFrame.frameAnchor],
                    UIParent,
                    self.frameAnchors[focusFrame.screenAnchor],
                    focusFrame.x,
                    focusFrame.y
            )
            FocusFrame:SetScale(focusFrame.scale)
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
            CastingBarFrame:SetScale(castBar.scale)
        end

        CastingBarFrame.settingsKey = "castBar"
        self:CreateMover(CastingBarFrame, castBar)

        if castBar.hide then
            CastingBarFrame:UnregisterAllEvents()
            CastingBarFrame:SetParent(self.hideFrameContainer)
        end
    end
end
