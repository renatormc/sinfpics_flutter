import 'dart:io';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';

class Pic {
  String name;
  File file;


  Pic(this.name, this.file);

  // generateThumb() async {
  //
  //   img.Image image = img.decodeImage(file.readAsBytesSync());
  //   img.Image thumbnail = img.copyResize(image, width: 120);
  //   var docsDir = await getApplicationDocumentsDirectory();
  //   var path = File("${docsDir.path}/thumbnails/$name.png");
  //   path.writeAsBytesSync(img.encodePng(thumbnail));
  //   _thumb = path;
  //
  // }

  deleteThumb() async {
    var docsDir = await getApplicationDocumentsDirectory();
    var thumb = File("${docsDir.path}/thumbnails/$name.png");
    if (thumb.existsSync()) {
      thumb.delete();
    }
  }

  Future<File> get thumb async {
    var docsDir = await getApplicationDocumentsDirectory();
    var path = File("${docsDir.path}/thumbnails/$name.png");

    if ( path.existsSync()) {
      return path;
    }
    img.Image image = img.decodeImage(file.readAsBytesSync());
    img.Image thumbnail = img.copyResize(image, width: 120);
    path.writeAsBytesSync(img.encodePng(thumbnail));
    return path;
  }
}
