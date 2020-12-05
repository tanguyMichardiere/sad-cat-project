import 'dart:io';

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_displaymode/flutter_displaymode.dart';
import 'package:file_picker/file_picker.dart';

import 'body.dart';
import 'admin.dart';

const ADMIN = bool.fromEnvironment('admin');

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  if (ADMIN) {
    await adminSignIn();
  } else {
    await FirebaseAuth.instance.signInAnonymously();
  }
  try {
    List<DisplayMode> modes = await FlutterDisplayMode.supported;
    await FlutterDisplayMode.setMode(
      modes.reduce((mode1, mode2) {
        if (mode1.width * mode1.height * mode1.refreshRate >
            mode2.width * mode2.height * mode2.refreshRate) {
          return mode1;
        } else {
          return mode2;
        }
      }),
    );
  } catch (_) {}
  runApp(
    MaterialApp(
      title: 'Sad Cat',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      darkTheme: ThemeData(
        primarySwatch: Colors.grey,
        brightness: Brightness.dark,
      ),
      home: Home(),
    ),
  );
}

class Home extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Sad Cat'),
        actions: [
          ADMIN
              ? IconButton(
                  icon: Icon(Icons.settings),
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => AdminPanel(),
                      ),
                    );
                  },
                )
              : Container(),
          IconButton(
            icon: Icon(Icons.info),
            onPressed: () {
              showAboutDialog(
                context: context,
                applicationName: 'Sad Cat',
                applicationVersion: '1.0.0',
                applicationIcon: Image.asset(
                  'assets/icon.jpg',
                  width: IconTheme.of(context).size,
                ),
                applicationLegalese: '©️ 2020 Tanguy Michardière',
              );
            },
          ),
        ],
      ),
      body: Body(),
      floatingActionButton: UploadButton(),
    );
  }
}

class UploadButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      onPressed: () {
        FilePicker.platform.pickFiles(
          type: FileType.custom,
          allowedExtensions: ['jpg', 'jpeg'],
        ).then((filePickerResult) {
          if (filePickerResult != null) {
            String filePath = filePickerResult.paths.single;
            try {
              FirebaseStorage.instance
                  .ref(
                    'pending/${DateTime.now().microsecondsSinceEpoch}.jpg',
                  )
                  .putFile(File(filePath))
                  .then((_) {
                Scaffold.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Upload success'),
                  ),
                );
              });
            } on FirebaseException catch (e) {
              Scaffold.of(context).showSnackBar(
                SnackBar(
                  content: Text('Upload failed, code: ${e.code}'),
                ),
              );
            }
          }
        });
      },
      tooltip: 'Upload',
      child: Icon(Icons.add),
    );
  }
}
