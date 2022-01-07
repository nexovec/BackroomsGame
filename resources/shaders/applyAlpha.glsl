#pragma language glsl3
#ifdef PIXEL
uniform sampler2D MainTex;
uniform sampler2D alphaMask;

void effect()
{
  vec4 color = VaryingColor;
  vec3 texture_coords = VaryingTexCoord.xyz;
  vec4 texturecolor = Texel(MainTex, texture_coords.xy);
  vec4 alphacolor = Texel(alphaMask, texture_coords.xy);
  love_PixelColor = vec4(texturecolor.xyz, alphacolor.w);
}
#endif