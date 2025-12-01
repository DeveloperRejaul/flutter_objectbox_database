import 'package:objectbox/objectbox.dart';

@Entity()
class ShopOrder {
  int id;
  int price;

  final coustomer = ToOne<Coustomer>();

  ShopOrder({this.id = 0, required this.price});
}

@Entity()
class Coustomer {
  int id;
  String name;

  @Backlink()
  final orders = ToMany<ShopOrder>();

  Coustomer({this.id = 0, required this.name});
}
