import 'dart:html';
import 'dart:web_gl';
import 'dart:typed_data';

import 'package:stats/stats.dart';
import 'package:vector_math/vector_math.dart';
import 'package:game_loop/game_loop_html.dart';
import 'package:obj/obj.dart';

final String vertexShaderSource = """
attribute vec3 a_Position;
attribute vec2 a_TextureCoord;
uniform mat4 u_MV;         // model-view
uniform mat4 u_P;          // projection
varying vec2 v_TextureCoord;

void main() {
  v_TextureCoord = a_TextureCoord;
  gl_Position = u_P * u_MV * vec4(a_Position, 1.0);
}
""";

final String fragmentShaderSource = """
precision mediump float; // required

uniform sampler2D u_Sampler;
varying vec2 v_TextureCoord;

void main() {
  gl_FragColor = texture2D(u_Sampler, v_TextureCoord);
}
""";

Stats stats;
bool ext_element_uint = false;

void main() {
  log("main: begin");
  
  run();
    
  log("main: end");
}

void run() {
  DivElement div = querySelector("#framerate");
  stats = new Stats();
  div.children.add(stats.container);
  
  CanvasElement canvas = querySelector('#main_canvas');
  RenderingContext gl = canvas.getContext3d();
  if (gl == null) {
    log("WebGL: initialization failure");
    return;
  }
  log("WebGL: initialized");
  
  Shader vertShader = gl.createShader(RenderingContext.VERTEX_SHADER);
  gl.shaderSource(vertShader, vertexShaderSource);
  gl.compileShader(vertShader);
  
  Shader fragShader = gl.createShader(RenderingContext.FRAGMENT_SHADER);
  gl.shaderSource(fragShader, fragmentShaderSource);
  gl.compileShader(fragShader); 
  
  Program p = gl.createProgram();
  gl.attachShader(p, vertShader);
  gl.attachShader(p, fragShader);
  gl.linkProgram(p);
  int a_Position = gl.getAttribLocation(p, "a_Position");
  int a_TextureCoord = gl.getAttribLocation(p, "a_TextureCoord");
  UniformLocation u_MV = gl.getUniformLocation(p, "u_MV");
  UniformLocation u_P = gl.getUniformLocation(p, "u_P");
  UniformLocation u_Sampler = gl.getUniformLocation(p, "u_Sampler");
  
  gl.useProgram(p);
  gl.enableVertexAttribArray(a_Position);  
  
  gl.clearColor(0.5, 0.5, 0.5, 1.0);       // clear color
  gl.enable(RenderingContext.DEPTH_TEST);  // enable depth testing
  gl.depthFunc(RenderingContext.LESS);     // gl.LESS is default depth test
  gl.depthRange(0.0, 1.0);                 // default
  gl.viewport(0, 0, canvas.width, canvas.height);
  
  updateCulling(gl, true);
  
  detect_element_uint(gl);
  
  GameLoopHtml gameLoop = new GameLoopHtml(gl.canvas);

  gameLoop.pointerLock.lockOnClick = false; // disable pointer lock

  gameLoop.onUpdate = ((gLoop) {
    update(gl, gLoop);
  });
  gameLoop.onRender = ((gLoop) {
    render(gl, gLoop);
  });
  
  log("starting game loop");
  
  fetchObj("old_house.obj");
  fetchObj("house.obj");
 
  gameLoop.start();
}

void updateCulling(RenderingContext gl, bool culling) {
  if (culling) {
    log("backface culling: ON");

    gl.frontFace(RenderingContext.CCW);
    gl.cullFace(RenderingContext.BACK);
    gl.enable(RenderingContext.CULL_FACE);
    return;
  }

  log("backface culling: OFF");
  gl.disable(RenderingContext.CULL_FACE);
}

int get ext_get_element_type {
  if (ext_element_uint) {
    return RenderingContext.UNSIGNED_INT;
  }

  return RenderingContext.UNSIGNED_SHORT;
}

void detect_element_uint(RenderingContext gl) {
  String extName = "OES_element_index_uint";
  OesElementIndexUint ext;

  try {
    ext = gl.getExtension(extName);
  } catch (exc) {
    log("gl.getExtension('$extName') exception: $exc");
  }

  ext_element_uint = ext != null;

  log("gl.getExtension('$extName'): available = $ext_element_uint");
}


void fetchObj(String objURL) {
  
  void handleObjResponse(String objString) {

    log("OBJ loaded from URL=$objURL");
    
    Obj obj = new Obj.fromString(objURL, objString,
        defaultName: "noname",
        fillMissingTextCoord: true,
        printStats: true);
    
    String mtlURL = obj.mtllib;

    void handleMtlResponse(String mtlString) {
      
      log("MTL loaded from URL=$mtlURL");
      
      Map<String, Material> lib = mtllib_parse(mtlString, mtlURL);      
    }

    void handleMtlError(Object err) {
      log("failure fetching MTL from URL=$mtlURL: $err");
    }
    
    HttpRequest.getString(mtlURL).then(handleMtlResponse).catchError(handleMtlError);
    
  }

  void handleObjError(Object err) {
    log("failure fetching OBJ from URL=$objURL: $err");
  }

  HttpRequest.getString(objURL).then(handleObjResponse).catchError(handleObjError);  
}

void log(String msg) {
  msg = "${new DateTime.now()} $msg";
  
  print(msg);
  DivElement m = new DivElement();
  m.text = msg;
  
  DivElement output = querySelector('#output');
  output.children.insert(0, m);
  if (output.children.length > 20) {
    output.children.removeLast();
  }
}

void update(RenderingContext gl, GameLoopHtml gameLoop) {
}

void render(RenderingContext gl, GameLoopHtml gameLoop) {
  stats.begin();
  
  gl.clear(RenderingContext.COLOR_BUFFER_BIT | RenderingContext.DEPTH_BUFFER_BIT);
  
  stats.end(); 
}
