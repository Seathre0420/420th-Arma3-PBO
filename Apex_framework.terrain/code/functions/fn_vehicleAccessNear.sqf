/* Distance to vehicle bounds, shared by the UI and server. Large aircraft must
   be reachable at their doors, rather than only near their model origin. */
params ['_unit','_vehicle'];
if (isNull _unit || {isNull _vehicle} || {!alive _vehicle}) exitWith {FALSE};
if ((objectParent _unit) isEqualTo _vehicle) exitWith {TRUE};
if (!isNull objectParent _unit) exitWith {FALSE};
private _point = _vehicle worldToModel (ASLToAGL (getPosASL _unit));
(boundingBoxReal _vehicle) params ['_min','_max'];
private _offset = [0,1,2] apply {
	((_min # _x) - (_point # _x)) max ((_point # _x) - (_max # _x)) max 0
};
(vectorMagnitude _offset) <= 3
