/*/
File: fn_clientDamageModifier.sqf
Author:

	Quiksilver

Last modified:

	31/05/2023 A3 2.12 by Quiksilver

Description:

	Player Damage Modification
___________________________________________________________________/*/

params ['_unit','','_damage','_source','_projectile','_hitPartIndex','_instigator','','_directHit'];
if (_this call TGC_fnc_isFriendlyFire) exitWith {0};
private _return = 0.925;
_objectParent = objectParent _unit;
// Preserve the mission's pre-overhaul fall protection. Arma can identify the
// falling unit as its own damage source. This is environmental damage, so the
// friendly-fire resolver deliberately does not infer a friendly attacker.
// Exit before the combat branch can apply random additional hit-index damage.
if (
    (isNull _objectParent) &&
    {_source isEqualTo _unit} &&
    {_projectile isEqualTo ''} &&
    {!_directHit} &&
    {(isNull _instigator) || {_instigator isEqualTo _unit}}
) exitWith {0};
(_unit getVariable ['QS_inzone',[]]) params ['_inSafezone','_safezoneLevel','_safezoneActive'];
if (_inSafezone && _safezoneActive && (_safezoneLevel > 1)) exitWith {0};
if (isNull _objectParent) then {
	if (_source isEqualType objNull) then {
		if (!isNull _source) then {

				if ((call (missionNamespace getVariable ['QS_missionConfig_reducedDamage',{1}])) isEqualTo 1) then {
					_return = 0.333;
					if (
						(!(_inSafezone && _safezoneActive)) &&
						{(_hitPartIndex in [-1,0,1,2,3,4,5,6,7,11])} &&
						{((random 1) > ([0.5,0.25] select (((((_unit getVariable 'QS_client_soundControllers') # 1) # 8) # 1) isEqualTo 1)))}
					) then {
						_randomSelection = selectRandomWeighted [8,0.5,9,0.25,10,0.25];
						_hitValue = (_unit getHitIndex _randomSelection) max ((_unit getHitIndex _randomSelection) + _damage);
						[_this,'setHitIndex',[_randomSelection,_hitValue,TRUE,_source,_instigator]] call TGC_fnc_applyCombatDamage;
						_return = 0.05;
					};
					if (_source getVariable ['QS_AI_ignoreDamageReduction',FALSE]) then {
						_return = 1;
					};
					if (_unit getVariable ['QS_unit_ignoreDamageReduction',FALSE]) then {
						_return = 1;
					};
				};
				if (
					((_source getVariable ['QS_logistics',FALSE]) && {(!(_source isKindOf 'CAManBase'))}) ||			// To do: Harden this (could be exploited?)
					{((!isNull (attachedTo _source)) && {((attachedTo _source) isKindOf 'CAManBase')})}
				) then {
					_return = 0;
				};

		} else {
			// To do: debug
			if (
				(isNull _instigator) &&
				{(_projectile isEqualTo '')}
			) then {
				_return = 0.025;
			};
		};
	};
} else {
	if (alive _objectParent) then {
		if (_objectParent isKindOf 'Air') then {
			if ((call (missionNamespace getVariable ['QS_missionConfig_reducedDamage',{1}])) isEqualTo 1) then {
				_return = 0.333;
			};
			if (
				(_objectParent isKindOf 'Heli_Light_01_unarmed_base_F') &&
				((_objectParent animationSourcePhase 'BenchL_Up') isEqualTo 1)
			) then {
				_return = 0.15;
			};

		} else {
			if (
				((_objectParent isKindOf 'Tank') || (_objectParent isKindOf 'Wheeled_APC_F')) &&
				(!isTurnedOut _unit)
			) then {
				_return = 0.075;
			};
			if (_objectParent isKindOf 'Car') then {
				_return = 0.25;
			};
			if (
				(
					(_objectParent isKindOf 'LandVehicle') ||
					{(_objectParent isKindOf 'Ship')}
				) &&
				{(isNull _source)} &&
				{(isNull _instigator)} &&
				{((_this # 4) isEqualTo '')} &&
				{((_unit targets [TRUE,50]) isEqualTo [])}
			) then {
				_return = (_damage * 0.1) min 0.75;
			};
		};
		if (
			(
				((ropeAttachedObjects _objectParent) isNotEqualTo []) &&
				{(_source in (ropeAttachedObjects _objectParent))}
			) ||
			{(
				(!isNull (ropeAttachedTo _objectParent)) &&
				{(_source isEqualTo (ropeAttachedTo _objectParent))}
			)}
		) then {
			_return = 0.05;
		};
	};
};
_return;
