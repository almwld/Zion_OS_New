import 'dart:io';
class ModelManager {
  final Directory directory;
  ModelManager({Directory? directory}):directory=directory??Directory.systemTemp;
  Future<void> init()=>directory.create(recursive:true);
  Future<List<File>> list() async {
    await init();
    final files=directory.listSync().whereType<File>().where((f)=>f.path.toLowerCase().endsWith('.gguf')).toList();
    files.sort((a,b)=>a.path.compareTo(b.path)); return files;
  }
  Future<File> store(File source) async {
    if(!await source.exists())throw FileSystemException('Model does not exist',source.path);
    await init(); final name=source.uri.pathSegments.last;
    if(!name.toLowerCase().endsWith('.gguf'))throw ArgumentError('Only GGUF models are supported');
    return source.copy(directory.path+'/'+name);
  }
  Future<void> delete(File file) async {if(await file.exists())await file.delete();}
}
