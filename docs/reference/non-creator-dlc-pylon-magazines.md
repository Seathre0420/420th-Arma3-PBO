# Non-Creator-DLC pylon weapon magazines

**35 selectable weapon magazine classes**, extracted from the locally installed Arma 3 **2.22.0.154089** (Steam build **25623484**) on **2026-10-12**.

Includes live missiles, rockets, GBU-12/Mk82 bombs, and gun pods from the base game, free updates, and Bohemia DLC.

Excludes fuel tanks, sensor/searchlight/ECM/countermeasure pods, leaflet dispensers, dummy training ammunition, non-selectable base classes, all AMRAAM-D variants, Creator DLC, and third-party mods.

Air-to-ground missiles and guided rockets are limited to KH25 (external and internal variants) and Sharur.

Bombs are limited to GBU-12 (single and double racks) and Mk82; cluster bombs and mine-clearing charges are excluded.

The SQF file returns all 35 classnames as an array. The JSON adds English display names, ammo classes, pylon weapons, hardpoints, scope, and source PBOs. The runtime allowlist is `random_pylon_magazines_1` in `Apex_framework.terrain/code/config/QS_data_listItems.sqf`; keep these references synchronized with it.

## Method and scope

Scanned 508 PBOs in the installed non-Creator-DLC content roots; read their root config.bin/config.cpp files and converted binary configs using Bohemia's [CfgConvert](https://community.bohemia.net/wiki/CfgConvert). Resolved magazine property inheritance and selected classes with `scope = 2` and non-empty `hardpoints[]`, then removed non-weapon stores and dummy ammunition. English names come from the installed stringtables.

Scanned roots: `Addons`, `Dta`, `AoW`, `Argo`, `Bonus`, `Contact`, `Curator`, `Enoch`, `Expansion`, `Heli`, `Jets`, `Kart`, `Mark`, `Orange`, `Tacops`, `Tank`.

The installed Creator DLC roots `EF`, `RF`, and `WS`, Steam Workshop content, and external mod directories were excluded. This is a snapshot of the installed version.

Randomized loadouts (mode 2) choose only magazines that are both in this list and compatible with the specific aircraft pylon. Matching is case-insensitive. This replaces the old air-to-ground missile blacklist, so compatible KH25, Sharur, and Mk82 magazines are eligible. The existing helicopter filter still excludes ammo classnames containing `aa`. Pylons with no eligible magazines remain empty; the old bomb substitution is removed. Preset mode (1) and Skyfire-only mode (3) retain their existing behavior. Normal AO and defend jets still have bombs removed after loading.

## Counts

| Category | Classes |
| --- | ---: |
| Air-to-air missiles | 17 |
| Air-to-ground missiles and guided rockets | 3 |
| Bombs | 4 |
| Gun pods | 4 |
| Unguided rockets | 7 |
| **Total** | **35** |

## Air-to-air missiles

| Classname | English display name | Count | Source PBO |
| --- | --- | ---: | --- |
| `PylonMissile_1Rnd_AAA_missiles` | ASRAAM | 1 | `Addons/weapons_f.pbo` |
| `PylonMissile_1Rnd_GAA_missiles` | Zephyr | 1 | `Addons/weapons_f.pbo` |
| `PylonMissile_1Rnd_Missile_AA_03_F` | Sahr-3 | 1 | `Addons/weapons_f.pbo` |
| `PylonMissile_1Rnd_Missile_AA_04_F` | Falchion-22 | 1 | `Addons/weapons_f.pbo` |
| `PylonMissile_Missile_AA_R73_x1` | R73 SR AA x1 | 1 | `Jets/Addons/weapons_f_jets.pbo` |
| `PylonMissile_Missile_AA_R77_INT_x1` | R77 MR AA x1 | 1 | `Jets/Addons/weapons_f_jets.pbo` |
| `PylonMissile_Missile_AA_R77_x1` | R77 MR AA x1 | 1 | `Jets/Addons/weapons_f_jets.pbo` |
| `PylonMissile_Missile_AMRAAM_C_x1` | AMRAAM C AA x1 | 1 | `Jets/Addons/weapons_f_jets.pbo` |
| `PylonMissile_Missile_BIM9X_x1` | BIM 9X AA x1 | 1 | `Jets/Addons/weapons_f_jets.pbo` |
| `PylonRack_1Rnd_AAA_missiles` | ASRAAM | 1 | `Addons/weapons_f.pbo` |
| `PylonRack_1Rnd_GAA_missiles` | Zephyr | 1 | `Addons/weapons_f.pbo` |
| `PylonRack_1Rnd_Missile_AA_03_F` | Sahr-3 | 1 | `Addons/weapons_f.pbo` |
| `PylonRack_1Rnd_Missile_AA_04_F` | Falchion-22 | 1 | `Addons/weapons_f.pbo` |
| `PylonRack_Missile_AMRAAM_C_x1` | AMRAAM C AA x1 | 1 | `Jets/Addons/weapons_f_jets.pbo` |
| `PylonRack_Missile_AMRAAM_C_x2` | AMRAAM C AA x2 | 2 | `Jets/Addons/weapons_f_jets.pbo` |
| `PylonRack_Missile_BIM9X_x1` | BIM 9X AA x1 | 1 | `Jets/Addons/weapons_f_jets.pbo` |
| `PylonRack_Missile_BIM9X_x2` | BIM 9X AA x2 | 2 | `Jets/Addons/weapons_f_jets.pbo` |

