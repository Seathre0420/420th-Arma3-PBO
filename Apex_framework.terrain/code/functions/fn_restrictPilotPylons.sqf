/*
Keep compatible air-to-air missiles and the four UH-80 external fuel tanks while a transport/logistics pilot
occupies the driver seat. Run on each crew client; only the local turret owner
changes its pylons. Repeated calls also cover locality and role changes.
Optional spawn role clears default weapons (including AA) on the server before
the requester enters the aircraft, retaining compatible external fuel tanks.
*/
params [['_aircraft',objNull],['_spawnRole','']];
if (isNull _aircraft || {!(_aircraft isKindOf 'Air')}) exitWith {0};
private _isSpawn = _spawnRole isNotEqualTo '';
if (_isSpawn && {!isServer}) exitWith {0};
private _pilot = driver _aircraft;
private _role = if (_isSpawn) then {_spawnRole} else {_pilot getVariable ['QS_unit_role','']};
if (!((toLowerANSI _role) in ['pilot_heli','pilot_heli_WL','pilot_logistics_WL'])) exitWith {0};

private _removed = 0;
private _fuelTanks = [
	'pylonfueltank_uh80',
	'pylonfueltank_uh80_green',
	'pylonfueltank_uh80_tropic',
	'pylonfueltank_uh80_sand'
];
{
	_x params ['_index','','_turret','_magazine'];
	if ((_magazine isNotEqualTo '') && {_aircraft turretLocal _turret}) then {
		private _isAirToAir = QS_hashmap_configfile getOrDefaultCall [
			format ['cfgmagazines_%1_pilotAirToAir',toLowerANSI _magazine],
			{
				private _ammo = getText (configFile >> 'CfgMagazines' >> _magazine >> 'ammo');
				(_ammo isKindOf ['MissileCore',configFile >> 'CfgAmmo']) &&
				{(getNumber (configFile >> 'CfgAmmo' >> _ammo >> 'airLock')) isEqualTo 2}
			},
			TRUE
		];
		private _isFuelTank = (toLowerANSI _magazine) in _fuelTanks;
		private _isAllowed = _isFuelTank || {!_isSpawn && {_isAirToAir}};
		if (!_isAllowed || {!(_magazine in (_aircraft getCompatiblePylonMagazines _index))}) then {
			_aircraft setAmmoOnPylon [_index,0];
			_aircraft setPylonLoadout [_index,'',TRUE,_turret];
			_removed = _removed + 1;
		};
	};
} forEach (getAllPylonsInfo _aircraft);
// Do not remove weapon classes: a pylon can share one with a built-in gun.
// Clearing the pylon magazine removes its ammunition without touching native guns.
_removed
