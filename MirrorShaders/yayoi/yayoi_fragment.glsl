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
float wall_height = 50. ;
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

// polynomial smooth min 2 (k=0.1)
float smin( float a, float b, float k )
{
    float h = max( k-abs(a-b), 0.0 )/k;
    return min( a, b ) - h*h*k*(1.0/4.0);
}

float opUnion( float d1, float d2) {
    return min(d1, d2);
}
vec3 opRep( vec3 p, vec3 c ){
    return mod( p + 0.5 * c, c ) - 0.5 * c;
}

float sdCylinder( vec3 p, float r, float h ){
  
  return max(length(p.xz)-r, abs(p.y)-h);
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
  float q = length(p.xz);
  return max(dot(c.xy,vec2(q,p.y)),-h-p.y);
}

float sdWall(vec3 p, vec3 a, vec3 b, float height, float thickness) {
    vec3 d = b - a;

    // cw is the centre of the wall
    vec3 cw = 0.5*(a+b);
    float angle = acos(d.x / length(d));
    p -= cw; 
    p = rotMat(vec3(0., 1., 0.), -angle) * p; // translate by centre and rotate 
    
    return sdBox(p, vec3(0.5 * length(d), height, thickness));
}



// object

float sdf_mirrors(vec3 p){
    
    float df = sdBox(p, vec3(6.)); // the room

    return -df;
}

