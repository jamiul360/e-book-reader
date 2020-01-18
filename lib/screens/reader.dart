import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart';
import 'package:path_provider/path_provider.dart';

class ReaderPage extends StatefulWidget {
  final String name;
  final bool night;

  ReaderPage({@required this.name, this.night = false});

  @override
  _ReaderPageState createState() => _ReaderPageState();
}

class _ReaderPageState extends State<ReaderPage> {
  final Completer<PDFViewController> _controller =
      Completer<PDFViewController>();

  Future<File> getFile() async {
    final url = await get(
        "https://unpaprdapi.gargakshit.now.sh/api/getEbook?q=${widget.name}");

    if (url.statusCode == 200) {
      final raw = await get(url.body);

      if (raw.statusCode == 200) {
        final filename = "${widget.name}.pdf";
        final bytes = raw.bodyBytes;

        String dir = (await getApplicationDocumentsDirectory()).path;
        File file = new File('$dir/$filename');
        await file.writeAsBytes(bytes);
        return file;
      } else {
        throw Exception("HTTP Error!!");
      }
    } else {
      throw Exception("HTTP Error!");
    }
  }

  int page = 0;
  int total = 1;

  Color bgColor = Colors.black;

  @override
  Widget build(BuildContext gContext) {
    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: FutureBuilder<File>(
          future: getFile(),
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              return Column(
                children: <Widget>[
                  Container(
                    width: MediaQuery.of(context).size.width,
                    height: MediaQuery.of(context).size.height - 130,
                    child: PDFView(
                      filePath: snapshot.data.path,
                      enableSwipe: true,
                      swipeHorizontal: true,
                      nightMode: widget.night,
                      onViewCreated: (PDFViewController pdfViewController) {
                        _controller.complete(pdfViewController);
                      },
                      onPageChanged: (int p, int t) {
                        setState(() {
                          page = p;
                          total = t;
                        });
                      },
                      onError: (error) {
                        print(error.toString());
                      },
                      onPageError: (page, error) {
                        print('$page: ${error.toString()}');
                      },
                    ),
                  ),
                  Expanded(
                    child: Container(
                        child: FutureBuilder<PDFViewController>(
                      future: _controller.future,
                      builder: (context, snapshot) {
                        if (snapshot.hasData) {
                          return Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: <Widget>[
                              Expanded(
                                child: IconButton(
                                  onPressed: page == 0
                                      ? null
                                      : () async {
                                          snapshot.data.setPage(page - 1);
                                        },
                                  icon: Icon(Icons.keyboard_arrow_left),
                                ),
                              ),
                              FlatButton(
                                onPressed: () {
                                  if (Platform.isAndroid) {
                                    Navigator.of(context).pop();

                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) => ReaderPage(
                                          name: widget.name,
                                          night: !widget.night,
                                        ),
                                      ),
                                    );
                                  }
                                },
                                child: Container(
                                  width: 120,
                                  child: Center(
                                    child: Text(
                                      "${page + 1} / ${total + 1}",
                                      style: TextStyle(
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              Expanded(
                                child: IconButton(
                                  onPressed: page == total
                                      ? null
                                      : () {
                                          snapshot.data.setPage(page + 1);
                                        },
                                  icon: Icon(Icons.keyboard_arrow_right),
                                ),
                              ),
                            ],
                          );
                        }

                        return Container();
                      },
                    )),
                  ),
                ],
              );
            }

            if (snapshot.hasError) {
              return Center(
                child: Padding(
                  padding: EdgeInsets.only(
                    left: 16,
                    right: 16,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Text(
                        "${snapshot.error}",
                        style: GoogleFonts.montserrat(
                          textStyle: TextStyle(
                            color: Colors.white,
                            fontSize: 18.0,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      Text(
                        "Error while downloading your book...",
                        style: GoogleFonts.montserrat(
                          textStyle: TextStyle(
                            color: Colors.black,
                            fontSize: 14.0,
                          ),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              );
            }

            return Center(
              child: Padding(
                padding: EdgeInsets.only(
                  left: 16,
                  right: 16,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Text(
                      "Please wait while we download the book for you",
                      style: GoogleFonts.montserrat(
                        textStyle: TextStyle(
                          color: Colors.white,
                          fontSize: 18.0,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(
                      height: 16,
                    ),
                    CircularProgressIndicator(),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
