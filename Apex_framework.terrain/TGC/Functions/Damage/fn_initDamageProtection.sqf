if (is3DEN) exitWith {};
addMissionEventHandler ['EntityCreated',{[_this # 0] call TGC_fnc_addDamageProtection}];
addMissionEventHandler ['EntityRespawned',{[_this # 0] call TGC_fnc_addDamageProtection}];
[] spawn {
    while {true} do {
        {[_x] call TGC_fnc_addDamageProtection} forEach (vehicles + allUnits + (agents apply {agent _x}));
        uiSleep 1;
    };
};
