import '/backend/api_requests/api_calls.dart';
import '/backend/supabase/supabase.dart';
import '/flutter_flow/flutter_flow_animations.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/upload_data.dart';
import '/custom_code/widgets/index.dart' as custom_widgets;
import '/flutter_flow/custom_functions.dart' as functions;
import 'dart:async';
import 'dart:math' as math;
import 'package:easy_debounce/easy_debounce.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'chat_page_model.dart';
export 'chat_page_model.dart';

class ChatPageWidget extends StatefulWidget {
  const ChatPageWidget({
    super.key,
    required this.chatRef,
    bool? didSnapMode,
    this.tempImagesPath,
    this.tempText,
  }) : this.didSnapMode = didSnapMode ?? false;

  final String? chatRef;
  final bool didSnapMode;
  final List<String>? tempImagesPath;
  final String? tempText;

  static String routeName = 'chatPage';
  static String routePath = '/chatPage';

  @override
  State<ChatPageWidget> createState() => _ChatPageWidgetState();
}

class _ChatPageWidgetState extends State<ChatPageWidget>
    with TickerProviderStateMixin {
  late ChatPageModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  final animationsMap = <String, AnimationInfo>{};

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => ChatPageModel());

    // On page load action.
    SchedulerBinding.instance.addPostFrameCallback((_) async {
      if (widget.didSnapMode) {
        await Future.delayed(
          Duration(
            milliseconds: 200,
          ),
        );
        FFAppState().chatCreatedTimeSystem = getCurrentTimestamp;
        safeSetState(() {});
        _model.createMessagesSystem1 = await AiChatMessagesTable().insert({
          'chat_ref': widget.chatRef,
          'role': 'system',
          'created_at':
              supaSerialize<DateTime>(FFAppState().chatCreatedTimeSystem),
        });
        safeSetState(() => _model.requestCompleter = null);
        await _model.waitForRequestCompleted();
        _model.apiResult1 = await AskSciBotCall.call(
          imageUrlsList: widget.tempImagesPath != null &&
                  (widget.tempImagesPath)!.isNotEmpty
              ? widget.tempImagesPath
              : [],
          question: widget.tempText,
        );

        if ((_model.apiResult1?.succeeded ?? true)) {
          await AiChatMessagesTable().update(
            data: {
              'message': getJsonField(
                (_model.apiResult1?.jsonBody ?? ''),
                r'''$.body.answer''',
              ).toString(),
              'created_at': supaSerialize<DateTime>(getCurrentTimestamp),
            },
            matchingRows: (rows) => rows.eqOrNull(
              'created_at',
              supaSerialize<DateTime>(FFAppState().chatCreatedTimeSystem),
            ),
          );
          await AiChatsTable().update(
            data: {
              'conversation_id': getJsonField(
                (_model.apiResult1?.jsonBody ?? ''),
                r'''$.body.conversation_id''',
              ).toString(),
              'updated_at': supaSerialize<DateTime>(getCurrentTimestamp),
            },
            matchingRows: (rows) => rows.eqOrNull(
              'id',
              widget.chatRef,
            ),
          );
          safeSetState(() => _model.requestCompleter = null);
          await _model.waitForRequestCompleted();
        }
      }
    });

    _model.msgFieldTextController ??= TextEditingController();
    _model.msgFieldFocusNode ??= FocusNode();
    _model.msgFieldFocusNode!.addListener(() => safeSetState(() {}));
    animationsMap.addAll({
      'imageOnPageLoadAnimation': AnimationInfo(
        trigger: AnimationTrigger.onPageLoad,
        effectsBuilder: () => [
          MoveEffect(
            curve: Curves.easeInOut,
            delay: 0.0.ms,
            duration: 300.0.ms,
            begin: Offset(0.0, 100.0),
            end: Offset(0.0, 0.0),
          ),
          FadeEffect(
            curve: Curves.easeInOut,
            delay: 0.0.ms,
            duration: 300.0.ms,
            begin: 0.0,
            end: 1.0,
          ),
        ],
      ),
      'transformOnPageLoadAnimation': AnimationInfo(
        trigger: AnimationTrigger.onPageLoad,
        effectsBuilder: () => [
          RotateEffect(
            curve: Curves.easeInOut,
            delay: 100.0.ms,
            duration: 650.0.ms,
            begin: 0.65,
            end: 1.0,
          ),
          FadeEffect(
            curve: Curves.easeInOut,
            delay: 0.0.ms,
            duration: 250.0.ms,
            begin: 0.12,
            end: 1.0,
          ),
        ],
      ),
    });

    WidgetsBinding.instance.addPostFrameCallback((_) => safeSetState(() {}));
  }

  @override
  void dispose() {
    _model.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    context.watch<FFAppState>();

    return FutureBuilder<List<AiChatsRow>>(
      future: AiChatsTable().querySingleRow(
        queryFn: (q) => q.eqOrNull(
          'id',
          widget.chatRef,
        ),
      ),
      builder: (context, snapshot) {
        // Customize what your widget looks like when it's loading.
        if (!snapshot.hasData) {
          return Scaffold(
            backgroundColor: FlutterFlowTheme.of(context).info,
            body: Center(
              child: SizedBox(
                width: 50.0,
                height: 50.0,
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(
                    FlutterFlowTheme.of(context).primary,
                  ),
                ),
              ),
            ),
          );
        }
        List<AiChatsRow> chatPageAiChatsRowList = snapshot.data!;

        final chatPageAiChatsRow = chatPageAiChatsRowList.isNotEmpty
            ? chatPageAiChatsRowList.first
            : null;

        return GestureDetector(
          onTap: () {
            FocusScope.of(context).unfocus();
            FocusManager.instance.primaryFocus?.unfocus();
          },
          child: Scaffold(
            key: scaffoldKey,
            backgroundColor: FlutterFlowTheme.of(context).info,
            body: SafeArea(
              top: true,
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(),
                child: Stack(
                  children: [
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Align(
                          alignment: AlignmentDirectional(0.0, -1.0),
                          child: Padding(
                            padding: EdgeInsets.all(FlutterFlowTheme.of(context)
                                .designToken
                                .spacing
                                .sm),
                            child: Container(
                              width: double.infinity,
                              height: 40.0,
                              decoration: BoxDecoration(),
                              child: Row(
                                mainAxisSize: MainAxisSize.max,
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  InkWell(
                                    splashColor: Colors.transparent,
                                    focusColor: Colors.transparent,
                                    hoverColor: Colors.transparent,
                                    highlightColor: Colors.transparent,
                                    onTap: () async {
                                      context.safePop();
                                    },
                                    child: Container(
                                      width: 36.0,
                                      height: 36.0,
                                      decoration: BoxDecoration(
                                        color: Color(0xFFE8F0FE),
                                        borderRadius:
                                            BorderRadius.circular(10.0),
                                      ),
                                      child: Align(
                                        alignment:
                                            AlignmentDirectional(0.0, 0.0),
                                        child: Icon(
                                          Icons.chevron_left_rounded,
                                          color: Color(0xFF4A6CF7),
                                          size: 30.0,
                                        ),
                                      ),
                                    ),
                                  ),
                                  Icon(
                                    Icons.manage_accounts_rounded,
                                    color: Color(0xFF6C63FF),
                                    size: 24.0,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        Flexible(
                          child: Padding(
                            padding: EdgeInsetsDirectional.fromSTEB(
                                5.0, 0.0, 5.0, 5.0),
                            child: Container(
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: Color(0xFFFEFFFF),
                                borderRadius: BorderRadius.only(
                                  topLeft: Radius.circular(50.0),
                                  topRight: Radius.circular(50.0),
                                ),
                              ),
                              child: Stack(
                                children: [
                                  Column(
                                    mainAxisSize: MainAxisSize.max,
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Flexible(
                                        child: Stack(
                                          children: [
                                            Align(
                                              alignment: AlignmentDirectional(
                                                  0.0, -1.0),
                                              child: Padding(
                                                padding: EdgeInsetsDirectional
                                                    .fromSTEB(
                                                        0.0, 10.0, 0.0, 10.0),
                                                child: ListView(
                                                  padding: EdgeInsets.zero,
                                                  reverse: true,
                                                  shrinkWrap: true,
                                                  scrollDirection:
                                                      Axis.vertical,
                                                  children: [
                                                    FutureBuilder<
                                                        List<
                                                            AiChatMessagesRow>>(
                                                      future: (_model
                                                                  .requestCompleter ??=
                                                              Completer<
                                                                  List<
                                                                      AiChatMessagesRow>>()
                                                                ..complete(
                                                                    AiChatMessagesTable()
                                                                        .queryRows(
                                                                  queryFn: (q) => q
                                                                      .eqOrNull(
                                                                        'chat_ref',
                                                                        widget
                                                                            .chatRef,
                                                                      )
                                                                      .order('created_at'),
                                                                )))
                                                          .future,
                                                      builder:
                                                          (context, snapshot) {
                                                        // Customize what your widget looks like when it's loading.
                                                        if (!snapshot.hasData) {
                                                          return Center(
                                                            child: SizedBox(
                                                              width: 50.0,
                                                              height: 50.0,
                                                              child:
                                                                  CircularProgressIndicator(
                                                                valueColor:
                                                                    AlwaysStoppedAnimation<
                                                                        Color>(
                                                                  FlutterFlowTheme.of(
                                                                          context)
                                                                      .primary,
                                                                ),
                                                              ),
                                                            ),
                                                          );
                                                        }
                                                        List<AiChatMessagesRow>
                                                            listViewAiChatMessagesRowList =
                                                            snapshot.data!;

                                                        return ListView.builder(
                                                          padding:
                                                              EdgeInsets.zero,
                                                          reverse: true,
                                                          primary: false,
                                                          shrinkWrap: true,
                                                          scrollDirection:
                                                              Axis.vertical,
                                                          itemCount:
                                                              listViewAiChatMessagesRowList
                                                                  .length,
                                                          itemBuilder: (context,
                                                              listViewIndex) {
                                                            final listViewAiChatMessagesRow =
                                                                listViewAiChatMessagesRowList[
                                                                    listViewIndex];
                                                            return Padding(
                                                              padding:
                                                                  EdgeInsetsDirectional
                                                                      .fromSTEB(
                                                                          0.0,
                                                                          1.0,
                                                                          0.0,
                                                                          0.0),
                                                              child: Builder(
                                                                builder:
                                                                    (context) {
                                                                  if (listViewAiChatMessagesRow
                                                                          .role ==
                                                                      'user') {
                                                                    return Align(
                                                                      alignment:
                                                                          AlignmentDirectional(
                                                                              1.0,
                                                                              0.0),
                                                                      child:
                                                                          Padding(
                                                                        padding: EdgeInsetsDirectional.fromSTEB(
                                                                            5.0,
                                                                            0.0,
                                                                            5.0,
                                                                            1.0),
                                                                        child:
                                                                            Container(
                                                                          decoration:
                                                                              BoxDecoration(),
                                                                          child:
                                                                              Row(
                                                                            mainAxisSize:
                                                                                MainAxisSize.min,
                                                                            mainAxisAlignment:
                                                                                MainAxisAlignment.end,
                                                                            crossAxisAlignment:
                                                                                CrossAxisAlignment.end,
                                                                            children: [
                                                                              Column(
                                                                                mainAxisSize: MainAxisSize.max,
                                                                                mainAxisAlignment: MainAxisAlignment.end,
                                                                                crossAxisAlignment: CrossAxisAlignment.end,
                                                                                children: [
                                                                                  Padding(
                                                                                    padding: EdgeInsetsDirectional.fromSTEB(0.0, 0.0, 5.0, 5.0),
                                                                                    child: Text(
                                                                                      valueOrDefault<String>(
                                                                                        functions.parseDateFormatHM(listViewAiChatMessagesRow.createdAt),
                                                                                        '123',
                                                                                      ),
                                                                                      style: FlutterFlowTheme.of(context).bodyMedium.override(
                                                                                            font: GoogleFonts.interTight(
                                                                                              fontWeight: FlutterFlowTheme.of(context).bodyMedium.fontWeight,
                                                                                              fontStyle: FlutterFlowTheme.of(context).bodyMedium.fontStyle,
                                                                                            ),
                                                                                            color: FlutterFlowTheme.of(context).primaryBackground,
                                                                                            fontSize: 10.0,
                                                                                            letterSpacing: 0.0,
                                                                                            fontWeight: FlutterFlowTheme.of(context).bodyMedium.fontWeight,
                                                                                            fontStyle: FlutterFlowTheme.of(context).bodyMedium.fontStyle,
                                                                                          ),
                                                                                    ),
                                                                                  ),
                                                                                ],
                                                                              ),
                                                                              Column(
                                                                                mainAxisSize: MainAxisSize.min,
                                                                                crossAxisAlignment: CrossAxisAlignment.end,
                                                                                children: [
                                                                                  if (listViewAiChatMessagesRow.message != null && listViewAiChatMessagesRow.message != '')
                                                                                    Align(
                                                                                      alignment: AlignmentDirectional(1.0, 0.0),
                                                                                      child: Container(
                                                                                        constraints: BoxConstraints(
                                                                                          minWidth: 40.0,
                                                                                          minHeight: 40.0,
                                                                                          maxWidth: MediaQuery.sizeOf(context).width * 0.6,
                                                                                        ),
                                                                                        decoration: BoxDecoration(
                                                                                          color: FlutterFlowTheme.of(context).accent1,
                                                                                          borderRadius: BorderRadius.only(
                                                                                            topLeft: Radius.circular(20.0),
                                                                                            bottomLeft: Radius.circular(20.0),
                                                                                          ),
                                                                                          border: Border.all(
                                                                                            width: 1.0,
                                                                                          ),
                                                                                        ),
                                                                                        child: Column(
                                                                                          mainAxisSize: MainAxisSize.min,
                                                                                          mainAxisAlignment: MainAxisAlignment.center,
                                                                                          crossAxisAlignment: CrossAxisAlignment.center,
                                                                                          children: [
                                                                                            Padding(
                                                                                              padding: EdgeInsets.all(10.0),
                                                                                              child: Text(
                                                                                                valueOrDefault<String>(
                                                                                                  listViewAiChatMessagesRow.message,
                                                                                                  'ㄱㄴㄷ',
                                                                                                ),
                                                                                                style: FlutterFlowTheme.of(context).bodyMedium.override(
                                                                                                      font: GoogleFonts.interTight(
                                                                                                        fontWeight: FontWeight.w500,
                                                                                                        fontStyle: FlutterFlowTheme.of(context).bodyMedium.fontStyle,
                                                                                                      ),
                                                                                                      color: FlutterFlowTheme.of(context).secondaryBackground,
                                                                                                      fontSize: 12.0,
                                                                                                      letterSpacing: 0.0,
                                                                                                      fontWeight: FontWeight.w500,
                                                                                                      fontStyle: FlutterFlowTheme.of(context).bodyMedium.fontStyle,
                                                                                                    ),
                                                                                              ),
                                                                                            ),
                                                                                          ],
                                                                                        ),
                                                                                      ),
                                                                                    ),
                                                                                  if (listViewAiChatMessagesRow.imageUrls.isNotEmpty)
                                                                                    Padding(
                                                                                      padding: EdgeInsetsDirectional.fromSTEB(15.0, 10.0, 0.0, 15.0),
                                                                                      child: Container(
                                                                                        constraints: BoxConstraints(
                                                                                          maxWidth: 230.0,
                                                                                          maxHeight: 230.0,
                                                                                        ),
                                                                                        decoration: BoxDecoration(
                                                                                          borderRadius: BorderRadius.circular(3.0),
                                                                                          border: Border.all(
                                                                                            color: FlutterFlowTheme.of(context).primaryText,
                                                                                          ),
                                                                                        ),
                                                                                        child: SingleChildScrollView(
                                                                                          scrollDirection: Axis.horizontal,
                                                                                          child: Row(
                                                                                            mainAxisSize: MainAxisSize.max,
                                                                                            children: [
                                                                                              ClipRRect(
                                                                                                borderRadius: BorderRadius.circular(3.0),
                                                                                                child: Image.network(
                                                                                                  valueOrDefault<String>(
                                                                                                    listViewAiChatMessagesRow.imageUrls.firstOrNull,
                                                                                                    'https://i.pinimg.com/736x/85/cc/e9/85cce90402bfafcf8c1f58bef25615c6.jpg',
                                                                                                  ),
                                                                                                  fit: BoxFit.contain,
                                                                                                ),
                                                                                              ),
                                                                                            ],
                                                                                          ),
                                                                                        ),
                                                                                      ),
                                                                                    ),
                                                                                ],
                                                                              ),
                                                                            ],
                                                                          ),
                                                                        ),
                                                                      ),
                                                                    );
                                                                  } else {
                                                                    return Align(
                                                                      alignment:
                                                                          AlignmentDirectional(
                                                                              -1.0,
                                                                              0.0),
                                                                      child:
                                                                          Padding(
                                                                        padding: EdgeInsetsDirectional.fromSTEB(
                                                                            5.0,
                                                                            0.0,
                                                                            5.0,
                                                                            20.0),
                                                                        child:
                                                                            Container(
                                                                          decoration:
                                                                              BoxDecoration(),
                                                                          child:
                                                                              Column(
                                                                            mainAxisSize:
                                                                                MainAxisSize.max,
                                                                            crossAxisAlignment:
                                                                                CrossAxisAlignment.start,
                                                                            children: [
                                                                              Row(
                                                                                mainAxisSize: MainAxisSize.min,
                                                                                crossAxisAlignment: CrossAxisAlignment.end,
                                                                                children: [
                                                                                  Column(
                                                                                    mainAxisSize: MainAxisSize.min,
                                                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                                                    children: [
                                                                                      Row(
                                                                                        mainAxisSize: MainAxisSize.min,
                                                                                        crossAxisAlignment: CrossAxisAlignment.start,
                                                                                        children: [
                                                                                          Column(
                                                                                            mainAxisSize: MainAxisSize.max,
                                                                                            children: [
                                                                                              Container(
                                                                                                width: 36.0,
                                                                                                height: 36.0,
                                                                                                decoration: BoxDecoration(
                                                                                                  boxShadow: [
                                                                                                    BoxShadow(
                                                                                                      blurRadius: 3.0,
                                                                                                      color: Color(0x33000000),
                                                                                                      offset: Offset(
                                                                                                        0.0,
                                                                                                        1.0,
                                                                                                      ),
                                                                                                    )
                                                                                                  ],
                                                                                                  gradient: LinearGradient(
                                                                                                    colors: [
                                                                                                      Color(0xFFF6FAFF),
                                                                                                      Color(0xFF4285F4)
                                                                                                    ],
                                                                                                    stops: [0.85, 1.0],
                                                                                                    begin: AlignmentDirectional(-0.98, 1.0),
                                                                                                    end: AlignmentDirectional(0.98, -1.0),
                                                                                                  ),
                                                                                                  borderRadius: BorderRadius.only(
                                                                                                    topLeft: Radius.circular(20.0),
                                                                                                    topRight: Radius.circular(20.0),
                                                                                                    bottomLeft: Radius.circular(20.0),
                                                                                                    bottomRight: Radius.circular(20.0),
                                                                                                  ),
                                                                                                  border: Border.all(
                                                                                                    color: FlutterFlowTheme.of(context).alternate,
                                                                                                    width: 1.0,
                                                                                                  ),
                                                                                                ),
                                                                                                child: Container(
                                                                                                  width: MediaQuery.sizeOf(context).width * 1.0,
                                                                                                  height: MediaQuery.sizeOf(context).width * 1.0,
                                                                                                  clipBehavior: Clip.antiAlias,
                                                                                                  decoration: BoxDecoration(
                                                                                                    shape: BoxShape.circle,
                                                                                                  ),
                                                                                                  child: Image.network(
                                                                                                    'https://images.unsplash.com/photo-1527430253228-e93688616381?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w0NTYyMDF8MHwxfHNlYXJjaHwyfHxyb2JvdHxlbnwwfHx8fDE3NzYyNTU3ODl8MA&ixlib=rb-4.1.0&q=80&w=400',
                                                                                                    fit: BoxFit.cover,
                                                                                                  ),
                                                                                                ),
                                                                                              ),
                                                                                              Container(
                                                                                                width: 36.0,
                                                                                                height: 5.0,
                                                                                                decoration: BoxDecoration(
                                                                                                  color: Color(0x00FF0000),
                                                                                                  borderRadius: BorderRadius.only(
                                                                                                    topLeft: Radius.circular(20.0),
                                                                                                    topRight: Radius.circular(20.0),
                                                                                                    bottomLeft: Radius.circular(20.0),
                                                                                                    bottomRight: Radius.circular(20.0),
                                                                                                  ),
                                                                                                  border: Border.all(
                                                                                                    color: Color(0x00FF0000),
                                                                                                    width: 1.0,
                                                                                                  ),
                                                                                                ),
                                                                                              ),
                                                                                            ],
                                                                                          ),
                                                                                          Column(
                                                                                            mainAxisSize: MainAxisSize.max,
                                                                                            crossAxisAlignment: CrossAxisAlignment.start,
                                                                                            children: [
                                                                                              Padding(
                                                                                                padding: EdgeInsetsDirectional.fromSTEB(0.0, 3.0, 0.0, 3.0),
                                                                                                child: Text(
                                                                                                  'sciBot',
                                                                                                  style: FlutterFlowTheme.of(context).bodyMedium.override(
                                                                                                        font: GoogleFonts.notoSansJp(
                                                                                                          fontWeight: FontWeight.w500,
                                                                                                          fontStyle: FlutterFlowTheme.of(context).bodyMedium.fontStyle,
                                                                                                        ),
                                                                                                        color: Colors.black,
                                                                                                        fontSize: 12.0,
                                                                                                        letterSpacing: 0.0,
                                                                                                        fontWeight: FontWeight.w500,
                                                                                                        fontStyle: FlutterFlowTheme.of(context).bodyMedium.fontStyle,
                                                                                                      ),
                                                                                                ),
                                                                                              ),
                                                                                              Row(
                                                                                                mainAxisSize: MainAxisSize.max,
                                                                                                children: [
                                                                                                  if (listViewAiChatMessagesRow.message != null && listViewAiChatMessagesRow.message != '')
                                                                                                    Align(
                                                                                                      alignment: AlignmentDirectional(-1.0, 0.0),
                                                                                                      child: Padding(
                                                                                                        padding: EdgeInsetsDirectional.fromSTEB(0.0, 3.0, 0.0, 0.0),
                                                                                                        child: Container(
                                                                                                          constraints: BoxConstraints(
                                                                                                            minWidth: 40.0,
                                                                                                            minHeight: 40.0,
                                                                                                            maxWidth: MediaQuery.sizeOf(context).width * 0.7,
                                                                                                          ),
                                                                                                          decoration: BoxDecoration(
                                                                                                            color: Color(0xFFF2F6FF),
                                                                                                            borderRadius: BorderRadius.only(
                                                                                                              topRight: Radius.circular(20.0),
                                                                                                              bottomRight: Radius.circular(20.0),
                                                                                                            ),
                                                                                                            border: Border.all(
                                                                                                              width: 1.0,
                                                                                                            ),
                                                                                                          ),
                                                                                                          child: Column(
                                                                                                            mainAxisSize: MainAxisSize.min,
                                                                                                            mainAxisAlignment: MainAxisAlignment.center,
                                                                                                            crossAxisAlignment: CrossAxisAlignment.center,
                                                                                                            children: [
                                                                                                              Padding(
                                                                                                                padding: EdgeInsets.all(5.0),
                                                                                                                child: MarkdownBody(
                                                                                                                  data: valueOrDefault<String>(
                                                                                                                    listViewAiChatMessagesRow.message,
                                                                                                                    '123',
                                                                                                                  ),
                                                                                                                  selectable: true,
                                                                                                                  onTapLink: (_, url, __) => launchURL(url!),
                                                                                                                ),
                                                                                                              ),
                                                                                                            ],
                                                                                                          ),
                                                                                                        ),
                                                                                                      ),
                                                                                                    ),
                                                                                                  if (listViewAiChatMessagesRow.message == null || listViewAiChatMessagesRow.message == '')
                                                                                                    Padding(
                                                                                                      padding: EdgeInsetsDirectional.fromSTEB(0.0, 2.0, 0.0, 0.0),
                                                                                                      child: Container(
                                                                                                        width: 72.0,
                                                                                                        height: 36.0,
                                                                                                        decoration: BoxDecoration(
                                                                                                          color: FlutterFlowTheme.of(context).alternate,
                                                                                                          borderRadius: BorderRadius.only(
                                                                                                            topLeft: Radius.circular(20.0),
                                                                                                            topRight: Radius.circular(20.0),
                                                                                                            bottomLeft: Radius.circular(20.0),
                                                                                                            bottomRight: Radius.circular(20.0),
                                                                                                          ),
                                                                                                        ),
                                                                                                        child: Align(
                                                                                                          alignment: AlignmentDirectional(0.0, 0.0),
                                                                                                          child: Container(
                                                                                                            width: 68.0,
                                                                                                            height: 25.0,
                                                                                                            child: custom_widgets.TypingIndicator(
                                                                                                              width: 68.0,
                                                                                                              height: 25.0,
                                                                                                            ),
                                                                                                          ),
                                                                                                        ),
                                                                                                      ),
                                                                                                    ),
                                                                                                ],
                                                                                              ),
                                                                                              if (listViewAiChatMessagesRow.imageUrls.isNotEmpty)
                                                                                                Padding(
                                                                                                  padding: EdgeInsetsDirectional.fromSTEB(0.0, 3.0, 15.0, 15.0),
                                                                                                  child: Container(
                                                                                                    constraints: BoxConstraints(
                                                                                                      maxWidth: MediaQuery.sizeOf(context).width * 0.6,
                                                                                                      maxHeight: 230.0,
                                                                                                    ),
                                                                                                    decoration: BoxDecoration(
                                                                                                      borderRadius: BorderRadius.circular(3.0),
                                                                                                      border: Border.all(
                                                                                                        color: FlutterFlowTheme.of(context).primaryText,
                                                                                                      ),
                                                                                                    ),
                                                                                                    child: ClipRRect(
                                                                                                      borderRadius: BorderRadius.circular(3.0),
                                                                                                      child: Image.network(
                                                                                                        'https://i.pinimg.com/736x/85/cc/e9/85cce90402bfafcf8c1f58bef25615c6.jpg',
                                                                                                        fit: BoxFit.contain,
                                                                                                      ),
                                                                                                    ),
                                                                                                  ),
                                                                                                ),
                                                                                            ],
                                                                                          ),
                                                                                        ].divide(SizedBox(width: 10.0)),
                                                                                      ),
                                                                                    ].divide(SizedBox(height: 6.0)),
                                                                                  ),
                                                                                  Column(
                                                                                    mainAxisSize: MainAxisSize.max,
                                                                                    mainAxisAlignment: MainAxisAlignment.end,
                                                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                                                    children: [
                                                                                      Padding(
                                                                                        padding: EdgeInsetsDirectional.fromSTEB(5.0, 0.0, 0.0, 5.0),
                                                                                        child: Text(
                                                                                          valueOrDefault<String>(
                                                                                            functions.parseDateFormatHM(listViewAiChatMessagesRow.createdAt),
                                                                                            '123',
                                                                                          ),
                                                                                          style: FlutterFlowTheme.of(context).bodyMedium.override(
                                                                                                font: GoogleFonts.interTight(
                                                                                                  fontWeight: FlutterFlowTheme.of(context).bodyMedium.fontWeight,
                                                                                                  fontStyle: FlutterFlowTheme.of(context).bodyMedium.fontStyle,
                                                                                                ),
                                                                                                color: FlutterFlowTheme.of(context).primaryBackground,
                                                                                                fontSize: 10.0,
                                                                                                letterSpacing: 0.0,
                                                                                                fontWeight: FlutterFlowTheme.of(context).bodyMedium.fontWeight,
                                                                                                fontStyle: FlutterFlowTheme.of(context).bodyMedium.fontStyle,
                                                                                              ),
                                                                                        ),
                                                                                      ),
                                                                                    ],
                                                                                  ),
                                                                                ],
                                                                              ),
                                                                            ],
                                                                          ),
                                                                        ),
                                                                      ),
                                                                    );
                                                                  }
                                                                },
                                                              ),
                                                            );
                                                          },
                                                        );
                                                      },
                                                    ),
                                                    Row(
                                                      mainAxisSize:
                                                          MainAxisSize.min,
                                                      mainAxisAlignment:
                                                          MainAxisAlignment
                                                              .center,
                                                      children: [
                                                        Padding(
                                                          padding:
                                                              EdgeInsetsDirectional
                                                                  .fromSTEB(
                                                                      10.0,
                                                                      0.0,
                                                                      0.0,
                                                                      0.0),
                                                          child: Container(
                                                            width: MediaQuery
                                                                        .sizeOf(
                                                                            context)
                                                                    .width *
                                                                0.2,
                                                            height: MediaQuery
                                                                        .sizeOf(
                                                                            context)
                                                                    .height *
                                                                0.001,
                                                            decoration:
                                                                BoxDecoration(
                                                              color: FlutterFlowTheme
                                                                      .of(context)
                                                                  .secondaryBackground,
                                                              boxShadow: [
                                                                BoxShadow(
                                                                  blurRadius:
                                                                      3.0,
                                                                  color: Color(
                                                                      0x33000000),
                                                                  offset:
                                                                      Offset(
                                                                    0.0,
                                                                    1.0,
                                                                  ),
                                                                )
                                                              ],
                                                            ),
                                                          ),
                                                        ),
                                                        Padding(
                                                          padding:
                                                              EdgeInsetsDirectional
                                                                  .fromSTEB(
                                                                      10.0,
                                                                      0.0,
                                                                      0.0,
                                                                      0.0),
                                                          child: Icon(
                                                            Icons
                                                                .calendar_month_rounded,
                                                            color: FlutterFlowTheme
                                                                    .of(context)
                                                                .secondaryBackground,
                                                            size: 20.0,
                                                          ),
                                                        ),
                                                        Padding(
                                                          padding:
                                                              EdgeInsetsDirectional
                                                                  .fromSTEB(
                                                                      10.0,
                                                                      0.0,
                                                                      0.0,
                                                                      0.0),
                                                          child: Text(
                                                            valueOrDefault<
                                                                String>(
                                                              functions.parseDateFormatYM(
                                                                  chatPageAiChatsRow
                                                                      ?.createdAt),
                                                              '123',
                                                            ),
                                                            style: FlutterFlowTheme
                                                                    .of(context)
                                                                .bodyMedium
                                                                .override(
                                                                  font: GoogleFonts
                                                                      .notoSansKr(
                                                                    fontWeight: FlutterFlowTheme.of(
                                                                            context)
                                                                        .bodyMedium
                                                                        .fontWeight,
                                                                    fontStyle: FlutterFlowTheme.of(
                                                                            context)
                                                                        .bodyMedium
                                                                        .fontStyle,
                                                                  ),
                                                                  color: FlutterFlowTheme.of(
                                                                          context)
                                                                      .secondaryBackground,
                                                                  fontSize:
                                                                      12.0,
                                                                  letterSpacing:
                                                                      0.0,
                                                                  fontWeight: FlutterFlowTheme.of(
                                                                          context)
                                                                      .bodyMedium
                                                                      .fontWeight,
                                                                  fontStyle: FlutterFlowTheme.of(
                                                                          context)
                                                                      .bodyMedium
                                                                      .fontStyle,
                                                                ),
                                                          ),
                                                        ),
                                                        Padding(
                                                          padding:
                                                              EdgeInsetsDirectional
                                                                  .fromSTEB(
                                                                      10.0,
                                                                      0.0,
                                                                      0.0,
                                                                      0.0),
                                                          child: Container(
                                                            width: MediaQuery
                                                                        .sizeOf(
                                                                            context)
                                                                    .width *
                                                                0.2,
                                                            height: MediaQuery
                                                                        .sizeOf(
                                                                            context)
                                                                    .height *
                                                                0.001,
                                                            decoration:
                                                                BoxDecoration(
                                                              color: FlutterFlowTheme
                                                                      .of(context)
                                                                  .secondaryBackground,
                                                              boxShadow: [
                                                                BoxShadow(
                                                                  blurRadius:
                                                                      3.0,
                                                                  color: Color(
                                                                      0x33000000),
                                                                  offset:
                                                                      Offset(
                                                                    0.0,
                                                                    1.0,
                                                                  ),
                                                                )
                                                              ],
                                                            ),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ].divide(
                                                      SizedBox(height: 10.0)),
                                                ),
                                              ),
                                            ),
                                            if (_model.imageToggle)
                                              Align(
                                                alignment: AlignmentDirectional(
                                                    0.0, 1.0),
                                                child: Container(
                                                  height:
                                                      MediaQuery.sizeOf(context)
                                                              .height *
                                                          0.2,
                                                  decoration: BoxDecoration(
                                                    color: FlutterFlowTheme.of(
                                                            context)
                                                        .secondaryText,
                                                    borderRadius:
                                                        BorderRadius.only(
                                                      topLeft:
                                                          Radius.circular(20.0),
                                                      topRight:
                                                          Radius.circular(20.0),
                                                    ),
                                                    border: Border.all(
                                                      color:
                                                          FlutterFlowTheme.of(
                                                                  context)
                                                              .accent1,
                                                      width: 1.0,
                                                    ),
                                                  ),
                                                  child: Column(
                                                    mainAxisSize:
                                                        MainAxisSize.max,
                                                    children: [
                                                      Flexible(
                                                        child: Stack(
                                                          children: [
                                                            Align(
                                                              alignment:
                                                                  AlignmentDirectional(
                                                                      0.0, 0.0),
                                                              child: Container(
                                                                decoration:
                                                                    BoxDecoration(),
                                                                child: Padding(
                                                                  padding:
                                                                      EdgeInsets
                                                                          .all(
                                                                              3.0),
                                                                  child:
                                                                      ClipRRect(
                                                                    borderRadius:
                                                                        BorderRadius.circular(
                                                                            3.0),
                                                                    child: Image
                                                                        .network(
                                                                      valueOrDefault<
                                                                          String>(
                                                                        _model
                                                                            .uploadedFileUrl_uploadDataUa6,
                                                                        'https://images.saymedia-content.com/.image/t_share/MTk2NTgzMjA1NDIyMjQ1Njk0/five-best-small-white-dog-breeds.jpg',
                                                                      ),
                                                                      fit: BoxFit
                                                                          .contain,
                                                                    ),
                                                                  ).animateOnPageLoad(
                                                                          animationsMap[
                                                                              'imageOnPageLoadAnimation']!),
                                                                ),
                                                              ),
                                                            ),
                                                            Align(
                                                              alignment:
                                                                  AlignmentDirectional(
                                                                      1.0,
                                                                      -1.0),
                                                              child: Padding(
                                                                padding:
                                                                    EdgeInsetsDirectional
                                                                        .fromSTEB(
                                                                            0.0,
                                                                            5.0,
                                                                            5.0,
                                                                            0.0),
                                                                child: InkWell(
                                                                  splashColor:
                                                                      Colors
                                                                          .transparent,
                                                                  focusColor: Colors
                                                                      .transparent,
                                                                  hoverColor: Colors
                                                                      .transparent,
                                                                  highlightColor:
                                                                      Colors
                                                                          .transparent,
                                                                  onTap:
                                                                      () async {
                                                                    _model.imageUploaded =
                                                                        [];
                                                                    _model.imageUrls =
                                                                        [];
                                                                    _model.imageToggle =
                                                                        false;
                                                                    safeSetState(
                                                                        () {});
                                                                  },
                                                                  child:
                                                                      Container(
                                                                    decoration:
                                                                        BoxDecoration(
                                                                      color: Color(
                                                                          0xFFEA4335),
                                                                      shape: BoxShape
                                                                          .circle,
                                                                    ),
                                                                    child:
                                                                        Padding(
                                                                      padding:
                                                                          EdgeInsets.all(
                                                                              10.0),
                                                                      child:
                                                                          FaIcon(
                                                                        FontAwesomeIcons
                                                                            .trashAlt,
                                                                        color: Colors
                                                                            .white,
                                                                        size:
                                                                            16.0,
                                                                      ),
                                                                    ),
                                                                  ),
                                                                ),
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                      Align(
                                        alignment:
                                            AlignmentDirectional(0.0, 0.0),
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          mainAxisAlignment:
                                              MainAxisAlignment.end,
                                          children: [
                                            Container(
                                              decoration: BoxDecoration(),
                                              child: Column(
                                                mainAxisSize: MainAxisSize.min,
                                                mainAxisAlignment:
                                                    MainAxisAlignment.start,
                                                children: [
                                                  Container(
                                                    width: double.infinity,
                                                    decoration: BoxDecoration(
                                                      color:
                                                          FlutterFlowTheme.of(
                                                                  context)
                                                              .info,
                                                    ),
                                                    child: Padding(
                                                      padding:
                                                          EdgeInsetsDirectional
                                                              .fromSTEB(
                                                                  0.0,
                                                                  5.0,
                                                                  0.0,
                                                                  5.0),
                                                      child: Row(
                                                        mainAxisSize:
                                                            MainAxisSize.min,
                                                        mainAxisAlignment:
                                                            MainAxisAlignment
                                                                .spaceBetween,
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .center,
                                                        children: [
                                                          Align(
                                                            alignment:
                                                                AlignmentDirectional(
                                                                    0.0, 0.0),
                                                            child: Padding(
                                                              padding:
                                                                  EdgeInsetsDirectional
                                                                      .fromSTEB(
                                                                          0.0,
                                                                          0.0,
                                                                          3.0,
                                                                          0.0),
                                                              child: InkWell(
                                                                splashColor: Colors
                                                                    .transparent,
                                                                focusColor: Colors
                                                                    .transparent,
                                                                hoverColor: Colors
                                                                    .transparent,
                                                                highlightColor:
                                                                    Colors
                                                                        .transparent,
                                                                onTap:
                                                                    () async {
                                                                  final selectedMedia =
                                                                      await selectMediaWithSourceBottomSheet(
                                                                    context:
                                                                        context,
                                                                    storageFolderPath:
                                                                        'chatImages',
                                                                    maxWidth:
                                                                        1080.00,
                                                                    maxHeight:
                                                                        1080.00,
                                                                    imageQuality:
                                                                        80,
                                                                    allowPhoto:
                                                                        true,
                                                                  );
                                                                  if (selectedMedia !=
                                                                          null &&
                                                                      selectedMedia.every((m) => validateFileFormat(
                                                                          m.storagePath,
                                                                          context))) {
                                                                    safeSetState(() =>
                                                                        _model.isDataUploading_uploadDataUa6 =
                                                                            true);
                                                                    var selectedUploadedFiles =
                                                                        <FFUploadedFile>[];

                                                                    var downloadUrls =
                                                                        <String>[];
                                                                    try {
                                                                      selectedUploadedFiles = selectedMedia
                                                                          .map((m) => FFUploadedFile(
                                                                                name: m.storagePath.split('/').last,
                                                                                bytes: m.bytes,
                                                                                height: m.dimensions?.height,
                                                                                width: m.dimensions?.width,
                                                                                blurHash: m.blurHash,
                                                                                originalFilename: m.originalFilename,
                                                                              ))
                                                                          .toList();

                                                                      downloadUrls =
                                                                          await uploadSupabaseStorageFiles(
                                                                        bucketName:
                                                                            'images',
                                                                        selectedFiles:
                                                                            selectedMedia,
                                                                      );
                                                                    } finally {
                                                                      _model.isDataUploading_uploadDataUa6 =
                                                                          false;
                                                                    }
                                                                    if (selectedUploadedFiles.length ==
                                                                            selectedMedia
                                                                                .length &&
                                                                        downloadUrls.length ==
                                                                            selectedMedia.length) {
                                                                      safeSetState(
                                                                          () {
                                                                        _model.uploadedLocalFile_uploadDataUa6 =
                                                                            selectedUploadedFiles.first;
                                                                        _model.uploadedFileUrl_uploadDataUa6 =
                                                                            downloadUrls.first;
                                                                      });
                                                                    } else {
                                                                      safeSetState(
                                                                          () {});
                                                                      return;
                                                                    }
                                                                  }

                                                                  if (_model.uploadedFileUrl_uploadDataUa6 !=
                                                                          '') {
                                                                    _model.addToImageUrls(
                                                                        _model
                                                                            .uploadedFileUrl_uploadDataUa6);
                                                                    _model.imageToggle =
                                                                        true;
                                                                    safeSetState(
                                                                        () {});
                                                                  }
                                                                },
                                                                child:
                                                                    Container(
                                                                  width: 40.0,
                                                                  height: 40.0,
                                                                  decoration:
                                                                      BoxDecoration(
                                                                    color: FlutterFlowTheme.of(
                                                                            context)
                                                                        .primaryText,
                                                                    boxShadow: [
                                                                      BoxShadow(
                                                                        blurRadius:
                                                                            4.0,
                                                                        color: Color(
                                                                            0x33000000),
                                                                        offset:
                                                                            Offset(
                                                                          0.0,
                                                                          2.0,
                                                                        ),
                                                                      )
                                                                    ],
                                                                    borderRadius:
                                                                        BorderRadius.circular(
                                                                            10.0),
                                                                    shape: BoxShape
                                                                        .rectangle,
                                                                    border:
                                                                        Border
                                                                            .all(
                                                                      width:
                                                                          0.5,
                                                                    ),
                                                                  ),
                                                                  child: Align(
                                                                    alignment:
                                                                        AlignmentDirectional(
                                                                            0.0,
                                                                            0.0),
                                                                    child: Icon(
                                                                      Icons
                                                                          .image_search_rounded,
                                                                      color: FlutterFlowTheme.of(
                                                                              context)
                                                                          .primaryBackground,
                                                                      size:
                                                                          24.0,
                                                                    ),
                                                                  ),
                                                                ),
                                                              ),
                                                            ),
                                                          ),
                                                          Flexible(
                                                            flex: 1,
                                                            child: Align(
                                                              alignment:
                                                                  AlignmentDirectional(
                                                                      0.0, 0.0),
                                                              child: Container(
                                                                constraints:
                                                                    BoxConstraints(
                                                                  minHeight:
                                                                      40.0,
                                                                ),
                                                                decoration:
                                                                    BoxDecoration(
                                                                  borderRadius:
                                                                      BorderRadius
                                                                          .only(),
                                                                ),
                                                                child: Align(
                                                                  alignment:
                                                                      AlignmentDirectional(
                                                                          0.0,
                                                                          0.0),
                                                                  child:
                                                                      Container(
                                                                    width: double
                                                                        .infinity,
                                                                    child:
                                                                        TextFormField(
                                                                      controller:
                                                                          _model
                                                                              .msgFieldTextController,
                                                                      focusNode:
                                                                          _model
                                                                              .msgFieldFocusNode,
                                                                      onChanged:
                                                                          (_) =>
                                                                              EasyDebounce.debounce(
                                                                        '_model.msgFieldTextController',
                                                                        Duration(
                                                                            milliseconds:
                                                                                200),
                                                                        () => safeSetState(
                                                                            () {}),
                                                                      ),
                                                                      autofocus:
                                                                          false,
                                                                      enabled:
                                                                          true,
                                                                      obscureText:
                                                                          false,
                                                                      decoration:
                                                                          InputDecoration(
                                                                        isDense:
                                                                            false,
                                                                        hintText:
                                                                            '메세지를 입력하세요',
                                                                        hintStyle: FlutterFlowTheme.of(context)
                                                                            .labelLarge
                                                                            .override(
                                                                              font: GoogleFonts.notoSansKr(
                                                                                fontWeight: FontWeight.normal,
                                                                                fontStyle: FlutterFlowTheme.of(context).labelLarge.fontStyle,
                                                                              ),
                                                                              color: FlutterFlowTheme.of(context).secondaryText,
                                                                              fontSize: 13.0,
                                                                              letterSpacing: 0.0,
                                                                              fontWeight: FontWeight.normal,
                                                                              fontStyle: FlutterFlowTheme.of(context).labelLarge.fontStyle,
                                                                            ),
                                                                        enabledBorder:
                                                                            OutlineInputBorder(
                                                                          borderSide:
                                                                              BorderSide(
                                                                            color:
                                                                                Color(0xFFE5E7EB),
                                                                            width:
                                                                                1.0,
                                                                          ),
                                                                          borderRadius:
                                                                              const BorderRadius.only(
                                                                            topLeft:
                                                                                Radius.circular(4.0),
                                                                            topRight:
                                                                                Radius.circular(4.0),
                                                                          ),
                                                                        ),
                                                                        focusedBorder:
                                                                            OutlineInputBorder(
                                                                          borderSide:
                                                                              BorderSide(
                                                                            color:
                                                                                Color(0xFF4285F4),
                                                                            width:
                                                                                1.0,
                                                                          ),
                                                                          borderRadius:
                                                                              const BorderRadius.only(
                                                                            topLeft:
                                                                                Radius.circular(4.0),
                                                                            topRight:
                                                                                Radius.circular(4.0),
                                                                          ),
                                                                        ),
                                                                        errorBorder:
                                                                            OutlineInputBorder(
                                                                          borderSide:
                                                                              BorderSide(
                                                                            color:
                                                                                Color(0xFFEA4335),
                                                                            width:
                                                                                1.0,
                                                                          ),
                                                                          borderRadius:
                                                                              const BorderRadius.only(
                                                                            topLeft:
                                                                                Radius.circular(4.0),
                                                                            topRight:
                                                                                Radius.circular(4.0),
                                                                          ),
                                                                        ),
                                                                        focusedErrorBorder:
                                                                            OutlineInputBorder(
                                                                          borderSide:
                                                                              BorderSide(
                                                                            color:
                                                                                Color(0xFFEA4335),
                                                                            width:
                                                                                1.0,
                                                                          ),
                                                                          borderRadius:
                                                                              const BorderRadius.only(
                                                                            topLeft:
                                                                                Radius.circular(4.0),
                                                                            topRight:
                                                                                Radius.circular(4.0),
                                                                          ),
                                                                        ),
                                                                        filled:
                                                                            true,
                                                                        fillColor:
                                                                            Color(0xFFF9FAFB),
                                                                        contentPadding: EdgeInsetsDirectional.fromSTEB(
                                                                            15.0,
                                                                            10.0,
                                                                            10.0,
                                                                            10.0),
                                                                        suffixIcon: _model.msgFieldTextController!.text.isNotEmpty
                                                                            ? InkWell(
                                                                                onTap: () async {
                                                                                  _model.msgFieldTextController?.clear();
                                                                                  safeSetState(() {});
                                                                                },
                                                                                child: Icon(
                                                                                  Icons.clear,
                                                                                  color: Color(0xFF4285F4),
                                                                                  size: 10.0,
                                                                                ),
                                                                              )
                                                                            : null,
                                                                      ),
                                                                      style: FlutterFlowTheme.of(
                                                                              context)
                                                                          .bodyLarge
                                                                          .override(
                                                                            font:
                                                                                GoogleFonts.notoSansKr(
                                                                              fontWeight: FlutterFlowTheme.of(context).bodyLarge.fontWeight,
                                                                              fontStyle: FlutterFlowTheme.of(context).bodyLarge.fontStyle,
                                                                            ),
                                                                            color:
                                                                                Colors.black,
                                                                            fontSize:
                                                                                13.0,
                                                                            letterSpacing:
                                                                                0.0,
                                                                            fontWeight:
                                                                                FlutterFlowTheme.of(context).bodyLarge.fontWeight,
                                                                            fontStyle:
                                                                                FlutterFlowTheme.of(context).bodyLarge.fontStyle,
                                                                          ),
                                                                      textAlign:
                                                                          TextAlign
                                                                              .start,
                                                                      maxLines:
                                                                          7,
                                                                      minLines:
                                                                          1,
                                                                      maxLength:
                                                                          3000,
                                                                      maxLengthEnforcement:
                                                                          MaxLengthEnforcement
                                                                              .enforced,
                                                                      buildCounter: (context,
                                                                              {required currentLength,
                                                                              required isFocused,
                                                                              maxLength}) =>
                                                                          null,
                                                                      cursorColor:
                                                                          FlutterFlowTheme.of(context)
                                                                              .primaryText,
                                                                      enableInteractiveSelection:
                                                                          true,
                                                                      validator: _model
                                                                          .msgFieldTextControllerValidator
                                                                          .asValidator(
                                                                              context),
                                                                    ),
                                                                  ),
                                                                ),
                                                              ),
                                                            ),
                                                          ),
                                                          Padding(
                                                            padding:
                                                                EdgeInsetsDirectional
                                                                    .fromSTEB(
                                                                        3.0,
                                                                        0.0,
                                                                        0.0,
                                                                        0.0),
                                                            child: Container(
                                                              width: 40.0,
                                                              height: 40.0,
                                                              decoration:
                                                                  BoxDecoration(
                                                                color: FlutterFlowTheme.of(
                                                                        context)
                                                                    .secondaryBackground,
                                                                boxShadow: [
                                                                  BoxShadow(
                                                                    blurRadius:
                                                                        3.0,
                                                                    color: Color(
                                                                        0x33000000),
                                                                    offset:
                                                                        Offset(
                                                                      0.0,
                                                                      1.0,
                                                                    ),
                                                                  )
                                                                ],
                                                                borderRadius:
                                                                    BorderRadius
                                                                        .circular(
                                                                            10.0),
                                                                shape: BoxShape
                                                                    .rectangle,
                                                              ),
                                                              child: Stack(
                                                                children: [
                                                                  if (_model.msgFieldTextController
                                                                              .text ==
                                                                          '')
                                                                    Container(
                                                                      width:
                                                                          40.0,
                                                                      height:
                                                                          40.0,
                                                                      decoration:
                                                                          BoxDecoration(
                                                                        color: FlutterFlowTheme.of(context)
                                                                            .secondaryText,
                                                                        boxShadow: [
                                                                          BoxShadow(
                                                                            blurRadius:
                                                                                3.0,
                                                                            color:
                                                                                Color(0x33000000),
                                                                            offset:
                                                                                Offset(
                                                                              0.0,
                                                                              1.0,
                                                                            ),
                                                                          )
                                                                        ],
                                                                        borderRadius:
                                                                            BorderRadius.circular(10.0),
                                                                        shape: BoxShape
                                                                            .rectangle,
                                                                      ),
                                                                      alignment:
                                                                          AlignmentDirectional(
                                                                              0.0,
                                                                              1.0),
                                                                      child:
                                                                          Align(
                                                                        alignment: AlignmentDirectional(
                                                                            0.0,
                                                                            0.0),
                                                                        child: Transform
                                                                            .rotate(
                                                                          angle:
                                                                              325.0 * (math.pi / 180),
                                                                          child:
                                                                              Padding(
                                                                            padding: EdgeInsetsDirectional.fromSTEB(
                                                                                5.0,
                                                                                0.0,
                                                                                0.0,
                                                                                0.0),
                                                                            child:
                                                                                Icon(
                                                                              Icons.send_rounded,
                                                                              color: FlutterFlowTheme.of(context).primaryText,
                                                                              size: 24.0,
                                                                            ),
                                                                          ),
                                                                        ),
                                                                      ),
                                                                    ),
                                                                  if (_model.msgFieldTextController
                                                                              .text !=
                                                                          '')
                                                                    Align(
                                                                      alignment:
                                                                          AlignmentDirectional(
                                                                              0.0,
                                                                              0.0),
                                                                      child:
                                                                          InkWell(
                                                                        splashColor:
                                                                            Colors.transparent,
                                                                        focusColor:
                                                                            Colors.transparent,
                                                                        hoverColor:
                                                                            Colors.transparent,
                                                                        highlightColor:
                                                                            Colors.transparent,
                                                                        onTap:
                                                                            () async {
                                                                          _model.tempText = _model
                                                                              .msgFieldTextController
                                                                              .text;
                                                                          _model.imageToggle =
                                                                              false;
                                                                          safeSetState(
                                                                              () {});
                                                                          safeSetState(
                                                                              () {
                                                                            _model.msgFieldTextController?.clear();
                                                                          });
                                                                          FFAppState().chatCreatedTimeUser =
                                                                              getCurrentTimestamp;
                                                                          safeSetState(
                                                                              () {});
                                                                          await AiChatMessagesTable()
                                                                              .insert({
                                                                            'chat_ref':
                                                                                widget.chatRef,
                                                                            'role':
                                                                                'user',
                                                                            'message':
                                                                                _model.tempText,
                                                                            'image_urls':
                                                                                _model.imageUrls,
                                                                            'created_at':
                                                                                supaSerialize<DateTime>(FFAppState().chatCreatedTimeUser),
                                                                          });
                                                                          safeSetState(() =>
                                                                              _model.requestCompleter = null);
                                                                          await _model
                                                                              .waitForRequestCompleted();
                                                                          await Future
                                                                              .delayed(
                                                                            Duration(
                                                                              milliseconds: 200,
                                                                            ),
                                                                          );
                                                                          FFAppState().chatCreatedTimeSystem =
                                                                              getCurrentTimestamp;
                                                                          safeSetState(
                                                                              () {});
                                                                          _model.createMessagesSystem2 =
                                                                              await AiChatMessagesTable().insert({
                                                                            'chat_ref':
                                                                                widget.chatRef,
                                                                            'role':
                                                                                'system',
                                                                            'created_at':
                                                                                supaSerialize<DateTime>(FFAppState().chatCreatedTimeSystem),
                                                                          });
                                                                          safeSetState(() =>
                                                                              _model.requestCompleter = null);
                                                                          await _model
                                                                              .waitForRequestCompleted();
                                                                          _model.apiResult2 =
                                                                              await AskSciBotCall.call(
                                                                            question:
                                                                                _model.tempText,
                                                                            conversationId:
                                                                                chatPageAiChatsRow?.conversationId,
                                                                            imageUrlsList: _model.imageUrls.isNotEmpty
                                                                                ? _model.imageUrls
                                                                                : [],
                                                                          );

                                                                          if ((_model.apiResult2?.succeeded ??
                                                                              true)) {
                                                                            await AiChatMessagesTable().update(
                                                                              data: {
                                                                                'message': getJsonField(
                                                                                  (_model.apiResult2?.jsonBody ?? ''),
                                                                                  r'''$.body.answer''',
                                                                                ).toString(),
                                                                                'created_at': supaSerialize<DateTime>(getCurrentTimestamp),
                                                                              },
                                                                              matchingRows: (rows) => rows.eqOrNull(
                                                                                'created_at',
                                                                                supaSerialize<DateTime>(FFAppState().chatCreatedTimeSystem),
                                                                              ),
                                                                            );
                                                                            await AiChatsTable().update(
                                                                              data: {
                                                                                'conversation_id': getJsonField(
                                                                                  (_model.apiResult2?.jsonBody ?? ''),
                                                                                  r'''$.body.conversation_id''',
                                                                                ).toString(),
                                                                                'last_message': _model.tempText,
                                                                                'updated_at': supaSerialize<DateTime>(getCurrentTimestamp),
                                                                              },
                                                                              matchingRows: (rows) => rows.eqOrNull(
                                                                                'id',
                                                                                chatPageAiChatsRow?.id,
                                                                              ),
                                                                            );
                                                                            safeSetState(() =>
                                                                                _model.requestCompleter = null);
                                                                            await _model.waitForRequestCompleted();
                                                                          }
                                                                          safeSetState(
                                                                              () {
                                                                            _model.isDataUploading_uploadDataUa6 =
                                                                                false;
                                                                            _model.uploadedLocalFile_uploadDataUa6 =
                                                                                FFUploadedFile(bytes: Uint8List.fromList([]), originalFilename: '');
                                                                            _model.uploadedFileUrl_uploadDataUa6 =
                                                                                '';
                                                                          });

                                                                          _model.tempText =
                                                                              null;
                                                                          _model.imageUrls =
                                                                              [];
                                                                          _model.imageUploaded =
                                                                              [];
                                                                          safeSetState(
                                                                              () {});

                                                                          safeSetState(
                                                                              () {});
                                                                        },
                                                                        child:
                                                                            Container(
                                                                          width:
                                                                              40.0,
                                                                          height:
                                                                              40.0,
                                                                          decoration:
                                                                              BoxDecoration(
                                                                            color:
                                                                                FlutterFlowTheme.of(context).primaryText,
                                                                            boxShadow: [
                                                                              BoxShadow(
                                                                                blurRadius: 12.0,
                                                                                color: Color(0x33000000),
                                                                                offset: Offset(
                                                                                  0.0,
                                                                                  5.0,
                                                                                ),
                                                                              )
                                                                            ],
                                                                            borderRadius:
                                                                                BorderRadius.circular(10.0),
                                                                            shape:
                                                                                BoxShape.rectangle,
                                                                            border:
                                                                                Border.all(
                                                                              width: 0.5,
                                                                            ),
                                                                          ),
                                                                          alignment: AlignmentDirectional(
                                                                              0.0,
                                                                              1.0),
                                                                          child:
                                                                              Align(
                                                                            alignment:
                                                                                AlignmentDirectional(0.0, 0.0),
                                                                            child:
                                                                                Transform.rotate(
                                                                              angle: 325.0 * (math.pi / 180),
                                                                              child: Padding(
                                                                                padding: EdgeInsetsDirectional.fromSTEB(5.0, 0.0, 0.0, 0.0),
                                                                                child: Icon(
                                                                                  Icons.send_rounded,
                                                                                  color: FlutterFlowTheme.of(context).primaryBackground,
                                                                                  size: 24.0,
                                                                                ),
                                                                              ),
                                                                            ).animateOnPageLoad(animationsMap['transformOnPageLoadAnimation']!),
                                                                          ),
                                                                        ),
                                                                      ),
                                                                    ),
                                                                ],
                                                              ),
                                                            ),
                                                          ),
                                                        ]
                                                            .divide(SizedBox(
                                                                width: 3.0))
                                                            .addToStart(
                                                                SizedBox(
                                                                    width: 5.0))
                                                            .addToEnd(SizedBox(
                                                                width: 5.0)),
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
