#pragma language glsl3
#ifdef PIXEL
uniform sampler2DArray MainTex;
uniform vec4 color1;
uniform vec4 color2;
uniform vec2 rectSize;

void effect() {
  vec4 color = VaryingColor;
  vec3 texture_coords = VaryingTexCoord.xyz;
  vec4 texturecolor = Texel(MainTex, texture_coords);

  //   love_PixelColor = texturecolor * color;
  if (int(love_PixelCoord.x / rectSize.x) % 2 + (int(love_PixelCoord.y / rectSize.y) % 2 - 1) == 0) {
    love_PixelColor = color1;
  } else {
    love_PixelColor = color2;
  }
}
#endif