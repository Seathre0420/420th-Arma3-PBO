"""Check the runtime pylon allowlist against the reviewed reference artifacts."""

from collections import Counter
import json
from pathlib import Path
import re


ROOT = Path(__file__).resolve().parents[2]
REFERENCE = ROOT / "docs/reference/non-creator-dlc-pylon-magazines"
runtime = (ROOT / "Apex_framework.terrain/code/config/QS_data_listItems.sqf").read_text(encoding="utf-8")
block = re.search(
    r"if \(_type isEqualTo 'random_pylon_magazines_1'\) exitWith \{(.*?)\n\};",
    runtime,
    re.S,
)
assert block, "Runtime allowlist is missing"
runtime_names = re.findall(r"'(Pylon\w+)'", block[1])
sqf_names = re.findall(r'^\s+"(Pylon\w+)"', REFERENCE.with_suffix(".sqf").read_text(), re.M)
report_names = re.findall(r'^\| `(Pylon\w+)` \|', REFERENCE.with_suffix(".md").read_text(), re.M)
data = json.loads(REFERENCE.with_suffix(".json").read_text(encoding="utf-8"))
rows = data["magazines"]
json_names = [row["classname"] for row in rows]

assert len(runtime_names) == len(set(name.lower() for name in runtime_names)) == 35
assert runtime_names == sqf_names == json_names, "Runtime and reference arrays differ"
assert set(report_names) == set(runtime_names), "Readable reference differs"
assert all(row["scope"] == 2 and row["hardpoints"] and row["pylonWeapon"] for row in rows)
assert data["metadata"]["selectable_count"] == len(rows)
assert data["metadata"]["categories"] == dict(Counter(row["category"] for row in rows))
assert {row["classname"] for row in rows if row["category"] == "Air-to-ground missiles and guided rockets"} == {
    "PylonMissile_Missile_AGM_KH25_INT_x1",
    "PylonMissile_Missile_AGM_KH25_x1",
    "PylonRack_1Rnd_Missile_AGM_01_F",
}
assert {row["classname"] for row in rows if row["category"] == "Bombs"} == {
    "PylonMissile_1Rnd_Bomb_04_F",
    "PylonMissile_1Rnd_Mk82_F",
    "PylonMissile_Bomb_GBU12_x1",
    "PylonRack_Bomb_GBU12_x2",
}
assert not any("amraam_d" in name.lower() for name in runtime_names)
print("Pylon allowlist passed: 35 unique weapon magazines; all reference files agree.")
