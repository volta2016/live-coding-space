uniform float iBeat;
uniform float iHat;
uniform sampler2D iChannel0;
uniform float iWobble;
uniform sampler2D iChannel1;
//No we just need to plug it in somewhere...
uniform float iFizzle;

uniform float iStars;
uniform float iCells;

#ifdef GL_ES
precision mediump float;
#endif

vec2 rotate(vec2 p, float a){
  return vec2(p.x * cos(a) - p.y * sin(a), p.x * sin(a) + p.y * cos(a));
}

float smoothedVolume;

vec4 generateSpaceLights(vec2 uv1){
  vec2 uv = uv1 * 2.0 - 1.0;
  uv.x *= iResolution.x / iResolution.y;

  float v = 0.0;

  vec3 ray = vec3(sin(iGlobalTime * 0.1) * 0.2, cos(iGlobalTime * 0.13) * 0.2, 1.5);
  vec3 dir;
  dir = normalize(vec3(uv, 1.0));

  ray.z += iGlobalTime * 0.001 - 20.0;
  dir.xz = rotate(dir.xz, sin(iGlobalTime * 0.001) * 0.1);
  dir.xy = rotate(dir.xy, iGlobalTime * 0.01);

  #define STEPS 8


  smoothedVolume += (iVolume  - smoothedVolume) * 0.1;

  float inc = smoothedVolume / float(STEPS);
  if (iVolume <=0.01){
    inc = 0;
  }
  else{
    inc = clamp(inc, 0.2,0.8);
  }

  vec3 acc = vec3(0.0);

  for(int i = 0; i < STEPS; i ++){
    vec3 p = ray * 0.4;

    for(int i = 0; i < 14; i ++){
      p = abs(p) / dot(p, p) * 2.0 - 1.0;
    }
    float it = 0.001 * length(p * p);
    v += it;

    acc += sqrt(it) * texture2D(iChannel1, ray.xy * 0.1 + ray.z * 0.1).xyz;
    ray += dir * inc;
  }

  float br = pow(v * 2.0, 1.0) * 0.5;
  vec3 col = pow(acc * 4.1, vec3(2.2)) + br;
  return vec4(col, 1.0);
}

vec2 hash( vec2 p ){
  float sound = texture2D(iChannel0, vec2(p.x,.15)).x;
  //CRAZy 
     mat2 m = mat2( 15.32, 83.43,
                     117.38, 289.59);
                     vec2 uv = ( gl_FragCoord.xy / iResolution.xy ) * 2.0 - 1.0;
   
                     //We have access to the sound in
                     //An FFT with data as a texture

       //Now the frequency is controlling the cells
     return fract( sin( m * p) * 46783.289+ sound*0.01 );
}

float voronoi( vec2 p ){
     vec2 g = floor( p );
     vec2 f = fract( p );
    
     float distanceFromPointToCloestFeaturePoint = 1.0;
     for( int y = -1; y <= 1.0; ++y )
     {
          for( int x = -1; x <= 1.0; ++x )
          {
               vec2 latticePoint = vec2( x, y );
               float h = distance( latticePoint + hash( g + latticePoint), f );
		  
		distanceFromPointToCloestFeaturePoint = min( distanceFromPointToCloestFeaturePoint, h ); 
          }
     }
    
     return 1.0 - sin(distanceFromPointToCloestFeaturePoint);
}

float texture(vec2 uv )
{
	float t = voronoi( uv * 8.0 + vec2(iGlobalTime*0.1) );
    t *= 1.0-length(uv * 2.0);
	
	return t;
}

float fbm( vec2 uv ){
	float sum = 0.00;
	float amp = 1.0;
	
	for( int i = 0; i < 2; ++i )
	{
		sum += texture( uv ) * amp;
		uv += uv;
		amp *= 0.1 * iFizzle;
    //nice! accident but I like it
	}
	return sum;
}

vec4 lineDistort(vec4 cTextureScreen, vec2 uv1){
  float sCount = 900.;
  float nIntensity=0.1;
  float sIntensity=0.2;
  float noiseEntry = 0.0;
  float accelerator= 1000.0;

  // sample the source
  float x = uv1.x * uv1.y * iGlobalTime * accelerator;
  x = mod( x, 13.0 ) * mod( x, 123.0 );
  float dx = mod( x, 0.05 );
  vec3 cResult = cTextureScreen.rgb + cTextureScreen.rgb * clamp( 0.1 + dx * 100.0, 0.0, 1.0 );
  // get us a sine and cosine
  vec2 sc = vec2( sin( uv1.y * sCount ), cos( uv1.y * sCount ) );
  // add scanlines
  cResult += cTextureScreen.rgb * vec3( sc.x, sc.y, sc.x ) * sIntensity;

  // interpolate between source and result by intensity
  cResult = cTextureScreen.rgb + clamp(nIntensity, noiseEntry,1.0 ) * (cResult - cTextureScreen.rgb);

  return vec4(cResult, cTextureScreen.a);
}

void main(void){
    vec2 uv = ( gl_FragCoord.xy / iResolution.xy ) * 2.0 - 1.0;
    uv.x *= iResolution.x / iResolution.y;
  
    vec4 lights = vec4(0.0);
    if(iStars > 0.0){
      lights = generateSpaceLights(uv);
    }
    vec4 cells = vec4(0.0);
    if(iCells > 0.0){
      float zoom = sin(iGlobalTime*0.01)*0.5 + 0.5 + iBeat;
      float t = pow( fbm( uv * zoom ), 2.0);
      cells = vec4( vec3( t * iBeat+(iHat*0.2), t * iBeat, t * iBeat ), 1.0 );
    }
    
    vec4 result = cells + lights;
    gl_FragColor = lineDistort(result, uv);
}