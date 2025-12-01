import 'package:flutter_objectbox_database/db/entities.dart';
import 'package:flutter_objectbox_database/objectbox.g.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart';

late Store _store;
final shopBox = _store.box<ShopOrder>();
final customerBox = _store.box<Coustomer>();

Future<void> initObjectBox() async {
  final dir = await getApplicationDocumentsDirectory();
  _store = Store(getObjectBoxModel(), directory: join(dir.path, 'objectbox'));
}

Future<void> closeObjectBox() async {
  _store.close();
}
