import 'dart:html';
import 'dart:web_gl';

void main() {
  log("main: begin");
  //querySelector('#output').text = 'Your Dart app is running.';
  
  run();
    
  log("main: end");
}

void run() {
  CanvasElement canvas = querySelector('#main_canvas');
  RenderingContext gl = canvas.getContext3d();
  if (gl == null) {
    log("WebGL: initialization failure");
    return;
  }
  log("WebGL: initialized");    
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
