import 'dart:html';
import 'dart:web_gl';
import 'dart:typed_data';

import 'package:stats/stats.dart';
import 'package:vector_math/vector_math.dart';
import 'package:game_loop/game_loop_html.dart';

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
  
  GameLoopHtml gameLoop = new GameLoopHtml(gl.canvas);

  gameLoop.pointerLock.lockOnClick = false; // disable pointer lock

  gameLoop.onUpdate = ((gLoop) {
    update(gl, gLoop);
  });
  gameLoop.onRender = ((gLoop) {
    render(gl, gLoop);
  });
 
  gameLoop.start();
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
