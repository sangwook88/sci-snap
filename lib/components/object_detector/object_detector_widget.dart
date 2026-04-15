import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/custom_code/widgets/index.dart' as custom_widgets;
import 'package:flutter/material.dart';
import 'object_detector_model.dart';
export 'object_detector_model.dart';

class ObjectDetectorWidget extends StatefulWidget {
  const ObjectDetectorWidget({
    super.key,
    required this.imagePath,
  });

  final FFUploadedFile? imagePath;

  @override
  State<ObjectDetectorWidget> createState() => _ObjectDetectorWidgetState();
}

class _ObjectDetectorWidgetState extends State<ObjectDetectorWidget> {
  late ObjectDetectorModel _model;

  @override
  void setState(VoidCallback callback) {
    super.setState(callback);
    _model.onUpdate();
  }

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => ObjectDetectorModel());

    WidgetsBinding.instance.addPostFrameCallback((_) => safeSetState(() {}));
  }

  @override
  void dispose() {
    _model.maybeDispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        decoration: BoxDecoration(
          color: FlutterFlowTheme.of(context).secondaryBackground,
        ),
        child: Container(
          width: double.infinity,
          height: MediaQuery.sizeOf(context).height * 1.0,
          child: custom_widgets.ObjectDetector(
            width: double.infinity,
            height: MediaQuery.sizeOf(context).height * 1.0,
            uploadedFile: widget.imagePath,
            onObjectSelected: (objectLabel) async {
              FFAppState().objectLabel = objectLabel;
              safeSetState(() {});
            },
          ),
        ),
      ),
    );
  }
}
