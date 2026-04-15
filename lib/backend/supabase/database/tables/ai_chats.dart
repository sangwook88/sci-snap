import '../database.dart';

class AiChatsTable extends SupabaseTable<AiChatsRow> {
  @override
  String get tableName => 'aiChats';

  @override
  AiChatsRow createRow(Map<String, dynamic> data) => AiChatsRow(data);
}

class AiChatsRow extends SupabaseDataRow {
  AiChatsRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => AiChatsTable();

  String? get id => getField<String>('id');
  set id(String? value) => setField<String>('id', value);

  String? get uid => getField<String>('uid');
  set uid(String? value) => setField<String>('uid', value);

  String? get conversationId => getField<String>('conversation_id');
  set conversationId(String? value) =>
      setField<String>('conversation_id', value);

  String? get lastMessage => getField<String>('last_message');
  set lastMessage(String? value) => setField<String>('last_message', value);

  DateTime? get createdAt => getField<DateTime>('created_at');
  set createdAt(DateTime? value) => setField<DateTime>('created_at', value);

  DateTime? get updatedAt => getField<DateTime>('updated_at');
  set updatedAt(DateTime? value) => setField<DateTime>('updated_at', value);
}
