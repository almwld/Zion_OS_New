import 'dart:io';
class FileTransfer {
  Stream<double> upload(File file, Directory target) async* {
    if(!await file.exists())throw FileSystemException('Source file does not exist',file.path);
    await target.create(recursive:true);
    final output=File(target.path+'/'+file.uri.pathSegments.last);
    final sink=output.openWrite(); final total=await file.length(); var sent=0;
    await for(final chunk in file.openRead()){sink.add(chunk);sent+=chunk.length;yield total==0?1.0:sent/total;}
    await sink.close();
  }
  Stream<double> download(File source, File target) async* {
    if(!await source.exists())throw FileSystemException('Source file does not exist',source.path);
    await target.parent.create(recursive:true); final sink=target.openWrite(); final total=await source.length(); var received=0;
    await for(final chunk in source.openRead()){sink.add(chunk);received+=chunk.length;yield total==0?1.0:received/total;}
    await sink.close();
  }
}
