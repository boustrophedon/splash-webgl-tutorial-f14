import 'dart:html';
import 'dart:web_gl' as WebGL;

import 'webgl_utils.dart';

void main() {
  CanvasElement canvas = querySelector("#canvas-area");
  canvas.height = 800;
  canvas.width = 800;

  WebGL.RenderingContext gl = canvas.getContext3d();
  if (canvas is! CanvasElement || gl is! WebGL.RenderingContext) {
    print("Failed to load canvas");
    return;
  }
  else {
    print("loaded canvas successfully!");
  }
  gl.clearColor(0.0, 0.0, 0.0, 1.0);
  gl.clear(WebGL.COLOR_BUFFER_BIT | WebGL.DEPTH_BUFFER_BIT);
  // set up shaders

  WebGL.Shader vertexShader = createShaderFromScriptElement(gl, "#v2d-vertex-shader");
  //print(gl.getShaderInfoLog(vertexShader));
  WebGL.Shader fragmentShader = createShaderFromScriptElement(gl, "#f2d-fragment-shader");
  //print(gl.getShaderInfoLog(fragmentShader));
  WebGL.Program program = createProgram(gl, [vertexShader, fragmentShader]);

  gl.useProgram(program);
  int positionLocation = gl.getAttribLocation(program, "a_position");
}
