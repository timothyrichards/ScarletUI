-- Dialog to reload after addon settings are changed
StaticPopupDialogs['SCARLET_UI_RELOAD_DIALOG'] = {
    text = '<Scarlet UI>\n\nRequires a reload to properly configure your UI.',
    button1 = 'Reload',
    button2 = 'Close',
    OnAccept = function()
        ReloadUI()
    end,
    timeout = 0,
    whileDead = true,
    hideOnEscape = false,
    preferredIndex = 3,
}

-- Dialog to confirm restoration of default settings
StaticPopupDialogs['SCARLET_RESTORE_DEFAULTS_DIALOG'] = {
    text = '<Scarlet UI>\n\nAre you sure you want to restore all settings to default settings?',
    button1 = 'Confirm',
    button2 = 'Cancel',
    OnAccept = function()
        ScarletUI:ResetDefaults()
    end,
    timeout = 0,
    whileDead = true,
    hideOnEscape = false,
    preferredIndex = 3,
}