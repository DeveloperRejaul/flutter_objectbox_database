# flutter_objectbox_database

> A production-ready Flutter example demonstrating **ObjectBox** as a local NoSQL database with entity relations, CRUD operations, and proper initialization patterns.

**Status:** Ready to run | **Flutter:** 3.10.1+ | **Platform:** iOS, Android

---

## Quick Start

```bash
# 1. Install dependencies
flutter pub get

# 2. Run the app
flutter run

# 3. If you modify entities, regenerate bindings
flutter pub run build_runner build --delete-conflicting-outputs
```

---

## Table of Contents

- [Architecture](#architecture)
- [Project Structure](#project-structure)
- [Dependencies](#dependencies)
- [How ObjectBox is Used](#how-objectbox-is-used)
- [Code Examples](#code-examples)
- [Advanced Usage](#advanced-usage)
- [Building & Regenerating](#building--regenerating)
- [Troubleshooting & FAQ](#troubleshooting--faq)
- [Platform-Specific Notes](#platform-specific-notes)
- [Next Steps](#next-steps)

---

## Architecture

```
┌─────────────────────────────────────┐
│        Flutter UI (main.dart)       │
│   (ListView of Orders, Add/Remove)  │
└────────────┬────────────────────────┘
             │ initObjectBox() at startup
             ▼
┌─────────────────────────────────────┐
│    ObjectBox Store (init.dart)      │
│  Store → shopBox, customerBox       │
└────────────┬────────────────────────┘
             │
             ▼
┌─────────────────────────────────────┐
│    Entity Models (entities.dart)    │
│  ShopOrder ↔ Coustomer (ToOne/Many) │
└────────────┬────────────────────────┘
             │
             ▼
┌─────────────────────────────────────┐
│  ObjectBox Native Library (.so/.a)  │
│   & Generated Bindings (objectbox   │
│            .g.dart)                 │
└─────────────────────────────────────┘
```

---

## Project Structure

This repo contains a minimal example with two entities: `ShopOrder` and `Coustomer` (spelling as in the code). It demonstrates model definitions, initialization of ObjectBox in a Flutter app, and simple CRUD usage.

```
lib/
├── main.dart                    # Entry point; UI demo with add/remove
├── db/
│   ├── entities.dart            # @Entity classes: ShopOrder, Coustomer
│   └── init.dart                # initObjectBox(), shopBox, customerBox
├── objectbox-model.json         # Model metadata (keep in VCS)
└── objectbox.g.dart             # Generated bindings (keep in VCS)
```

---

## Dependencies

**Runtime** (add to `pubspec.yaml` → `dependencies`):

| Package | Version | Purpose |
|---------|---------|---------|
| `objectbox` | ^5.0.2 | Core ObjectBox SDK |
| `objectbox_flutter_libs` | ^5.0.2 | Native libs for iOS/Android |
| `path_provider` | ^2.1.5 | App documents directory |
| `path` | ^1.9.1 | Path utilities |

**Development** (add to `pubspec.yaml` → `dev_dependencies`):

| Package | Version | Purpose |
|---------|---------|---------|
| `build_runner` | ^2.10.4 | Code generation orchestrator |
| `objectbox_generator` | ^5.0.2 | Generates objectbox.g.dart |
| `flutter_lints` | ^6.0.0 | Lint rules |

See `pubspec.yaml` for exact versions.

---

## How ObjectBox is Used

### Entity Model

This project defines **two entities** with a **one-to-many relationship**:

```dart
// Coustomer has many ShopOrders (backlink)
@Entity()
class Coustomer {
  int id;              // Primary key (auto-generated)
  String name;
  @Backlink()
  final orders = ToMany<ShopOrder>();  // All orders for this customer
}

// ShopOrder belongs to one Coustomer
@Entity()
class ShopOrder {
  int id;              // Primary key (auto-generated)
  int price;           // Price of the order
  final coustomer = ToOne<Coustomer>();  // Link to customer
}
```

### Initialization & Global Boxes

In `lib/db/init.dart`:

```dart
late Store _store;

// Global boxes (accessed from anywhere)
final shopBox = _store.box<ShopOrder>();
final customerBox = _store.box<Coustomer>();

Future<void> initObjectBox() async {
  final dir = await getApplicationDocumentsDirectory();
  _store = Store(
    getObjectBoxModel(),
    directory: join(dir.path, 'objectbox'),
  );
}

Future<void> closeObjectBox() async {
  _store.close();
}
```

### Usage Pattern

In `lib/main.dart`, the app:

1. **Calls `initObjectBox()`** before `runApp()` to initialize the store.
2. **Loads all orders** on startup: `orders.addAll(shopBox.getAll());`
3. **Adds a new order**:
   ```dart
   final customer = Coustomer(name: 'Rezaul');
   final order = ShopOrder(price: 100)
     ..coustomer.target = customer;
   shopBox.put(order);
   ```
4. **Removes an order**: `shopBox.remove(id);`

---

## Code Examples

### Create & Save

```dart
// Create a customer
final customer = Coustomer(name: 'John Doe');

// Create an order and link to customer
final order = ShopOrder(price: 99)
  ..coustomer.target = customer;

// Save to database
shopBox.put(order);
```

### Read / Query

```dart
// Get all orders
final allOrders = shopBox.getAll();

// Get a specific order
final order = shopBox.get(orderId);

// Lazy-load related customer
final customer = order.coustomer.target;  // or order.coustomer.value
```

### Update

```dart
final order = shopBox.get(orderId);
order.price = 150;
shopBox.put(order);  // Updates existing record
```

### Delete

```dart
shopBox.remove(orderId);  // Delete by ID
shopBox.removeAll();      // Delete all
```

---

## Advanced Usage

### Query with Conditions

```dart
import 'package:objectbox/objectbox.dart';

// Find all orders with price > 50
final expensiveOrders = shopBox
    .query(ShopOrder_.price.greaterThan(50))
    .build()
    .find();

// Combine conditions (AND)
final filtered = shopBox
    .query(ShopOrder_.price.between(50, 200))
    .build()
    .find();

// Sort results
final sorted = shopBox
    .query()
    .order(ShopOrder_.price, flags: Order.descending)
    .build()
    .find();
```

### Backlink Traversal

```dart
final customer = customerBox.get(customerId);

// Get all orders for this customer via backlink
final customerOrders = customer.orders;

// Iterate
for (final order in customerOrders) {
  print('Order ${order.id}: \$${order.price}');
}
```

### Transaction / Batch Operations

```dart
_store.runInTransaction(TxMode.write, () {
  for (int i = 0; i < 100; i++) {
    final order = ShopOrder(price: i * 10);
    shopBox.put(order);
  }
});
```

### Count & Exists

```dart
// Count all orders
final totalOrders = shopBox.count();

// Check if record exists
final exists = shopBox.get(orderId) != null;
```

---

## Building & Regenerating

### When to Regenerate

If you **modify entity classes** (add/remove fields, change relations), you must regenerate:

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

This:
- Runs `objectbox_generator` to produce `lib/objectbox.g.dart`
- Updates `lib/objectbox-model.json` with new entity/property IDs

### Watch Mode (for development)

```bash
flutter pub run build_runner watch
```

Automatically regenerates when you save changes.

### If Build Fails

1. **Clean generated files**:
   ```bash
   rm -f lib/objectbox.g.dart
   flutter pub run build_runner clean
   ```
2. **Regenerate**:
   ```bash
   flutter pub run build_runner build --delete-conflicting-outputs
   ```
3. **Ensure version compatibility**: `objectbox_generator` and `build_runner` should match `objectbox` version.

---

## Troubleshooting & FAQ

### Q: I see "objectbox.g.dart not found"

**A:** Run:
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

Ensure `objectbox_generator` version matches your `objectbox` version in `pubspec.yaml`.

### Q: Changes to my entities aren't applied

**A:** Regenerate bindings:
```bash
flutter pub run build_runner clean
flutter pub run build_runner build --delete-conflicting-outputs
```

### Q: What's `objectbox-model.json`?

**A:** This file stores stable IDs for your entities and properties. **Keep it in version control** (git). It prevents ID collisions during code generation.

If you have merge conflicts, see [ObjectBox documentation](https://docs.objectbox.io/) on resolving them—do not regenerate blindly.

### Q: iOS build fails with ObjectBox linking errors

**A:** Try:
```bash
cd ios
pod install
cd ..
flutter clean
flutter pub get
flutter run
```

### Q: How do I close the database?

**A:** Call `closeObjectBox()` (defined in `lib/db/init.dart`):
```dart
await closeObjectBox();
```

Typically called on app exit or when switching users.

### Q: Can I use ObjectBox in tests?

**A:** Yes! Use `directory` parameter with a temporary directory:
```dart
final tempDir = await getTemporaryDirectory();
final store = Store(
  getObjectBoxModel(),
  directory: '${tempDir.path}/test-objectbox',
);
// ... test operations ...
await store.close();
```

### Q: How do I update an existing record?

**A:** ObjectBox uses **put** for both insert and update:
```dart
final order = shopBox.get(orderId);  // Fetch
order.price = 999;                     // Modify
shopBox.put(order);                    // Save (auto-updates)
```

### Q: Performance tips?

**A:** 
- Batch operations with `Store.runInTransaction()` for multiple writes.
- Use queries instead of `getAll()` + manual filtering for large datasets.
- Consider adding indexes via `@Index()` on fields frequently queried.

### Q: How do I add indexes?

**A:**
```dart
@Entity()
class ShopOrder {
  int id;
  @Index()
  int price;  // Indexed for faster queries
  final coustomer = ToOne<Coustomer>();
}
```

Then regenerate bindings with `build_runner`.

---

## Platform-Specific Notes

| Platform | Note |
|----------|------|
| **iOS** | Uses `objectbox_flutter_libs` to load `.xcframework`. Run `pod install` if deps change. |
| **Android** | Native `.so` files included in `objectbox_flutter_libs`. Handles Android 6+ compatibility via `loadObjectBoxLibraryAndroidCompat()`. |

---

## Next Steps

1. **Add Tests**: Create `test/db_test.dart` to verify put/get/remove operations.
2. **Advanced Queries**: Implement filters and sorting using `Query<ShopOrder>`.
3. **State Management**: Integrate with Provider, Riverpod, or GetX for reactive UI.
4. **Migrations**: If you need schema updates, plan ahead using ObjectBox's migration features.

---

## Resources

- [ObjectBox Documentation](https://docs.objectbox.io/)
- [ObjectBox Dart Packages](https://pub.dev/packages/objectbox)
- [Flutter Documentation](https://flutter.dev/)

---

**Happy coding! 🚀**
