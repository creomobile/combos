import 'dart:math' as math;

import 'package:combos/combos.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';

const _customAnimationDurationMs = 150;

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'Combo Samples',
        home: MyHomePage(),
      );
}

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final _comboKey = GlobalKey<ComboState>();
  final _awaitComboKey = GlobalKey<ComboState>();
  GlobalKey<_TestPopupState> _popupKey;
  GlobalKey<_TestPopupState> _awaitPopupKey;
  final _offsetXController = TextEditingController(text: '0');
  final _offsetYController = TextEditingController(text: '0');
  final _screenPaddingHorizontalController = TextEditingController(text: '0');
  final _screenPaddingVerticalController = TextEditingController(text: '0');
  final _animationDurationController = TextEditingController(text: '150');
  final _requiredSpaceController = TextEditingController(text: '300');
  final _popupWidthController = TextEditingController(text: '300');
  final _itemsCountController = TextEditingController(text: '3');
  final _spaceAboveController = TextEditingController(text: '16');
  final _comboWidthController = TextEditingController(text: '200');

  var _position = PopupPosition.bottomMinMatch;
  var _offsetX = 0;
  var _offsetY = 0;
  var _screenPaddingHorizontal = 0;
  var _screenPaddingVertical = 0;
  var _requiredSpace = 300;
  var _autoClose = PopupAutoClose.tapOutsideWithChildIgnorePointer;
  var _autoOpen = PopupAutoOpen.tap;
  var _animation = PopupAnimation.fade;
  var _animationDurationMs = 150;
  var _popupWidth = 300;
  var _itemsCount = 3;
  var _spaceAbove = 16;
  var _comboWidth = 200;
  var _comboAlignment = CrossAxisAlignment.center;

  String _selectorItem;
  String _typeaheadItem;

  @override
  Widget build(BuildContext context) {
    Widget buildEnumSelector<T>(String title, Iterable<T> values, T value,
            void Function(T value) setValue) =>
        Row(mainAxisSize: MainAxisSize.min, children: [
          Text(title,
              style:
                  TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
          const SizedBox(width: 8),
          DropdownButton<T>(
            items: values
                .map((_) => DropdownMenuItem<T>(
                    value: _, child: Text(TextHelper.enumToString(_))))
                .toList(),
            value: value,
            onChanged: (_) => setState(() => setValue(_)),
          ),
        ]);

    Widget buildBoolSelector(
            String title, bool value, void Function(bool value) setValue) =>
        SizedBox(
          width: 200,
          child: CheckboxListTile(
            value: value,
            onChanged: (_) => setState(() => setValue(_)),
            controlAffinity: ListTileControlAffinity.leading,
            title: Text(title),
            dense: true,
          ),
        );

    Widget buildIntSelector(TextEditingController controller, String labelText,
            void Function(int value) setValue,
            [enabled = true]) =>
        SizedBox(
          width: 200,
          child: TextField(
            controller: controller,
            enabled: enabled,
            inputFormatters: [
              IntTextInputFormatter(minValue: 0, maxValue: 5000)
            ],
            decoration: InputDecoration(labelText: labelText),
            onChanged: (_) => setState(() => setValue(int.tryParse(_) ?? 0)),
          ),
        );

    Widget buildComboContainer({String title, Widget child}) =>
        Row(mainAxisSize: MainAxisSize.min, children: [
          SizedBox(
              width: 160,
              child: Text(
                title,
                style: const TextStyle(
                    color: Colors.grey, fontWeight: FontWeight.bold),
              )),
          child,
        ]);

    return Scaffold(
      appBar: AppBar(
        title: Text('Combo Samples'),
      ),
      body: ListView(
        children: [
          Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            // properties
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Wrap(spacing: 24, runSpacing: 16, children: [
                // position
                buildEnumSelector<PopupPosition>('Position:',
                    PopupPosition.values, _position, (_) => _position = _),

                // offsetX
                buildIntSelector(
                    _offsetXController, 'Offset X', (_) => _offsetX = _),

                // offsetY
                buildIntSelector(
                    _offsetYController, 'Offset Y', (_) => _offsetY = _),

                // screen padding horizontal
                buildIntSelector(
                    _screenPaddingHorizontalController,
                    'Screen Padding Horizontal',
                    (_) => _screenPaddingHorizontal = _),

                // screen padding vertical
                buildIntSelector(
                    _screenPaddingVerticalController,
                    'Screen Padding Horizontal',
                    (_) => _screenPaddingVertical = _),

                // requiredSpace
                buildIntSelector(_requiredSpaceController, 'Required Space',
                    (_) => _requiredSpace = _),

                // auto close
                buildEnumSelector<PopupAutoClose>('Auto Close:',
                    PopupAutoClose.values, _autoClose, (_) => _autoClose = _),

                // auto open
                buildEnumSelector<PopupAutoOpen>('Auto Open:',
                    PopupAutoOpen.values, _autoOpen, (_) => _autoOpen = _),

                // animation
                buildEnumSelector<PopupAnimation>('Animation:',
                    PopupAnimation.values, _animation, (_) => _animation = _),

                // animationDuration
                buildIntSelector(
                    _animationDurationController,
                    'Animation Duration (Ms)',
                    (_) => _animationDurationMs = _,
                    _animation != PopupAnimation.custom &&
                        _animation != PopupAnimation.none),

                // popup width
                buildIntSelector(_popupWidthController, 'Popup Width',
                    (_) => _popupWidth = _),

                // items count
                buildIntSelector(_itemsCountController, 'Items Count',
                    (_) => _itemsCount = _),

                // space above
                buildIntSelector(_spaceAboveController, 'Space Above',
                    (_) => _spaceAbove = _),

                // space above
                buildIntSelector(_comboWidthController, 'Combo Width',
                    (_) => _comboWidth = _),

                // horizontalBehavior
                buildEnumSelector<CrossAxisAlignment>(
                    'Combo Alignment:',
                    [
                      CrossAxisAlignment.start,
                      CrossAxisAlignment.center,
                      CrossAxisAlignment.end
                    ],
                    _comboAlignment,
                    (_) => _comboAlignment = _),

                // close
                SizedBox(
                  width: 200,
                  child: RaisedButton(
                      color: Colors.blueAccent,
                      textColor: Colors.white,
                      child: Text('Close Popup'),
                      onPressed: Combo.closeAll),
                )
              ]),
            ),

            // combos
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(crossAxisAlignment: _comboAlignment, children: [
                // space
                SizedBox(
                    key: ValueKey(_spaceAbove), height: _spaceAbove.toDouble()),

                // Combo
                buildComboContainer(
                  title: 'Combo',
                  child: Material(
                    borderRadius: BorderRadius.circular(29),
                    child: Combo(
                      key: _comboKey,
                      position: _position,
                      offset: Offset(_offsetX.toDouble(), _offsetY.toDouble()),
                      requiredSpace: _requiredSpace.toDouble(),
                      screenPadding: EdgeInsets.symmetric(
                          horizontal: _screenPaddingHorizontal.toDouble(),
                          vertical: _screenPaddingVertical.toDouble()),
                      autoClose: _autoClose,
                      autoOpen: _autoOpen,
                      animation: _animation,
                      animationDuration:
                          Duration(milliseconds: _animationDurationMs),
                      openedChanged: (isOpened) {
                        if (!isOpened && _animation == PopupAnimation.custom) {
                          _popupKey.currentState?.animatedClose();
                        }
                      },
                      child: Container(
                        width: _comboWidth.toDouble(),
                        height: 58,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.blueAccent.withOpacity(0.2),
                                Colors.blueAccent.withOpacity(0.0),
                                Colors.blueAccent.withOpacity(0.0),
                                Colors.blueAccent.withOpacity(0.2),
                              ]),
                          borderRadius: BorderRadius.circular(29),
                          border: Border.all(color: Colors.blueAccent),
                        ),
                        child: Row(
                          children: [
                            const Expanded(
                                child: Text('Combo Child',
                                    textAlign: TextAlign.center,
                                    style:
                                        TextStyle(color: Colors.blueAccent))),
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 16),
                              child: Icon(Icons.arrow_drop_down,
                                  color: Colors.blueAccent),
                            ),
                          ],
                        ),
                      ),
                      popupBuilder: (context, mirrored) => TestPopup(
                          key: _popupKey = GlobalKey<_TestPopupState>(),
                          mirrored: mirrored,
                          width: _popupWidth.toDouble(),
                          itemsCount: _itemsCount,
                          onClose: () => _comboKey.currentState?.close(),
                          animated: _animation == PopupAnimation.custom,
                          radius: const Radius.circular(24)),
                      highlightColor: Colors.blueAccent.withOpacity(0.1),
                      splashColor: Colors.blueAccent.withOpacity(0.1),
                      hoverColor: Colors.blueAccent.withOpacity(0.1),
                      onTap: () => print('tapped'),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // AwaitCombo
                buildComboContainer(
                  title: 'AwaitCombo',
                  child: Material(
                    borderRadius: BorderRadius.circular(29),
                    child: Builder(builder: (context) {
                      final horizontal = _position == PopupPosition.left ||
                          _position == PopupPosition.right;
                      return AwaitCombo(
                        key: _awaitComboKey,
                        refreshOnOpened: true,
                        progressPosition: horizontal
                            ? ProgressPosition.child
                            : ProgressPosition.popup,
                        progressDecoratorBuilder:
                            (context, waiting, mirrored, child) =>
                                ProgressDecorator(
                          waiting: waiting,
                          mirrored: mirrored,
                          child: child,
                          progressBackgroundColor:
                              horizontal ? Colors.transparent : null,
                          progressValueColor: horizontal
                              ? AlwaysStoppedAnimation(
                                  Colors.blueAccent.withOpacity(0.2))
                              : null,
                          progressHeight: horizontal ? null : 2.0,
                        ),
                        position: _position,
                        offset:
                            Offset(_offsetX.toDouble(), _offsetY.toDouble()),
                        requiredSpace: _requiredSpace.toDouble(),
                        screenPadding: EdgeInsets.symmetric(
                            horizontal: _screenPaddingHorizontal.toDouble(),
                            vertical: _screenPaddingVertical.toDouble()),
                        autoClose: _autoClose,
                        autoOpen: _autoOpen,
                        animation: _animation,
                        animationDuration:
                            Duration(milliseconds: _animationDurationMs),
                        openedChanged: (isOpened) {
                          if (!isOpened &&
                              _animation == PopupAnimation.custom) {
                            _popupKey.currentState?.animatedClose();
                          }
                        },
                        child: Container(
                          width: _comboWidth.toDouble(),
                          height: 58,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.blueAccent.withOpacity(0.2),
                                  Colors.blueAccent.withOpacity(0.0),
                                  Colors.blueAccent.withOpacity(0.0),
                                  Colors.blueAccent.withOpacity(0.2),
                                ]),
                            borderRadius: BorderRadius.circular(29),
                            border: Border.all(color: Colors.blueAccent),
                          ),
                          child: Row(
                            children: [
                              const Expanded(
                                  child: Text('AwaitCombo Child',
                                      textAlign: TextAlign.center,
                                      style:
                                          TextStyle(color: Colors.blueAccent))),
                              const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 16),
                                child: Icon(Icons.arrow_drop_down,
                                    color: Colors.blueAccent),
                              ),
                            ],
                          ),
                        ),
                        popupBuilder: (context) async {
                          await Future.delayed(Duration(milliseconds: 500));
                          return TestPopup(
                              key: _awaitPopupKey =
                                  GlobalKey<_TestPopupState>(),
                              mirrored: false,
                              width: _popupWidth.toDouble(),
                              itemsCount: _itemsCount,
                              onClose: () => _comboKey.currentState?.close(),
                              animated: _animation == PopupAnimation.custom,
                              radius: const Radius.circular(24));
                        },
                        highlightColor: Colors.blueAccent.withOpacity(0.1),
                        splashColor: Colors.blueAccent.withOpacity(0.1),
                        hoverColor: Colors.blueAccent.withOpacity(0.1),
                      );
                    }),
                  ),
                ),

                const SizedBox(height: 16),

                // ListCombo
                buildComboContainer(
                  title: 'ListCombo',
                  child: Material(
                    borderRadius: BorderRadius.circular(29),
                    child: Builder(builder: (context) {
                      final horizontal = _position == PopupPosition.left ||
                          _position == PopupPosition.right;
                      return ListCombo<String>(
                        getList: () async {
                          await Future.delayed(Duration(milliseconds: 500));
                          return Iterable.generate(_itemsCount)
                              .map((_) => 'Item ${_ + 1}')
                              .toList();
                        },
                        itemBuilder: (context, item) =>
                            ListTile(title: Text(item)),
                        onItemTapped: (item) {
                          final dialog =
                              AlertDialog(content: Text('$item tapped!'));
                          showDialog(context: context, builder: (_) => dialog);
                        },
                        popupBuilder: _position == PopupPosition.bottomMatch ||
                                _position == PopupPosition.topMatch
                            ? null
                            : (context, list, itemBuilder, onItemTapped,
                                    mirrored, getIsSelectable) =>
                                ListPopup<String>(
                                    list: list,
                                    itemBuilder: itemBuilder,
                                    onItemTapped: onItemTapped,
                                    width: 300,
                                    getIsSelectable: getIsSelectable),
                        refreshOnOpened: true,
                        progressPosition: horizontal
                            ? ProgressPosition.child
                            : ProgressPosition.popup,
                        progressDecoratorBuilder:
                            (context, waiting, mirrored, child) =>
                                ProgressDecorator(
                          waiting: waiting,
                          mirrored: mirrored,
                          child: child,
                          progressBackgroundColor:
                              horizontal ? Colors.transparent : null,
                          progressValueColor: horizontal
                              ? AlwaysStoppedAnimation(
                                  Colors.blueAccent.withOpacity(0.2))
                              : null,
                          progressHeight: horizontal ? null : 2.0,
                        ),
                        position: _position,
                        offset:
                            Offset(_offsetX.toDouble(), _offsetY.toDouble()),
                        requiredSpace: _requiredSpace.toDouble(),
                        screenPadding: EdgeInsets.symmetric(
                            horizontal: _screenPaddingHorizontal.toDouble(),
                            vertical: _screenPaddingVertical.toDouble()),
                        autoClose: _autoClose,
                        autoOpen: _autoOpen,
                        animation: _animation,
                        animationDuration:
                            Duration(milliseconds: _animationDurationMs),
                        openedChanged: (isOpened) {
                          if (!isOpened &&
                              _animation == PopupAnimation.custom) {
                            _popupKey.currentState?.animatedClose();
                          }
                        },
                        child: Container(
                          width: _comboWidth.toDouble(),
                          height: 58,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.blueAccent.withOpacity(0.2),
                                  Colors.blueAccent.withOpacity(0.0),
                                  Colors.blueAccent.withOpacity(0.0),
                                  Colors.blueAccent.withOpacity(0.2),
                                ]),
                            borderRadius: BorderRadius.circular(29),
                            border: Border.all(color: Colors.blueAccent),
                          ),
                          child: Row(
                            children: [
                              const Expanded(
                                  child: Text('ListCombo Child',
                                      textAlign: TextAlign.center,
                                      style:
                                          TextStyle(color: Colors.blueAccent))),
                              const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 16),
                                child: Icon(Icons.arrow_drop_down,
                                    color: Colors.blueAccent),
                              ),
                            ],
                          ),
                        ),
                        highlightColor: Colors.blueAccent.withOpacity(0.1),
                        splashColor: Colors.blueAccent.withOpacity(0.1),
                        hoverColor: Colors.blueAccent.withOpacity(0.1),
                      );
                    }),
                  ),
                ),

                const SizedBox(height: 16),

                // ListCombo
                buildComboContainer(
                  title: 'SelectorCombo',
                  child: Container(
                    width: _comboWidth.toDouble(),
                    height: 58,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.blueAccent.withOpacity(0.2),
                            Colors.blueAccent.withOpacity(0.0),
                            Colors.blueAccent.withOpacity(0.0),
                            Colors.blueAccent.withOpacity(0.2),
                          ]),
                      borderRadius: BorderRadius.circular(29),
                      border: Border.all(color: Colors.blueAccent),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(29),
                      child: Builder(builder: (context) {
                        final horizontal = _position == PopupPosition.left ||
                            _position == PopupPosition.right;
                        return SelectorCombo<String>(
                          selected: _selectorItem,
                          childBuilder: (context, item) => item == null
                              ? const Center(
                                  child: Text('<None>',
                                      style: TextStyle(color: Colors.grey)),
                                )
                              : ListTile(
                                  title: Text(item,
                                      style: const TextStyle(
                                          color: Colors.blueAccent)),
                                ),
                          getList: () async {
                            await Future.delayed(Duration(milliseconds: 500));
                            return Iterable.generate(_itemsCount)
                                .map((_) => 'Item ${_ + 1}')
                                .toList();
                          },
                          itemBuilder: (context, item) =>
                              ListTile(title: Text(item ?? '')),
                          onItemTapped: (item) =>
                              setState(() => _selectorItem = item),
                          popupBuilder:
                              _position == PopupPosition.bottomMatch ||
                                      _position == PopupPosition.topMatch
                                  ? null
                                  : (context, list, itemBuilder, onItemTapped,
                                          mirrored, getIsSelectable) =>
                                      ListPopup<String>(
                                          list: list,
                                          itemBuilder: itemBuilder,
                                          onItemTapped: onItemTapped,
                                          width: 300,
                                          getIsSelectable: getIsSelectable),
                          refreshOnOpened: true,
                          progressPosition: horizontal
                              ? ProgressPosition.child
                              : ProgressPosition.popup,
                          progressDecoratorBuilder:
                              (context, waiting, mirrored, child) =>
                                  ProgressDecorator(
                            waiting: waiting,
                            mirrored: mirrored,
                            child: child,
                            progressBackgroundColor:
                                horizontal ? Colors.transparent : null,
                            progressValueColor: horizontal
                                ? AlwaysStoppedAnimation(
                                    Colors.blueAccent.withOpacity(0.2))
                                : null,
                            progressHeight: horizontal ? null : 2.0,
                          ),
                          position: _position,
                          offset:
                              Offset(_offsetX.toDouble(), _offsetY.toDouble()),
                          requiredSpace: _requiredSpace.toDouble(),
                          screenPadding: EdgeInsets.symmetric(
                              horizontal: _screenPaddingHorizontal.toDouble(),
                              vertical: _screenPaddingVertical.toDouble()),
                          autoClose: _autoClose,
                          autoOpen: _autoOpen,
                          animation: _animation,
                          animationDuration:
                              Duration(milliseconds: _animationDurationMs),
                          openedChanged: (isOpened) {
                            if (!isOpened &&
                                _animation == PopupAnimation.custom) {
                              _popupKey.currentState?.animatedClose();
                            }
                          },
                          highlightColor: Colors.blueAccent.withOpacity(0.1),
                          splashColor: Colors.blueAccent.withOpacity(0.1),
                          hoverColor: Colors.blueAccent.withOpacity(0.1),
                        );
                      }),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // TypeaheadCombo
                buildComboContainer(
                  title: 'TypeaheadCombo',
                  child: Container(
                    width: _comboWidth.toDouble(),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(29),
                      gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.blueAccent.withOpacity(0.2),
                            Colors.blueAccent.withOpacity(0.0),
                            Colors.blueAccent.withOpacity(0.0),
                            Colors.blueAccent.withOpacity(0.2),
                          ]),
                    ),
                    child: Builder(builder: (context) {
                      final horizontal = _position == PopupPosition.left ||
                          _position == PopupPosition.right;
                      return TypeaheadCombo<String>(
                        selected: _typeaheadItem,
                        onItemTapped: (_) => setState(() => _typeaheadItem = _),
                        getList: (text) async {
                          await Future.delayed(Duration(seconds: 1));
                          return [
                            'Item1',
                            'Item2',
                            'Item3',
                            'Item4',
                            'Item5',
                            'Item6',
                            'Item7',
                          ];
                        },
                        itemBuilder: (context, item) => ListTile(
                            selected: item == _typeaheadItem,
                            title: Text(item)),
                        getItemText: (item) => item,
                        //minTextLength: 0,
                        //popupWidth: _popupWidth.toDouble(),
                        //popupMaxHeight: _popupHeight.toDouble(),
                        decoration: InputDecoration(
                          labelText: 'Sample Typeahead',
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(29),
                            borderSide: BorderSide(color: Colors.blueAccent),
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(29),
                            borderSide: BorderSide(color: Colors.blueAccent),
                          ),
                          labelStyle: TextStyle(color: Colors.blueAccent),
                        ),
                        popupBuilder: _position == PopupPosition.bottomMatch ||
                                _position == PopupPosition.topMatch
                            ? null
                            : (context, list, itemBuilder, onItemTapped,
                                    mirrored, getIsSelectable) =>
                                ListPopup<String>(
                                    list: list,
                                    itemBuilder: itemBuilder,
                                    onItemTapped: onItemTapped,
                                    width: 300,
                                    getIsSelectable: getIsSelectable),
                        progressPosition: horizontal
                            ? ProgressPosition.child
                            : ProgressPosition.popup,
                        progressDecoratorBuilder:
                            (context, waiting, mirrored, child) =>
                                ProgressDecorator(
                          waiting: waiting,
                          mirrored: mirrored,
                          child: child,
                          progressBackgroundColor:
                              horizontal ? Colors.transparent : null,
                          progressValueColor: horizontal
                              ? AlwaysStoppedAnimation(
                                  Colors.blueAccent.withOpacity(0.2))
                              : null,
                          progressHeight: horizontal ? null : 2.0,
                        ),
                        position: _position,
                        offset:
                            Offset(_offsetX.toDouble(), _offsetY.toDouble()),
                        requiredSpace: _requiredSpace.toDouble(),
                        screenPadding: EdgeInsets.symmetric(
                            horizontal: _screenPaddingHorizontal.toDouble(),
                            vertical: _screenPaddingVertical.toDouble()),
                        animation: _animation,
                        animationDuration:
                            Duration(milliseconds: _animationDurationMs),
                      );
                    }),
                  ),
                ),

                const SizedBox(height: 16),

                // MenuItemCombo
                buildComboContainer(
                    title: 'MenuItemCombo',
                    child: SizedBox(
                      width: _comboWidth.toDouble(),
                      child: Row(
                        children: [
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
                                                  await Future.delayed(Duration(
                                                      milliseconds: 500));
                                                  return [
                                                    MenuItem('Folder 1'),
                                                    MenuItem('Folder 2'),
                                                    MenuItem('Folder 3'),
                                                  ];
                                                }),
                                                MenuItem('Files', () async {
                                                  await Future.delayed(Duration(
                                                      milliseconds: 500));
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
                            itemBuilder: (context, item) => Padding(
                              padding: const EdgeInsets.all(16),
                              child: Text(item.item),
                            ),
                            onItemTapped: (value) {
                              final dialog = AlertDialog(
                                  content: Text('${value.item} tapped!'));
                              showDialog(
                                  context: context, builder: (_) => dialog);
                            },
                            autoOpen: _autoOpen,
                          ),
                          MenuItemCombo<String>(
                            item: MenuItem(
                                'Edit',
                                () => [
                                      MenuItem('Undo'),
                                      MenuItem('Redo'),
                                      MenuItem.separator,
                                      MenuItem('Cut'),
                                      MenuItem('Copy'),
                                      MenuItem('Paste'),
                                      MenuItem.separator,
                                      MenuItem('Find'),
                                    ]),
                            itemBuilder: (context, item) => Padding(
                              padding: const EdgeInsets.all(16),
                              child: item.item == 'Edit'
                                  ? Text(item.item)
                                  : ConstrainedBox(
                                      constraints: BoxConstraints(minWidth: 80),
                                      child: Text(item.item)),
                            ),
                            onItemTapped: (value) {
                              final dialog = AlertDialog(
                                  content: Text('${value.item} tapped!'));
                              showDialog(
                                  context: context, builder: (_) => dialog);
                            },
                            autoOpen: _autoOpen,
                            onTap: () {
                              print(1);
                            },
                          ),
                        ],
                      ),
                    )),
              ]),
            ),

            const SizedBox(height: 800),
          ])
        ],
      ),
    );
  }
}

