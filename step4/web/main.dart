import 'dart:html';
import 'dart:web_gl' as WebGL;
import 'dart:typed_data';

import 'package:vector_math/vector_math.dart';

import 'webgl_utils.dart';

class SquareRenderer {
  CanvasElement canvas;
  WebGL.RenderingContext gl;

  WebGL.Shader vertexShader;
  WebGL.Shader fragmentShader;
  WebGL.Program program;

  int positionLocation;

  Float32List rect_data;
  WebGL.Buffer rectBuffer;

  SquareRenderer(CanvasElement canvas) {
    this.canvas = canvas;
    this.gl = canvas.getContext3d();

    if (canvas is! CanvasElement || gl is! WebGL.RenderingContext) {
      print("Failed to load canvas");
      return;
    }
    else {
      print("Loaded canvas successfully!");
    }
    gl.clearColor(0.0, 0.0, 0.0, 1.0);
  }
  void setup_shaders() {
    vertexShader = createShaderFromScriptElement(gl, "#v2d-vertex-shader");
    //print(gl.getShaderInfoLog(vertexShader));
    fragmentShader = createShaderFromScriptElement(gl, "#f2d-fragment-shader");
    //print(gl.getShaderInfoLog(fragmentShader));
    program = createProgram(gl, [vertexShader, fragmentShader]);

    gl.useProgram(program);
    positionLocation = gl.getAttribLocation(program, "a_position");
  }

  void setup_buffers() {
    // six vertices, or two triangles, with points (x,y)
    rect_data = new Float32List.fromList( [-0.5, -0.5,
                                                    0.5, -0.5,
                                                   -0.5,  0.5,
                                                   -0.5,  0.5,
                                                    0.5, -0.5,
                                                    0.5,  0.5]);

    // create a new buffer object, floating somewhere magically inside the graphics card
    rectBuffer = gl.createBuffer();

    // tell opengl, hey, i'm going to be using that buffer object for array data
    gl.bindBuffer(WebGL.RenderingContext.ARRAY_BUFFER, rectBuffer);
    // send the rect data to the gpu. STATIC_DRAW gives the gpu a hint that the data isn't going to be changing a lot
    // note that we don't use the rectBuffer variable in this call. we're sending the data to whatever buffer object is currently bound
    // to ARRAY_BUFFER
    gl.bufferDataTyped(WebGL.RenderingContext.ARRAY_BUFFER, rect_data, WebGL.RenderingContext.STATIC_DRAW);
  }

  void bind_rect_buffer() {
    gl.bindBuffer(WebGL.RenderingContext.ARRAY_BUFFER, rectBuffer);
      
    // tell opengl we're using the positionLocation that we got above. this is the position that goes into the vertex shader 
    gl.enableVertexAttribArray(positionLocation);
    // tell opengl two things: 1) the currently bound buffer (ARRAY_BUFFER) is the data source for "a_position"
    // 2) the buffer has two components per vertex, they are floats, we don't need our data normalized (i.e mapped from 0-255 to 0.0-1.0)
    //    and the data starts at the beginning of the array and there's no other data inbetween each vertex in the array
    gl.vertexAttribPointer(positionLocation, 2, WebGL.RenderingContext.FLOAT, false, 0, 0);
  }

  void draw(num dt) {
    gl.clear(WebGL.COLOR_BUFFER_BIT | WebGL.DEPTH_BUFFER_BIT);
    bind_rect_buffer();
    // finally, draw the array
    // draw each 3 vertices processed by the vertex shader as an individual triangle
    // use the data starting at 0 and draw 6 vertices
    gl.drawArrays(WebGL.RenderingContext.TRIANGLES, 0, 6);
    print('rendering! woo!11111one!!!');
    window.requestAnimationFrame(draw);
  }

  void start() {
    setup_shaders();
    setup_buffers();
    window.requestAnimationFrame(draw);
  }
}

void main() {
  CanvasElement canvas = querySelector("#canvas-area");
  canvas.height = 800;
  canvas.width = 800;

  SquareRenderer r = new SquareRenderer(canvas);
  r.start();
}
