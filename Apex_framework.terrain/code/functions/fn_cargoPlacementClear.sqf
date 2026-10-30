/*
    Conservative separation test for cargo and its original carrier.
    Project the cargo's world-space bounding box onto the carrier's model axes.
    A separating axis is sufficient to prove clearance; touching is allowed.
*/
params ['_cargo','_carrier'];
if (isNull _carrier || {_carrier isKindOf 'CAManBase'}) exitWith {TRUE};
private _bounds = 0 boundingBoxReal _cargo;
private _carrierBounds = 0 boundingBoxReal _carrier;
private _low = [1e10,1e10,1e10];
private _high = [-1e10,-1e10,-1e10];
{
    private _xPos = _x;
    {
        private _yPos = _x;
        {
            private _point = _carrier worldToModel (_cargo modelToWorld [_xPos,_yPos,_x]);
            for '_axis' from 0 to 2 do {
                _low set [_axis,(_low # _axis) min (_point # _axis)];
                _high set [_axis,(_high # _axis) max (_point # _axis)];
            };
        } forEach [(_bounds # 0) # 2,(_bounds # 1) # 2];
    } forEach [(_bounds # 0) # 1,(_bounds # 1) # 1];
} forEach [(_bounds # 0) # 0,(_bounds # 1) # 0];
([0,1,2] findIf {
    ((_high # _x) <= ((_carrierBounds # 0) # _x)) ||
    {(_low # _x) >= ((_carrierBounds # 1) # _x)}
}) isNotEqualTo -1