float sdf( vec3 p) {
    
    float df  = (sdf_mirrors(p));
    df = opUnion(df, sdSphere(p - vec3(0.2, 0., 0.), 0.1));
    // df = opUnion(df, sdCylinder(p, 0.1, 0.2));
    df = opUnion(df, sdBox(p -vec3(0.0, 0.0, 0.0), vec3(0.1,0.2,0.1)));
    // df = opUnion(df, smin(sdSphere(p - vec3(0.,-0.2,0.), 0.1), sdSphere(p*vec3(1.,0.1*sin(u_time) + 0.3, 1.)-vec3(0.,0.,0.) , 0.1), 0.3));
    // for(float i = -5.; i <= 5.; i++){
    //     for(float j = -5.; j <= 5.; j++){
    //          df = opUnion(df, sdBox(p - vec3(i, 0., j), vec3(0.1,0.2,0.1)));
    //     }
    // }

    df = opUnion(df, sdBox(p -vec3(-4.0, -2.384651586395572, -4.0), vec3(0.1,0.2,0.1)));
    df = opUnion(df, sdBox(p -vec3(-4.0, -4.992872661172636, -2.0), vec3(0.1,0.2,0.1)));
    df = opUnion(df, sdBox(p -vec3(-4.0, -1.993204983878235, 0.0), vec3(0.1,0.2,0.1)));
    df = opUnion(df, sdBox(p -vec3(-4.0, -3.4712152739916844, 2.0), vec3(0.1,0.2,0.1)));
    df = opUnion(df, sdBox(p -vec3(-4.0, 1.4616270226297867, 4.0), vec3(0.1,0.2,0.1)));
    df = opUnion(df, sdBox(p -vec3(-2.0, 1.531803776388313, -4.0), vec3(0.1,0.2,0.1)));
    df = opUnion(df, sdBox(p -vec3(-2.0, 0.7370181557748601, -2.0), vec3(0.1,0.2,0.1)));
    df = opUnion(df, sdBox(p -vec3(-2.0, -3.672739741299229, 0.0), vec3(0.1,0.2,0.1)));
    df = opUnion(df, sdBox(p -vec3(-2.0, 1.6100337505422924, 2.0), vec3(0.1,0.2,0.1)));
    df = opUnion(df, sdBox(p -vec3(-2.0, 0.004821044320938439, 4.0), vec3(0.1,0.2,0.1)));
    df = opUnion(df, sdBox(p -vec3(0.0, -1.7719338267916962, -4.0), vec3(0.1,0.2,0.1)));
    df = opUnion(df, sdBox(p -vec3(0.0, -2.5816143931237012, -2.0), vec3(0.1,0.2,0.1)));
    df = opUnion(df, sdBox(p -vec3(0.0, -3.4028242413160847, 0.0), vec3(0.1,0.2,0.1)));
    df = opUnion(df, sdBox(p -vec3(0.0, 2.8603954328851677, 2.0), vec3(0.1,0.2,0.1)));
    df = opUnion(df, sdBox(p -vec3(0.0, 3.1395541998815424, 4.0), vec3(0.1,0.2,0.1)));
    df = opUnion(df, sdBox(p -vec3(2.0, -1.3779836690227576, -4.0), vec3(0.1,0.2,0.1)));
    df = opUnion(df, sdBox(p -vec3(2.0, 3.198415606657863, -2.0), vec3(0.1,0.2,0.1)));
    df = opUnion(df, sdBox(p -vec3(2.0, 0.4750072929153648, 0.0), vec3(0.1,0.2,0.1)));
    df = opUnion(df, sdBox(p -vec3(2.0, 4.340126549174977, 2.0), vec3(0.1,0.2,0.1)));
    df = opUnion(df, sdBox(p -vec3(2.0, 3.4042578052234083, 4.0), vec3(0.1,0.2,0.1)));
    df = opUnion(df, sdBox(p -vec3(4.0, -2.139463757772443, -4.0), vec3(0.1,0.2,0.1)));
    df = opUnion(df, sdBox(p -vec3(4.0, -3.629608008070101, -2.0), vec3(0.1,0.2,0.1)));
    df = opUnion(df, sdBox(p -vec3(4.0, 2.0006207831907883, 0.0), vec3(0.1,0.2,0.1)));
    df = opUnion(df, sdBox(p -vec3(4.0, -0.5972803062778353, 2.0), vec3(0.1,0.2,0.1)));
    df = opUnion(df, sdBox(p -vec3(4.0, 2.6041023253153908, 4.0), vec3(0.1,0.2,0.1)));

    // df = opUnion(df, sdBox( vec3(mod(p.x, .2), 0.,0. ), vec3(0.01)));
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
                pos += 2.*eps * ray;
                collision_count += 1.;                          
            } 
            if(t > tMax){ 
                pos = vec3(tMax);
                break;
            }
        }
        t += h;

    }

    // color

    vec3 color = vec3(0.);
    if(t < tMax) {
        vec3 pos = cameraPos + t * ray;
        vec3 normal = normalize(getNormal(pos));
        // light
        //float diff = dot(vec3(1.), normal);
        // color = vec3(0.5*diff);
        color += normal * 0.5 + 0.5;
         
        
        // float df = sdSphere(pos -vec3(-4.0, -2.384651586395572, -4.0), 0.1);
        // df = opUnion(df, sdSphere(pos -vec3(-4.0, -4.992872661172636, -2.0), 0.1));
        // df = opUnion(df, sdSphere(pos -vec3(-4.0, -1.993204983878235, 0.0), 0.1));
        // df = opUnion(df, sdSphere(pos -vec3(-4.0, -3.4712152739916844, 2.0), 0.1));
        // df = opUnion(df, sdSphere(pos -vec3(-4.0, 1.4616270226297867, 4.0), 0.1));
        // df = opUnion(df, sdSphere(pos -vec3(-2.0, 1.531803776388313, -4.0), 0.1));
        // df = opUnion(df, sdSphere(pos -vec3(-2.0, 0.7370181557748601, -2.0), 0.1));
        // df = opUnion(df, sdSphere(pos -vec3(-2.0, -3.672739741299229, 0.0), 0.1));
        // df = opUnion(df, sdSphere(pos -vec3(-2.0, 1.6100337505422924, 2.0), 0.1));
        // df = opUnion(df, sdSphere(pos -vec3(-2.0, 0.004821044320938439, 4.0), 0.1));
        // df = opUnion(df, sdSphere(pos -vec3(0.0, -1.7719338267916962, -4.0), 0.1));
        // df = opUnion(df, sdSphere(pos -vec3(0.0, -2.5816143931237012, -2.0), 0.1));
        // df = opUnion(df, sdSphere(pos -vec3(0.0, -3.4028242413160847, 0.0), 0.1));
        // df = opUnion(df, sdSphere(pos -vec3(0.0, 2.8603954328851677, 2.0), 0.1));
        // df = opUnion(df, sdSphere(pos -vec3(0.0, 3.1395541998815424, 4.0), 0.1));
        // df = opUnion(df, sdSphere(pos -vec3(2.0, -1.3779836690227576, -4.0), 0.1));
        // df = opUnion(df, sdSphere(pos -vec3(2.0, 3.198415606657863, -2.0), 0.1));
        // df = opUnion(df, sdSphere(pos -vec3(2.0, 0.4750072929153648, 0.0), 0.1));
        // df = opUnion(df, sdSphere(pos -vec3(2.0, 4.340126549174977, 2.0), 0.1));
        // df = opUnion(df, sdSphere(pos -vec3(2.0, 3.4042578052234083, 4.0), 0.1));
        // df = opUnion(df, sdSphere(pos -vec3(4.0, -2.139463757772443, -4.0), 0.1));
        // df = opUnion(df, sdSphere(pos -vec3(4.0, -3.629608008070101, -2.0), 0.1));
        // df = opUnion(df, sdSphere(pos -vec3(4.0, 2.0006207831907883, 0.0), 0.1));
        // df = opUnion(df, sdSphere(pos -vec3(4.0, -0.5972803062778353, 2.0), 0.1));
        // df = opUnion(df, sdSphere(pos -vec3(4.0, 2.6041023253153908, 4.0), 0.1));
        // float strength = df;


        // color += exp(-(strength)*(strength))*vec3(1.0, 3.*0.2, 0.);
        // strength = 15.*sdBox(pos - vec3(0., -0.06, 0.), vec3(0.1, eps, 0.1)); 
        // color += exp(-(strength)*(strength))*vec3(1.0, 3.*0.2, 0.);
        // strength = 20. * smin(sdSphere(pos - vec3(0.,-0.25,0.), 0.1), sdSphere(pos*vec3(1.,0.1*sin(u_time) + 0.3, 1.)-vec3(0.,0.05,0.) , 0.1), 0.3);
        // color += exp(-(strength)*(strength))*vec3(1.0, 3.*0.2, 0.);

        // color += (0.5- 0.3 * strength)*vec3(1.0, 3.*0.2, 0.);
        }

    // adding collision fog
    gl_FragColor = vec4(color, .1);
}