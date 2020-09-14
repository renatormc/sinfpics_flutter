import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:photo_view/photo_view.dart';
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
  final renameController = TextEditingController();
  int selectedPicIndex = -1;
  bool modalOpened = false;

  void initState() {
    storageManager.init();
    loadPictures();
    super.initState();
  }

  @override
  void dispose() {
    objNameController.dispose();
    renameController.dispose();
    super.dispose();
  }

  loadPictures() async {
    var pics = await storageManager.getPics();
    setState(() {
      this.pics = pics;
    });
  }

  clearFolder() async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        // retorna um objeto do tipo Dialog
        return AlertDialog(
          title: new Text("Deletar todas"),
          content: new Text("Tem certeza que quer deletar todas as fotos?"),
          actions: <Widget>[
            // define os botões na base do dialogo
            FlatButton(
              child: new Text("Não"),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            FlatButton(
              child: new Text("Sim"),
              onPressed: () async {
                await this.storageManager.clearFolder();
                await this.loadPictures();
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  deletePic() async {
    await storageManager.deletePicFile(pics[selectedPicIndex]);
    setState(() {
      pics.removeAt(selectedPicIndex);
    });
  }

  renamePic() async {
    renameController.text = pics[selectedPicIndex].name;
    renameController.selection = TextSelection(
        baseOffset: 0, extentOffset: renameController.text.length);
    showDialog(
      context: context,
      builder: (BuildContext context) {
        // retorna um objeto do tipo Dialog
        return AlertDialog(
          title: Text("Novo nome"),
          content: TextField(
            controller: renameController,
            autofocus: true,
            decoration: InputDecoration(hintText: "Novo nome para a foto"),
          ),
          actions: <Widget>[
            // define os botões na base do dialogo
            new FlatButton(
              child: new Text("Cancelar"),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            new FlatButton(
              child: new Text("OK"),
              onPressed: () async {
                Navigator.of(context).pop();
                if (renameController.text != pics[selectedPicIndex].name &&
                    renameController.text != "") {
                  var pic = await storageManager.movePicture(
                      pics[selectedPicIndex].file.path, renameController.text);
                  setState(() {
                    pics[selectedPicIndex] = pic;
                  });
                }
              },
            ),
          ],
        );
      },
    );
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

  vizualizePic() async {
    setState(() {
      modalOpened = true;
    });
  }

  void _showModalBottomSheet(context) {
    showModalBottomSheet(
        context: context,
        builder: (BuildContext bc) {
          return Container(
            child: Wrap(
              children: <Widget>[
                ListTile(
                    leading: new Icon(Icons.zoom_in),
                    title: new Text('Vizualizar'),
                    onTap: () {
                      Navigator.of(context).pop();
                      vizualizePic();
                    }),
                ListTile(
                  leading: new Icon(Icons.delete_forever),
                  title: new Text('Deletar'),
                  onTap: () {
                    Navigator.of(context).pop();
                    deletePic();
                  },
                ),
                ListTile(
                    leading: new Icon(Icons.edit),
                    title: new Text('Renomear'),
                    onTap: () {
                      Navigator.of(context).pop();
                      renamePic();
                    }),
              ],
            ),
          );
        });
  }

  Future getImage() async {
    await Permission.storage.request();
    if (await Permission.camera.request().isGranted) {
      var objName = objNameController.text;
      if (objName == "") {
        _showDialog("Objeto sem nome",
            "É preciso definir um nome para o objeto antes de tirar a foto.");
        return;
      }
      final pickedFile = await picker.getImage(source: ImageSource.camera, imageQuality: 1);
      var pic = await storageManager.movePicture(
          pickedFile.path, objNameController.text);
      setState(() {
        pics.add(pic);
      });
      print("Tirou foto");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: !modalOpened ? AppBar(title: Text(widget.title), actions: <Widget>[
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
      ]): null,
      body: !modalOpened
          ? Column(
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


                Expanded(
                  child: GridView.builder(
                    itemCount: pics.length,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        crossAxisSpacing: 2.0,
                        mainAxisSpacing: 2.0),
                    itemBuilder: (BuildContext context, int index) {
                      return Padding(
                          padding: EdgeInsets.all(1),
                          child: InkWell(

                            onTap: () {
                              setState(() {
                                selectedPicIndex = index;
                              });
                              vizualizePic();
                            },
                            onLongPress: () {
                              setState(() {
                                selectedPicIndex = index;
                              });
                              _showModalBottomSheet(context);
                            },
                            child: Column(
                              children: [
                                Expanded(
                                  child: FutureBuilder(
                                    future: pics[index].thumb,
                                    builder: (context, snapshot){
                                      if(snapshot.hasData){
                                        return Image.file(snapshot.data);
                                      }else{
                                        return Center(
                                          child: CircularProgressIndicator(),
                                        );
                                      }
                                    },
                                  ),
                                ),
                                Text(pics[index].name),
                              ],
                            ),
                          ));
                    },
                  ),
                )
              ],
            )
          : Column(
              children: [
                Expanded(
                    child: selectedPicIndex > -1
                        ? PhotoView(
                            imageProvider:
                                FileImage(pics[selectedPicIndex].file),
                          )
                        : Text("Nenhuma imagem selecionada")),
                MaterialButton(
                  height: 40.0,
                  minWidth: double.infinity,
                  color: Theme.of(context).primaryColor,
                  textColor: Colors.white,
                  child: Text("Fechar foto"),
                  onPressed: () {
                    setState(() {
                      modalOpened = false;
                    });
                  },
                  splashColor: Colors.redAccent,
                )
              ],
            ),
    );
  }
}
