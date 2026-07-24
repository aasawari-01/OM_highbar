
import "dart:io";

void main() {
  final lines = File("lib/feature/failure/view/create_failure_screen.dart").readAsLinesSync();
  for (int i = 0; i < lines.length; i++) {
    final line = lines[i].trim();
    if (line.startsWith("Widget _build") || line.startsWith("Widget build")) {
      print("${i+1}: $line");
    }
  }
}

