/*
Function: TGC_fnc_staffForceRiflemanGUI

Description:
    Select a connected player and immediately change their role to Rifleman.
*/
disableSerialization;
if (dialog) exitWith {};
if (!call TGC_fnc_isStaff) exitWith {};

playSoundUI ["click"];
with uiNamespace do {
    createDialog "RscDisplayEmpty";
    private _display = findDisplay -1;

    private _primaryColor = ["GUI", "BCG_RGB"] call BIS_fnc_displayColorGet;
    private _scaleToGroup = {_this vectorMultiply [_width, _height, _width, _height]};

    private _group = _display ctrlCreate ["RscControlsGroup", -1];
    _group ctrlSetPosition [safeZoneX + 0.3 * safeZoneW, safeZoneY + 0.25 * safeZoneH, 0.4 * safeZoneW, 0.5 * safeZoneH];
    _group ctrlCommit 0;
    ctrlPosition _group params ["_groupX", "_groupY", "_width", "_height"];

    private _frame = _display ctrlCreate ["RscText", -1, _group];
    _frame ctrlSetPosition ([0, 0, 1, 1] call _scaleToGroup);
    _frame ctrlSetBackgroundColor [0, 0, 0, 0.4];
    _frame ctrlEnable false;
    _frame ctrlCommit 0;

    private _title = _display ctrlCreate ["RscText", -1, _group];
    _title ctrlSetPosition ([0, 0, 1, 0.07] call _scaleToGroup);
    _title ctrlSetBackgroundColor _primaryColor;
    _title ctrlSetText "Change Player Role to Rifleman";
    _title ctrlEnable false;
    _title ctrlCommit 0;

    private _list = _display ctrlCreate ["RscListbox", 8600, _group];
    _list ctrlSetPosition ([0.05, 0.11, 0.9, 0.67] call _scaleToGroup);
    _list ctrlCommit 0;
    _list ctrlAddEventHandler ["LBSelChanged", {
        params ["_list", "_selection"];
        ((ctrlParent _list) displayCtrl 8601) ctrlEnable (_selection >= 0);
    }];

    private _change = _display ctrlCreate ["RscButtonMenu", 8601, _group];
    _change ctrlSetPosition ([0.05, 0.84, 0.4, 0.08] call _scaleToGroup);
    _change ctrlSetText "Change Role";
    _change ctrlEnable false;
    _change ctrlCommit 0;
    _change ctrlAddEventHandler ["ButtonClick", {
        params ["_button"];
        private _list = (ctrlParent _button) displayCtrl 8600;
        private _selection = lbCurSel _list;
        if (_selection < 0) exitWith {};
        private _uid = _list lbData _selection;
        if (_uid isEqualTo "") exitWith {};
        [_uid] remoteExecCall ["TGC_fnc_forceRiflemanRole", 2, false];
        closeDialog 1;
    }];

    private _back = _display ctrlCreate ["RscButtonMenu", -1, _group];
    _back ctrlSetPosition ([0.6, 0.84, 0.35, 0.08] call _scaleToGroup);
    _back ctrlSetText "BACK";
    _back ctrlCommit 0;
    _back ctrlAddEventHandler ["ButtonClick", {
        closeDialog 1;
        0 spawn {isNil TGC_fnc_staffGUI};
    }];

    private _close = _display ctrlCreate ["RscButtonMenu", 2];
    _close ctrlSetPosition [_groupX, _groupY + _height, 0.2, 0.04];
    _close ctrlSetText toUpper localize "$str_disp_cancel";
    _close ctrlCommit 0;

    _display spawn {
        disableSerialization;
        private _display = _this;
        private _list = _display displayCtrl 8600;
        private _roster = [];
        while {!isNull _display} do {
            private _players = [];
            {
                private _uid = getPlayerUID _x;
                if (isPlayer _x && {_uid isNotEqualTo ""} && {!(_x isKindOf "HeadlessClient_F")}) then {
                    _players pushBack [name _x, _uid];
                };
            } forEach allPlayers;
            _players sort true;
            if (_players isNotEqualTo _roster) then {
                private _selection = lbCurSel _list;
                private _selectedUID = if (_selection < 0) then {""} else {_list lbData _selection};
                lbClear _list;
                {
                    _x params ["_name", "_uid"];
                    private _index = _list lbAdd _name;
                    _list lbSetData [_index, _uid];
                    _list lbSetTooltip [_index, _uid];
                } forEach _players;
                _list lbSetCurSel (_players findIf {(_x # 1) isEqualTo _selectedUID});
                (_display displayCtrl 8601) ctrlEnable ((lbCurSel _list) >= 0);
                _roster = _players;
            };
            uiSleep 1;
        };
    };
};
