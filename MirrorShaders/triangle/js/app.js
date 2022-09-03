/**
 * This is a basic asyncronous shader loader for THREE.js.
 * 
 * It uses the built-in THREE.js async loading capabilities to load shaders from files!
 * 
 * `onProgress` and `onError` are stadard TREE.js stuff. Look at 
 * https://threejs.org/examples/webgl_loader_obj.html for an example. 
 * 
 * @param {String} vertex_url URL to the vertex shader code.
 * @param {String} fragment_url URL to fragment shader code
 * @param {function(String, String)} onLoad Callback function(vertex, fragment) that take as input the loaded vertex and fragment contents.
 * @param {function} onProgress Callback for the `onProgress` event. 
 * @param {function} onError Callback for the `onError` event.
 */
 function ShaderLoader(vertex_url, fragment_url, onLoad, onProgress, onError) {
  var vertex_loader = new THREE.XHRLoader(THREE.DefaultLoadingManager);
  vertex_loader.setResponseType('text');
  vertex_loader.load(vertex_url, function (vertex_text) {
    var fragment_loader = new THREE.XHRLoader(THREE.DefaultLoadingManager);
    fragment_loader.setResponseType('text');
    fragment_loader.load(fragment_url, function (fragment_text) {
      onLoad(vertex_text, fragment_text);
    });
  }, onProgress, onError);
}

// FPS info
(function(){var script=document.createElement('script');script.onload=function(){var stats=new Stats();document.body.appendChild(stats.dom);requestAnimationFrame(function loop(){stats.update();requestAnimationFrame(loop)});};script.src='//mrdoob.github.io/stats.js/build/stats.min.js';document.head.appendChild(script);})()

// ============================================================================

// An example!


var scene = new THREE.Scene();
var camera = new THREE.PerspectiveCamera(75, window.innerWidth / window.innerHeight, 0.1, 1000);

var renderer = new THREE.WebGLRenderer({ antialias: true });
renderer.setSize(window.innerWidth, window.innerHeight);
document.body.appendChild(renderer.domElement);

var geometry = new THREE.PlaneGeometry(2, 2);


var uniforms = {
  u_time: { type: "f", value: 1.0 },
  u_resolution: { type: "v2", value: new THREE.Vector2() },
  u_cameraPos: { type: "v3", value : new THREE.Vector3(0.,0.,-.0) },
  u_viewAngle: { type: "v2", value: new THREE.Vector2() },
  u_dx: { type: "f", value: 0.},
  u_dy: { type: "f", value: 0.},
  u_dz: { type: "f", value: 0.}
}

camera.position.z = 4;

const clock = new THREE.Clock();

// ShaderLoader("vertex.glsl", "yayoi_fragment.glsl",
// ShaderLoader("vertex.glsl", "L_shape_fragment.glsl",
// ShaderLoader("vertex.glsl", "double_pentagon_fragment.glsl",
ShaderLoader("vertex.glsl", "triangle.glsl",
function (vertex, fragment) {
    var material = new THREE.ShaderMaterial({

      uniforms: uniforms,
      attributes: {
        vertexOpacity: { type: 'f', value: [] }
      },
      vertexShader: vertex,
      fragmentShader: fragment
    });

    var cube = new THREE.Mesh(geometry, material);
    scene.add(cube);

    var render = function () {
      requestAnimationFrame(render);
      uniforms.u_time.value += clock.getDelta();
      renderer.render(scene, camera);
    };

    function onWindowResize() {
      renderer.setSize( window.innerWidth, window.innerHeight );
      uniforms.u_resolution.value.x = renderer.domElement.width;
      uniforms.u_resolution.value.y = renderer.domElement.height;
    }

    function zoom(event){
      // console.log(event.deltaY);
      uniforms.u_cameraPos.value.z -= event.deltaY/(1*window.innerHeight);
    } 

    function changeViewAngle(event){
      // console.log(event.which)
      if(event.which == 1){
        uniforms.u_viewAngle.value.x -= 2*event.movementX/window.innerHeight;
        uniforms.u_viewAngle.value.y -= 2*event.movementY/window.innerHeight;
      }
    }
    window.addEventListener("wheel", event => {
      const delta = Math.sign(event.deltaY);
      uniforms.u_dz.value -= 0.3*delta;
    });
    window.addEventListener("mousemove", changeViewAngle);
    window.addEventListener("wheel", zoom);
    window.addEventListener( "resize", onWindowResize, false );
    window.addEventListener("keydown", function (event) {
      var speed = 50./window.innerHeight ; 
      // console.log(event.key);
      if (event.defaultPrevented) {
        return; // Do nothing if the event was already processed
      }
      switch (event.key) {
        case "w":
          uniforms.u_dy.value += speed;
          break;
        case "s":
          uniforms.u_dy.value -= speed;
          break;
        case "a":
          uniforms.u_dx.value -= speed;
          break;
        case "d":
          uniforms.u_dx.value += speed;
          break;        // case "ArrowDown":
        //   uniforms.u_dz.value -= speed;
        //   break;
        // case "ArrowUp":
        //   uniforms.u_dz.value += speed;
        //   break;
        // case "ArrowLeft":
        //   uniforms.u_dx.value -= speed;
        //   break;
        // case "ArrowRight":
        //   uniforms.u_dx.value += speed;
        //   break;
          // case "i":
          //   uniforms.u_cameraPos.value.z += speed;
          //   break;
          // case "o":
          //   uniforms.u_cameraPos.value.z -= speed;
          //   break;
        default:
          return; // Quit when this doesn't handle the key event.
      }
      // Cancel the default action to avoid it being handled twice
      event.preventDefault();
    }, true);

    
    onWindowResize();
    render();
  }
)