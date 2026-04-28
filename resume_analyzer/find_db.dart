import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart';

void main() async {
  final dbPath = await getApplicationDocumentsDirectory();
  final path = join(dbPath.path, 'resume_analyzer.db');
  print('DATABASE PATH: $path');
}
