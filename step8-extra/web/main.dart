import 'dart:html';
import 'dart:web_gl' as WebGL;
import 'dart:typed_data';
import 'dart:math' as math;

import 'package:vector_math/vector_math.dart';

import 'webgl_utils.dart';

// global rng
math.Random rng = new math.Random();

class Cube {
  Matrix4 model_matrix;
  num x_rotation = 0.0;
  num y_rotation = 0.0;
  num x_speed, y_speed;
  num x,y,z;

  Cube(this.x, this.y, this.z) {
    x_speed = rng.nextDouble()*math.PI;
    y_speed = rng.nextDouble()*math.PI;
    model_matrix = new Matrix4.identity();
    model_matrix.setTranslationRaw(x,y,z);
  }
  void update(num dt) {
    x_rotation += (dt/1000*x_speed) % math.PI;
    y_rotation += (dt/1000*y_speed) % math.PI;
    model_matrix.setRotationX(x_rotation);
    model_matrix.rotateY(y_rotation);
    model_matrix.setTranslationRaw(x,y,z);
  }
}

class CubeRenderer {
  CanvasElement canvas;
  WebGL.RenderingContext gl;

  WebGL.Shader vertexShader;
  WebGL.Shader fragmentShader;
  WebGL.Program program;

  int positionLocation;
  int colorLocation;

  // it is silly that there's a uniformlocation class for uniforms but not attributes
  WebGL.UniformLocation mvMatrixLocation;
  WebGL.UniformLocation projectionMatrixLocation;
  
  Float32List cube_data;
  Float32List color_data;
  Uint16List index_data;

  WebGL.Buffer cubeBuffer;
  WebGL.Buffer colorBuffer;
  WebGL.Buffer indexBuffer;

  Matrix4 view_matrix;
  Matrix4 projection_matrix;

  List<Cube> cubes;

  num dt = 0.0;
  num timestamp = 0.0;


  CubeRenderer(CanvasElement canvas) {
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
    gl.enable(WebGL.DEPTH_TEST);

    cubes = new List<Cube>();
    add_cube(-2.0, 2.0, 0.0);
    add_cube(2.0, -1.0, 0.0);
    add_cube(2.0, 0.0, -20.0);
    add_cube(2.0, 1.0, 3.0);
  }
  
  void add_cube([num x, num y, num z]) {
    if (x == null) x = 0.0;
    if (y == null) y = 0.0;
    if (z == null) z = 0.0;
    cubes.add(new Cube(x,y,z));
  }

  void setup_shaders() {
    vertexShader = createShaderFromScriptElement(gl, "#v2d-vertex-shader");
    //print(gl.getShaderInfoLog(vertexShader));
    fragmentShader = createShaderFromScriptElement(gl, "#f2d-fragment-shader");
    //print(gl.getShaderInfoLog(fragmentShader));
    program = createProgram(gl, [vertexShader, fragmentShader]);

    gl.useProgram(program);

    setup_attribs();
    setup_uniforms();
  }
  void setup_attribs() {
    positionLocation = gl.getAttribLocation(program, "a_position");
    colorLocation = gl.getAttribLocation(program, "a_color");
    // enable vertex attribs moved here! 
    gl.enableVertexAttribArray(positionLocation);
    gl.enableVertexAttribArray(colorLocation);
  }
  void setup_uniforms() {
    mvMatrixLocation = gl.getUniformLocation(program, "u_mvMatrix");
    projectionMatrixLocation = gl.getUniformLocation(program, "u_pMatrix");
  }

  void setup_buffers() {
    setup_cube_buffer();
    setup_cube_color_buffer();
    setup_cube_index_buffer();
  }

  void setup_cube_buffer() {
    // 8 vertices of the cube, with points (x,y,z)
    // specified counterclockwise from the first quadrant
    cube_data = new Float32List.fromList([
        1.0,  1.0,  1.0, // 0 through 4 front vertices counterclockwise
        1.0, -1.0,  1.0, // 1
       -1.0, -1.0,  1.0, // 2
       -1.0,  1.0,  1.0, // 3 
        1.0,  1.0, -1.0, // 4 through 7 back vertices counterclockwise
        1.0, -1.0, -1.0, // 5
       -1.0, -1.0, -1.0, // 6
       -1.0,  1.0, -1.0, // 7
    ]);

    // create a new buffer object, floating somewhere magically inside the graphics card
    cubeBuffer = gl.createBuffer();

    // tell opengl, hey, i'm going to be using that buffer object for array data
    gl.bindBuffer(WebGL.RenderingContext.ARRAY_BUFFER, cubeBuffer);
    // send the cube data to the gpu. STATIC_DRAW gives the gpu a hint that the data isn't going to be changing a lot
    // note that we don't use the cubeBuffer variable in this call. we're sending the data to whatever buffer object is currently bound
    // to ARRAY_BUFFER
    gl.bufferDataTyped(WebGL.RenderingContext.ARRAY_BUFFER, cube_data, WebGL.RenderingContext.STATIC_DRAW);
  }

