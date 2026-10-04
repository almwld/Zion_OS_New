import 'dart:io';
class FileSharer {
  Future<int> size(File file)=>file.length();
  Stream<List<int>> read(File file,{int chunkSize=64*1024}) async* {
    if(!await file.exists())throw FileSystemException('File not found',file.path);
    await for(final chunk in file.openRead(0,null)){yield chunk;}
  }
  Future<void> write(File file,List<int> data) async {await file.parent.create(recursive:true);await file.writeAsBytes(data,flush:true);}
}
