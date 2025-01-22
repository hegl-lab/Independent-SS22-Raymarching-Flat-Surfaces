#define M_PI 3.1415926535897932384626433832795

uniform vec2 u_resolution;
uniform float u_time;
uniform vec3 u_cameraPos;
uniform vec2 u_viewAngle;
uniform float u_dz;
uniform float u_dy;
uniform float u_dx;


const float eps = 0.0001;
const float n_eps = 1000.;
float tMax = 50.;
float b =2.0;
float wall_height = 5. ;
float wall_thickness = 0.000001;
float dist_screen = 1.;
float cam_detection_boundary = 50.;
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

// signed distance functions

float sdBox( vec3 p, vec3 b ) {
    vec3 q = abs(p) - b;
    return length(max(q,0.0)) + min(max(q.x,max(q.y,q.z)),0.0);
}

float opSubtraction( float d1, float d2 ) {
    return max(-d1,d2);
}

float opUnion( float d1, float d2) {
    return min(d1, d2);
}
vec3 opRep( vec3 p, vec3 c ){
    return mod( p + 0.5 * c, c ) - 0.5 * c;
}

float sdCylinder( vec3 p, vec3 c ){
  return length(p.xz-c.xy)-c.z;
}

float sdPlane( vec3 p, vec3 n, float h ) {
    return dot( p, n ) + h;
}

float dot2(vec3 v){
    return dot(v, v);
}

float sdSphere( vec3 p, float r ) {
    return length(p) - r;
}

float sdCone( vec3 p, vec2 c, float h )
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
  return sqrt(d)*sign(s);
}


// object
float sdf( vec3 p) {
    
    float df  = sdBox(p - vec3(-3.*b, 0.,0.), vec3(wall_thickness, wall_height, b)); //Edge 1
    df = opUnion(df, sdBox(vec3(p.xy, abs(p.z))- vec3(-2.*b,0., b ), vec3(b, wall_height, wall_thickness ))); // Edge 2
    df = opUnion(df, sdBox(vec3(p.xy, abs(p.z))- vec3(-b, 0., 2.*b ), vec3(wall_thickness, wall_height, b))); // Edge 3
    df = opUnion(df, sdBox(vec3(p.xy, abs(p.z))- vec3(0. ,0., 3.*b ), vec3(b, wall_height, wall_thickness ))); // Edge 4
    df = opUnion(df, sdBox(vec3(p.xy, abs(p.z))- vec3(b, 0., 2.*b ), vec3(wall_thickness, wall_height, b ))); // Edge 5
    df = opUnion(df, sdBox(vec3(p.xy, abs(p.z))- vec3(2.*b,0., b ), vec3(b, wall_height, wall_thickness ))); // Edge 6
    df = opUnion(df, sdBox(vec3(p.xy, abs(p.z))- vec3(4.*b,0., b ), vec3(b, wall_height, wall_thickness ))); // Edge 7
    df = opUnion(df, sdBox(p - vec3(5.*b,0., 0. ), vec3(wall_thickness, wall_height, b ))); // Edge 8
    // df = opUnion(df, sdBox(p- vec3(4.*b,0., b ), vec3(b, wall_height, wall_thickness ))); // Edge 9
    // df = opUnion(df, sdBox(p- vec3(2.*b,0., b ), vec3(b, wall_height, wall_thickness ))); // Edge 10
    // df = opUnion(df, sdBox(p- vec3(b, 0., -2.*b ), vec3(b, wall_height, wall_thickness ))); // Edge 11 
    df = opUnion(df, opSubtraction( sdSphere(p, 0.13), sdBox(p, vec3(0.1))));
    df = opUnion(df, sdSphere(p -vec3(0., 0.,2.*b), 0.13));
    // df = opUnion(df, sdSphere(p - vec3(1.618033988749895, 0.,0.), 0.2));
    df = opUnion(df, sdCone(p + vec3(-2.*b, cos(u_time),0.),vec2(.1), .075));
    df = opUnion(df, sdCone(p - vec3(4.*b, 0.,0.),vec2(.1), .075));
    return df;
}

float sdfBlack(vec3 p){    
    float df  = sdBox(p - vec3(-3.*b, 0.,0.), vec3(wall_thickness, wall_height, b)); //Edge 1
    df = opUnion(df, sdBox(p - vec3(5.*b,0., 0. ), vec3(wall_thickness, wall_height, b ))); // Edge 8
    return df;
}

float sdfPink(vec3 p){
    // float df = (sdBox(vec3(p.xy, abs(p.z))- vec3(-2.*b,0., b ), vec3(b, wall_height, eps ))); //Edge 2
    // df = opUnion(df, sdBox(vec3(p.xy, abs(p.z))- vec3(b, 0., 2.*b ), vec3(eps, wall_height, b ))); // Edge 5
    float df = (sdBox(p- vec3(-2.*b,0., -b ), vec3(b, wall_height, wall_thickness ))); //Edge 2
    df = opUnion(df, sdBox(p- vec3(b, 0., -2.*b ), vec3(wall_thickness, wall_height, b ))); // Edge 5
    df = opUnion(df, sdBox(p- vec3(2.*b,0., b ), vec3(b, wall_height, wall_thickness ))); //Edge 10
    df = opUnion(df, sdBox(p- vec3(-b, 0., 2.*b ), vec3(wall_thickness, wall_height, b))); // Edge 13

    return df;
}

