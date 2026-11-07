# Building the mansion

Open `Globals/game.tscn`. The `MansionLayout` node is the single editable template. Its children are copied to both player worlds when the scene starts; arrange this template rather than editing the two viewport copies. Run the project or this scene to test it.

- Drag room scenes from `scenes/rooms` under `MansionLayout`. Position them in the 2D editor. Rooms are 540 pixels high. Use the Inspector's Room Width and Room Id fields when needed.
- Instance `scenes/connectors/door_connector.tscn` under `MansionLayout` at the shared horizontal edge of two rooms, at the players' floor height. Give it a unique, non-empty Door Id, set Room A and Room B to the two room nodes using the Inspector, and choose Initially Locked. Doors block crossing until unlocked. Both worlds share the same door state. The player interacts with a door to toggle its lock.
- Instance `scenes/connectors/ladder_connector.tscn` under `MansionLayout`. Place its lower endpoint at the lower room's player height. To change the other end, enable Editable Children for that ladder instance and move its UpperEndpoint. Each endpoint's Destination points to the opposite ArrivalMarker, which can also be repositioned. Both endpoints use the local player's interact button.
- Align adjacent room edges exactly. Doors currently connect rooms side by side at their shared edge; ladders connect vertically separated locations. The movement system uses room rectangles and connector positions, so update room width and door placement together.
- Rooms with no doors are visible by default. Other rooms are visible to a local player when they are inside or at least one connected door is unlocked. Players use E and Enter respectively; 6, 7 and 8 drop shared inventory slots.

To run the connector integration check from the project directory with Godot 4:

`godot --headless --path . --script res://scripts/tests/mansion_connectors_test.gd`
