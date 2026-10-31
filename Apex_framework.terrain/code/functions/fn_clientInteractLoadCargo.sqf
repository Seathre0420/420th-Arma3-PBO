/*/
File: fn_clientInteractLoadCargo.sqf
Author:

	Quiksilver
	
Last Modified:

	27/05/2023 A3 2.12 by Quiksilver
	
Description:

	Load Vehicle Cargo
_____________________________________________________________/*/

(_this # 3) params ['_child','_parent'];
params ['','','','',['_bypass',FALSE]];
if ((getPlayerUID player) in QS_blacklist_logistics) exitWith {
	50 cutText [localize 'STR_QS_Text_388','PLAIN',0.3];
};
if (_parent isEqualType []) then {
	_parent = _parent apply { [_x distance _child,_x] };
	_parent sort TRUE;
	_parent = (_parent # 0) # 1;
};
if (
	(!alive _parent) ||
	{(!alive _child)} || 
	{(_parent getVariable ['QS_logistics_wreck',FALSE])}
) exitWith {
	50 cutText [localize 'STR_QS_Text_116','PLAIN DOWN',0.5];
};
_displayName1 = QS_hashmap_configfile getOrDefaultCall [
	format ['cfgvehicles_%1_displayname',toLowerANSI (typeOf _child)],
	{(getText ((configOf _child) >> 'displayName'))},
	TRUE
];
_displayName2 = QS_hashmap_configfile getOrDefaultCall [
	format ['cfgvehicles_%1_displayname',toLowerANSI (typeOf _parent)],
	{(getText ((configOf _parent) >> 'displayName'))},
	TRUE
];
if (_child getVariable ['QS_logistics_immovable',FALSE]) exitWith {50 cutText [localize 'STR_QS_Text_335','PLAIN DOWN',0.25];};
private _canLoad = [_parent,_child] call QS_fnc_canVehicleCargo;
private _moveState = _child getVariable ['QS_cargoMove_state',[]];
private _protectedCarry = _moveState isNotEqualTo [] && {(_moveState # 4) isEqualTo QS_player} &&
	{(_moveState # 0) isEqualTo (QS_player getVariable ['QS_cargoMove_active',[]])} &&
	{!(_child getVariable ['QS_cargoMove_busy',FALSE])} &&
	{(attachedTo _child) in [QS_player,vehicle QS_player]};
if (_moveState isNotEqualTo [] && {!_protectedCarry}) exitWith {
	50 cutText [localize 'STR_QS_Text_444','PLAIN',0.3];
};
private _hiddenStorage = !(_canLoad # 1);
if (_hiddenStorage && {!_protectedCarry}) exitWith {
	_result = [nil,nil,nil,nil,_parent,_child] call QS_fnc_clientInteractLoad;
	if (!(_result)) then {
		50 cutText [format [localize 'STR_QS_Text_348',(_child getVariable ['QS_ST_customDN',_displayName1]),(_parent getVariable ['QS_ST_customDN',_displayName2])],'PLAIN DOWN',0.333];
	};
};
if ((!_hiddenStorage && {!(_canLoad # 0)}) ||
	{_hiddenStorage && {!([0,_child,_parent] call QS_fnc_getCustomCargoParams) ||
	{!([1,_child,_parent] call QS_fnc_getCustomCargoParams)}}}) exitWith {
	50 cutText [localize 'STR_QS_Text_349','PLAIN DOWN',0.333];
};
if (([_child,0] call QS_fnc_logisticsMovementDisallowed) && {(!_bypass) || {_protectedCarry}}) exitWith {
	50 cutText [localize 'STR_QS_Text_378','PLAIN',0.3];
};
// Legacy cargo includes configured classes/static weapons without QS_logistics.
// Only the current carry operation may use its saved simulation state.
private _temporaryFreeze = _protectedCarry && {_moveState # 1} && {
	(_child getVariable ['QS_logistics',FALSE]) || {[0,_child,_parent] call QS_fnc_getCustomCargoParams}
};
if (([_child,1] call QS_fnc_logisticsMovementDisallowed) && {!_temporaryFreeze} && {(!_bypass) || {_protectedCarry}}) exitWith {
	50 cutText [localize 'STR_QS_Text_444','PLAIN',0.3];
};
if (lockedInventory _parent || {_parent getVariable ['QS_lockedInventory',FALSE]}) exitWith {
	50 cutText [format ['%1 %2',(_parent getVariable ['QS_ST_customDN',_displayName2]),localize 'STR_QS_Text_380'],'PLAIN DOWN',0.333];
};
private _text = '';
_boundingBox = QS_hashmap_boundingBoxes getOrDefaultCall [
	toLowerANSI (typeOf _child),
	{(0 boundingBoxReal _child)},
	TRUE
];
if (_child getVariable ['QS_logistics_virtual',FALSE]) exitWith {
	if ((_child getVariable ['QS_cargoMove_state',[]]) isNotEqualTo []) then {
		uiNamespace setVariable ['QS_cargoPlacement_committing',TRUE];
		QS_player setVariable ['QS_cargoMove_active',nil,TRUE];
		missionNamespace setVariable ['QS_targetBoundingBox_placementMode',FALSE,FALSE];
	};
	['SET_CLIENT',_parent,_child] call QS_fnc_virtualVehicleCargo;
};
if ((_child getVariable ['QS_cargoMove_state',[]]) isNotEqualTo []) exitWith {
	uiNamespace setVariable ['QS_cargoPlacement_committing',TRUE];
	private _ticket = _moveState # 0;
	['LOAD',_child,[],[],[_parent,['STANDARD','HIDDEN'] select _hiddenStorage],QS_player,_ticket] remoteExecCall ['QS_fnc_cargoMove',_child,FALSE];
	QS_player setVariable ['QS_cargoMove_active',nil,TRUE];
	missionNamespace setVariable ['QS_targetBoundingBox_placementMode',FALSE,FALSE];
	[_child,_parent,_ticket] spawn {
		params ['_child','_parent','_ticket'];
		private _deadline = diag_tickTime + 8;
		waitUntil {uiSleep 0.1; isNull _child ||
			{((_child getVariable ['QS_cargoMove_state',[]]) param [0,[]]) isNotEqualTo _ticket} || {diag_tickTime > _deadline}};
		private _loaded = !isNull _child && {(attachedTo _child) isEqualTo _parent || {(isVehicleCargo _child) isEqualTo _parent}} &&
			{(_child getVariable ['QS_cargoMove_state',[]]) isEqualTo []};
		private _message = localize 'STR_QS_Text_116';
		if (_loaded) then {
			_message = format ['%1 %3 %2',getText ((configOf _child) >> 'displayName'),
				getText ((configOf _parent) >> 'displayName'),localize 'STR_QS_Text_114'];
		};
		50 cutText [_message,'PLAIN DOWN',0.5];
	};
};
if ([_parent,_child] call QS_fnc_setVehicleCargo) then {
	playSound3D [
		'A3\Sounds_F\sfx\ui\vehicles\vehicle_rearm.wss',
		_child,
		FALSE,
		(getPosASL _child),
		1,
		1,
		15
	];
	_text = format ['%1 %3 %2',(_child getVariable ['QS_ST_customDN',_displayName1]),(_parent getVariable ['QS_ST_customDN',_displayName2]),localize 'STR_QS_Text_114'];
	[_parent,TRUE,FALSE] call QS_fnc_updateCenterOfMass;
} else {
	_text = localize 'STR_QS_Text_116';
};
50 cutText [_text,'PLAIN DOWN',0.5];
