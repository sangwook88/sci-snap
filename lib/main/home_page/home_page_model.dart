import '/backend/supabase/supabase.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/index.dart';
import 'home_page_widget.dart' show HomePageWidget;
import 'package:flutter/material.dart';

class HomePageModel extends FlutterFlowModel<HomePageWidget> {
  ///  Local state fields for this page.

  List<String> imageUrls = [];
  void addToImageUrls(String item) => imageUrls.add(item);
  void removeFromImageUrls(String item) => imageUrls.remove(item);
  void removeAtIndexFromImageUrls(int index) => imageUrls.removeAt(index);
  void insertAtIndexInImageUrls(int index, String item) =>
      imageUrls.insert(index, item);
  void updateImageUrlsAtIndex(int index, Function(String) updateFn) =>
      imageUrls[index] = updateFn(imageUrls[index]);

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

  bool imageToggle = false;

  ///  State fields for stateful widgets in this page.

  bool isDataUploading_uploadedData = false;
  FFUploadedFile uploadedLocalFile_uploadedData =
      FFUploadedFile(bytes: Uint8List.fromList([]), originalFilename: '');
  String uploadedFileUrl_uploadedData = '';

  // Stores action output result for [Backend Call - Insert Row] action in NotificationListener widget.
  AiChatsRow? createAiChats;
  bool isDataUploading_uploadDataGv2 = false;
  FFUploadedFile uploadedLocalFile_uploadDataGv2 =
      FFUploadedFile(bytes: Uint8List.fromList([]), originalFilename: '');
  String uploadedFileUrl_uploadDataGv2 = '';

  // State field(s) for msgField widget.
  FocusNode? msgFieldFocusNode;
  TextEditingController? msgFieldTextController;
  String? Function(BuildContext, String?)? msgFieldTextControllerValidator;
  // Stores action output result for [Backend Call - Insert Row] action in sendContainer widget.
  AiChatsRow? createAiChats1;

  @override
  void initState(BuildContext context) {}

  @override
  void dispose() {
    msgFieldFocusNode?.dispose();
    msgFieldTextController?.dispose();
  }
}
