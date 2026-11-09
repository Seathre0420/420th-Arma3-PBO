/* Explicit noncombat exception: owner may retire an unmanned owned asset.
Never permit a nearby action to destroy somebody else's or a base weapon.
*/
params ['_player','_asset'];
private _uid = getPlayerUID _player;
private _owner = _asset getVariable ['TGC_drones_owner',_asset getVariable ['QS_spawnMenu_spawnedBy','']];
_uid isNotEqualTo '' && {_owner isEqualTo _uid} &&
{!(_asset getVariable ['QS_hidden',false])} &&
{((crew _asset) findIf {isPlayer _x}) < 0}
