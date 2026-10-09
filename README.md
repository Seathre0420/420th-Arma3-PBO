Mission file for 420th Delta Invade & Annex.

## Main base safe zone

Place markers in the Arma 3 Editor named `QS_base_safe_1`, `QS_base_safe_2`,
`QS_base_safe_3`, and so on. Each marker's position defines one vertex of the
main base safe zone. Use unique positive integer suffixes; gaps are allowed.
Markers are sorted numerically (so 2 comes before 10), then connected in that
order, with the last point connected back to the first.

Number the markers clockwise or counterclockwise around the perimeter. Concave
boundaries are supported, but edges must not cross. Use at least three distinct
points enclosing a nonzero area. Marker shape, size, and direction do not affect
the boundary. There is no script-imposed limit on the number of vertices.

The polygon is built at mission initialization and has no altitude restriction.
Adding, removing, or moving these markers in the editor changes the boundary on
the next mission start. With missing markers, malformed or duplicate numeric
suffixes, repeated positions, or zero signed area, the mission logs a diagnostic
and falls back to the original circle (750 m on Altis; 500 m on other maps).
Crossing edges are not automatically validated; check the perimeter in the editor.

This changes only `BASE_HIGHSEC_0`. Its existing protection behavior is retained.
Polygon queries support both objects and coordinate positions so fire-support
target checks also respect the boundary.
The separate 1,000 m `QS_client_inBaseArea` check, vehicle-restricted infantry
spawn polygon, and speed-limit polygons keep their existing definitions.

## Spawn Menu vehicle abandonment

Non-UAV Spawn Menu vehicles are checked approximately every five seconds. An
unattached vehicle that is neither deployed nor logistics-packed is deleted when
its owner is more than 25 m away inside the main base boundary, or more than
1,500 m away outside it. Owner distance is horizontal (`distance2D`), and exactly
25 m or 1,500 m does not trigger deletion. The main base query uses
`BASE_HIGHSEC_0`, including its existing circular fallback for invalid markers.

This check does not require an empty vehicle, movement from its spawn position,
or absence of other players or rally points. It also replaces submerged cleanup
for these vehicles. Attachment means an `attachedTo` parent; ropes and vehicle
cargo do not independently exempt a vehicle. Deletion retires the vehicle's
manager entry so it is not automatically replaced. Owner disconnect, destruction,
manual vehicle respawn, and UAV cleanup retain their separate behavior.
