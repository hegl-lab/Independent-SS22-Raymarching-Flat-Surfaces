
#define M_PI 3.1415926535897932384626433832795

uniform vec2 u_resolution;
uniform float u_time;
uniform vec3 u_cameraPos;
uniform vec2 u_viewAngle;
uniform float u_dz;
uniform float u_dy;
uniform float u_dx;


const float eps = 0.0001;
float tMax = 90.;
float b =2.0;
float wall_height = 2. ;
float dist_screen = 1.;
float cam_detection_boundary = 100.;
vec3 ex = vec3(1.,0.,0.);
vec3 ey = vec3(0.,1.,0.);
vec3 ez = vec3(0.,0.,1.);


mat3 rotMat(vec3 axis, float angle)
{
    axis = normalize(axis);
    float s = sin(angle);
    float c = cos(angle);
    float oc = 1.0 - c;
    
    return mat3(oc * axis.x * axis.x + c,           oc * axis.x * axis.y - axis.z * s,  oc * axis.z * axis.x + axis.y * s,
                oc * axis.x * axis.y + axis.z * s,  oc * axis.y * axis.y + c,           oc * axis.y * axis.z - axis.x * s,
                oc * axis.z * axis.x - axis.y * s,  oc * axis.y * axis.z + axis.x * s,  oc * axis.z * axis.z + c);
}

vec4 opSubtractionT( vec4 d1, vec4 d2 ) {
    return (d2.w < -d1.w) ? vec4(d1.xyz, -d1.w): d2;
}

vec4 opUnionT( vec4 d1, vec4 d2) {
        return (d2.w < d1.w) ? d2: d1;
}

float dot2(vec3 v){
    return dot(v, v);
}


vec4 sdWallT(vec3 p, vec3 a, vec3 b, float height, vec3 translate_by) {
    vec3 d = b - a;

    // cw is the centre of the wall
    vec3 cw = 0.5*(a+b);
    float angle = acos(d.x / length(d));
    p -= cw; 
    p = rotMat(vec3(0., 1., 0.), -angle) * p; // translate by centre and rotate 
    
    vec3 q = abs(p) - vec3(0.5 * length(d), height, 0.5*eps);
    return vec4( translate_by, length(max(q,0.0)) + min(max(q.x,max(q.y,q.z)),0.0));
}

vec4 sdSphereT(vec3 p, float r){
    return vec4(vec3(.0), length(p) - r);
}

vec4 sdBoxT(vec3 p, vec3 b, vec3 translate_by){
    vec3 q = abs(p) - b;
    return vec4(translate_by, length(max(q,0.0)) + min(max(q.x,max(q.y,q.z)),0.0));
}

vec4 sdConeT( vec3 p, vec2 c, float h )
{
    // c is the sin/cos of the angle, h is height
  // Alternatively pass q instead of (c,h),
  // which is the point at the base in 2D
  vec2 q = h*vec2(c.x/c.y,-1.0);
    
  vec2 w = vec2( length(p.xz), p.y );
  vec2 a = w - q*clamp( dot(w,q)/dot(q,q), 0.0, 1.0 );
  vec2 b = w - q*vec2( clamp( w.x/q.x, 0.0, 1.0 ), 1.0 );
  float k = sign( q.y );
  float d = min(dot( a, a ),dot(b, b));
  float s = max( k*(w.x*q.y-w.y*q.x),k*(w.y-q.y)  );
  return vec4(vec3(.0),sqrt(d)*sign(s));
}

/////////////////////////////////////// precomputed values for the double pentagon ////////////////////////////////

// Right pentagon:
//  [[ 3.61803399e+00  0.00000000e+00]
//  [ 2.23606798e+00  1.90211303e+00]
//  [ 2.22044605e-16  1.17557050e+00]
//  [ 0.00000000e+00 -1.17557050e+00]
//  [ 2.23606798e+00 -1.90211303e+00]]
// Left pentagon:
//  [[-2.23606798e+00 -1.90211303e+00]
//  [-0.00000000e+00 -1.17557050e+00]
//  [-2.22044605e-16  1.17557050e+00]
//  [-2.23606798e+00  1.90211303e+00]
//  [-3.61803399e+00  0.00000000e+00]]
// Translation vectors:
//  [[-5.85410197e+00 -1.90211303e+00]
//  [-2.23606798e+00 -3.07768354e+00]
//  [-4.44089210e-16  0.00000000e+00]
//  [-2.23606798e+00  3.07768354e+00]
//  [-5.85410197e+00  1.90211303e+00]]

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

