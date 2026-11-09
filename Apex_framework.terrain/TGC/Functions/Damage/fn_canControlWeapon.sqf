params ['_player','_weapon'];
!isNull _player && {alive _weapon} && {!(_weapon getVariable ['QS_hidden',false])} &&
{!(_weapon getVariable ['QS_uav_disabled',false])} && {_weapon getVariable ['QS_uav_toggleEnabled',true]} &&
{(_weapon getVariable ['TGC_drones_owner','']) in ['',getPlayerUID _player]} &&
{_player isUAVConnectable [_weapon,true]}