float sdfGreen(vec3 p){
    float df = sdBox(p- vec3(-b, 0., -2.*b ), vec3(wall_thickness, wall_height, b)); // Edge 3
    df = opUnion(df, sdBox(p- vec3(2.*b,0., -b ), vec3(b, wall_height, wall_thickness ))); // Edge 6
    df = opUnion(df, sdBox(p - vec3(b, 0., 2.*b ), vec3(wall_thickness, wall_height, b ))); // Edge 11
    df = opUnion(df, sdBox(p- vec3(-2.*b,0., b ), vec3(b, wall_height, wall_thickness ))); // Edge 14
    return df;
}

float sdfOrange(vec3 p){
    float df = sdBox(vec3(p.xy, abs(p.z))- vec3(0. ,0., 3.*b ), vec3(b, wall_height, wall_thickness )); // Edge 4 & 12
    return df;
}

float sdfBlue(vec3 p){
    float df = sdBox(vec3(p.xy, abs(p.z))- vec3(4.*b,0., b ), vec3(b, wall_height, wall_thickness )); // Edge 7 & 9
    return df;
}


vec3 getNormal( vec3 p ) {
    const float eps = 0.0001;
    const vec2 h = vec2( eps, 0. );
    return normalize( vec3(sdf(p+h.xyy) - sdf(p-h.xyy),
                            sdf(p+h.yxy) - sdf(p-h.yxy),
                            sdf(p+h.yyx) - sdf(p-h.yyx) ) );
}


void main() {
    // camera rotationmatrix
    mat3 viewRotation = rotMat(ey, u_viewAngle[0]) * rotMat(ex, u_viewAngle[1]);
    ex = viewRotation * ex;
    ey = viewRotation * ey;
    ez = viewRotation * ez;

    // translation of the uv_screen
    vec3 uv_screen_origin = u_dz * ez  + u_dx * ex + u_dy * ey;
    
    float h_cam = sdf(uv_screen_origin);
    vec3 cameraPos = uv_screen_origin - dist_screen*ez;
    vec3 uv_screen = uv_screen_origin + viewRotation * vec3((gl_FragCoord.xy - 0.5 * u_resolution) / (1.*u_resolution.y) + u_cameraPos.xy, 0.);
    // ray marching
    vec3 ray = normalize(uv_screen - cameraPos);
    float t = 0.;
    float t_surface = 0.;
    vec3 pos = cameraPos;
    float collision_count = 0.;
    for(int i = 0; i < 2000; i++) {
        float h = (sdf(pos));

        pos = pos + h * ray;
        if(h < eps ) {
            if( sdfBlack(pos) < eps)  //Edge 1 & 8
            {
                pos.x -= sign(pos.x) *(8. * b - 4.*eps);
                pos += h * ray;
                collision_count += 1.;            
            } else if( sdfPink(pos) < eps) //Edge 2, 5, 10, 13
            {
                mat2 r = mat2(0., 1.,
                              -1., 0.);
                pos.xz = r * (pos.xz - b*sign(pos.xz)) + b*sign(pos.xz);
                ray.xz = r * ray.xz;
                pos += (h+n_eps*eps) * ray;
                collision_count += 1.;  
            } else if( sdfGreen(pos) < eps) //Edge 3, 6, 11, 14
            {
                mat2 r = mat2(0., -1.,
                              1., 0.);
                pos.xz = r * (pos.xz - b*sign(pos.xz)) + b*sign(pos.xz);
                ray.xz = r * ray.xz;
                pos += (h+n_eps*eps) * ray;
                collision_count += 1.;   
            } else if( sdfOrange(pos) < eps) //Edge 4, 12
            {
                pos.x *= -1.;
                pos.xz += vec2(4.*b, -sign(pos.z)*2.*b);
                ray.xz = -ray.xz;
                pos += (h+n_eps*eps) * ray;
                
                
                collision_count += 1.;  
                // pos.xz += vec2(-4.*b, sign(pos.z)*2.*b);
                // ray.xz =  -ray.xz;
                // pos += (h+n_eps*eps) * ray;
                // collision_count += 100.;       
            }else if( sdfBlue(pos) < eps) //Edge 7, 9
            {
                pos.xz += vec2(-4.*b, sign(pos.z)*2.*b);
                pos.x *= -1.;
                ray.xz = - ray.xz;
                pos += (h+n_eps*eps) * ray;
                collision_count += 1.;  
                // pos.xz -= vec2(-4.*b, sign(pos.z)*2.*b);
                // // ray.xz =  - ray.xz;
                // pos += (h+n_eps*eps) * ray;
                // collision_count += 1.;       
            }else if(t > tMax){ 
                pos = vec3(tMax);
                break;
            }
        }
        t += h;

    }

    // color

    vec3 color = vec3(1.);
    if(t < tMax) {
        //vec3 pos = cameraPos + t * ray;
        vec3 normal = normalize(getNormal(pos));
        // light
        float diff = dot(vec3(1.), normal);
        // color = vec3(0.5*diff);
        color = normal * 0.5 + 0.5;
    }

    // adding collision fog
    gl_FragColor = vec4(color, .1) - collision_count*vec4(.05);
}