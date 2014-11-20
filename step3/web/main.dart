import 'dart:html';
import 'dart:web_gl' as WebGL;
import 'dart:typed_data';

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


  // set up buffers

  // six vertices, or two triangles, with points (x,y)
  Float32List rect_data = new Float32List.fromList( [-0.5, -0.5,
                                                  0.5, -0.5,
                                                 -0.5,  0.5,
                                                 -0.5,  0.5,
                                                  0.5, -0.5,
                                                  0.5,  0.5]);

  // create a new buffer object, floating somewhere magically inside the graphics card
  WebGL.Buffer rect_buffer = gl.createBuffer();

  // tell opengl, hey, i'm going to be using that buffer object for array data
  gl.bindBuffer(WebGL.RenderingContext.ARRAY_BUFFER, rect_buffer);
  // send the rect data to the gpu. STATIC_DRAW gives the gpu a hint that the data isn't going to be changing a lot
  // note that we don't use the rect_buffer variable in this call. we're sending the data to whatever buffer object is currently bound
  // to ARRAY_BUFFER
  gl.bufferDataTyped(WebGL.RenderingContext.ARRAY_BUFFER, rect_data, WebGL.RenderingContext.STATIC_DRAW);
 
  // tell opengl we're using the positionLocation that we got above. this is the position that goes into the vertex shader 
  gl.enableVertexAttribArray(positionLocation);
  // tell opengl two things: 1) the currently bound buffer (ARRAY_BUFFER) is the data source for "a_position"
  // 2) the buffer has two components per vertex, they are floats, we don't need our data normalized (i.e mapped from 0-255 to 0.0-1.0)
  //    and the data starts at the beginning of the array and there's no other data inbetween each vertex in the array
  gl.vertexAttribPointer(positionLocation, 2, WebGL.RenderingContext.FLOAT, false, 0, 0);

  // finally, draw the array
  // draw each 3 vertices processed by the vertex shader as an individual triangle
  // use the data starting at 0 and draw 6 vertices
  gl.drawArrays(WebGL.RenderingContext.TRIANGLES, 0, 6);

}
