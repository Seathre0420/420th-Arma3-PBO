/* Local helper: replies always carry the full session identity. */
params ['_session','_phase',['_reason',''],['_remaining',0],['_level',0]];
_session params ['_vehicle','_unit','_token','_mode','_caller'];
['status',_vehicle,_unit,_token,_mode,_phase,_reason,_remaining,_level] remoteExecCall ['QS_fnc_engineerServiceServer',2];