vec4 sdfT(vec3 p){
    //vec4 df = sdBoxT(rotMat(vec3(0., 1., 0.), -M_PI * .75) * (p - vec3(2., 0. ,2.)), vec3(b, wall_height, eps), vec3(4., 0., 4.));
    vec4 df = sdWallT(          p, 
                                vec3(3.61803399e+00,0.,  0.00000000e+00), 
                                vec3(2.23606798e+00, 0., 1.90211303e+00), 
                                wall_height, 
                                (1.- 3.*eps)*vec3(-5.85410197e+00, 0., -1.90211303e+00)); // d right
    df = opUnionT(df, sdWallT(  p, 
                                vec3(-2.23606798e+00,0., -1.90211303e+00), 
                                vec3(-3.61803399e+00,0.,  0.00000000e+00), 
                                wall_height, 
                                -1.*(1.-3.*eps)*vec3(-5.85410197e+00, 0., -1.90211303e+00))); // d left

    df = opUnionT(df, sdWallT(  p, 
                                vec3(0., 0., 1.17557050e+00), 
                                vec3(2.23606798e+00, 0., 1.90211303e+00), 
                                wall_height, 
                                (1.-3.*eps)*vec3(-2.23606798e+00, 0.,-3.07768354e+00))); // c right
    df = opUnionT(df, sdWallT(  p, 
                                vec3(-2.23606798e+00, 0., -1.90211303e+00), 
                                vec3(-0.00000000e+00, 0., -1.17557050e+00), 
                                wall_height, 
                                -1.*(1.-3.*eps)*vec3(-2.23606798e+00, 0.,-3.07768354e+00))); // c left


    df = opUnionT(df, sdWallT(  p, 
                                vec3(2.23606798e+00,0., -1.90211303e+00), 
                                vec3(0.00000000e+00, 0., -1.17557050e+00), 
                                wall_height, 
                                (1.-3.*eps)*vec3(-2.23606798e+00, 0., 3.07768354e+00))); // b right

    df = opUnionT(df, sdWallT(  p, 
                                vec3(0., 0.,  1.17557050e+00), 
                                vec3(-2.23606798e+00, 0.,  1.90211303e+00), 
                                wall_height, 
                                -1. *(1.-3.*eps)*vec3(-2.23606798e+00, 0., 3.07768354e+00))); // b left

    df = opUnionT(df, sdWallT(  p, 
                                vec3(2.23606798e+00, 0., -1.90211303e+00), 
                                vec3(3.61803399e+00, 0.,  0.00000000e+00), 
                                wall_height, 
                                (1.-3.*eps)*vec3(-5.85410197e+00, 0., 1.90211303e+00))); // a left

    df = opUnionT(df, sdWallT(  p, 
                                vec3(-3.61803399e+00, 0.,  0.00000000e+00), 
                                vec3(-2.23606798e+00, 0., 1.90211303e+00), 
                                wall_height, 
                                -1. *(1.-3.*eps)*vec3(-5.85410197e+00, 0., 1.90211303e+00))); // a right
    
    
    df = opUnionT(df, opSubtractionT(sdSphereT(p, 0.13), sdBoxT(p, vec3(0.1), vec3(.0))));
    df = opUnionT(df, sdSphereT(p - vec3(1.618033988749895+1.618033988749895*cos( 3.0 * (0.5*u_time)), 0., sin(3.0 * (0.5*u_time))), 0.07));
    return df;
}

vec3 getNormalT(vec3 p){
    const vec2 h = vec2( eps, 0. );
    return normalize( vec3(sdfT(p+h.xyy).w - sdfT(p-h.xyy).w,
                            sdfT(p+h.yxy).w - sdfT(p-h.yxy).w,
                            sdfT(p+h.yyx).w - sdfT(p-h.yyx).w ) );
}

void main() {
    // camera rotationmatrix
    mat3 viewRotation = rotMat(ey, u_viewAngle[0]) * rotMat(ex, u_viewAngle[1]);
    ex = viewRotation * ex;
    ey = viewRotation * ey;
    ez = viewRotation * ez;

    // translation of the uv_screen
    vec3 uv_screen_origin = u_dz * ez  + u_dx * ex + u_dy * ey;
    vec3 cameraPos = uv_screen_origin - dist_screen*ez;
    vec3 uv_screen = uv_screen_origin + viewRotation * vec3((gl_FragCoord.xy - 0.5 * u_resolution) / (1.*u_resolution.y) + u_cameraPos.xy, 0.);
    // ray marching
    vec3 ray = normalize(uv_screen - cameraPos);
    float t = 0.;
    float t_surface = 0.;
    vec3 pos = cameraPos;
    float collision_count = 0.;

    for(int i = 0; i < 1000; i++) {
        vec4 h = sdfT(pos);
        if(h.w < eps){
            if(h.xyz == vec3(.0)) break;
            pos += h.xyz;
            collision_count += 1.;
            //pos = pos + h.w * ray;
        }
        pos = pos + h.w * ray;
        t += h.w;
    
    }

    // color

    vec3 color = vec3(1.);
    if(t < tMax) {
        //vec3 pos = cameraPos + t * ray;
        vec3 normal = normalize(getNormalT(pos));
        
        //simple vertical light
        // float diff = dot(vec3(1.), normal);
        // color = vec3(0.1*diff);
        
        color = normal * 0.5 + 0.5;
    }
    float fog = collision_count*0.00001;
    gl_FragColor = vec4(color, .1) - collision_count*vec4(.05);
}