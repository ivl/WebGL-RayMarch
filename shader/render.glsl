#ifdef GL_ES
precision highp float;
#endif

/* CONSTANTS */
#define EPS       0.001
#define EPS1      0.01
#define PI        3.14159265
#define HALFPI    1.57079633
#define QUARTPI   0.78539816
#define ROOTTHREE 0.57735027
#define HUGE_VAL  1e20

#define MAX_STEPS 32

/* GENERAL FUNCS */
// source: inigo quilez
float maxcomp( in vec3 p ) {
  return max(p.x,max(p.y,p.z));
}

/* DISTANCE FUNCS */
// source: http://www.iquilezles.org/www/articles/distfunctions/distfunctions.htm

/* PRIMITIVES */
float sdPlane( vec3 p, vec4 n )
{
  // n must be normalized
  return dot(p,n.xyz) + n.w;
}
float sdSphere( vec3 p, float s )
{
  return length(p)-s;
}
float sdBox( vec3 p, vec3 b ) {
  vec3  di = abs(p) - b;
  float mc = maxcomp(di);
  return min(mc,length(max(di,0.0)));
}
float udBox( vec3 p, vec3 b )
{
  return length(max(abs(p)-b,0.0));
}
float udRoundBox( vec3 p, vec3 b, float r )
{
  return length(max(abs(p)-b,0.0))-r;
}
float sdCylinder( vec3 p, vec3 c )
{
  return length(p.xz-c.xy)-c.z;
}
float sdTorus( vec3 p, vec2 t )
{
  vec2 q = vec2(length(p.xz)-t.x,p.y);
  return length(q)-t.y;
}
float lengthN(vec2 v, float n) {
  return pow(pow(v.x,n)+pow(v.y,n), 1.0/n);
}
float sdTorusN( vec3 p, vec2 t, float n )
{
  vec2 q = vec2(lengthN(p.xz,n)-t.x,p.y);
  return lengthN(q,n)-t.y;
}

/* OPERATIONS */
float opU( float d1, float d2 )
{
  return min(d1,d2);
}
float opS( float d1, float d2 )
{
  return max(-d1,d2);
}
float opI( float d1, float d2 )
{
  return max(d1,d2);
}

/* FRACTALS */

#define ITERATIONS 3
float sdMenger(in vec3 p)
{
  float d = sdBox(p,vec3(1.0));

  float s = 1.0;
  for( int m=0; m<ITERATIONS; m++ )
  {
    vec3 a = mod( p*s, 2.0 )-1.0;
    s *= 3.0;
    vec3 r = abs(1.0 - 3.0*abs(a));
  
    float da = max(r.x,r.y);
    float db = max(r.y,r.z);
    float dc = max(r.z,r.x);
    float c = (min(da,min(db,dc))-1.0)/s;
  
    d = max(d,c);
  }
  
  return d;
}
#undef ITERATIONS

#define ITERATIONS 10
#define SCALE 2.0
float sdTetra(vec3 z)
{
  vec3 a1 = vec3(1,1,1);
  vec3 a2 = vec3(-1,-1,1);
  vec3 a3 = vec3(1,-1,-1);
  vec3 a4 = vec3(-1,1,-1);
  vec3 c;
  float dist, d;
  int n = 0;
  for(int i=0; i<ITERATIONS; i++) {
    c = a1; dist = length(z-a1);
    d = length(z-a2); if (d < dist) { c = a2; dist=d; }
    d = length(z-a3); if (d < dist) { c = a3; dist=d; }
    d = length(z-a4); if (d < dist) { c = a4; dist=d; }
    z = SCALE*z-c*(SCALE-1.0);
    n++;
  }

  return length(z) * pow(SCALE, float(-n));
}
#define OFFSET 1.0
float sdTetra1(vec3 z)
{
  float r;
  int n = 0;
  for(int i=0; i<ITERATIONS; i++) {
     if(z.x+z.y<0.0) z.xy = -z.yx; // fold 1
     if(z.x+z.z<0.0) z.xz = -z.zx; // fold 2
     if(z.y+z.z<0.0) z.zy = -z.yz; // fold 3
     z = z*SCALE - OFFSET*(SCALE-1.0);
     r = dot(z, z);
     n++;
  }
  return length(z) * pow(SCALE, float(-n));
}
#undef OFFSET
#undef ITERATIONS
#undef SCALE



