/*
  Outline shader by Nathan Lovato
  Released under the MIT-LICENSE
  Retrieved from github: https://github.com/GDquest/Godot-engine-tutorial-demos/blob/fce6be9/2018/09-20-shaders/shaders/outline.shader
*/

shader_type canvas_item;
render_mode unshaded;
 
uniform float width : hint_range(0.0, 16.0) = 10;
uniform vec4 outline_color : source_color = vec4(1);
uniform bool enable_shader;
 
void fragment()
{
    if(enable_shader) {
        vec2 size = vec2(width) / vec2(textureSize(TEXTURE, 0));
       
        vec4 sprite_color = texture(TEXTURE, UV);
       
        float alpha = sprite_color.a;
        alpha += texture(TEXTURE, UV + vec2(0.0, -size.y)).a;
        alpha += texture(TEXTURE, UV + vec2(size.x, -size.y)).a;
        alpha += texture(TEXTURE, UV + vec2(size.x, 0.0)).a;
        alpha += texture(TEXTURE, UV + vec2(size.x, size.y)).a;
        alpha += texture(TEXTURE, UV + vec2(0.0, size.y)).a;
        alpha += texture(TEXTURE, UV + vec2(-size.x, size.y)).a;
        alpha += texture(TEXTURE, UV + vec2(-size.x, 0.0)).a;
        alpha += texture(TEXTURE, UV + vec2(-size.x, -size.y)).a;
       
        vec3 final_color = mix(outline_color.rgb, sprite_color.rgb, sprite_color.a);
        COLOR = vec4(final_color, clamp(alpha, 0.0, 1.0));
    } else {
        COLOR = texture(TEXTURE, UV);
    }
}