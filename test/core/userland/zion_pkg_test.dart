import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import '../../../lib/core/userland/zion_pkg.dart';
void main(){test('missing deb is rejected',()async{final r=await ZionPkg().installFromFile(Directory.systemTemp.path+'/missing.deb');expect(r.success,isFalse);});test('tool status is explicit',()async{final s=await ZionPkg().checkTools();expect(s.keys,containsAll(<String>['bash','dpkg','proot','ssh']));expect(s.values.every(PackageStatus.values.contains),isTrue);});test('unsafe package names are rejected',()async{final r=await ZionPkg().remove('../escape');expect(r.success,isFalse);});}
