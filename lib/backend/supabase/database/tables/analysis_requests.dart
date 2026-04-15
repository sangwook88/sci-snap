import '../database.dart';

class AnalysisRequestsTable extends SupabaseTable<AnalysisRequestsRow> {
  @override
  String get tableName => 'analysis_requests';

  @override
  AnalysisRequestsRow createRow(Map<String, dynamic> data) =>
      AnalysisRequestsRow(data);
}

class AnalysisRequestsRow extends SupabaseDataRow {
  AnalysisRequestsRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => AnalysisRequestsTable();

  String? get id => getField<String>('id');
  set id(String? value) => setField<String>('id', value);

  String? get userId => getField<String>('user_id');
  set userId(String? value) => setField<String>('user_id', value);

  String get question => getField<String>('question')!;
  set question(String value) => setField<String>('question', value);

  dynamic get imageUrls => getField<dynamic>('image_urls');
  set imageUrls(dynamic value) => setField<dynamic>('image_urls', value);

  String? get answer => getField<String>('answer');
  set answer(String? value) => setField<String>('answer', value);

  DateTime? get createdAt => getField<DateTime>('created_at');
  set createdAt(DateTime? value) => setField<DateTime>('created_at', value);

  String? get conversationId => getField<String>('conversation_id');
  set conversationId(String? value) =>
      setField<String>('conversation_id', value);
}
