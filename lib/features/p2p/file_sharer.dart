import 'dart:io';
class FileSharer { Future<List<int>> read(File file)=>file.readAsBytes(); Future<void> write(File file,List<int> data)=>file.writeAsBytes(data); }