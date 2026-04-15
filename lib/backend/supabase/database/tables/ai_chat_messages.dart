import '../database.dart';

class AiChatMessagesTable extends SupabaseTable<AiChatMessagesRow> {
  @override
  String get tableName => 'aiChat_messages';

  @override
  AiChatMessagesRow createRow(Map<String, dynamic> data) =>
      AiChatMessagesRow(data);
}

class AiChatMessagesRow extends SupabaseDataRow {
  AiChatMessagesRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => AiChatMessagesTable();

  String? get id => getField<String>('id');
  set id(String? value) => setField<String>('id', value);

  String get chatRef => getField<String>('chat_ref')!;
  set chatRef(String value) => setField<String>('chat_ref', value);

  String? get role => getField<String>('role');
  set role(String? value) => setField<String>('role', value);

  String? get message => getField<String>('message');
  set message(String? value) => setField<String>('message', value);

  List<String> get imageUrls => getListField<String>('image_urls');
  set imageUrls(List<String>? value) =>
      setListField<String>('image_urls', value);

  DateTime? get createdAt => getField<DateTime>('created_at');
  set createdAt(DateTime? value) => setField<DateTime>('created_at', value);
}