  void bind_cube_buffer() {
    gl.bindBuffer(WebGL.RenderingContext.ARRAY_BUFFER, cubeBuffer);
      
    // tell opengl two things: 1) the currently bound buffer (ARRAY_BUFFER) is the data source for "a_position"
    // 2) the buffer has three components per vertex, they are floats, we don't need our data normalized (i.e mapped from 0-255 to 0.0-1.0)
    //    and the data starts at the beginning of the array and there's no other data inbetween each vertex in the array
    gl.vertexAttribPointer(positionLocation, 3, WebGL.RenderingContext.FLOAT, false, 0, 0);
  }

  void setup_cube_index_buffer() {
    // note these indices specify the triangles' vertices counterclockwise; the order matters
    // you can change the order with gl.frontFace(WebGL.CCW or WebGL.CW)
    index_data = new Uint16List.fromList([
         0, 1, 2,  0, 2, 3,  // Front face
         4, 5, 6,  4, 6, 7,  // Back face
         4, 5, 1,  4, 1, 0,  // Top face
         7, 6, 2,  7, 2, 3,  // Bottom face
         4, 0, 3,  4, 3, 7,  // Right face
         1, 5, 6,  1, 6, 2   // Left face
    ]);

    indexBuffer = gl.createBuffer();
    // note the ELEMENT_ARRAY_BUFFER here
    gl.bindBuffer(WebGL.RenderingContext.ELEMENT_ARRAY_BUFFER, indexBuffer);
    gl.bufferDataTyped(WebGL.RenderingContext.ELEMENT_ARRAY_BUFFER, index_data, WebGL.RenderingContext.STATIC_DRAW);
  }

  void bind_cube_index_buffer() {
    gl.bindBuffer(WebGL.RenderingContext.ELEMENT_ARRAY_BUFFER, indexBuffer);
  }

  void setup_cube_color_buffer() {
    // one color for each vertex
    color_data = new Float32List.fromList( [0.0, 1.0, 0.0, 1.0, // front 4 vertices
                                            1.0, 0.0, 0.0, 1.0,
                                            0.0, 0.0, 1.0, 1.0,
                                            1.0, 1.0, 1.0, 1.0,

                                            1.0, 1.0, 1.0, 1.0, // back 4 vertices
                                            0.0, 1.0, 0.0, 1.0,
                                            0.0, 0.0, 1.0, 1.0,
                                            1.0, 0.0, 0.0, 1.0]);

    colorBuffer = gl.createBuffer();
    gl.bindBuffer(WebGL.RenderingContext.ARRAY_BUFFER, colorBuffer);
    gl.bufferDataTyped(WebGL.RenderingContext.ARRAY_BUFFER, color_data, WebGL.RenderingContext.STATIC_DRAW);
  }
  void bind_cube_color_buffer() {
    gl.bindBuffer(WebGL.RenderingContext.ARRAY_BUFFER, colorBuffer);
    gl.vertexAttribPointer(colorLocation, 4, WebGL.RenderingContext.FLOAT, false, 0, 0);
  }

  void set_matrices() {
    // model-view matrix is the composition of the object (model) transform and the camera (view) transform
    // mvMatrix = view * model
    // projection matrix does the perspective projection that takes parallel lines and makes them meet at infinity

    // 0.78 radians is about 45 degrees
    // the zNear and zFar are arbitrary and are essentially the view distance
    projection_matrix = makePerspectiveMatrix(0.78, canvas.width/canvas.height, 1.0, 100.0);

    // both the projection matrix and the three vectors below do not need to be computed every frame
    Vector3 camera_pos = new Vector3(0.0, 0.0, 10.0);
    Vector3 lookAt_dir = new Vector3(0.0, 0.0, -1.0); // looking straight down the z axis
    Vector3 up_dir = new Vector3(0.0, 1.0, 0.0);

    view_matrix = makeViewMatrix(camera_pos, lookAt_dir, up_dir);
  }

  void set_matrix_uniforms(Matrix4 model_matrix) {
    Matrix4 mvMatrix = view_matrix*model_matrix; // order matters!
    gl.uniformMatrix4fv(mvMatrixLocation, false, mvMatrix.storage);
    gl.uniformMatrix4fv(projectionMatrixLocation, false, projection_matrix.storage);
  }

  void draw(num timestamp) {
    this.dt = timestamp - this.timestamp;
    this.timestamp = timestamp;

    gl.clear(WebGL.COLOR_BUFFER_BIT | WebGL.DEPTH_BUFFER_BIT);
    bind_cube_color_buffer();
    bind_cube_buffer();
    bind_cube_index_buffer();

    for (Cube cube in cubes) {
      cube.update(dt);
      set_matrices();
      set_matrix_uniforms(cube.model_matrix);

      // draw the triangles via indexed elements
      gl.drawElements(WebGL.RenderingContext.TRIANGLES, index_data.length, WebGL.UNSIGNED_SHORT, 0); // index_data.length == 6
    }

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

  CubeRenderer r = new CubeRenderer(canvas);
  r.start();
}
