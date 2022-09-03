
#define M_PI 3.1415926535897932384626433832795

uniform vec2 u_resolution;
uniform float u_time;
uniform vec3 u_cameraPos;
uniform vec2 u_viewAngle;
uniform float u_dz;
uniform float u_dy;
uniform float u_dx;


const float eps = 0.0001;
float tMax = 50.;
float b =2.0;
float wall_height = 5. ;
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




// object

float sdf_mirrors(vec3 p){
    float df  = sdBox(p - vec3(0.,0.,2.*b + eps), vec3(b, wall_height, eps)); //Edge 6
    df = opUnion(df, sdBox(p- vec3(-b-eps,0., b ), vec3(eps, wall_height, 1.*b ))); // Edge 8
    df = opUnion(df, sdBox(p- vec3(-b-eps ,0., -b), vec3(eps, wall_height, 1.*b ))); // Edge 7 
    df = opUnion(df, sdBox(p- vec3(b + eps, 0. ,b), vec3(eps, wall_height, b ))); // Edge 5
    df = opUnion(df, sdBox(p- vec3(2.*b, 0. ,0.+eps), vec3(b, wall_height, eps ))); // Edge 4
    df = opUnion(df, sdBox(p- vec3(3.*b+eps, 0., -b), vec3(eps, wall_height, b ))); // Edge 3
    df = opUnion(df, sdBox(p- vec3(2. * b, 0., -2.*b -eps), vec3( b, wall_height , eps ))); // Edge 2
    df = opUnion(df, sdBox(p- vec3(0., 0., -2.*b-eps), vec3( b, wall_height , eps ))); // Edge 1
    return df;
}

float sdf( vec3 p) {
    
    float df  = sdf_mirrors(p);
    df = opUnion(df, sdSphere(p - vec3(1.* b, 0., -b), 0.1));
    df = opUnion(df, opSubtraction( sdSphere(p, 0.13), sdBox(p, vec3(0.1))));

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
        float h = sdf(pos);

        pos = pos + h * ray;
        if(h < eps ) {
            if( sdf_mirrors(pos) < eps)  //Edge 6
            {
                vec3 n = getNormal(pos);
                ray = ray - 2.*dot(ray,n)*n;
                pos += 3.*eps * ray;
                collision_count += 1.;                          
            } else if(t > tMax){ 
                pos = vec3(tMax);
                break;
            }
        }
        t += h;

    }

    // color

    vec3 color = vec3(0.);
    if(t < tMax) {
        //vec3 pos = cameraPos + t * ray;
        vec3 normal = normalize(getNormal(pos));
        // light
        float diff = dot(vec3(1.), normal);
        // color = vec3(0.5*diff);
        color += normal * 0.5 + 0.5;
    }

    // adding collision fog
    gl_FragColor = vec4(color, .1) + collision_count*vec4(.05);
}