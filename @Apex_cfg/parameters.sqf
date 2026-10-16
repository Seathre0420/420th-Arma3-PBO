diag_log format ['***** %1 * Loading mission parameters *****',diag_tickTime];

_teamspeak_server = 'discord.gg/420th';
_website_url = ["'https://www.420thdelta.net'","420thdelta.net","420thdelta.net"];
_discord_server = ["'https://discord.gg/420th'","Discord","discord.gg/420th"];
_arma_units_url = ["'https://units.arma3.com/unit/420th-delta'","Arma 3 Unit","units.arma3.com/unit/420th-delta"];
_monetizeURL = ["'https://my.420thdelta.net'","420th Dashboard","my.420thdelta.net"];

_serverRules = '
Friendly Fire: Apologize in Side channel to avoid Robocops and staff intervention.<br/>
Behavior: Respect our players and our staff. Avoid using insults. Help new players.<br/>
Waiting For Passengers: Helicopters should not park in the lane between spawn and yellow barriers.<br/>
AFK Pilots: Please tell someone you are going AFK. Fighter Pilot AFK timer is 6 minutes. Transport Pilot AFK timer is 10 minutes.<br/>
Aircraft and Command Channels: Be mindful when using voice communication in these channels. Use other channels where possible.<br/>
No Vehicles on Kavala: All vehicles are forbidden to engage the Priority Mission Kavala. This mission is meant to be close-quarters combat.<br/>
Rearming with Pylon Manager: Please avoid using Pylon Manager to rearm in the field. Use proper service areas. Offenders will lose their flying privileges.';

_staffNames = 'Seathre, Colonel Cookie, Big Bird, Twisted, CanadianDimebag, Hecks, Dragon, Astrid, Enchanted, Checkmate, Cowboy, Crowe, DB, Radium, Seth, Soldi, ZEROBLOOD';

_splashMenu = 1;
_introMusic = 1;
_baseLayout = 1;
_closeAirSupport = 1;
_enemyCAS = 1;
_jetLaser = 1;
_arsenal = 2;
_armor = 1;
_reducedDamage = 1;
_stamina = 0;
_commander = 0;
_artillery = 2;
_artilleryComputer = 2;
_mapContentEnemy = 1;
_recruitableAI = 1;
_playable_opfor = 0;
_ambient_civilians = 0;
_ambient_animals = 0;
_vehicle_active_protection = 3;
_hitMarker_audio = 1;
_effectKnockdown = 0;
_craters = 0;
_groupForced = 0;
_groupRegisterInit = 0;
_groupLocking = 1;
_groupWaypoint = 0;
_enemyUrbanSpawning = 1;
_tracers = 1;
_enemyGearRandomization = 0;
_vehicleRoleRestriction_heli = 1;
_vehicleRoleRestriction_plane = 1;
_customPylonPresets = 1;
_attachExplosives = 1;
_wrecks = 0;
_bobcatRecovery = 0;
_vehicleLock = 1;
_vehicleCargoLock = 1;
_vehicleGroupLock = 1;
_autohover = 1;
_autopilot = 1;
_planeForce1PV = 0;
_quickBuild = 1;
_maxSandbags = 1000;
_maxBuiltObjects = 1000;
_towing = 1;
_winch = 2;
_mass = 0;
_centerofmass = 0;
_role_selection_menu_button = 0;
_deploymentMenu = 1;
_deployMenuOnRespawn = 1;
_deployMenuHome = 1;
_weaponLasers = 1;
_weaponLasersColorForced = [-1,-1,-1];
_weaponLasersHighPower = 1;
_fireSupport = 2;

//===================================================== SYSTEM

_restart_hours = [];
_restart_dynamic = 0;
_dynamic_simulation = 1;
_startDate = [2035, 6, 1, 6, 0];
_timeMultiplier = [
	24,
	24,
	24
];
_weatherDynamic = 1;
_weatherForcedMode = -1;
_logReportFrequency = 600;

//===================================================== ZEUS

_zeusModePlayerRespawn = 1;
_zeusModeRespawnMarker = 1;
_zeusModeArsenalFlag = 1;
_zeusCanOffloadAI = 1;
_zeusRestrictions = 0;
_zeusLightning = 1;

//===================================================== HEADLESS CLIENT

_hc_maxLoad_1 = 40;
_hc_maxLoad_2 = 40;
_hc_maxLoad_3 = 40;
_hc_maxLoad_4 = 40;
_hc_maxAgents_1 = 5;
_hc_maxAgents_2 = 5;
_hc_maxAgents_3 = 5;
_hc_maxAgents_4 = 5;

