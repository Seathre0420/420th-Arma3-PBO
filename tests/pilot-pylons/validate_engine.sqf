/* Run on the server after mission initialization in a disposable local session. */
if (!isServer) exitWith {['Run the pilot pylon harness on the server.']};
private _failures = [];
private _aaSeen = 0;
private _forbiddenSeen = 0;
private _fuelTanks = ['PylonFuelTank_UH80','PylonFuelTank_UH80_Green','PylonFuelTank_UH80_Tropic','PylonFuelTank_UH80_Sand'];
private _fuelTanksSeen = [];
// Independent expected set for these vanilla aircraft, not the runtime classifier.
private _aaMagazines = [
	'PylonMissile_1Rnd_AAA_missiles','PylonRack_1Rnd_AAA_missiles',
	'PylonMissile_1Rnd_GAA_missiles','PylonRack_1Rnd_GAA_missiles',
	'PylonMissile_1Rnd_Missile_AA_03_F','PylonRack_1Rnd_Missile_AA_03_F',
	'PylonMissile_1Rnd_Missile_AA_04_F','PylonRack_1Rnd_Missile_AA_04_F',
	'PylonMissile_Missile_AA_R73_x1','PylonMissile_Missile_AA_R77_x1',
	'PylonMissile_Missile_AA_R77_INT_x1',
	'PylonMissile_Missile_BIM9X_x1','PylonRack_Missile_BIM9X_x1','PylonRack_Missile_BIM9X_x2',
	'PylonMissile_Missile_AMRAAM_C_x1','PylonRack_Missile_AMRAAM_C_x1','PylonRack_Missile_AMRAAM_C_x2',
	'PylonMissile_Missile_AMRAAM_D_x1','PylonMissile_Missile_AMRAAM_D_INT_x1',
	'PylonRack_Missile_AMRAAM_D_x1','PylonRack_Missile_AMRAAM_D_x2'
] apply {toLowerANSI _x};
private _check = {
	params ['_condition','_message'];
	if (!_condition) then {
		_failures pushBack _message;
		diag_log format ['[QS PILOT PYLONS] FAIL: %1',_message];
	};
};
private _pilot = createAgent ['B_Helipilot_F',[0,0,0],[],0,'NONE'];
{
	private _aircraft = createVehicleLocal [_x,[0,0,1000],[],0,'NONE'];
	_pilot moveInDriver _aircraft;
	private _nativeWeapons = weapons _aircraft;
	private _nativeAmmo = (magazinesAllTurrets [_aircraft,TRUE]) select {
		(getText (configFile >> 'CfgMagazines' >> (_x # 0) >> 'pylonWeapon')) isEqualTo ''
	};
	private _compatible = _aircraft getCompatiblePylonMagazines 0;
	private _cases = [];
	{
		private _index = _forEachIndex + 1;
		{_cases pushBack [_index,_x];} forEach _x;
	} forEach _compatible;
	// Also exercise a forced gun pod and bomb on a potentially incompatible pylon.
	_cases append [[1,'PylonWeapon_300Rnd_20mm_shells'],[1,'PylonMissile_1Rnd_Bomb_04_F']];
	{
		_x params ['_index','_magazine'];
		private _expectedAA = ((toLowerANSI _magazine) in _aaMagazines) &&
			{_magazine in (_compatible # (_index - 1))};
		private _expectedTank = (_magazine in _fuelTanks) && {_magazine in (_compatible # (_index - 1))};
		private _expectedAllowed = _expectedAA || _expectedTank;
		if (_expectedTank) then {_fuelTanksSeen pushBackUnique _magazine;};
		if (_expectedAA) then {_aaSeen = _aaSeen + 1;};
		if (!_expectedAllowed) then {_forbiddenSeen = _forbiddenSeen + 1;};
		{
			_pilot setVariable ['QS_unit_role',_x];
			_aircraft setPylonLoadout [_index,_magazine,TRUE,[-1]];
			private _beforeAmmo = _aircraft ammoOnPylon _index;
			private _beforeFuel = fuel _aircraft;
			[_aircraft] call QS_fnc_restrictPilotPylons;
			private _after = (getPylonMagazines _aircraft) # (_index - 1);
			private _expected = ['',_magazine] select _expectedAllowed;
			[_after isEqualTo _expected,format ['%1 %2: %3',typeOf _aircraft,_x,_magazine]] call _check;
			if (_expectedAllowed) then {
				[(_aircraft ammoOnPylon _index) isEqualTo _beforeAmmo,'Retained pylon ammunition/count unchanged'] call _check;
			};
			if (_expectedTank) then {
				[(fuel _aircraft) isEqualTo _beforeFuel,'Retained fuel tank does not change fuel level'] call _check;
			};
		} forEach ['pilot_heli','pilot_heli_WL','pilot_logistics_WL'];
		{
			_pilot setVariable ['QS_unit_role',_x];
			_aircraft setPylonLoadout [_index,_magazine,TRUE,[-1]];
			private _before = getPylonMagazines _aircraft;
			[([_aircraft] call QS_fnc_restrictPilotPylons) isEqualTo 0,'Unrestricted role removes nothing'] call _check;
			[(getPylonMagazines _aircraft) isEqualTo _before,format ['Unrestricted role %1 retains loadout',_x]] call _check;
		} forEach ['pilot_attack_WL','pilot_plane','rifleman'];
		// Spawn Menu policy applies to the requester, even before boarding.
		moveOut _pilot;
		{
			_aircraft setPylonLoadout [_index,_magazine,TRUE,[-1]];
			[_aircraft,_x] call QS_fnc_restrictPilotPylons;
			private _expected = ['',_magazine] select _expectedTank;
			[((getPylonMagazines _aircraft) # (_index - 1)) isEqualTo _expected,
				format ['Spawn %1: %2 (AA also cleared)',_x,_magazine]] call _check;
		} forEach ['pilot_heli','pilot_heli_WL','pilot_logistics_WL'];
		{
			_aircraft setPylonLoadout [_index,_magazine,TRUE,[-1]];
			private _before = getPylonMagazines _aircraft;
			[_aircraft,_x] call QS_fnc_restrictPilotPylons;
			[(getPylonMagazines _aircraft) isEqualTo _before,
				format ['Unrestricted spawn %1 retains loadout',_x]] call _check;
		} forEach ['pilot_attack_WL','pilot_plane','staff'];
		_pilot moveInDriver _aircraft;
	} forEach _cases;
	{
		_aircraft setPylonLoadout [_forEachIndex + 1,'',TRUE];
	} forEach _compatible;
	_pilot setVariable ['QS_unit_role','pilot_heli'];
	[([_aircraft] call QS_fnc_restrictPilotPylons) isEqualTo 0,'Empty pylons are safe'] call _check;
	[(_nativeWeapons - (weapons _aircraft)) isEqualTo [],'Existing weapon classes preserved'] call _check;
	private _afterNativeAmmo = (magazinesAllTurrets [_aircraft,TRUE]) select {
		(getText (configFile >> 'CfgMagazines' >> (_x # 0) >> 'pylonWeapon')) isEqualTo ''
	};
	[_nativeAmmo isEqualTo _afterNativeAmmo,'Native ammunition preserved'] call _check;
	moveOut _pilot;
	deleteVehicle _aircraft;
} forEach ['B_Heli_Light_01_dynamicLoadout_F','B_Heli_Attack_01_dynamicLoadout_F','B_Plane_Fighter_01_F','B_Heli_Transport_01_pylons_F'];
deleteVehicle _pilot;
[_aaSeen > 0,'Compatible AA magazines were exercised'] call _check;
[_forbiddenSeen > 0,'Forbidden magazines were exercised'] call _check;
[(count _fuelTanksSeen) isEqualTo 4,'All four compatible fuel-tank variants were exercised'] call _check;
diag_log format ['[QS PILOT PYLONS] %1 failures; %2 AA, %3 forbidden cases, %4 tank variants',count _failures,_aaSeen,_forbiddenSeen,count _fuelTanksSeen];
_failures
