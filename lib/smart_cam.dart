import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gemini/flutter_gemini.dart';
import 'package:flutter_tts/flutter_tts.dart';

class SmartCam extends StatefulWidget {
  final String language;
  SmartCam(this.language);

  @override
  State<SmartCam> createState() => _SmartCamState();
}

class _SmartCamState extends State<SmartCam> {
  late List<CameraDescription> _cameras;
  CameraController? controller;

  bool processing = false;
  Uint8List? image;
  String description = '';

  final gemini = Gemini.instance;
  
  final tts = FlutterTts();

  @override
  void initState() {
    super.initState();
    if (widget.language.toLowerCase() == 'hindi') {
      tts.setLanguage('hi');
    }
    availableCameras().then((value) {
      _cameras = value;
      controller = CameraController(_cameras[0], ResolutionPreset.max);
      controller?.initialize().then((_) {
        if (!mounted) {
          return;
        }
        setState(() {});
      }).catchError((Object e) {
      });
    });
  }

  List<Widget> _showImage(CameraController? controller, Uint8List? image) {
    if (controller == null) {
      return <Widget>[
        SizedBox(
          width: 1,
        )
      ];
    } else if (processing == false) {
      return <Widget>[
        CameraPreview(controller),
      ];
    } else if (processing == true) {
      return <Widget>[
        Image.memory(image!),
        Positioned.fill(
            child: Center(child: CircularProgressIndicator.adaptive()))
      ];
    } else {
      return <Widget>[
        CameraPreview(controller),
      ];
    }
  }

  void _describeImage() async {
    var picture = await controller?.takePicture();
    var b = await picture?.readAsBytes();
    setState(() {
      processing = true;
      image = b;
    });
    var response = await gemini.textAndImage(
        text:
            "What does this show? Respond in ${widget.language} language with 3-4 lines",
        images: [b!]);
    var p = response?.outputPart as TextPart;
    setState(() {
      description = p.text;
      processing = false;
    });
    tts.speak(p.text);
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text("SmartCam"),
          backgroundColor: Colors.black54,
          foregroundColor: Colors.white,
        ),
        body: Center(
          child: GestureDetector(
            onLongPress: () {
              _describeImage();
            },
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Container(
                      color: Colors.black,
                      child: Container(
                          height:
                              2 * (MediaQuery.sizeOf(context).height / 3) - 60,
                          decoration: BoxDecoration(
                              border:
                                  Border.all(color: Colors.black, width: 13)),
                          child: Center(
                              child: ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: Stack(
                                      children:
                                          _showImage(controller, image))))),
                    ),
                  ),
                  Align(
                      alignment: Alignment.center,
                      child: Container(
                          width: MediaQuery.sizeOf(context).width,
                          color: Colors.black54,
                          child: Container(
                              padding: EdgeInsets.all(10),
                              margin: EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.black54,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                description,
                                style: TextStyle(color: Colors.white),
                              ))))
                ]),
          ),
        ));
  }
}