//===================================================== DLC/MODs Support

_dlc = '';
_dlc_vehicles = '';
_dlc_units = '';
// Steam Workshop IDs for every client mod allowed on the server.
// Keep the IDs quoted because getLoadedModsInfo returns them as strings.
// Non-official mods without a Workshop ID are always rejected.
_allowedClientWorkshopIds = [
	'2647830',
	'2647760',
	'1175380',
	'1681170',
	'1294440',
	'1227700',
	'1042220',
    '853333870',
    '3816007414',
    '1520786131',
    '3808428518',
    '3724191481',
    '3804858502',
    '3791469351',
    '3544334913',
    '3692961033',
    '3608865966',
    '1484261993',
    '2060770170',
    '2060770170',
	'3348605126',
	'3150497912',
	'2991828484',
	'2636962953',
	'2503886780',
	'2477276806',
	'1776428269',
	'450814997',
	'3647324436',
	'1779063631',
	'2980962612',
	'1867660876',
	'2261045061',
	'3346427969',
	'855973772',
	'3333302397',
	'3473383676',
	'3755886563',
	'3370946091',
	'1242734278',
	'2013446344',
	'2447965207',
	'825181638',
	'2041057379',
	'1364777346',
	'2513044572',
	'2910639448',
	'2953412769',
	'837729515',
	'925018569',
	'2791403093',
	'1911813061',
	'3212172319',
	'1942567517',
	'2071790996',
	'2260572637',
	'2626595531',
	'2857096620',
	'3289651152',
	'878502647',
	'767380317',
	'3117898674',
	'642912021',
    '3085697583',
    '3567067667',
    '3779191624'
];
// Full getLoadedModsInfo hashes allowed as a fallback for unapproved Workshop IDs.
// Keep hashes quoted. Empty hashes are never accepted.
_allowedClientModHashes = [
	'1e2fa70a1f94e14194e25c741ebc8c52995c9dbc',
	'270d716ed1b50d6452210d7de4da513e3a108c14',
	'0664faaf1b4a3037ee3e57d34032c5b5f42f2543',
	'f31d6f9ef58c425629dbe6d011577e65c81e3bb6',
	'08ba1cb93943d61ca6f8b9bb6c6d151328bc12d4',
    'ff1d1a72ade2adddfdf431c4e6dc70f7f9c8d166'
];
_zeus_reskinUnits = 0;
_basic_reskin = 0;
_basic_reskin_params = [
	['rhs_msv_rifleman'],
	['rhsusf_usmc_marpat_wd_rifleman'],
	['rhs_msv_rifleman'],
	[]
];

//===================================================== MAIN MISSION TYPE

_main_mission_type = 'CLASSIC';

//===================================================== SIDE MISSIONS

_sideMissions = 1;

//===================================================== SANDBOX COMBAT MISSIONS

_deploymentMissions = 0;
_dm_MaxConcurrent = 1;
_dm_Frequency = 0;
_dm_Intensity = 0;
_dm_Duration = 0;
_dm_SetupTime = 9999;
_dm_overclock = 0;

//===================================================== STATIC SHIPS
_aircraft_carrier_enabled = 1;
_aircraft_carrier_vehicles = 2;
_aircraft_carrier_respawning = 0;
_destroyer_enabled = 1;
_destroyer_vehicles = 2;
_destroyer_respawning = 0;
_destroyer_artillery = 1;
_destroyer_flag = 'a3\data_f\flags\flag_us_co.paa';
_destroyer_name = 'a3\boat_f_destroyer\destroyer_01\data\destroyer_01_tag_01_co.paa';
_destroyer_numbers = [4,2,0];
_destroyer_hangar = 1;

//===================================================== CONTAINERS

_fobs_default = 1;
_container_mobileRespawn = 1;
_container_baseSmall = 1;
_container_baseMedium = 1;
_container_baseLarge = 1;
_container_platform = 1;
_container_terrain = 0;
_container_SAM = 1;
_container_radar = 1;

//===================================================== TEXTURES

_IconColor3D = [255,102,252];
_community_logo = 'media\images\icons\logo.paa';
_community_flag_texture = 'a3\data_f\flags\flag_nato_co.paa';
_default_flag_texture = 'a3\data_f\flags\flag_nato_co.paa';
_billboard_1 = ['media\images\billboards\billboard3.jpg','media\images\billboards\billboard3.jpg'];
_billboard_2 = ['media\images\billboards\billboard4.jpg','media\images\billboards\billboard4.jpg'];
_infostand_1 = ['media\images\billboards\billboard5.jpg','media\images\billboards\billboard5.jpg'];
_infostand_2 = ['media\images\billboards\billboard6.jpg','media\images\billboards\billboard6.jpg'];

