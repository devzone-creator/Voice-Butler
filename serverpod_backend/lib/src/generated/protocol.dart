import 'package:serverpod/serverpod.dart';
import 'package:serverpod/src/generated/database/table_definition.dart';

class Protocol extends SerializationManagerServer {
  Protocol._();

  factory Protocol() => _instance;

  static final Protocol _instance = Protocol._();

  @override
  void initializeSerializers() {
    // Initialize serializers here when needed
  }

  @override
  String getModuleName() {
    return 'voice_butler';
  }

  @override
  Table? getTableForType(Type t) {
    // Return null for now - no database tables defined yet
    return null;
  }

  @override
  List<TableDefinition> getTargetTableDefinitions() {
    // Return empty list for now - no database tables defined yet
    return <TableDefinition>[];
  }
}