shader_type canvas_item;

// Applied only to the visual ghost sprite. Coordinates are in the source
// sprite's local space, so the animation cannot affect gameplay positions.
void vertex() {
	float wave_a = sin(TIME * 3.5 + VERTEX.y * 0.035);
	float wave_b = sin(TIME * 5.0 + VERTEX.y * 0.08);
	VERTEX.x += wave_a * 9.0 + wave_b * 3.0;
	VERTEX.y += sin(TIME * 2.2 + VERTEX.x * 0.04) * 2.5;
}
