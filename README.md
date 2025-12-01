## flutter_objectbox_database

A small Flutter demo showing how to use ObjectBox as a local database.

This repo contains a minimal example with two entities: `ShopOrder` and
`Coustomer` (spelling as in the code). It demonstrates model definitions,
initialization of ObjectBox in a Flutter app, and simple CRUD usage from
`lib/main.dart`.

## What’s included

- `lib/db/entities.dart` — ObjectBox entity classes (`@Entity`) and relations.
- `lib/db/init.dart` — ObjectBox store initialization (`initObjectBox`) and
	global boxes used by the app.
- `lib/main.dart` — Flutter UI that calls `initObjectBox()` before `runApp` and
	demonstrates adding/removing records.
- `lib/objectbox-model.json` and `lib/objectbox.g.dart` — ObjectBox model and
	generated bindings (checked-in here for convenience).

## Dependencies

This project uses the following notable packages (see `pubspec.yaml` for
versions):

- objectbox
- objectbox_flutter_libs
- path_provider
- path
- build_runner (dev)
- objectbox_generator (dev)

Exact versions are defined in `pubspec.yaml`.

## How ObjectBox is used in this project (summary of your code)

- Entities:
	- `ShopOrder` (fields: `id`, `price`) with a `ToOne<Coustomer>` relation
		(field `coustomer`).
	- `Coustomer` (fields: `id`, `name`) with a backlink `orders` of type
		`ToMany<ShopOrder>`.

- Initialization:
	- `initObjectBox()` (in `lib/db/init.dart`) gets the app documents
		directory and creates the ObjectBox `Store` using `getObjectBoxModel()`
		(from `objectbox.g.dart`). It stores the `Store` in a `late` variable and
		exposes `shopBox` and `customerBox` as global boxes.

- Usage (from `lib/main.dart`):
	- Before `runApp()` the app calls `await initObjectBox()`.
	- Adding an order: create a `Coustomer`, create a `ShopOrder` and set
		`order.coustomer.target = coustomer`, then `shopBox.put(order)`.
	- Reading: `shopBox.getAll()` to fetch all orders (used on widget init).
	- Removing: `shopBox.remove(id)`.

## Commands — generate & run

1. Install dependencies:

```bash
flutter pub get
```

2. If you change entity classes, regenerate ObjectBox bindings (this project
	 already includes `lib/objectbox.g.dart`, but if you modify entities run):

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

This runs the `objectbox_generator` which produces `objectbox.g.dart` and
updates `objectbox-model.json` as needed.

3. Run the app (Android/iOS/emulator):

```bash
flutter run
```

On iOS, if CocoaPods needs updating:

```bash
cd ios
pod install
cd ..
```

## Notes about the ObjectBox files

- `lib/objectbox-model.json` contains stable IDs for entities/properties used by
	ObjectBox. Keep it in version control. If you have merge conflicts here,
	follow ObjectBox guidance for resolving them rather than regenerating blindly.
- `lib/objectbox.g.dart` is generated; it contains helper `openStore` and
	`getObjectBoxModel()` functions plus runtime bindings. The generated file also
	handles loading the native ObjectBox library on older Android via
	`loadObjectBoxLibraryAndroidCompat()`.

## Code snippets (from the project)

Entities (simplified):

```dart
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
```

Init (key part):

```dart
late Store _store;
final shopBox = _store.box<ShopOrder>();

Future<void> initObjectBox() async {
	final dir = await getApplicationDocumentsDirectory();
	_store = Store(getObjectBoxModel(), directory: join(dir.path, 'objectbox'));
}
```

Usage (adding an order):

```dart
final coustomer = Coustomer(name: 'Alice');
final order = ShopOrder(price: 100)..coustomer.target = coustomer;
shopBox.put(order);
```

## Troubleshooting & tips

- If `objectbox.g.dart` is missing or outdated: run the `build_runner` command
	above. If you see errors from the generator, ensure `objectbox_generator` and
	`build_runner` versions in `dev_dependencies` match the `objectbox` SDK
	version.
- When changing entities, prefer incremental changes and commit
	`objectbox-model.json` to avoid accidental ID loss.
- Close the store on app shutdown if needed with `store.close()` (there is a
	`closeObjectBox()` helper in `lib/db/init.dart`).