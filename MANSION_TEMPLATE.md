# Building the mansion

Open `Globals/game.tscn`. The `MansionLayout` node is the single editable template. Its children are copied to both player worlds when the scene starts; arrange this template rather than editing the two viewport copies. Run the project or this scene to test it.

- Drag room scenes from `scenes/rooms` under `MansionLayout`. Position them in the 2D editor. Rooms are 540 pixels high. Use the Inspector's Room Width and Room Id fields when needed.
- Instance `scenes/connectors/door_connector.tscn` under `MansionLayout` at the shared horizontal edge of two rooms. Give it a unique, non-empty Door Id, set Room A and Room B, and choose its Initial State. Closed and locked doors block crossing. Interacting opens a closed door or closes an open door. A locked door opens only when the shared inventory holds a key, which stays in the inventory.
- Instance `scenes/connectors/ladder_connector.tscn` under `MansionLayout`. Place its lower endpoint at the lower room's player height. To change the other end, enable Editable Children for that ladder instance and move its UpperEndpoint. Each endpoint's Destination points to the opposite ArrivalMarker, which can also be repositioned. Both endpoints use the local player's interact button.
- Align adjacent room edges exactly. Doors currently connect rooms side by side at their shared edge; ladders connect vertically separated locations. The movement system uses room rectangles and connector positions, so update room width and door placement together.
- Rooms with no doors are visible by default. Other rooms are visible to a local player when they are inside or at least one connected door is open.
- `Attic/Player1Spawn` and `Attic/Player2Spawn` mark the starting positions. Players use E and Enter to interact. The shared inventory shows three slots. Keys 6, 7 and 8 drop items at the position of the player who most recently picked one up.

To run the connector integration check from the project directory with Godot 4:

`godot --headless --path . --script res://scripts/tests/mansion_connectors_test.gd`
