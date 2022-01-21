#pragma language glsl3

#ifdef PIXEL
uniform sampler2DArray MainTex;
uniform vec4 color1;
uniform vec4 color2;
uniform vec2 rectSize;

vec4 quat_from_axis_angle(vec3 axis, float angle) {
  vec4 qr;
  qr.x = axis.x * sin(angle);
  qr.y = axis.y * sin(angle);
  qr.z = axis.z * sin(angle);
  qr.w = cos(angle);
  return qr;
}

vec4 quat_conj(vec4 q) { return vec4(-q.x, -q.y, -q.z, q.w); }

vec4 quat_mult(vec4 q1, vec4 q2) {
  vec4 qr;
  qr.x = (q1.w * q2.x) + (q1.x * q2.w) + (q1.y * q2.z) - (q1.z * q2.y);
  qr.y = (q1.w * q2.y) - (q1.x * q2.z) + (q1.y * q2.w) + (q1.z * q2.x);
  qr.z = (q1.w * q2.z) + (q1.x * q2.y) - (q1.y * q2.x) + (q1.z * q2.w);
  qr.w = (q1.w * q2.w) - (q1.x * q2.x) - (q1.y * q2.y) - (q1.z * q2.z);
  return qr;
}

vec3 rotate_vertex_position(vec3 position, vec3 axis, float angle) {
  vec4 qr = quat_from_axis_angle(axis, angle);
  vec4 qr_conj = quat_conj(qr);
  vec4 q_pos = vec4(position.x, position.y, position.z, 0);

  vec4 q_tmp = quat_mult(qr, q_pos);
  qr = quat_mult(q_tmp, qr_conj);

  return vec3(qr.x, qr.y, qr.z);
}
float size(vec3 vec) {
  return sqrt(vec.x * vec.x + vec.y * vec.y + vec.z * vec.z);
}
float size(vec4 vec) {
  return sqrt(vec.x * vec.x + vec.y * vec.y + vec.z * vec.z + vec.w * vec.w);
}
vec3 rotateVector(vec4 quat, vec3 vec) {
  return vec + 2.0 * cross(cross(vec, quat.xyz) + quat.w * vec, quat.xyz);
}

void effect() {
  float PI = 3.1415926535897932384626433832795;
  vec3 oldPos = vec3(love_PixelCoord.xy, 10);
  float oldPosSize = size(oldPos);
  vec3 oldPosNormalized = oldPos / oldPosSize;
  // vec3 rot = rotate_vertex_position(oldPosNormalized, vec3(0, 0, 1), PI) * oldPosSize;
  vec3 rot = rotate_vertex_position(oldPosNormalized, vec3(0, 0, 1), PI/4) * oldPosSize;
  rot += vec3(oldPos);
  int col = int(rot.x / rectSize.x) % 2 + int(rot.y / rectSize.y) % 2;
  if (col % 2 == 0) {
    love_PixelColor = color1;
  } else {
    love_PixelColor = color2;
  }
}
#endif