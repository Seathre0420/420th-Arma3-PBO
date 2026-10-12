/*/
File: fn_getCompatiblePylonMags.sqf
Author:

	Quiksilver
	
Last Modified:
	
	15/05/2023 A3 2.12 by Quiksilver
	
Description:

	Get compatible pylon magazines restricted to the randomized loadout allowlist.
	Helicopters retain the existing anti-air ammo filter.
____________________________________________________/*/

params [
	['_type',0],
	['_vehicle',objNull,[objNull,'']],
	['_pylon',0]
];
if (_type isEqualTo 0) exitWith {
	private _allowedPylonMagazines = ['random_pylon_magazines_1'] call QS_data_listItems;
	private _compatiblePylonMagazines = _vehicle getCompatiblePylonMagazines _pylon;
	private _isHeli = _vehicle isKindOf 'Helicopter';
	private _isAllowedMagazine = {
		params ['_magazine'];
		if (!((toLowerANSI _magazine) in _allowedPylonMagazines)) exitWith {FALSE};
		if (!_isHeli) exitWith {TRUE};
		private _ammoText = QS_hashmap_configfile getOrDefaultCall [
			format ['cfgmagazines_%1_ammo',toLowerANSI _magazine],
			{getText (configFile >> 'CfgMagazines' >> _magazine >> 'ammo')},
			TRUE
		];
		!(['aa',_ammoText,FALSE] call (missionNamespace getVariable 'QS_fnc_inString'))
	};
	if (_pylon isNotEqualTo 0) then {
		_compatiblePylonMagazines = _compatiblePylonMagazines select {[_x] call _isAllowedMagazine};
	} else {
		_compatiblePylonMagazines = _compatiblePylonMagazines apply {
			_x select {[_x] call _isAllowedMagazine}
		};
	};
	_compatiblePylonMagazines
};
[]
