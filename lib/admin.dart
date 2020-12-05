import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

Future<UserCredential> adminSignIn() async {
  String jsonString;
  try {
    jsonString = await rootBundle.loadString('assets/admin.json');
    var json = jsonDecode(jsonString);
    return FirebaseAuth.instance.signInWithEmailAndPassword(
        email: json['email'], password: json['password']);
  } on Exception catch (_) {
    return FirebaseAuth.instance.signInAnonymously();
  }
}

class AdminPanel extends StatefulWidget {
  @override
  _AdminPanelState createState() => _AdminPanelState();
}

class _AdminPanelState extends State<AdminPanel> {
  Future<List<Reference>> _listPending() async {
    ListResult listResult =
        await FirebaseStorage.instance.ref('/pending').listAll();
    return listResult.items;
  }

  List<Reference> _pending;

  Future<void> refresh() async {
    List<Reference> pending = await _listPending();
    setState(() {
      _pending = pending;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Sad Cat Admin Panel'),
      ),
      body: FutureBuilder(
        future: _listPending(),
        builder: (context, AsyncSnapshot<List<Reference>> snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text('Error fetching Sad Cat database'),
            );
          }
          if (snapshot.connectionState == ConnectionState.done) {
            _pending = snapshot.data;
            return RefreshIndicator(
              onRefresh: refresh,
              child: GridView.builder(
                gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 300,
                ),
                physics: AlwaysScrollableScrollPhysics(),
                itemCount: _pending.length,
                itemBuilder: (context, index) {
                  return InkWell(
                    onTap: () {
                      showDialog(
                        context: context,
                        child: AlertDialog(
                          title: Text('Validate Sad Cat?'),
                          content: FutureBuilder(
                            future: _pending[index].getDownloadURL(),
                            builder: (context, AsyncSnapshot<String> snapshot) {
                              if (snapshot.hasError) {
                                return Center(
                                  child: Text('Error fetching Sad Cat image'),
                                );
                              }
                              if (snapshot.connectionState ==
                                  ConnectionState.done) {
                                return Image.network(snapshot.data);
                              }
                              return Center(
                                child: CircularProgressIndicator(),
                                heightFactor: 2,
                              );
                            },
                          ),
                          actions: [
                            FlatButton(
                              onPressed: () {
                                var deleting =
                                    Scaffold.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text("Deleting..."),
                                  ),
                                );
                                _pending[index].delete().then((value) {
                                  deleting.close();
                                  Scaffold.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text("Done"),
                                    ),
                                  );
                                  setState(() {
                                    _pending.removeAt(index);
                                  });
                                  Navigator.of(context).pop();
                                });
                              },
                              child: Icon(
                                Icons.delete,
                                color: Colors.red,
                              ),
                            ),
                            FlatButton(
                              onPressed: () {
                                var validating =
                                    Scaffold.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text("Validating..."),
                                  ),
                                );
                                getApplicationDocumentsDirectory()
                                    .then((directory) {
                                  File file = File(
                                    '${directory.path}/${DateTime.now().microsecondsSinceEpoch}.jpg',
                                  );
                                  try {
                                    _pending[index]
                                        .writeToFile(file)
                                        .whenComplete(() {
                                      try {
                                        FirebaseStorage.instance
                                            .ref(
                                              'approved/${DateTime.now().microsecondsSinceEpoch}.jpg',
                                            )
                                            .putFile(file)
                                            .then((_) {
                                          _pending[index].delete().then((_) {
                                            validating.close();
                                            Scaffold.of(context).showSnackBar(
                                              SnackBar(
                                                content: Text("Done"),
                                              ),
                                            );
                                            setState(() {
                                              _pending.removeAt(index);
                                            });
                                            Navigator.of(context).pop();
                                          });
                                        });
                                      } on FirebaseException catch (e) {
                                        Scaffold.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              "Upload failed, code: ${e.code}",
                                            ),
                                          ),
                                        );
                                      }
                                    });
                                  } on FirebaseException catch (e) {
                                    Scaffold.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          "Download failed, code: ${e.code}",
                                        ),
                                      ),
                                    );
                                  }
                                });
                              },
                              child: Icon(
                                Icons.check,
                                color: Colors.green,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                    child: FutureBuilder(
                      future: _pending[index].getDownloadURL(),
                      builder: (context, AsyncSnapshot<String> snapshot) {
                        if (snapshot.hasError) {
                          return Center(
                            child: Text('Error fetching Sad Cat image'),
                          );
                        }
                        if (snapshot.connectionState == ConnectionState.done) {
                          return Ink.image(
                            image: NetworkImage(snapshot.data),
                            fit: BoxFit.cover,
                          );
                        }
                        return Center(child: CircularProgressIndicator());
                      },
                    ),
                  );
                },
              ),
            );
          }
          return Center(child: CircularProgressIndicator());
        },
      ),
    );
  }
}