//===================================================== SECURITY

_serverCommandPassword = "'Cbdg3x5T7333VM2vwaSz7kB5698WrBz3'";
_anticheat = 0;

//===================================================== MONETIZATION

_monetizeCosmetics = 2;

//===================================================== DATABASE / SQL WHITELIST
// Enable SQL-based whitelists using ExtDB3 and MySQL/MariaDB

_query_debug = false;
// If true, outputs queries and results to the console.

_dynamic_whitelist = true;
// Use the database instead of whitelist.sqf to retrieve whitelists.
// If database configuration fails, this will fall back to whitelist.sqf.


//================== DO NOT EDIT BELOW =================== INTERPRETING MISSION PARAMETERS
systemTime params ['','_month','_day','','','',''];
if (_arsenal isEqualTo 3) then {};
if (_restart_hours isNotEqualTo []) then {
	_restart_hours sort TRUE;
};
if (_weatherForcedMode > -1) then {
	_weatherDynamic = 0;
};
if (
	(_month isEqualTo 12) &&
	(_day isEqualTo 25)
) then {
	_weatherForcedMode = 4;
	_weatherDynamic = 0;
};
if (
	(_aircraft_carrier_enabled > 0) &&
	{(_aircraft_carrier_respawning > 1)} &&
	{(_destroyer_enabled > 0)} &&
	{(_destroyer_respawning > 0)}
) then {
	_destroyer_respawning = 0;
};
if (!(worldName in ['Altis','Tanoa','Malden','Enoch','Stratis'])) then {
	_anticheat = 0;
};
if (_main_mission_type isEqualTo 'ZEUS') then {
	_sideMissions = 0;
};
if ((count _startDate) > 5) then {
	_startDate = _startDate select [0,5];
};
/*/QS Note: Not currently compatible with 1.5.x /*/ _anticheat = 0;
{
	missionNamespace setVariable _x;
	diag_log str ([_x # 0,_x # 1]);
} forEach [
	['QS_missionConfig_splash',_splashMenu > 0,TRUE],
	['QS_missionConfig_commTS',_teamspeak_server,TRUE],
	['QS_missionConfig_commDS',(compileFinal (str _discord_server)),TRUE],
	['QS_missionConfig_commURL',(compileFinal (str _website_url)),TRUE],
	['QS_missionConfig_commA3U',(compileFinal (str _arma_units_url)),TRUE],
	['QS_missionConfig_baseLayout',_baseLayout,TRUE],
	['QS_missionConfig_AH',(compileFinal (str _anticheat)),TRUE],
	['QS_missionConfig_stamina',_stamina,TRUE],
	['QS_missionConfig_enemyCAS',_enemyCAS,FALSE],
	['QS_missionConfig_CAS',_closeAirSupport,TRUE],
	['QS_missionConfig_Commander',_commander,TRUE],
	['QS_missionConfig_Arsenal',_arsenal,TRUE],
	['QS_missionConfig_armor',_armor,TRUE],
	['QS_missionConfig_reducedDamage',(compileFinal (str _reducedDamage)),TRUE],
	['QS_missionConfig_AmbCiv',_ambient_civilians,FALSE],
	['QS_missionConfig_AmbAnim',_ambient_animals,FALSE],
	['QS_missionConfig_APS',_vehicle_active_protection,TRUE],
	['QS_missionConfig_hitMarker',_hitMarker_audio,TRUE],
	['QS_missionConfig_knockdown',_effectKnockdown > 0,TRUE],
	['QS_missionConfig_craterEffects',_craters,TRUE],
	['QS_missionConfig_joinUngrouped',_groupForced > 0,TRUE],
	['QS_missionConfig_registerInitGroup',_groupRegisterInit > 0,TRUE],
	['QS_missionConfig_groupLocking',_groupLocking > 0,TRUE],
	['QS_missionConfig_groupWaypoint',_groupWaypoint > 0,TRUE],
	['QS_missionConfig_aoUrbanSpawning',_enemyUrbanSpawning,FALSE],
	['QS_missionConfig_tracers',_tracers,TRUE],
	['QS_missionConfig_enemyRandGear',_enemyGearRandomization > 0,TRUE],
	['QS_missionConfig_introMusic',_introMusic > 0,TRUE],
	['QS_missionConfig_jetLaser',_jetLaser > 0,TRUE],
	['QS_missionConfig_roleRestrictionHeli',_vehicleRoleRestriction_heli > 0,TRUE],
	['QS_missionConfig_roleRestrictionPlane',_vehicleRoleRestriction_plane > 0,TRUE],
	['QS_missionConfig_pylonPresets',_customPylonPresets,TRUE],
	['QS_missionConfig_attachExplosives',_attachExplosives > 0,TRUE],
	['QS_missionConfig_weaponLasers',_weaponLasers > 0,TRUE],
	['QS_missionConfig_wrecks',_wrecks > 0,TRUE],
	['QS_missionConfig_bobcatRecovery',_bobcatRecovery > 0,TRUE],
	['QS_missionConfig_seatLocking',_vehicleLock,TRUE],
	['QS_missionConfig_cargoLocking',_vehicleCargoLock,TRUE],
	['QS_missionConfig_vehicleGroupLock',_vehicleGroupLock > 0,TRUE],
	['QS_missionConfig_autohover',_autohover > 0,TRUE],
	['QS_missionConfig_autopilot',_autopilot > 0,TRUE],
	['QS_missionConfig_plane1PV',_planeForce1PV > 0,TRUE],
	['QS_missionConfig_quickBuild',_quickBuild,TRUE],
	['QS_missionConfig_maxPlayerBuildables',_maxSandbags,TRUE],
	['QS_missionConfig_maxBuild',_maxBuiltObjects,TRUE],
	['QS_missionConfig_interactTowing',_towing > 0,TRUE],
	['QS_missionConfig_interactWinch',_winch,TRUE],
	['QS_missionConfig_mass',_mass > 0,TRUE],
	['QS_missionConfig_centerOfMass',_centerofmass,TRUE],
	['QS_missionConfig_RSS_MenuButton',_role_selection_menu_button,TRUE],
	['QS_missionConfig_deployment',_deploymentMenu > 0,TRUE],
	['QS_missionConfig_respawnDeploy',_deployMenuOnRespawn > 0,TRUE],
	['QS_missionConfig_deployMenuHome',_deployMenuHome > 0,TRUE],
	['QS_missionConfig_weaponLasers',_weaponLasers > 0,TRUE],
	['QS_missionConfig_weaponLasersForced',_weaponLasersColorForced,TRUE],
	['QS_missionConfig_weaponLasersHiPower',_weaponLasersHighPower > 0,TRUE],
	['QS_missionConfig_fireSupport',_fireSupport,TRUE],
	['QS_missionConfig_restartHours',_restart_hours,TRUE],
	['QS_missionConfig_restartDynamic',_restart_dynamic,FALSE],
	['QS_missionConfig_dynSim',_dynamic_simulation,FALSE],
	['QS_missionConfig_startDate',_startDate,FALSE],
	['QS_missionConfig_timeMultiplier',_timeMultiplier,FALSE],
	['QS_missionConfig_weatherDynamic',_weatherDynamic > 0,TRUE],
	['QS_missionConfig_weatherForced',_weatherForcedMode,TRUE],
	['QS_missionConfig_logFrequency',_logReportFrequency,FALSE],
	['QS_missionConfig_zeusRespawnFlag',_zeusModePlayerRespawn > 0,TRUE],
	['QS_missionConfig_zeusRespawnMarker',_zeusModeRespawnMarker > 0,FALSE],
	['QS_missionConfig_zeusRespawnArsenal',_zeusModeArsenalFlag > 0,TRUE],
	['QS_missionConfig_zeusRestrictions',_zeusRestrictions > 0,TRUE],
	['QS_missionConfig_zeusLightning',_zeusLightning > 0,TRUE],
	['QS_missionConfig_zeusOffload',_zeusCanOffloadAI > 0,TRUE],
	['QS_missionConfig_hcMaxLoad',[_hc_maxLoad_1,_hc_maxLoad_2,_hc_maxLoad_3,_hc_maxLoad_4],TRUE],
	['QS_missionConfig_hcMaxAgents',[_hc_maxAgents_1,_hc_maxAgents_2,_hc_maxAgents_3,_hc_maxAgents_4],TRUE],
	['QS_missionConfig_dlcVehicles',_dlc_vehicles,TRUE],
	['QS_missionConfig_dlcUnits',_dlc_units,TRUE],
	['QS_missionConfig_allowedClientWorkshopIds',_allowedClientWorkshopIds,FALSE],
	['QS_missionConfig_allowedClientModHashes',_allowedClientModHashes,FALSE],
	['QS_missionConfig_zeusReskinUnits',_zeus_reskinUnits > 0,TRUE],
	['QS_missionConfig_dlcReskin',_basic_reskin > 0,FALSE],
	['QS_missionConfig_dlcReskinParams',_basic_reskin_params,FALSE],
	['QS_missionConfig_aoType',_main_mission_type,TRUE],
	['QS_missionConfig_sideMissions',_sideMissions,FALSE],
	['QS_missionConfig_deploymentMissions',_deploymentMissions > 0,FALSE],
	['QS_missionConfig_deploymentMissionParams',[_dm_MaxConcurrent,_dm_Frequency,_dm_Intensity,_dm_Duration,_dm_SetupTime,_dm_overclock],FALSE],
	['QS_missionConfig_arty',_artillery,FALSE],
	['QS_missionConfig_artyEngine',_artilleryComputer,TRUE],
	['QS_missionConfig_mapContentEnemy',_mapContentEnemy,TRUE],
	['QS_missionConfig_recruitableAI',_recruitableAI,FALSE],
	['QS_missionConfig_playableOPFOR',_playable_opfor,TRUE],
	['QS_missionConfig_carrierEnabled',_aircraft_carrier_enabled,TRUE],
	['QS_missionConfig_carrierVehicles',_aircraft_carrier_vehicles,TRUE],
	['QS_missionConfig_carrierRespawn',_aircraft_carrier_respawning,TRUE],
	['QS_missionConfig_destroyerEnabled',_destroyer_enabled,TRUE],
	['QS_missionConfig_destroyerVehicles',_destroyer_vehicles,FALSE],
	['QS_missionConfig_destroyerRespawn',_destroyer_respawning,TRUE],
	['QS_missionConfig_destroyerArtillery',_destroyer_artillery,TRUE],
	['QS_missionConfig_destroyerFlag',_destroyer_flag,FALSE],
	['QS_missionConfig_destroyerName',_destroyer_name,FALSE],
	['QS_missionConfig_destroyerNumbers',_destroyer_numbers,FALSE],
	['QS_missionConfig_destroyerHangar',_destroyer_hangar,FALSE],
	['QS_missionConfig_fobsDefault',_fobs_default > 0,FALSE],
	['QS_missionConfig_cntnrMobRespawn',_container_mobileRespawn > 0,FALSE],
	['QS_missionConfig_cntnrFortSmall',_container_baseSmall > 0,FALSE],
	['QS_missionConfig_cntnrFortMed',_container_baseMedium > 0,FALSE],
	['QS_missionConfig_cntnrFortBig',_container_baseLarge > 0,FALSE],
	['QS_missionConfig_cntnrPlatform',_container_platform > 0,FALSE],
	['QS_missionConfig_cntnrTerrain',_container_terrain > 0,FALSE],
	['QS_missionConfig_cntnrSAM',_container_SAM > 0,FALSE],
	['QS_missionConfig_cntnrRadar',_container_radar > 0,FALSE],
	['ApexFramework_3DGroupIconColor',_IconColor3D,TRUE],
	['QS_missionConfig_communityLogo',_community_logo,TRUE],
	['QS_missionConfig_textures_communityFlag',_community_flag_texture,TRUE],
	['QS_missionConfig_textures_defaultFlag',_default_flag_texture,TRUE],
	['QS_missionConfig_textures_billboard1',_billboard_1,TRUE],
	['QS_missionConfig_textures_billboard2',_billboard_2,TRUE],
	['QS_missionConfig_textures_infostand1',_infostand_1,TRUE],
	['QS_missionConfig_textures_infostand2',_infostand_2,TRUE],
	['QS_missionConfig_splash_serverRules',_serverRules,TRUE],
	['QS_missionConfig_splash_adminNames',_staffNames,TRUE],
	['QS_missionConfig_cosmetics',(compileFinal (str _monetizeCosmetics)),TRUE],
	['QS_missionConfig_monetizeURL',(compileFinal (str _monetizeURL)),TRUE],
	['QS_missionConfig_dbQueryDebug',_query_debug,FALSE],
	['QS_missionConfig_dbWhitelistEnabled',_dynamic_whitelist,FALSE]
];
{
	uiNamespace setVariable _x;
} forEach [
	['QS_fnc_serverCommandPassword',(compileFinal _serverCommandPassword)]
];
diag_log format ['***** %1 * Loaded mission parameters *****',diag_tickTime];
