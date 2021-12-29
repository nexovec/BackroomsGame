#pragma language glsl3
#ifdef PIXEL
uniform sampler2DArray MainTex;
uniform float rounding;

float componentSum(vec2 vec){
    return vec.x+vec.y;
}
void effect()
{
  vec2 screenPos = love_PixelCoord.xy;
  vec2 screenSize = love_ScreenSize.xy;

  vec2 distanceFromUpperLeftCorner = vec2(rounding - screenPos.x, rounding - screenPos.y);
  bool isInUpperLeftCorner = screenPos.x < rounding && screenPos.y < rounding && rounding*rounding < componentSum(distanceFromUpperLeftCorner * distanceFromUpperLeftCorner);

  vec2 distanceFromUpperRightCorner = vec2(screenPos.x - (screenSize.x - rounding), rounding - screenPos.y);
  bool isInUpperRightCorner = screenPos.y < rounding && screenPos.x > screenSize.x - rounding && rounding * rounding < componentSum(distanceFromUpperRightCorner * distanceFromUpperRightCorner);

  vec2 distanceFromBottomLeftCorner = vec2(rounding - screenPos.x,  screenPos.y - (screenSize.y - rounding));
  bool isInBottomLeftCorner = screenPos.y > screenSize.y - rounding && screenPos.x < rounding && rounding * rounding < componentSum(distanceFromBottomLeftCorner * distanceFromBottomLeftCorner);

  vec2 distanceFromBottomRightCorner = vec2(screenPos.x - (screenSize.x - rounding),  screenPos.y - (screenSize.y - rounding));
  bool isInBottomRightCorner = screenPos.y > screenSize.y - rounding && screenPos.x > screenSize.x - rounding && rounding * rounding < componentSum(distanceFromBottomRightCorner * distanceFromBottomRightCorner);
// bool isInBottomRightCorner = false;
  if(isInUpperRightCorner ||  isInUpperLeftCorner || isInBottomRightCorner || isInBottomLeftCorner){
      love_PixelColor = vec4(0,0,0,0);
  }
  else{
      love_PixelColor = vec4(1,1,1,1);
  }
}
#endif