////////////////////////////////////////////////////////////
//  PROGRAM CODE
////////////////////////////////////////////////////////////

/* SHADER VARS */
varying vec2 vUv;

uniform vec3 uCamCenter;
uniform vec3 uCamPos;
uniform vec3 uCamUp;
uniform float uAspect;
uniform float uTime;
uniform vec3 uLightP;

#define FOGCOLOR  vec3(0.6, 0.6, 0.7)
#define MATERIAL0 vec3(0.5)
#define MATERIAL1 vec3(0.9, 0.7, 0.5)
#define MATERIAL2 vec3(0.3, 0.5, 1.0)

vec3 currCol = MATERIAL0;
float currSSS = 1.0;

float getDist(in vec3 p) {
  // wrapping xz plane
  //p.x = mod(p.x,8.0)-4.0;
  //p.z = mod(p.z,8.0)-4.0;

  float d0, d1;
  
  // rotation matrix
  //mat3 rotateY = mat3(
  //  cos(uTime),   0.0,  sin(uTime),
  //  0.0,          1.0,  0.0,       
  //  -sin(uTime),  0.0,  cos(uTime)
  //);
  //mat3 rotateX = mat3(
  //  1.0, 0.0, 0.0,
  //  0.0, cos(uTime), sin(uTime), 
  //  0.0, -sin(uTime), cos(uTime)
  //);
  //vec3 p1 = rotateY*rotateX*p;
  
  d0 = sdTetra1(p/2.0)*2.0;
  
  //d0 = sdBox(p,vec3(1.0, 2.0, 2.0));
  //d1 = sdSphere(p-vec3(0.0, 1.5, 0.0), 1.5);
  //d0 = opS(d1, d0);
  
  d1 = sdPlane(p+vec3(0.0,3.0,0.0), vec4(0.0,1.0,0.0,0.0));
  if (d1<d0) {
    d0 = d1;
    currCol = MATERIAL0;
    currSSS = 0.0;
  }
  else   {
    currCol = MATERIAL2;
    currSSS = 1.0;
  }
  
  return d0;
}

// source: inigo quilez
// normal from central difference
vec3 getNormal(in vec3 pos) {
  vec3 eps = vec3(EPS, 0.0, 0.0);
  vec3 nor;
  nor.x = getDist(pos+eps.xyy) - getDist(pos-eps.xyy);
  nor.y = getDist(pos+eps.yxy) - getDist(pos-eps.yxy);
  nor.z = getDist(pos+eps.yyx) - getDist(pos-eps.yyx);
  return normalize(nor);
}

int intersectSteps(in vec3 ro, in vec3 rd) {
  float t = 0.0;
  int steps = -1;  
  
  for(int i=0; i<MAX_STEPS; ++i)
  {
    float dt = getDist(ro + rd*t);
    if(dt >= EPS) {
      steps++;
    }
    else {
      break;
    }
    t += dt;
  }
  return steps;
}
float intersectDist(in vec3 ro, in vec3 rd) {
  float t = 0.0;
  float dist = -1.0;
  
  for(int i=0; i<MAX_STEPS; ++i)
  {
    float dt = getDist(ro + rd*t);
    if(dt < EPS) {
      dist = t;
      break;
    }
    t += dt;
  }
  
  return dist;
}

// source: the.savage@hotmail.co.uk
float getShadow (in vec3 pos, in vec3 toLight) {
  float fShadow=1.0;
  float fLight = distance(uLightP,pos);

  float fLen=EPS*2.0;

  for(int n=0;n<MAX_STEPS;n++)
  {
    if(fLen>=fLight) break;

    float fDist = getDist(pos+(toLight*fLen));
    if(fDist<EPS) return 0.0;

    fShadow=min(fShadow,10.0*(fDist/fLen));

    fLen+=fDist;
  }

  return clamp(fShadow, 0.0, 1.0);
}

