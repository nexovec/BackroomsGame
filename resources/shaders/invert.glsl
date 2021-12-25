#pragma language glsl3
#ifdef PIXEL
uniform sampler2DArray MainTex;

void effect()
{
  vec4 color = VaryingColor;
  vec3 texture_coords = VaryingTexCoord.xyz;
  vec4 texturecolor = Texel(MainTex, texture_coords);
  love_PixelColor = vec4((vec4(1.0,1.0,1.0,1.0) - texturecolor).xyz, 1.0) * color;
}
#endif