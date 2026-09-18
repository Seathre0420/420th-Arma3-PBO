with uiNamespace do {SLTScriptDisplayName = "Team Name Tags";};

// Own the former core cursor labels. No all-player or nearby-AI scans are needed.
SLT_fnc_enableScript = {
	if (!hasInterface || {!isNil 'TeamNameTagEvent'}) exitWith {};
	QS_teamNameTagTargets = [];
	TeamNameTagEvent = addMissionEventHandler ['Draw3D',{
		private _player = missionNamespace getVariable ['QS_player',objNull];
		private _cameraOn = cameraOn;
		if (
			isNull _player ||
			{isNull _cameraOn} ||
			{!((lifeState _player) in ['HEALTHY','INJURED'])} ||
			{!isNull (findDisplay 49)} ||
			{!isNull curatorCamera} ||
			{visibleMap} ||
			{isStreamFriendlyUIEnabled} ||
			{freeLook}
		) exitWith {QS_teamNameTagTargets = [];};

		private _font = 'RobotoCondensedBold';
		(profileNamespace getVariable ['ApexFramework_3DGroupIconColor',(missionNamespace getVariable ['QS_missionConfig_3DIconColor',[0,125,255]])]) params ['_r','_g','_b'];
		private ['_unit','_fade','_unitName','_unitType','_alpha'];
		private _cursorTarget = cursorTarget;
		if (isNull _cursorTarget) then {
			_cursorTarget = getCursorObjectParams # 0;
			if (isNull _cursorTarget) then {
				_cursorTarget = cursorObject;
			};
		};
		if (
			(!isNull _cursorTarget) &&
			{(!(_cursorTarget in [_player,_cameraOn]))} &&
			{(
				(
					((_cursorTarget isKindOf 'CAManBase') || {((effectiveCommander _cursorTarget) isKindOf 'CAManBase')}) &&
					{(_cursorTarget isNotEqualTo _cameraOn)} &&
					{(!(_cursorTarget in (attachedObjects _cameraOn)))} &&
					{(
						((_cursorTarget isKindOf 'CAManBase') && {((side (group _cursorTarget)) isEqualTo (_player getVariable ['QS_unit_side',WEST]))}) ||
						(!(_cursorTarget isKindOf 'CAManBase') && {((side (assignedGroup _cursorTarget)) isEqualTo (_player getVariable ['QS_unit_side',WEST]))})
					)} &&
					{(!(_cursorTarget getVariable ['QS_hidden',FALSE]))}
				) ||
				{(
					(!(_cursorTarget isKindOf 'CAManBase')) &&
					{(
						(_cursorTarget getVariable ['QS_ST_showDisplayName',FALSE]) ||
						{((!isNull (assignedGroup _cursorTarget)) && {((side (assignedGroup _cursorTarget)) isEqualTo (_player getVariable ['QS_unit_side',WEST]))})} ||
						{(_cursorTarget getVariable ['QS_logistics_wreck',FALSE])} ||
						{(_cursorTarget getVariable ['QS_logistics_deployed',FALSE])} ||
						{(_cursorTarget getVariable ['QS_logistics_isCargoParent',FALSE])}
					)}
				)}
			)}
		) then {
			if ((QS_teamNameTagTargets findIf { (_x # 0) isEqualTo _cursorTarget }) isEqualTo -1) then {
				QS_teamNameTagTargets pushBack [_cursorTarget,0.01];
			};
		};
		QS_teamNameTagTargets = QS_teamNameTagTargets select { (!isNull (_x # 0)) && {((_x # 1) > 0)} && {!((_x # 0) in [_player,_cameraOn])} };
		if (QS_teamNameTagTargets isNotEqualTo []) then {
			private _cursorColor = [_r,_g,_b,1];
			{
				_unit = _x # 0;
				_fade = _x # 1;
				_unitName = '';
				if ((_unit isKindOf 'CAManBase') || {((effectiveCommander _unit) isKindOf 'CAManBase')}) then {
					if ((_cameraOn distance2D _unit) >= 30) then {
						if ((_cameraOn distance2D _unit) >= 300) then {
							_unitName = [
								'',
								format ['(%1)',localize 'STR_QS_Utility_029']
							] select (isPlayer _unit);
						} else {
							if (isPlayer _unit) then {
								_unitName = (name _unit) + (format [' (%1)',localize 'STR_QS_Utility_029']);
							} else {
								_unitName = '';
							};
						};
					} else {
						if (isPlayer _unit) then {
							if ((_unit getVariable ['QS_ST_customDN','']) isNotEqualTo '') then {
								_unitType = _unit getVariable ['QS_ST_customDN',''];
							} else {
								_unitType = ['GET_ROLE_DISPLAYNAME',(_unit getVariable ['QS_unit_role','rifleman'])] call (missionNamespace getVariable 'QS_fnc_roles');
							};
							_unitName = (name _unit) + (format [' (%1)',_unitType]);
						} else {
							_unitName = '';
						};
					};
					_alpha = [0.1 max (1 - ((((_cameraOn distance2D _unit) / 1000)) % 1)),0.1] select ((_cameraOn distance2D _unit) >= 1000);
					QS_teamNameTagTargets set [_forEachIndex,[_unit,([(_fade + 0.1) min 1,(_fade - 0.1) max 0] select (_unit isNotEqualTo _cursorTarget))]];
					_alpha = _alpha * _fade;
					_cursorColor = if (
						(isPlayer _unit) &&
						{(group _unit) isEqualTo (group _player)}
					) then {
						[0,0.77,1,_alpha]
					} else {
						_unit getVariable ['QS_ST_cursorIcon_color',[_r,_g,_b,_alpha]]
					};
				} else {
					if (
						(_unit getVariable ['QS_ST_showDisplayName',FALSE]) ||
						{(_unit getVariable ['QS_logistics_wreck',FALSE])} ||
						{(_unit getVariable ['QS_logistics_deployed',FALSE])} ||
						{(_unit getVariable ['QS_logistics_isCargoParent',FALSE])}
					) then {
						_unitName = _unit getVariable ['QS_ST_customDN',''];
						if (_unitName isEqualTo '') then {
							_unitName = QS_hashmap_configfile getOrDefaultCall [
								format ['cfgvehicles_%1_displayname',toLowerANSI (typeOf _unit)],
								{(getText ((configOf _unit) >> 'displayName'))},
								TRUE
							];
							_unit setVariable ['QS_ST_customDN',_unitName,FALSE];
						};
						if (_unit getVariable ['QS_logistics_wreck',FALSE]) then {
							_unitName = format ['%1 (%2)',_unitName,localize 'STR_QS_Text_384'];
						};
						if (_unit getVariable ['QS_logistics_deployed',FALSE]) then {
							_unitName = format ['%1 (%2)',_unitName,localize 'STR_QS_Text_409'];
						};
						if (_unit getVariable ['QS_logistics_isCargoParent',FALSE]) then {
							_unitName = format ['%1 (%2)',_unitName,localize 'STR_QS_Text_410'];
						};
					};
					if (
						(_unitName isEqualTo '') &&
						{(!isNull (assignedGroup _unit))} &&
						{((crew _unit) isEqualTo [])}
					) then {
						_unitName = groupId (assignedGroup _unit);
					};
					_alpha = [0 max (1 - ((((_cameraOn distance2D _unit) / 30)) % 1)),0] select ((_cameraOn distance2D _unit) >= 30);
					QS_teamNameTagTargets set [_forEachIndex,[_unit,([(_fade + 0.1) min 1,(_fade - 0.1) max 0] select (_unit isNotEqualTo _cursorTarget))]];
					_alpha = _alpha * _fade;
					_cursorColor = _unit getVariable ['QS_ST_cursorIcon_color',[0.5,0.5,0.5,_alpha]];
				};
				if ((_unitName isNotEqualTo '') && {_alpha > 0}) then {
					drawIcon3D [
						'',
						_cursorColor,
						((_unit modelToWorldVisual ((selectionPosition [_unit,(['pilot','head'] select (_unit isKindOf 'CAManBase')),11,TRUE]))) vectorAdd [0,0,0.5]),
						1,
						1,
						0,
						_unitName,
						2,
						0.03,
						_font,
						'center',
						FALSE,
						0,
						-0.03
					];
				};
			} forEach QS_teamNameTagTargets;
		};
	}];
};

SLT_fnc_disableScript = {
	if (!isNil 'TeamNameTagEvent') then {
		removeMissionEventHandler ['Draw3D',TeamNameTagEvent];
	};
	TeamNameTagEvent = nil;
	QS_teamNameTagTargets = [];
};

QS_fnc_teamNameTagsEnable = SLT_fnc_enableScript;
QS_fnc_teamNameTagsDisable = SLT_fnc_disableScript;

SLT_fnc_init = {
 params[["_useToggleOptions",true]];

 with uiNamespace do {

  createDialog "RscDisplayEmpty";
  private _display = findDisplay -1;
  {_x ctrlShow false;} foreach allControls _display;

  private _ctrlHeader = _display ctrlCreate ["RscStructuredText",-1];
  _ctrlHeader ctrlSetPosition [0.396875 * safezoneW + safezoneX,0.445 * safezoneH + safezoneY,0.20625 * safezoneW,0.022 * safezoneH];
  _ctrlHeader ctrlSetBackgroundColor [1,0.7,0,0.66];
  _ctrlHeader ctrlSetStructuredText parseText ("<t size='0.85' font='PuristaMedium'>"+toUpper SLTScriptDisplayName+"</t>");
  _ctrlHeader ctrlCommit 0;

  private _ctrlBorder = _display ctrlCreate ["RscPicture",-1];
  _ctrlBorder ctrlSetPosition [0.396875 * safezoneW + safezoneX,0.467 * safezoneH + safezoneY,0.20625 * safezoneW,0.077 * safezoneH];
  _ctrlBorder ctrlSetText "#(rgb,1,1,1)color(1,1,1,1)";
  _ctrlBorder ctrlSetTextColor [0,0,0,0.5];
  _ctrlBorder ctrlCommit 0;

  private _ctrlBackground = _display ctrlCreate ["RscPicture",-1];
  _ctrlBackground ctrlSetPosition [0.402031 * safezoneW + safezoneX,0.478 * safezoneH + safezoneY,0.195937 * safezoneW,0.055 * safezoneH];
  _ctrlBackground ctrlSetText "#(rgb,1,1,1)color(1,1,1,1)";
  _ctrlBackground ctrlSetTextColor [0.1,0.1,0.1,0.75];
  _ctrlBackground ctrlCommit 0;

  SLTEnableButton = _display ctrlCreate ["RscButtonMenu",-1];
  SLTEnableButton ctrlSetPosition [0.407187 * safezoneW + safezoneX,0.489 * safezoneH + safezoneY,0.0928125 * safezoneW,0.033 * safezoneH];
  SLTEnableButton ctrlSetText "ENABLE";
  SLTEnableButton ctrlCommit 0;
  SLTEnableButton ctrlAddEventHandler ["ButtonClick",{
   ['NAME_TAGS',TRUE] remoteExecCall ['QS_fnc_serverSetTeamFeature',2,FALSE];
   closeDialog 0;
  }];

  SLTDisableButton = _display ctrlCreate ["RscButtonMenu",-1];
  SLTDisableButton ctrlSetPosition [0.5 * safezoneW + safezoneX,0.489 * safezoneH + safezoneY,0.0928125 * safezoneW,0.033 * safezoneH];
  SLTDisableButton ctrlSetText "DISABLE";
  SLTDisableButton ctrlCommit 0;
  SLTDisableButton ctrlAddEventHandler ["ButtonClick",{
   ['NAME_TAGS',FALSE] remoteExecCall ['QS_fnc_serverSetTeamFeature',2,FALSE];
   closeDialog 0;
  }];

  if (!_useToggleOptions) then
  {
   SLTEnableButton ctrlSetText "ARE YOU SURE?";
   SLTEnableButton ctrlSetTooltip "This script cannot be disabled!";
   SLTEnableButton ctrlCommit 0;

   SLTDisableButton ctrlSetText "CANCEL";
   SLTDisableButton ctrlCommit 0;
  };
 };
 deleteVehicle this;
};

[] spawn QS_fnc_teamNameTagsEnable;
