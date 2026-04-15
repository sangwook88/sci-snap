import '/backend/api_requests/api_calls.dart';
import '/backend/supabase/supabase.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'chat_page_widget.dart' show ChatPageWidget;
import 'dart:async';
import 'package:flutter/material.dart';

class ChatPageModel extends FlutterFlowModel<ChatPageWidget> {
  ///  Local state fields for this page.

  List<FFUploadedFile> imageUploaded = [];
  void addToImageUploaded(FFUploadedFile item) => imageUploaded.add(item);
  void removeFromImageUploaded(FFUploadedFile item) =>
      imageUploaded.remove(item);
  void removeAtIndexFromImageUploaded(int index) =>
      imageUploaded.removeAt(index);
  void insertAtIndexInImageUploaded(int index, FFUploadedFile item) =>
      imageUploaded.insert(index, item);
  void updateImageUploadedAtIndex(
          int index, Function(FFUploadedFile) updateFn) =>
      imageUploaded[index] = updateFn(imageUploaded[index]);

  String? tempText;

  List<String> imageUrls = [];
  void addToImageUrls(String item) => imageUrls.add(item);
  void removeFromImageUrls(String item) => imageUrls.remove(item);
  void removeAtIndexFromImageUrls(int index) => imageUrls.removeAt(index);
  void insertAtIndexInImageUrls(int index, String item) =>
      imageUrls.insert(index, item);
  void updateImageUrlsAtIndex(int index, Function(String) updateFn) =>
      imageUrls[index] = updateFn(imageUrls[index]);

  bool imageToggle = false;

  ///  State fields for stateful widgets in this page.

  // Stores action output result for [Backend Call - Insert Row] action in chatPage widget.
  AiChatMessagesRow? createMessagesSystem1;
  Completer<List<AiChatMessagesRow>>? requestCompleter;
  // Stores action output result for [Backend Call - API (askSciBot)] action in chatPage widget.
  ApiCallResponse? apiResult1;
  bool isDataUploading_uploadDataUa6 = false;
  FFUploadedFile uploadedLocalFile_uploadDataUa6 =
      FFUploadedFile(bytes: Uint8List.fromList([]), originalFilename: '');
  String uploadedFileUrl_uploadDataUa6 = '';

  // State field(s) for msgField widget.
  FocusNode? msgFieldFocusNode;
  TextEditingController? msgFieldTextController;
  String? Function(BuildContext, String?)? msgFieldTextControllerValidator;
  // Stores action output result for [Backend Call - Insert Row] action in sendContainer widget.
  AiChatMessagesRow? createMessagesSystem2;
  // Stores action output result for [Backend Call - API (askSciBot)] action in sendContainer widget.
  ApiCallResponse? apiResult2;

  @override
  void initState(BuildContext context) {}

  @override
  void dispose() {
    msgFieldFocusNode?.dispose();
    msgFieldTextController?.dispose();
  }

  /// Additional helper methods.
  Future waitForRequestCompleted({
    double minWait = 0,
    double maxWait = double.infinity,
  }) async {
    final stopwatch = Stopwatch()..start();
    while (true) {
      await Future.delayed(Duration(milliseconds: 50));
      final timeElapsed = stopwatch.elapsedMilliseconds;
      final requestComplete = requestCompleter?.isCompleted ?? false;
      if (timeElapsed > maxWait || (requestComplete && timeElapsed > minWait)) {
        break;
      }
    }
  }
}
