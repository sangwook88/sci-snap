// Automatic FlutterFlow imports
import '/backend/supabase/supabase.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'index.dart'; // Imports other custom widgets
import '/custom_code/actions/index.dart'; // Imports custom actions
import '/flutter_flow/custom_functions.dart'; // Imports custom functions
import 'package:flutter/material.dart';
// Begin custom widget code
// DO NOT REMOVE OR MODIFY THE CODE ABOVE!

import 'dart:io';
import 'dart:async';
import 'dart:ui' as ui;
import 'dart:math' as math;
import 'package:path_provider/path_provider.dart';
import 'package:google_mlkit_object_detection/google_mlkit_object_detection.dart'
    as mlkit;

class ObjectDetector extends StatefulWidget {
  const ObjectDetector({
    Key? key,
    this.width,
    this.height,
    required this.uploadedFile,
    required this.onObjectSelected,
  }) : super(key: key);

  final double? width;
  final double? height;
  final FFUploadedFile? uploadedFile;
  final Future<dynamic> Function(String objectLabel) onObjectSelected;

  @override
  _ObjectDetectorState createState() => _ObjectDetectorState();
}

class _ObjectDetectorState extends State<ObjectDetector> {
  List<mlkit.DetectedObject> _objects = [];
  bool _isProcessing = false;
  File? _localImageFile;

  double _imageWidth = 1.0;
  double _imageHeight = 1.0;

  @override
  void initState() {
    super.initState();
    _processUploadedFile();
  }

  @override
  void didUpdateWidget(ObjectDetector oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.uploadedFile != oldWidget.uploadedFile) {
      _processUploadedFile();
    }
  }

  Future<ui.Image> _getTrueImageSize(File file) async {
    final completer = Completer<ui.Image>();
    final stream = FileImage(file).resolve(const ImageConfiguration());
    stream.addListener(ImageStreamListener((info, _) {
      completer.complete(info.image);
    }));
    return completer.future;
  }

  Future<void> _processUploadedFile() async {
    if (widget.uploadedFile == null || widget.uploadedFile!.bytes == null) {
      if (mounted) {
        setState(() {
          _localImageFile = null;
          _objects = [];
          _isProcessing = false;
        });
      }
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    try {
      final tempDir = await getTemporaryDirectory();
      final tempPath =
          '${tempDir.path}/scisnap_${DateTime.now().millisecondsSinceEpoch}.png';
      final file = File(tempPath);
      await file.writeAsBytes(widget.uploadedFile!.bytes!);

      setState(() {
        _localImageFile = file;
      });

      final uiImage = await _getTrueImageSize(file);
      _imageWidth = uiImage.width.toDouble();
      _imageHeight = uiImage.height.toDouble();

      final options = mlkit.ObjectDetectorOptions(
        mode: mlkit.DetectionMode.single,
        classifyObjects: true,
        multipleObjects: true,
      );

      final objectDetector = mlkit.ObjectDetector(options: options);
      final inputImage = mlkit.InputImage.fromFilePath(file.path);

      final List<mlkit.DetectedObject> objects =
          await objectDetector.processImage(inputImage);

      if (mounted) {
        setState(() {
          _objects = objects;
        });
      }
      await objectDetector.close();
    } catch (e) {
      print("ML Kit 분석 에러: $e");
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.uploadedFile == null || widget.uploadedFile!.bytes == null) {
      return Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
            color: Colors.black87, borderRadius: BorderRadius.circular(12)),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.camera_alt_outlined,
                  color: Color(0xFF00FF00), size: 40),
              SizedBox(height: 12),
              Text("스냅 대기 중...", style: TextStyle(color: Color(0xFF00FF00))),
            ],
          ),
        ),
      );
    }

    if (_isProcessing) {
      return Container(
        width: widget.width,
        height: widget.height,
        color: Colors.black,
        child: const Center(
            child: CircularProgressIndicator(color: Color(0xFF00FF00))),
      );
    }

    return LayoutBuilder(builder: (context, constraints) {
      double widgetWidth = widget.width ??
          (constraints.maxWidth.isInfinite
              ? MediaQuery.of(context).size.width
              : constraints.maxWidth);

      double widgetHeight = widget.height ??
          (constraints.maxHeight.isInfinite
              ? MediaQuery.of(context).size.height * 0.7
              : constraints.maxHeight);

      if (_imageWidth == 0 || _imageHeight == 0) {
        _imageWidth = 1;
        _imageHeight = 1;
      }

      final imageSize = Size(_imageWidth, _imageHeight);
      final widgetSize = Size(widgetWidth, widgetHeight);

      final fittedSizes = applyBoxFit(BoxFit.contain, imageSize, widgetSize);
      final renderedWidth = fittedSizes.destination.width;
      final renderedHeight = fittedSizes.destination.height;

      final offsetX = (widgetWidth - renderedWidth) / 2;
      final offsetY = (widgetHeight - renderedHeight) / 2;

      final scaleX = renderedWidth / _imageWidth;
      final scaleY = renderedHeight / _imageHeight;

      return Container(
        width: widgetWidth,
        height: widgetHeight,
        color: Colors.black,
        child: ClipRect(
          child: Stack(
            children: [
              if (_localImageFile != null)
                Center(
                  child: Image.file(
                    _localImageFile!,
                    width: widgetWidth,
                    height: widgetHeight,
                    fit: BoxFit.contain,
                  ),
                ),
              ..._objects.map((obj) {
                return Positioned(
                  left: offsetX + (obj.boundingBox.left * scaleX),
                  top: offsetY + (obj.boundingBox.top * scaleY),
                  width: obj.boundingBox.width * scaleX,
                  height: obj.boundingBox.height * scaleY,
                  child: GestureDetector(
                    onTap: () {
                      String label = obj.labels.isNotEmpty
                          ? obj.labels.first.text
                          : "Object";
                      widget.onObjectSelected(label);
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(
                            color: const Color(0xFF00FF00), width: 3),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Align(
                        alignment: Alignment.topLeft,
                        child: Container(
                          color: const Color(0xFF00FF00),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 4, vertical: 2),
                          child: Text(
                            obj.labels.isNotEmpty ? obj.labels.first.text : '?',
                            style: const TextStyle(
                                color: Colors.black,
                                fontSize: 12,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
      );
    });
  }
}
// Set your widget name, define your parameter, and then add the
// boilerplate code using the green button on the right!