class TestPopup extends StatefulWidget {
  const TestPopup({
    Key key,
    @required this.mirrored,
    @required this.width,
    @required this.itemsCount,
    @required this.onClose,
    @required this.animated,
    this.radius = Radius.zero,
  }) : super(key: key);

  final bool mirrored;
  final double width;
  final int itemsCount;
  final VoidCallback onClose;
  final bool animated;
  final Radius radius;

  @override
  _TestPopupState createState() => _TestPopupState(width, itemsCount);
}

class _TestPopupState extends State<TestPopup>
    with SingleTickerProviderStateMixin {
  _TestPopupState(this._width, this._itemsCount);

  double _width;
  final int _itemsCount;
  AnimationController _controller;

  void animatedClose() => _controller.animateBack(0.0);

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: _customAnimationDurationMs),
      vsync: this,
      value: widget.animated ? 0.0 : 1.0,
    );
    _controller.animateTo(1.0);
  }

  @override
  Widget build(BuildContext context) {
    final close = Ink(
      decoration: BoxDecoration(
        color: Colors.blueAccent,
        borderRadius: BorderRadius.only(
          topLeft: !widget.mirrored ? widget.radius : Radius.zero,
          topRight: !widget.mirrored ? widget.radius : Radius.zero,
          bottomLeft: widget.mirrored ? widget.radius : Radius.zero,
          bottomRight: widget.mirrored ? widget.radius : Radius.zero,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          IconButton(
            icon: Icon(Icons.close, color: Colors.white),
            onPressed: widget.onClose,
          ),
        ],
      ),
    );
    final size = Ink(
      decoration: BoxDecoration(color: Colors.blueAccent.withOpacity(0.7)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: Icon(Icons.remove, color: Colors.white),
            onPressed: () =>
                setState(() => _width = math.max(_width - 24, 108)),
          ),
          IconButton(
            icon: Icon(Icons.add, color: Colors.white),
            onPressed: () => setState(() => _width += 24),
          ),
        ],
      ),
    );
    final content = Column(
        children: Iterable.generate(_itemsCount)
            .map((_) => ListTile(title: Text('Item ${_ + 1}'), onTap: () {}))
            .toList());

    return Material(
      elevation: 4,
      borderRadius: BorderRadius.all(widget.radius),
      child: AnimatedContainer(
        width: _width,
        duration: const Duration(milliseconds: _customAnimationDurationMs),
        decoration:
            BoxDecoration(borderRadius: BorderRadius.all(widget.radius)),
        child: ScaleTransition(
          scale: _controller,
          child: Column(children: [
            if (widget.mirrored) ...[
              content,
              size,
              close
            ] else ...[
              close,
              size,
              content
            ],
          ]),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

class IntTextInputFormatter extends TextInputFormatter {
  IntTextInputFormatter({this.minValue, this.maxValue});

  final int minValue;
  final int maxValue;

  String format(String oldValue, String newValue) {
    if (newValue?.isNotEmpty != true) return '';
    if (newValue.contains('-')) return oldValue;

    var i = int.tryParse(newValue);
    if (i == null) return oldValue;
    if (minValue != null && i < minValue) i = minValue;
    if (maxValue != null && i > maxValue) i = maxValue;

    return i.toString();
  }

  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    final value = format(oldValue.text, newValue.text);
    return value != newValue.text
        ? newValue.copyWith(
            text: value,
            selection: TextSelection.collapsed(offset: value.length))
        : newValue.copyWith(text: value);
  }
}

class TextHelper {
  static String _camelToWords(String value) {
    final codes = value.runes
        .skip(1)
        .map((_) => String.fromCharCode(_))
        .map((_) => _.toUpperCase() == _ ? ' $_' : _)
        .expand((_) => _.runes);

    return value[0].toUpperCase() + String.fromCharCodes(codes);
  }

  static String enumToString(dynamic value) =>
      value == null ? '' : _camelToWords(value.toString().split('.')[1]);
}
