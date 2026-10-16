/* Run on the server in an isolated test mission, never a live mission.
 * Copy fn_aoDamageProtection.sqf into code/functions/ in that mission first.
 * No mission framework or mods are required (Nyx requires Tanks DLC assets).
 */
if (!isServer) exitWith {};
if ((missionNamespace getVariable ['QS_classicDamage_context',[-1,FALSE]]) # 1) exitWith {
	diag_log '[AO damage test] Refusing to replace an active AO';
};
QS_fnc_aoDamageProtection = compile preprocessFileLineNumbers 'code/functions/fn_aoDamageProtection.sqf';
private _failures = [];
private _assert = {
	params ['_ok','_label'];
	if (!_ok) then {_failures pushBack _label;};
	diag_log format ['[AO damage test] %1: %2',['FAIL','PASS'] select _ok,_label];
};
private _objects = [];
private _groups = [];
private _position = [worldSize / 2,worldSize / 2,0];
private _fn_man = {
	private _group = createGroup [EAST,TRUE];
	_groups pushBack _group;
	private _unit = _group createUnit ['O_Soldier_F',_position,[],0,'NONE'];
	_objects pushBack _unit;
	_unit
};
private _fn_vehicle = {
	params ['_class'];
	private _vehicle = createVehicle [_class,_position,[],20,'NONE'];
	_objects pushBack _vehicle;
	_vehicle
};
// Manually seed a locked epoch: proximity polling is tested separately with players.
missionNamespace setVariable ['QS_classicDamage_context',[1000000,TRUE,FALSE,_position],TRUE];
missionNamespace setVariable ['QS_classicDamage_entities',[]];
private _infantry = call _fn_man;
private _armor = ['O_APC_Wheeled_02_rcws_v2_F'] call _fn_vehicle;
private _armorGroup = createVehicleCrew _armor;
_groups pushBack _armorGroup;
_objects append (crew _armor);
private _mortar = ['O_Mortar_01_F'] call _fn_vehicle;
private _mortarGroup = createVehicleCrew _mortar;
_groups pushBack _mortarGroup;
_objects append (crew _mortar);
['REGISTER',[_infantry,_armor,_mortar],1000000] call QS_fnc_aoDamageProtection;
[!isDamageAllowed _infantry,'initial infantry protected'] call _assert;
[!isDamageAllowed _armor,'initial armor protected'] call _assert;
[!isDamageAllowed _mortar,'static weapon protected'] call _assert;
[{isDamageAllowed _x} count (crew _armor) isEqualTo 0,'armor crew protected'] call _assert;
['ALLOW',_armor] call QS_fnc_aoDamageProtection;
[!isDamageAllowed _armor,'delayed spawn callback cannot unlock armor'] call _assert;
private _reinforcement = call _fn_man;
['REGISTER',[_reinforcement],1000000] call QS_fnc_aoDamageProtection;
[!isDamageAllowed _reinforcement,'reinforcement protected before unlock'] call _assert;

{
	private _vehicle = [_x] call _fn_vehicle;
	private _group = createVehicleCrew _vehicle;
	_groups pushBack _group;
	_objects append (crew _vehicle);
	['REGISTER',[_vehicle],1000000] call QS_fnc_aoDamageProtection;
	[isDamageAllowed _vehicle,format ['exempt hull: %1',_x]] call _assert;
	[{!isDamageAllowed _x} count (crew _vehicle) isEqualTo 0,format ['exempt operators: %1',_x]] call _assert;
	if (_x isEqualTo 'O_Heli_Light_02_dynamicLoadout_F') then {
		private _cargo = call _fn_man;
		_cargo moveInCargo _vehicle;
		['REGISTER',[_cargo],1000000] call QS_fnc_aoDamageProtection;
		[!isDamageAllowed _cargo,'aircraft cargo infantry still protected'] call _assert;
	};
} forEach ['O_APC_Tracked_02_AA_F','O_T_APC_Tracked_02_AA_ghex_F','I_LT_01_AA_F','O_Heli_Light_02_dynamicLoadout_F','O_Plane_CAS_02_dynamicLoadout_F'];
private _commander = call _fn_man;
missionNamespace setVariable ['QS_csatCommander',_commander,TRUE];
_commander allowDamage FALSE;
private _tower = ['Land_TTowerBig_1_F'] call _fn_vehicle;
_tower allowDamage FALSE;
['REGISTER',[_commander,_tower],1000000] call QS_fnc_aoDamageProtection;
[!(['LOCKED',_commander] call QS_fnc_aoDamageProtection),'commander excluded from new protection'] call _assert;

['UNLOCK'] call QS_fnc_aoDamageProtection;
[isDamageAllowed _infantry && {isDamageAllowed _armor} && {isDamageAllowed _mortar} && {isDamageAllowed _reinforcement},'unlock releases tracked forces'] call _assert;
[!isDamageAllowed _commander && {!isDamageAllowed _tower},'commander/tower original protection retained'] call _assert;
private _late = call _fn_man;
['REGISTER',[_late],1000000] call QS_fnc_aoDamageProtection;
[isDamageAllowed _late,'reinforcements remain vulnerable after unlock'] call _assert;
[!(['TICK',objNull,1000000] call QS_fnc_aoDamageProtection),'unlocked monitor ends permanently'] call _assert;

['STOP'] call QS_fnc_aoDamageProtection;
missionNamespace setVariable ['QS_classicDamage_context',[1000001,TRUE,FALSE,_position],TRUE];
['REGISTER',[_infantry],1000001] call QS_fnc_aoDamageProtection;
[!isDamageAllowed _infantry,'next AO resets protection'] call _assert;
['LOCAL',_infantry,1000000] call QS_fnc_aoDamageProtection;
[!isDamageAllowed _infantry,'stale previous-AO callback cannot unlock current unit'] call _assert;
['REGISTER',[_late],1000000] call QS_fnc_aoDamageProtection;
[isDamageAllowed _late,'stale spawn cannot join current AO'] call _assert;
['STOP'] call QS_fnc_aoDamageProtection;
[isDamageAllowed _infantry,'STOP releases before Defend'] call _assert;
private _defender = call _fn_man;
['REGISTER',[_defender],1000001] call QS_fnc_aoDamageProtection;
[isDamageAllowed _defender,'Defend cannot register with retired AO epoch'] call _assert;

// Simulate the recycler removing metadata, then a stale release arriving.
_infantry setVariable ['QS_classicDamage_epoch',nil,TRUE];
_infantry setVariable ['QS_classicDamage_protected',nil,TRUE];
_infantry allowDamage FALSE;
['LOCAL',_infantry,1000001] call QS_fnc_aoDamageProtection;
[!isDamageAllowed _infantry,'stale release preserves recycled unit new damage policy'] call _assert;
['ALLOW',_infantry,1000001] call QS_fnc_aoDamageProtection;
[!isDamageAllowed _infantry,'stale spawn timer preserves recycled unit new damage policy'] call _assert;
{if (!isNull _x) then {deleteVehicle _x;};} forEach _objects;
{if (!isNull _x) then {deleteGroup _x;};} forEach _groups;
missionNamespace setVariable ['QS_csatCommander',nil,TRUE];
diag_log format ['[AO damage test] FINISHED: %1 failures: %2',count _failures,_failures];
