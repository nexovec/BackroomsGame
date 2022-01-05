#pragma language glsl3
#ifdef PIXEL
uniform sampler2DArray MainTex;
uniform vec4 top_left;
uniform vec4 top_right;
uniform vec4 bottom_right;
uniform vec4 bottom_left;

vec4 lerp(vec4 first, vec4 second, float t){
    return first + t * (second - first);
}
void effect()
{
    // TODO:
  vec4 color = VaryingColor;
  vec3 texture_coords = VaryingTexCoord.xyz;
  vec4 texturecolor = Texel(MainTex, texture_coords);
  vec2 lerpAmount = love_PixelCoord.xy / love_ScreenSize.xy;
  love_PixelColor = lerp(lerp(top_left, top_right, lerpAmount.x), lerp(bottom_left, bottom_right, lerpAmount.x), lerpAmount.y);
}
#endif