/* Run via execVM on a disposable dedicated server/editor, never live.
 * Copy fn_defendAssault.sqf into code/functions/ first. VR is sufficient.
 * Automatic tests cover state and pacing; see README for multiplayer acceptance.
 */
if (!isServer) exitWith {};
if (missionNamespace getVariable ['QS_defendControl_active',FALSE]) exitWith {
    diag_log '[Defend assault test] Refusing to replace an active defense';
};
QS_fnc_defendAssault = compile preprocessFileLineNumbers 'code/functions/fn_defendAssault.sqf';
private _failures = [];
private _assert = {
    params ['_ok','_label'];
    if (!_ok) then {_failures pushBack _label;};
    diag_log format ['[Defend assault test] %1: %2',['FAIL','PASS'] select _ok,_label];
};
private _epoch = 1000000;
private _hq = [worldSize / 2,worldSize / 2,0];
private _objects = [];
private _groups = [];
private _fn_man = {
    params ['_distance',['_group',grpNull]];
    if (isNull _group) then {_group = createGroup [EAST,TRUE]; _groups pushBack _group;};
    private _unit = _group createUnit ['O_Soldier_F',_hq vectorAdd [_distance,0,0],[],0,'NONE'];
    _unit setPosATL (_hq vectorAdd [_distance,0,0]);
    // Keep boundary assertions deterministic; PATH stays enabled.
    _unit disableAI 'MOVE';
    _objects pushBack _unit;
    _unit
};
missionNamespace setVariable ['QS_defendControl_epoch',_epoch,TRUE];
missionNamespace setVariable ['QS_defendControl_active',TRUE,TRUE];
missionNamespace setVariable ['QS_defendAssault_roster',[]];
private _outside = [101] call _fn_man;
private _inside = [99,group _outside] call _fn_man;
_outside disableAI 'COVER';
['REGISTER',[_outside,_inside],_epoch,_hq] call QS_fnc_defendAssault;
[!(_outside getVariable ['QS_defendAssault_released',TRUE]),'101m stays locked'] call _assert;
[unitCombatMode _outside isEqualTo 'BLUE','outside never-fire mode'] call _assert;
[{_outside checkAIFeature _x} count ['TARGET','AUTOTARGET','AUTOCOMBAT','COVER','SUPPRESSION'] isEqualTo 0,'rush combat features disabled'] call _assert;
[_outside checkAIFeature 'PATH','rush retains pathfinding'] call _assert;
[_inside getVariable ['QS_defendAssault_released',FALSE],'99m unlocks individually'] call _assert;
[_inside checkAIFeature 'TARGET' && {_inside checkAIFeature 'AUTOTARGET'},'inside targeting enabled'] call _assert;
[unitCombatMode _inside isEqualTo 'YELLOW','inside fire-at-will without pursuit'] call _assert;
[!attackEnabled (group _outside),'squad does not assign pursuit orders'] call _assert;
[getForcedSpeed _outside isEqualTo 24,'rush speed applied'] call _assert;
[getForcedSpeed _inside isEqualTo -1,'combat speed restriction removed'] call _assert;
[_outside getVariable ['QS_AI_UNIT_regroup_disable',FALSE],'regrouping disabled'] call _assert;
[count (missionNamespace getVariable ['QS_defendAssault_roster',[]]) isEqualTo 2,'bounded explicit roster'] call _assert;

