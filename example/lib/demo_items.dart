library demo_items;

import 'package:combos/combos.dart';
import 'package:flutter/material.dart';

import 'editors.dart';

typedef ChildBuilder<TProperties> = Widget Function(
    TProperties properties, Editor modifiedEditor);

abstract class DemoItemBase<TProperties> extends StatefulWidget {
  const DemoItemBase(
      {Key key, @required this.properties, @required this.childBuilder})
      : super(key: key);

  final TProperties properties;
  final ChildBuilder<TProperties> childBuilder;
}

abstract class DemoItemStateBase<TProperties>
    extends State<DemoItemBase<TProperties>> {
  static const _width = 300.0;
  final _comboKey = GlobalKey<ComboState>();
  Editor _modifiedEditor;

  Widget buildChild() =>
      widget.childBuilder(widget.properties, _modifiedEditor);
  Widget buildProperties();

  @override
  Widget build(BuildContext context) =>
      Row(mainAxisSize: MainAxisSize.min, children: [
        buildChild(),
        const SizedBox(width: 16),
        ComboContext(
          parameters: ComboParameters(
            autoOpen: ComboAutoOpen.none,
            position: PopupPosition.right,
            requiredSpace: _width,
          ),
          child: Combo(
            key: _comboKey,
            child: IconButton(
              icon: const Icon(Icons.tune),
              color: Colors.blueAccent,
              tooltip: 'Properties',
              onPressed: () => _comboKey.currentState.open(),
            ),
            popupBuilder: (context, mirrored) => ConstrainedBox(
              constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height / 3 * 2,
                  maxWidth: _width),
              child: Material(
                elevation: 4,
                child: EditorsContext(
                  onValueChanged: (editor, _) {
                    setState(() => _modifiedEditor = editor);
                    return true;
                  },
                  child: buildProperties(),
                ),
              ),
            ),
            ignoreChildDecorator: true,
          ),
        ),
      ]);
}

class EditorsSeparator implements EditorsBuilder {
  const EditorsSeparator(this.title);
  final String title;
  @override
  Widget build() => Padding(
        padding: const EdgeInsets.all(32.0),
        child: Text(
          '- $title -',
          style:
              const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold),
        ),
      );
}
