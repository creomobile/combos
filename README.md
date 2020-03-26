# Combos

## About

Combo widgets for Flutter.

[Install instructions](https://pub.dev/packages/combos#-installing-tab-)

[Docs](https://pub.dev/documentation/combos/latest/combos/combos-library.html)

[Online Samples](https://samples.creomobile.com/#/combos)

![alt text](https://samples.creomobile.com/combos2.png)

Includes:
* **Combo** - Simple combo widget for custom child and popup content.
* **AwaitCombo** - Combo widget with delayed popup content builder for loading data with the progress indication
* **ListCombo** - Combo widget for displaying items list
* **SelectorCombo** - Combo widget for displaying items list with selected value
* **TypeaheadCombo** - Typeahead widget with the text input and custom 'search' method
* **MenuItemCombo** - Menu item widget for displaying popup menus

### Examples

* Combo
```dart
Combo(
  child: const Padding(
    padding: EdgeInsets.all(16),
    child: Text('Combo child'),
  ),
  popupBuilder: (context, mirrored) => const Material(
    elevation: 4,
    child: Padding(
      padding:
          EdgeInsets.symmetric(vertical: 48, horizontal: 16),
      child: Center(child: Text('Combo popup')),
    ),
  ),
)
```

* AwaitCombo
```dart
AwaitCombo(
  child: const Padding(
    padding: EdgeInsets.all(16),
    child: Text('Combo child'),
  ),
  popupBuilder: (context) async {
    await Future.delayed(const Duration(milliseconds: 500));
    return const Material(
      elevation: 4,
      child: Padding(
        padding:
            EdgeInsets.symmetric(vertical: 48, horizontal: 16),
        child: Center(child: Text('Combo popup')),
      ),
    );
  },
)
```

* ListCombo
```dart
ListCombo<String>(
  child: const Padding(
    padding: EdgeInsets.all(16),
    child: Text('Combo child'),
  ),
  getList: () async {
    await Future.delayed(const Duration(milliseconds: 500));
    return ['Item1', 'Item2', 'Item3'];
  },
  itemBuilder: (context, parameters, item) => ListTile(title: Text(item)),
  onItemTapped: (item) {},
)
```

* SelectorCombo
```dart
String _item;

...

SizedBox(
  width: 200,
  child: SelectorCombo<String>(
    selected: _item,
    getList: () async {
      await Future.delayed(const Duration(milliseconds: 500));
      return ['Item1', 'Item2', 'Item3'];
    },
    itemBuilder: (context, parameters, item) =>
        ListTile(title: Text(item ?? '<Empty>')),
    onItemTapped: (item) => setState(() => _item = item),
  ),
)
```

* TypeaheadCombo
```dart
String _item;

...

SizedBox(
  width: 200,
  child: TypeaheadCombo<String>(
    selected: _item,
    getList: (text) async {
      await Future.delayed(const Duration(milliseconds: 500));
      return ['Item1', 'Item2', 'Item3'];
    },
    itemBuilder: (context, parameters, item) =>
        ListTile(title: Text(item ?? '<Empty>')),
    onItemTapped: (item) => setState(() => _item = item),
    getItemText: (item) => item,
    decoration: const InputDecoration(labelText: 'Typeahead'),
  ),
)
```

* MenuItemCombo
```dart
MenuItemCombo<String>(
  item: MenuItem(
      'File',
      () => [
            MenuItem('New'),
            MenuItem.separator,
            MenuItem('Open'),
            MenuItem('Save'),
            MenuItem('Save As...'),
            MenuItem.separator,
            MenuItem(
                'Recent',
                () => [
                      MenuItem('Folders', () async {
                        await Future.delayed(
                            Duration(milliseconds: 500));
                        return [
                          MenuItem('Folder 1'),
                          MenuItem('Folder 2'),
                          MenuItem('Folder 3'),
                        ];
                      }),
                      MenuItem('Files', () async {
                        await Future.delayed(
                            Duration(milliseconds: 500));
                        return [
                          MenuItem('File 1'),
                          MenuItem('File 2'),
                          MenuItem('File 3'),
                        ];
                      }),
                    ]),
            MenuItem.separator,
            MenuItem('Exit'),
          ]),
  itemBuilder: (context, parameters, item) => Padding(
    padding: const EdgeInsets.all(16),
    child: Text(item.item),
  ),
  onItemTapped: (value) {
    final dialog =
        AlertDialog(content: Text('${value.item} tapped!'));
    showDialog(context: context, builder: (_) => dialog);
  },
)
```
