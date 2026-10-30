/*
Author: 

	Quiksilver
	
Last modified:

	12/04/2014

Description:

	Delete enemies.
___________________________________________*/

{
    if (_x isEqualType grpNull) then {
        {
			if ((vehicle _x) isNotEqualTo _x) then {
                deleteVehicle (['CONTEXT',(vehicle _x),'MISSION_CLEANUP','fn_smDelete.sqf:19',[]] call QS_fnc_vehicleDespawnLog);
            };
            deleteVehicle (['CONTEXT',_x,'MISSION_CLEANUP','fn_smDelete.sqf:21',[]] call QS_fnc_vehicleDespawnLog);
        } forEach (units _x);
    } else {
        if ((vehicle _x) isNotEqualTo _x) then {
            deleteVehicle (['CONTEXT',(vehicle _x),'MISSION_CLEANUP','fn_smDelete.sqf:25',[]] call QS_fnc_vehicleDespawnLog);
        };
        if !(_x isKindOf 'CAManBase') then {
			deleteVehicleCrew _x;
        };
        deleteVehicle (['CONTEXT',_x,'MISSION_CLEANUP','fn_smDelete.sqf:30',[]] call QS_fnc_vehicleDespawnLog);
    };
} forEach (_this # 0);