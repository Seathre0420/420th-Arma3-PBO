if (is3DEN) exitWith {};
addMissionEventHandler ['EntityCreated',{
    // EntityCreated supplies the object directly. params also accepts that
    // single argument; indexing _this assumes an array and fails on creation.
    params ['_entity'];
    [_entity] call TGC_fnc_addDamageProtection;
}];
addMissionEventHandler ['EntityRespawned',{
    params ['_newEntity','_oldEntity'];
    [_newEntity] call TGC_fnc_addDamageProtection;
}];
[] spawn {
    while {true} do {
        {[_x] call TGC_fnc_addDamageProtection} forEach (vehicles + allUnits + (agents apply {agent _x}));
        uiSleep 1;
    };
};
