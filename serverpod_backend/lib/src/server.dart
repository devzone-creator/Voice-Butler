import 'package:serverpod/serverpod.dart';
import 'generated/endpoints.dart';
import 'generated/protocol.dart';

/// Voice Butler Serverpod server configuration
void run(List<String> args) async {
  print('Starting Voice Butler Serverpod server...');
  
  final pod = Serverpod(
    args,
    Protocol(),
    Endpoints(),
  );

  print('Server configuration complete, starting...');
  await pod.start();
  print('Server started successfully!');
}