// Same squad, opposite boundary sides; an unlocked leader must not unlock others.
(group _outside) selectLeader _inside;
['TICK',[_outside,_inside],_epoch,_hq] call QS_fnc_defendAssault;
[!(_outside checkAIFeature 'TARGET'),'unlocked leader does not unlock trailing soldier'] call _assert;
private _first = +(_outside getVariable ['QS_defendAssault_local',[]]);
['TICK',[_outside],_epoch,_hq] call QS_fnc_defendAssault;
[(_outside getVariable ['QS_defendAssault_local',[]]) # 5 isEqualTo _first # 5,'distance poll does not reissue movement'] call _assert;
_first set [4,diag_tickTime - 7]; _first set [5,diag_tickTime - 1];
_outside setVariable ['QS_defendAssault_local',_first];
['TICK',[_outside],_epoch,_hq] call QS_fnc_defendAssault;
[(_outside getVariable ['QS_defendAssault_local',[]]) # 5 > diag_tickTime + 7,'stalled soldier gets a paced retry'] call _assert;
_outside setPosATL (_hq vectorAdd [100,0,0]);
['TICK',[_outside],_epoch,_hq] call QS_fnc_defendAssault;
[_outside getVariable ['QS_defendAssault_released',FALSE],'exactly 100m unlocks'] call _assert;
_outside setPosATL (_hq vectorAdd [160,0,0]);
['REGISTER',[_outside],_epoch,_hq] call QS_fnc_defendAssault;
[_outside getVariable ['QS_defendAssault_released',FALSE],'unlock permanent and duplicate registration harmless'] call _assert;

private _airborne = [50] call _fn_man;
_airborne setPosATL (_hq vectorAdd [50,0,50]);
['REGISTER',[_airborne],_epoch,_hq] call QS_fnc_defendAssault;
[!(_airborne getVariable ['QS_defendAssault_released',TRUE]),'airborne over HQ stays locked'] call _assert;
[!((_airborne getVariable ['QS_defendAssault_local',[]]) # 2),'no ground order while airborne'] call _assert;
_airborne setPosATL (_hq vectorAdd [150,0,0]);
['TICK',[_airborne],_epoch,_hq] call QS_fnc_defendAssault;
[(_airborne getVariable ['QS_defendAssault_local',[]]) # 2,'landing outside HQ starts rush'] call _assert;
[!(_airborne checkAIFeature 'TARGET'),'landing outside HQ does not unlock combat'] call _assert;
(group _airborne) setVariable ['QS_taruDelivery_busy',TRUE];
_airborne setPosATL (_hq vectorAdd [50,0,0]);
['TICK',[_airborne],_epoch,_hq] call QS_fnc_defendAssault;
[!(_airborne getVariable ['QS_defendAssault_released',TRUE]),'Taru retains ownership during delivery'] call _assert;
(group _airborne) setVariable ['QS_taruDelivery_busy',FALSE];
_airborne setVariable ['AR_Is_Rappelling',TRUE];
['TICK',[_airborne],_epoch,_hq] call QS_fnc_defendAssault;
[!(_airborne getVariable ['QS_defendAssault_released',TRUE]),'rappelling does not unlock combat'] call _assert;
_airborne setVariable ['AR_Is_Rappelling',FALSE];
['TICK',[_airborne],_epoch,_hq] call QS_fnc_defendAssault;
[_airborne getVariable ['QS_defendAssault_released',FALSE],'delivery completion uses distance gate'] call _assert;

private _truck = createVehicle ['O_Truck_03_transport_F',_hq vectorAdd [140,10,0],[],0,'NONE'];
_objects pushBack _truck;
private _cargo = [140] call _fn_man;
_cargo moveInCargo _truck;
['REGISTER',[_cargo],_epoch,_hq] call QS_fnc_defendAssault;
[!((_cargo getVariable ['QS_defendAssault_local',[]]) # 2),'passenger does not receive driver orders'] call _assert;
moveOut _cargo;
_cargo setPosATL (_hq vectorAdd [140,0,0]);
['TICK',[_cargo],_epoch,_hq] call QS_fnc_defendAssault;
[(_cargo getVariable ['QS_defendAssault_local',[]]) # 2,'dismounted passenger starts rush'] call _assert;
private _unrelated = [150] call _fn_man;
['TICK',[_unrelated],_epoch,_hq] call QS_fnc_defendAssault;
[isNil {_unrelated getVariable 'QS_defendAssault_local'},'untagged AI unaffected'] call _assert;
private _captive = [150] call _fn_man;
_captive setCaptive TRUE;
['REGISTER',[_captive],_epoch,_hq] call QS_fnc_defendAssault;
[isNil {_captive getVariable 'QS_defendAssault_epoch'},'captives excluded'] call _assert;

// Rebuild local state as a transfer would. Released flag is replicated separately.
_outside setVariable ['QS_defendAssault_local',nil];
_outside disableAI 'TARGET';
['TICK',[_outside],_epoch,_hq] call QS_fnc_defendAssault;
[_outside checkAIFeature 'TARGET','owner initialization preserves combat unlock'] call _assert;
_cargo setPosATL (_hq vectorAdd [90,0,0]);
['TICK',[_cargo],_epoch - 1,_hq] call QS_fnc_defendAssault;
[!(_cargo getVariable ['QS_defendAssault_released',TRUE]),'stale tick cannot unlock new activity'] call _assert;
['RELEASE',[_cargo],_epoch - 1] call QS_fnc_defendAssault;
[(_cargo getVariable ['QS_defendAssault_epoch',-1]) isEqualTo _epoch,'stale release cannot retire current activity'] call _assert;
private _worker = ['RUN',[],_epoch,_hq] spawn QS_fnc_defendAssault;
uiSleep 1.2;
[_cargo getVariable ['QS_defendAssault_released',FALSE],'shared worker processes registered arrivals'] call _assert;
missionNamespace setVariable ['QS_defendControl_active',FALSE,TRUE];
uiSleep 1.2;
[scriptDone _worker,'worker exits when defense closes'] call _assert;
['TICK',[_unrelated],_epoch,_hq] call QS_fnc_defendAssault;
[isNil {_unrelated getVariable 'QS_defendAssault_local'},'closed activity ignores late ticks'] call _assert;
['RELEASE',_objects select {_x isKindOf 'CAManBase'},_epoch] call QS_fnc_defendAssault;
[_outside checkAIFeature 'TARGET','cleanup restores original targeting'] call _assert;
[!(_outside checkAIFeature 'COVER'),'cleanup preserves original disabled cover'] call _assert;
[getForcedSpeed _outside isEqualTo -1,'cleanup restores speed'] call _assert;
[!(_outside getVariable ['QS_AI_UNIT_regroup_disable',FALSE]),'cleanup restores regroup eligibility'] call _assert;
[isNil {_outside getVariable 'QS_defendAssault_epoch'},'cleanup removes ownership tag'] call _assert;
{deleteVehicle _x;} forEach _objects;
{deleteGroup _x;} forEach _groups;
missionNamespace setVariable ['QS_defendAssault_roster',[]];
diag_log format ['[Defend assault test] COMPLETE failures=%1 %2',count _failures,_failures];
missionNamespace setVariable ['QS_defendAssault_testFailures',_failures];
