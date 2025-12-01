import 'package:flutter/material.dart';
import 'package:flutter_objectbox_database/db/entities.dart';
import 'package:flutter_objectbox_database/db/init.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initObjectBox();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(colorScheme: .fromSeed(seedColor: Colors.deepPurple)),
      home: const MyHomePage(title: 'Flutter Objectbox database'),
      debugShowCheckedModeBanner: false,
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  List<ShopOrder> orders = [];

  @override
  void initState() {
    super.initState();
    orders.addAll(shopBox.getAll());
  }

  void _addData() {
    String name = "Rezaul${DateTime.now()}";
    final coustomer = Coustomer(name: name);
    final order = ShopOrder(price: 100)..coustomer.target = coustomer;
    shopBox.put(order);

    setState(() {
      orders.add(order);
    });
  }

  void _removeData(int id) {
    shopBox.remove(id);
    setState(() {
      orders = orders.where((or) => or.id != id).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: ListView.builder(
        itemBuilder: (BuildContext context, int index) {
          final order = orders[index];
          return ListTile(
            title: Text(order.coustomer.target?.name ?? ""),
            subtitle: Text(order.price.toString()),
            trailing: IconButton(
              onPressed: () => _removeData(order.id),
              icon: Icon(Icons.delete, color: Colors.red),
            ),
          );
        },
        itemCount: orders.length,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addData,
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ),
    );
  }
}
