shader_type canvas_item;

/* ───────── Colour controls ───────── */
uniform vec3 color_a : source_color = vec3(0.06, 0.15, 0.50);   // deep blue
uniform vec3 color_b : source_color = vec3(0.90, 0.55, 0.15);   // orange
uniform vec3 color_c : source_color = vec3(0.98, 0.90, 0.80);   // pale highlight
uniform float palette_mix : hint_range(0.0,1.0,0.01) = 0.5;   // blend-curve bias
uniform int quantize_steps : hint_range(0, 256, 1) = 8;

/* ───────── Pattern tuning ───────── */
uniform float zoom         : hint_range(0.05, 4.0, 0.01) = 1.2;
uniform float speed        : hint_range(0.0,  4.0, 0.01) = 0.35;
uniform int   octaves      : hint_range(1, 8, 1) = 6;
uniform float lacunarity   : hint_range(1.5, 4.0, 0.01) = 2.1;
uniform float gain         : hint_range(0.0, 1.0, 0.01) = 0.55;

/* ───────── Warp / squish ───────── */
uniform float swirl_amt    : hint_range(0.0, 2.0, 0.01) = 0.6;
uniform float pulse_amt    : hint_range(0.0, 1.0, 0.01) = 0.25;
uniform float pulse_freq   : hint_range(0.1,10.0,0.01) = 2.0;

uniform float alpha_pow    : hint_range(0.1, 4.0, 0.01) = 1.0;
uniform bool  invert       = false;

/* ───────── small helpers ────────── */
float hash(vec2 p){ return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453); }

float noise(vec2 p){
	vec2 i=floor(p), f=fract(p); f*=f*(3.0-2.0*f);
	float a=hash(i), b=hash(i+vec2(1,0)), c=hash(i+vec2(0,1)), d=hash(i+vec2(1,1));
	return mix(mix(a,b,f.x),mix(c,d,f.x),f.y);
}

float fbm(vec2 p){
	float v=0., amp=.5;
	for(int i=0;i<octaves;i++){
		v+=amp*noise(p);
		p*=lacunarity;
		amp*=gain;
	}
	return v;
}

/* simple tri-blend */
vec3 palette(float t){
	t = clamp(t,0.0,1.0);
	float k = smoothstep(0.0,1.0,palette_mix);
	return mix(mix(color_a,color_b,t), color_c, pow(t,k));
}

/* radial swirl + breathing pulse */
vec2 warp(vec2 uv){
	vec2 center = vec2(0.5);
	vec2 d = uv-center;

	/* swirl that oscillates over time */
	float angle = swirl_amt * sin(length(d)*6.0 - TIME*speed*3.0);
	float s=sin(angle), c=cos(angle);
	d = mat2(vec2(c,-s),vec2(s,c))*d;

	/* pulsating “squish” that pushes pixels in/out */
	float r = length(d);
	float pulse = 1.0 + pulse_amt * sin(TIME*pulse_freq + r*10.0);
	d *= pulse;

	return center + d;
}

vec4 quantize(vec4 color, int steps) {
	float s = float(steps - 1);
	color.rgb = floor(color.rgb * s + 0.5)   // round to nearest bucket
          / s;                       // bring back to 0-1 range
	return color;
}

void fragment(){
	/* pixel-to-UV with viewport-size independence */
	vec2 uv = FRAGCOORD.xy * SCREEN_PIXEL_SIZE;      // 0-1
	uv = (uv-0.5)*zoom + 0.5;                       // zoom centred
	uv = warp(uv);                                  // dynamic warp
	uv.y += TIME*speed;                             // gentle scroll after warp

	float n = fbm(uv*6.0);                          // detail scale
	n = invert ? 1.0-n : n;

	vec3 col = palette(n);
	float a   = pow(n, alpha_pow);

	COLOR = quantize(vec4(col, a), quantize_steps);
}
