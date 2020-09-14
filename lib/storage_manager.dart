import 'dart:io';
import 'package:ext_storage/ext_storage.dart';
import 'package:path/path.dart' as p;
import 'package:permission_handler/permission_handler.dart';
import 'package:sinfpics_flutter/pic.dart';
import 'package:path_provider/path_provider.dart';


class StorageManager {
  Future<Directory> picsFolder;
  Future<Directory> thumbsFolder;

  StorageManager();

  Future init() async {
    this.picsFolder = this.resolvePicsFolder();
    this.thumbsFolder = this.resolveThumbsFolder();
  }

  Future<Directory> resolvePicsFolder() async {
    return Directory(p.join(
        await ExtStorage.getExternalStoragePublicDirectory(
            ExtStorage.DIRECTORY_PICTURES),
        "sinfpics"));
  }

  Future<Directory> resolveThumbsFolder() async {
    return Directory(
        p.join((await getApplicationDocumentsDirectory()).path, "thumbnails"));
  }




  Future<Pic> movePicture(String path, String name) async {
    var _picsFolder = await this.picsFolder;
    var _thumbsFolder = await this.thumbsFolder;
    await prepareFolder();
    var file = File(path);
    var ext = file.path
        .split(".")
        .last;
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
    var pic = Pic(newName, file);
    return pic;
  }

  prepareFolder() async {
    Directory _picsFolder = await this.picsFolder;
    Directory _thumbsFolder = await this.thumbsFolder;
    var status = await Permission.storage.status;
    if (!status.isGranted) {
      await Permission.storage.request();
    }
    if (await Permission.storage
        .request()
        .isGranted) {
      var exists = await (await this.picsFolder).exists();
      if (!exists) {
        _picsFolder.createSync(recursive: true);
      }

      exists = await (await this.thumbsFolder).exists();
      if (!exists) {
        _thumbsFolder.createSync(recursive: true);
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

    var __thumbsFolder = await this.thumbsFolder;
    for (var file in __thumbsFolder.listSync()) {
      if (file is File) {
        file.delete();
      }
    }
  }

  deletePicFile(Pic pic) async {
    if (await pic.file.exists()) {
      await pic.deleteThumb();
      await pic.file.delete();
    }
  }
}