#define AO_K      1.5
#define AO_DELTA  0.15
#define AO_N      5
float getAO (in vec3 pos, in vec3 nor) {
  float sum = 0.0;
  float weight = 0.5;
  float delta = AO_DELTA;
  
  for (int i=0; i<AO_N; ++i) {
    sum += weight * (delta - getDist(pos+nor*delta));
    
    delta += AO_DELTA;
    weight *= 0.5;
  }
  return clamp(1.0 - AO_K*sum, 0.0, 1.0);
}

#define SSS_K      1.5
#define SSS_DELTA  0.3
#define SSS_N      5
float getSSS (in vec3 pos, in vec3 look) {
  float sum = 0.0;
  float weight = -0.5;
  float delta = SSS_DELTA;
  
  for (int i=0; i<SSS_N; ++i) {
    sum += weight * min(0.0, getDist(pos+look*delta));
    
    delta += delta;
    weight *= 0.5;
  }
  return clamp(SSS_K*sum, 0.0, 1.0);
}

#define SS_K      0.7
#define SS_DELTA  0.15
#define SS_BLEND  0.8
#define SS_N      6
float getSoftShadows (in vec3 pos) {
  vec3 lightv = normalize(uLightP-pos);
  
  float sum = 0.0;
  float blend = SS_BLEND;
  float delta = SS_DELTA;
  
  for (int i=0; i<SS_N; ++i) {
    sum += blend * (delta - getDist(pos+lightv*delta));
    
    delta += SS_DELTA;
    blend *= SS_BLEND;
  }
  return clamp(1.0 - SS_K*sum, 0.0, 1.0);
}

 #define RENDER_STEPS
// #define OCCLUSION
// #define SUBSURFACE
// #define SOFTSHADOWS
// #define FOG

#define KA      0.2
#define KD      0.8

vec3 rayMarch (in vec3 ro, in vec3 rd) {
  
#ifdef RENDER_STEPS
  int steps = intersectSteps(ro, rd);  
  return vec3(float(MAX_STEPS-steps)/float(MAX_STEPS));
#else

  float t = intersectDist(ro, rd);  
  
  // draw distance
  //#define TEMPDIST 10.0
  //t = min(t, TEMPDIST);
  //gl_FragColor = vec4(vec3((TEMPDIST-t)/TEMPDIST), 1.0);
  
  vec3 pos = ro + rd*t;
  vec3 nor = getNormal(pos);
  vec3 toLight = normalize(uLightP-pos);
  
  // diffuse lighting
  vec3 col = currCol * (KA + KD*dot(toLight,nor));
  //vec3 col = vec3(1.0);
  
  #ifdef OCCLUSION
  // Ambient Occlusion
  float ao = getAO(pos, nor);
  col *= ao;
  #endif
  
  #ifdef SUBSURFACE
  /// Subsurface Scattering
  float sss = currSSS*getSSS(pos, rd);
  col *= 1.0-sss;
  #endif
  
  #ifdef SOFTSHADOWS
  // Soft Shadows
  float ss = getSoftShadows(pos);
  col *= ss;
  #endif
  
  #ifdef FOG
  // Add Fog
  float fogAmount = 1.0-exp(-0.02*t);
  col = mix(col, FOGCOLOR, fogAmount);
  #endif

  t = max(sign(t), 0.0);
  return t*col;
  
#endif // RENDER_STEPS
}

////////////////////////////////////////////////////////////
//  MAIN
////////////////////////////////////////////////////////////

void main(void) {
  
  /* CAMERA RAY */
  vec3 C = normalize(uCamCenter-uCamPos);
  vec3 A = normalize(cross(C,uCamUp));
  vec3 B = -1.0/uAspect*normalize(cross(A,C));
  
  // scale A and B by root3/3 : fov = 30 degrees
  vec3 ro = uCamPos+C + (2.0*vUv.x-1.0)*ROOTTHREE*A + (2.0*vUv.y-1.0)*ROOTTHREE*B;
  vec3 rd = normalize(ro-uCamPos);
  
  // rendering
  gl_FragColor = vec4(rayMarch(ro, rd), 1.0);
}