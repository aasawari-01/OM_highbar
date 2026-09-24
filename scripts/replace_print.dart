import 'dart:io';

void main() {
  final dir = Directory('lib');
  int count = 0;

  for (final file in dir.listSync(recursive: true)) {
    if (file is File && file.path.endsWith('.dart')) {
      String content = file.readAsStringSync();
      
      // Basic check for print
      if (content.contains('print(')) {
        // Regex to replace print( with debugPrint(
        final newContent = content.replaceAll(RegExp(r'\bprint\('), 'debugPrint(');
        
        // Add import if not present and debugPrint is used
        if (newContent != content) {
          if (!newContent.contains("import 'package:flutter/material.dart';") &&
              !newContent.contains("import 'package:flutter/foundation.dart';")) {
            // Add import at the top
            content = "import 'package:flutter/foundation.dart';\n" + newContent;
          } else {
            content = newContent;
          }
          file.writeAsStringSync(content);
          count++;
          print('Updated ${file.path}');
        }
      }
    }
  }
  print('Updated $count files.');
}
