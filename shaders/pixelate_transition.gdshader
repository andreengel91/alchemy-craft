shader_type canvas_item;

// Samples the screen in square blocks that grow/shrink to create a pixelate wipe.
// pixel_size = 1 is a perfect passthrough; 32 gives chunky blocks.
uniform sampler2D SCREEN_TEXTURE: hint_screen_texture, filter_nearest;
uniform float pixel_size: hint_range(1.0, 64.0) = 1.0;

void fragment() {
	vec2 block = SCREEN_PIXEL_SIZE * pixel_size;
	vec2 snapped = floor(SCREEN_UV / block) * block + block * 0.5;
	COLOR = texture(SCREEN_TEXTURE, snapped);
	COLOR.a = 1.0;
}
