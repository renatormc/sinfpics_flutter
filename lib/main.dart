import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'pic.dart';
import 'storage_manager.dart';
import 'package:permission_handler/permission_handler.dart';

void main() async {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: MyHomePage(title: 'SinfPics'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final picker = ImagePicker();
  List<Pic> pics = <Pic>[];
  StorageManager storageManager = StorageManager();
  final objNameController = TextEditingController();

  void initState() {
    storageManager.init();
    loadPictures();
    super.initState();
  }

  loadPictures() async {
    var pics = await storageManager.getPics();
    setState(() {
      this.pics = pics;
    });
  }

  clearFolder() async {
    print("iniciando deleção");
    await this.storageManager.clearFolder();
    await this.loadPictures();
    print("finalizando deletação");
  }

  @override
  void dispose() {
    // Clean up the controller when the widget is removed from the
    // widget tree.
    objNameController.dispose();
    super.dispose();
  }

  void _showDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        // retorna um objeto do tipo Dialog
        return AlertDialog(
          title: new Text(title),
          content: new Text(message),
          actions: <Widget>[
            // define os botões na base do dialogo
            new FlatButton(
              child: new Text("Fechar"),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Future getImage() async {
    if (await Permission.camera.request().isGranted) {
      var objName = objNameController.text;
      if (objName == "") {
        _showDialog("Objeto sem nome",
            "É preciso definir um nome para o objeto antes de tirar a foto.");
        return;
      }
      final pickedFile = await picker.getImage(source: ImageSource.camera);
      var pic = await storageManager.movePicture(
          pickedFile.path, objNameController.text);
      setState(() {
        pics.add(pic);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title), actions: <Widget>[
        IconButton(
          icon: const Icon(Icons.delete),
          tooltip: 'Deletar todas',
          onPressed: clearFolder,
        ),
        IconButton(
          icon: const Icon(Icons.update),
          tooltip: 'Recarregar fotos',
          onPressed: loadPictures,
        ),
        IconButton(
          icon: const Icon(Icons.camera_alt),
          tooltip: 'Tirar foto',
          onPressed: getImage,
        ),
      ]),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: <Widget>[
          Padding(
            padding: EdgeInsets.only(
              top: 5,
              left: 5,
              right: 5,
            ),
            child: TextField(
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Nome do objeto',
              ),
              controller: objNameController,
            ),
          ),

          // _image == null ? Text('No image selected.') : Image.file(_image),
          Expanded(
            child: GridView.builder(
              itemCount: pics.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 4.0,
                  mainAxisSpacing: 4.0),
              itemBuilder: (BuildContext context, int index) {
                return InkWell(
                  onTap: () {
                    print("Clicou foto ${pics[index].name}");
                  },
                  onLongPress: (){
                    print("CLique longo");
                  },
                  child: Container(
                    padding: EdgeInsets.all(5),
                    child: Column(
                      children: [
                        Expanded(
                          child: Image.file(pics[index].file),
                        ),
                        Text(pics[index].name),
                      ],
                    ),
                  ),
                );
              },
            ),
          )
        ],
      ),
    );
  }
}
