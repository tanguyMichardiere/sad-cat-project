import 'dart:io';

import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share/share.dart';

class Body extends StatefulWidget {
  @override
  _BodyState createState() => _BodyState();
}

class _BodyState extends State<Body> {
  Future<List<Reference>> _listApproved() async {
    ListResult listResult =
        await FirebaseStorage.instance.ref('/approved').listAll();
    return listResult.items;
  }

  List<Reference> _approved;

  Future<void> refresh() async {
    List<Reference> approved = await _listApproved();
    setState(() {
      _approved = approved;
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _listApproved(),
      builder: (context, AsyncSnapshot<List<Reference>> snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Text('Error fetching Sad Cat database'),
          );
        }
        if (snapshot.connectionState == ConnectionState.done) {
          _approved = snapshot.data;
          return RefreshIndicator(
            onRefresh: refresh,
            child: GridView.builder(
              gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 300,
              ),
              physics: AlwaysScrollableScrollPhysics(),
              itemCount: _approved.length,
              itemBuilder: (context, index) {
                return InkWell(
                  onTap: () {
                    var snackBar = Scaffold.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Sharing image...'),
                      ),
                    );
                    getApplicationDocumentsDirectory().then((directory) {
                      File file = File(
                        '${directory.path}/${DateTime.now().microsecondsSinceEpoch}.jpg',
                      );
                      try {
                        _approved[index].writeToFile(file).whenComplete(() {
                          snackBar.close();
                          Share.shareFiles([file.path]);
                        });
                      } on FirebaseException catch (e) {
                        Scaffold.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Download failed, code: ${e.code}'),
                          ),
                        );
                      }
                    });
                  },
                  child: FutureBuilder(
                    future: _approved[index].getDownloadURL(),
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
    );
  }
}