## Air-to-ground missiles and guided rockets

| Classname | English display name | Count | Source PBO |
| --- | --- | ---: | --- |
| `PylonMissile_Missile_AGM_KH25_INT_x1` | KH25 AGM x1 | 1 | `Jets/Addons/weapons_f_jets.pbo` |
| `PylonMissile_Missile_AGM_KH25_x1` | KH25 AGM x1 | 1 | `Jets/Addons/weapons_f_jets.pbo` |
| `PylonRack_1Rnd_Missile_AGM_01_F` | Sharur | 1 | `Addons/weapons_f.pbo` |

## Bombs

| Classname | English display name | Count | Source PBO |
| --- | --- | ---: | --- |
| `PylonMissile_1Rnd_Bomb_04_F` | GBU-12 | 1 | `Addons/weapons_f.pbo`, `Orange/Addons/weapons_f_orange.pbo` |
| `PylonMissile_1Rnd_Mk82_F` | Mk82 | 1 | `Addons/weapons_f.pbo` |
| `PylonMissile_Bomb_GBU12_x1` | GBU 12 LGB x1 | 1 | `Jets/Addons/weapons_f_jets.pbo` |
| `PylonRack_Bomb_GBU12_x2` | GBU 12 LGB x2 | 2 | `Jets/Addons/weapons_f_jets.pbo` |

## Gun pods

| Classname | English display name | Count | Source PBO |
| --- | --- | ---: | --- |
| `PylonWeapon_2000Rnd_65x39_belt` | Minigun 6.5 mm | 2000 | `Addons/weapons_f.pbo` |
| `PylonWeapon_300Rnd_20mm_shells` | Twin Cannon 20mm | 300 | `Addons/weapons_f.pbo` |
| `PylonWeapon_500Rnd_127mm_HEIAP_belt_left` | Minigun 12.7 mm | 500 | `Addons/weapons_f.pbo` |
| `PylonWeapon_500Rnd_127mm_HEIAP_belt_right` | Minigun 12.7 mm | 500 | `Addons/weapons_f.pbo` |

## Unguided rockets

| Classname | English display name | Count | Source PBO |
| --- | --- | ---: | --- |
| `PylonRack_12Rnd_missiles` | DAR | 12 | `Addons/weapons_f.pbo` |
| `PylonRack_12Rnd_missiles_black` | DAR (Black) | 12 | `Addons/weapons_f.pbo` |
| `PylonRack_19Rnd_Rocket_Skyfire` | Skyfire 19x | 19 | `Addons/weapons_f.pbo` |
| `PylonRack_20Rnd_Rocket_03_AP_F` | Tratnyr 20x AP | 20 | `Addons/weapons_f.pbo` |
| `PylonRack_20Rnd_Rocket_03_HE_F` | Tratnyr 20x HE | 20 | `Addons/weapons_f.pbo` |
| `PylonRack_7Rnd_Rocket_04_AP_F` | Shrieker 7x AP | 7 | `Addons/weapons_f.pbo` |
| `PylonRack_7Rnd_Rocket_04_HE_F` | Shrieker 7x HE | 7 | `Addons/weapons_f.pbo` |
