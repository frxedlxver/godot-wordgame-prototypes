shader_type canvas_item;
uniform int steps : hint_range(2, 256, 1) = 16;	// levels per channel
void vertex() {

}

void fragment() {
	// Sample the sprite’s base texture
	vec4 col = COLOR;

	// Quantise each RGB channel
	float s = float(steps - 1);          // e.g. 7 if steps = 8
	col.rgb = floor(col.rgb * s + 0.5)   // round to nearest bucket
	          / s;                       // bring back to 0-1 range

	COLOR = col;                         // alpha is left unchanged
}

//void light() {
	// Called for every pixel for every light affecting the material.
	// Uncomment to replace the default light processing function with this one.
//}
