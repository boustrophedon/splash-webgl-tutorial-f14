import 'dart:html';
import 'dart:web_gl' as WebGL;

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
}
