/*
Run locally in a disposable editor/Server Lab session after mission initialization.
See README.md in this test directory for setup. Does not require live aircraft.
*/
private _failures = [];
private _check = {
	params ['_condition','_message'];
	if (!_condition) then {
		_failures pushBack _message;
		diag_log format ['[QS PYLON TEST] FAIL: %1',_message];
	};
};
private _allowed = ['random_pylon_magazines_1'] call QS_data_listItems;
[(count _allowed) isEqualTo 35,'Expected 35 allowlisted magazines'] call _check;
private _requiredSeen = [];
private _required = [
	'pylonmissile_missile_agm_kh25_int_x1',
	'pylonmissile_missile_agm_kh25_x1',
	'pylonrack_1rnd_missile_agm_01_f',
	'pylonmissile_1rnd_mk82_f'
];
{
	private _aircraft = createVehicleLocal [_x,[0,0,1000],[],0,'NONE'];
	private _raw = _aircraft getCompatiblePylonMagazines 0;
	private _filtered = [0,_aircraft,0] call QS_fnc_getCompatiblePylonMags;
	[(count _raw) isEqualTo (count _filtered),format ['%1: pylon count preserved',_x]] call _check;
	{
		private _pylonIndex = _forEachIndex;
		private _rawPylon = _raw # _pylonIndex;
		private _single = [0,_aircraft,(_pylonIndex + 1)] call QS_fnc_getCompatiblePylonMags;
		[_single isEqualTo _x,format ['%1 pylon %2: single/all results agree',typeOf _aircraft,(_pylonIndex + 1)]] call _check;
		{
			private _magazine = _x;
			[_magazine in _rawPylon,format ['%1: compatible magazine %2',typeOf _aircraft,_magazine]] call _check;
			[(toLowerANSI _magazine) in _allowed,format ['%1: allowlisted magazine %2',typeOf _aircraft,_magazine]] call _check;
			if (_aircraft isKindOf 'Helicopter') then {
				private _ammo = getText (configFile >> 'CfgMagazines' >> _magazine >> 'ammo');
				[!(['aa',_ammo,FALSE] call QS_fnc_inString),format ['%1: helicopter AA filter for %2',typeOf _aircraft,_magazine]] call _check;
			};
		} forEach _x;
		{
			if ((toLowerANSI _x) in _required) then {
				[_x in _single,format ['%1: explicitly allowed weapon retained: %2',typeOf _aircraft,_x]] call _check;
				_requiredSeen pushBackUnique (toLowerANSI _x);
			};
		} forEach _rawPylon;
	} forEach _filtered;
	for '_attempt' from 1 to 8 do {
		[_aircraft,2,[]] call QS_fnc_vehicleLoadouts;
		{
			private _index = _forEachIndex;
			if (_x isNotEqualTo '') then {
				[(toLowerANSI _x) in _allowed,format ['%1: selected magazine is allowed: %2',typeOf _aircraft,_x]] call _check;
				[_x in (_filtered # _index),format ['%1: selected magazine stays compatible at pylon %2',typeOf _aircraft,(_index + 1)]] call _check;
			} else {
				[(_filtered # _index) isEqualTo [],format ['%1: eligible pylon %2 was filled',typeOf _aircraft,(_index + 1)]] call _check;
			};
		} forEach (getPylonMagazines _aircraft);
	};
	// Exercise a fully filtered-out set through the actual cached data provider.
	QS_hashmap_classLists set ['i_random_pylon_magazines_1',[]];
	[_aircraft,2,[]] call QS_fnc_vehicleLoadouts;
	private _emptyResult = getPylonMagazines _aircraft;
	QS_hashmap_classLists set ['i_random_pylon_magazines_1',_allowed];
	[(_emptyResult findIf {_x isNotEqualTo ''}) isEqualTo -1,format ['%1: no eligible weapons leaves every pylon empty',typeOf _aircraft]] call _check;
	deleteVehicle _aircraft;
} forEach [
	'B_Plane_CAS_01_dynamicLoadout_F',
	'O_Plane_CAS_02_dynamicLoadout_F',
	'O_Plane_Fighter_02_F',
	'I_Plane_Fighter_03_dynamicLoadout_F',
	'I_Plane_Fighter_04_F',
	'O_Heli_Attack_02_dynamicLoadout_F',
	'B_Heli_Light_01_dynamicLoadout_F',
	'B_Heli_Transport_01_F',
	'C_Plane_Civil_01_F'
];
{
	[_x in _requiredSeen,format ['Coverage for retained weapon %1',_x]] call _check;
} forEach _required;
diag_log format ['[QS PYLON TEST] Complete: %1 failures: %2',count _failures,_failures];
_failures
