shader_type canvas_item;

void vertex() {
	float slowmotionFactor = 12.0;
	
	UV += vec2(-TIME, TIME ) / slowmotionFactor;
}
