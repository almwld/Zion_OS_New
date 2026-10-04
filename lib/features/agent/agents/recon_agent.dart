class ReconAgent {
  Future<Map<String,dynamic>> collect(String target) async {
    final value=target.trim();
    if(value.isEmpty)throw ArgumentError.value(target,'target');
    return {'target':value,'status':'collected','passive':true,'sources':const ['target-validation'],'findings':const <String>[]};
  }
}
