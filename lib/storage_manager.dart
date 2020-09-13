import 'dart:io';
import 'package:ext_storage/ext_storage.dart';
import 'package:path/path.dart' as p;
import 'package:permission_handler/permission_handler.dart';
import 'package:sinfpics_flutter/pic.dart';

class StorageManager {
  Future<Directory> picsFolder;
  StorageManager();

  Future init() async {
    this.picsFolder = this.resolveDir();
  }

  Future<Directory> resolveDir() async {
    return Directory(p.join(
        await ExtStorage.getExternalStoragePublicDirectory(
            ExtStorage.DIRECTORY_PICTURES),
        "sinfpics"));
  }

  Future<Pic> movePicture(String path, String name) async {
    var _picsFolder = await this.picsFolder;
    await prepareFolder();
    var file = File(path);
    var ext = file.path.split(".").last;
    var newName = name;
    var fullName = "$name.$ext";
    var destPath = p.join(_picsFolder.path, fullName);
    var i = 1;
    while (await File(destPath).exists()) {
      newName = "${name}_$i";
      fullName = "$newName.$ext";
      destPath = p.join(_picsFolder.path, fullName);
      i++;
    }
    file = await file.rename(destPath);
    return Pic(newName, file);
  }

  prepareFolder() async {
    Directory _picsFolder = await this.picsFolder;
    if (await Permission.storage.request().isGranted) {
      final exists = await (await this.picsFolder).exists();
      if (!exists) {
        _picsFolder.createSync(recursive: true);
      }
    }
  }

  Future<List<Pic>> getPics() async {
    await prepareFolder();
    var _picsFolder = await this.picsFolder;
    var pics = <Pic>[];
    for (var file in _picsFolder.listSync()) {
      if (file is File) {
        var name = p.basename(file.path);
        name = name.substring(0, name.length - 4);
        pics.add(Pic(name, file));
      }
    }
    return pics;
  }

  clearFolder() async {
    await prepareFolder();
    var _picsFolder = await this.picsFolder;
    for (var file in _picsFolder.listSync()) {
      if (file is File) {
        file.delete();
      }
    }
  }
}
