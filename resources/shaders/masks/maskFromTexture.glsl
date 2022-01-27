#pragma language glsl3
#ifdef PIXEL
uniform sampler2DArray MainTex;
uniform sampler2D Tex;

void effect()
{
  vec2 screenPos = love_PixelCoord.xy;
  vec2 screenSize = love_ScreenSize.xy;
  vec2 textureCoords = VaryingTexCoord.xy;

//   love_PixelColor = 1 - int(Texel(Tex, textureCoords)) * vec4(1, 1, 1, 1);
    vec4 texel = Texel(Tex, textureCoords);
  if(texel.w == 0){
      love_PixelColor = vec4(0, 0, 0, 0);
  }else{
    // love_PixelColor = vec4(1, 1, 1, 1);
    love_PixelColor = vec4(1, 1, 1, 1) * vec4(0.1, 0.1, 0.1, 0.7);
  }
}
#endif