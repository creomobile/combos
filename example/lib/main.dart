import 'dart:math' as math;

import 'package:combos/combos.dart';
import 'package:demo_items/demo_items.dart';
import 'package:editors/editors.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

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
  GlobalKey<_TestPopupState> _popupKey2;
  GlobalKey<_TestPopupState> _awaitPopupKey2;

  final _comboProperties = ComboProperties();
  final _awaitComboProperties = AwaitComboProperties();
  final _listComboProperties = ListProperties();
  final _selectorProperties = SelectorProperties();
  final _typeaheadProperties = TypeaheadProperties();
  final _menuProperties = MenuProperties();

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: Text('Combo Samples'),
        ),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Column(crossAxisAlignment: CrossAxisAlignment.center, children: [
              // combo
              DemoItem<ComboProperties>(
                properties: _comboProperties,
                childBuilder: (properties) => SizedBox(
                  width: properties.comboWidth.value?.toDouble(),
                  child: Combo(
                    key: _comboKey,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text('Combo'),
                    ),
                    popupBuilder: (context, mirrored) => TestPopup(
                      key: _popupKey2 = GlobalKey<_TestPopupState>(),
                      mirrored: mirrored,
                      animated:
                          properties.animation.value == PopupAnimation.custom,
                      itemsCount: properties.itemsCount.value ?? 0,
                      onClose: () => _comboKey.currentState.close(),
                      width: properties.popupWidth.value?.toDouble(),
                    ),
                    openedChanged: (isOpened) {
                      if (!isOpened &&
                          properties.animation.value == PopupAnimation.custom) {
                        _popupKey2.currentState?.animatedClose();
                      }
                    },
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // await combo
              DemoItem<AwaitComboProperties>(
                properties: _awaitComboProperties,
                childBuilder: (properties) => SizedBox(
                  width: properties.comboWidth.value?.toDouble(),
                  child: AwaitCombo(
                    key: _awaitComboKey,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text('Await Combo'),
                    ),
                    popupBuilder: (context) async {
                      await Future.delayed(const Duration(milliseconds: 500));
                      return TestPopup(
                        key: _awaitPopupKey2 = GlobalKey<_TestPopupState>(),
                        mirrored: false,
                        animated:
                            properties.animation.value == PopupAnimation.custom,
                        itemsCount: properties.itemsCount.value ?? 0,
                        onClose: () => _awaitComboKey.currentState.close(),
                        width: properties.popupWidth.value?.toDouble(),
                      );
                    },
                    openedChanged: (isOpened) {
                      if (!isOpened &&
                          properties.animation.value == PopupAnimation.custom) {
                        _awaitPopupKey2.currentState?.animatedClose();
                      }
                    },
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // list
              DemoItem<ListProperties>(
                properties: _listComboProperties,
                childBuilder: (properties) => SizedBox(
                  width: properties.comboWidth.value?.toDouble(),
                  child: ListCombo<String>(
                    getList: () async {
                      await Future.delayed(const Duration(milliseconds: 500));
                      return Iterable.generate(properties.itemsCount.value)
                          .map((e) => 'Item ${e + 1}')
                          .toList();
                    },
                    itemBuilder: (context, item) =>
                        ListTile(title: Text(item ?? '')),
                    child: const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text('List Combo'),
                    ),
                    onItemTapped: (value) {},
                    popupBuilder: properties.position.value ==
                                PopupPosition.bottomMatch ||
                            properties.position.value == PopupPosition.topMatch
                        ? null
                        : (context, list, itemBuilder, onItemTapped, parameters,
                                mirrored, getIsSelectable) =>
                            ListPopup<String>(
                                list: list,
                                itemBuilder: itemBuilder,
                                onItemTapped: onItemTapped,
                                parameters: parameters,
                                width: properties.popupWidth.value.toDouble(),
                                getIsSelectable: getIsSelectable),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // selector
              DemoItem<SelectorProperties>(
                properties: _selectorProperties,
                childBuilder: (properties) => SizedBox(
                  width: properties.comboWidth.value?.toDouble(),
                  child: SelectorCombo<String>(
                    getList: () async {
                      await Future.delayed(const Duration(milliseconds: 500));
                      return Iterable.generate(properties.itemsCount.value)
                          .map((e) => 'Item ${e + 1}')
                          .toList();
                    },
                    selected: properties.selected.value,
                    itemBuilder: (context, item) =>
                        ListTile(title: Text(item ?? '')),
                    childBuilder: (context, item) =>
                        ListTile(title: Text(item ?? 'Selector Combo')),
                    onItemTapped: (value) =>
                        setState(() => properties.selected.value = value),
                    popupBuilder: properties.position.value ==
                                PopupPosition.bottomMatch ||
                            properties.position.value == PopupPosition.topMatch
                        ? null
                        : (context, list, itemBuilder, onItemTapped, parameters,
                                mirrored, getIsSelectable) =>
                            ListPopup<String>(
                                list: list,
                                itemBuilder: itemBuilder,
                                onItemTapped: onItemTapped,
                                parameters: parameters,
                                width: properties.popupWidth.value.toDouble(),
                                getIsSelectable: getIsSelectable),
                  ),
                ),
              ),

              // typeahead
              DemoItem<TypeaheadProperties>(
                properties: _typeaheadProperties,
                childBuilder: (properties) => SizedBox(
                  width: properties.comboWidth.value?.toDouble(),
                  child: TypeaheadCombo<String>(
                    getList: (text) async {
                      await Future.delayed(const Duration(milliseconds: 500));
                      return Iterable.generate(properties.itemsCount.value)
                          .map((e) => 'Item ${e + 1}')
                          .toList();
                    },
                    enabled: properties.enabled.value,
                    minTextLength: properties.minTextLength.value,
                    delay: Duration(milliseconds: properties.delayMs.value),
                    cleanAfterSelection: properties.cleanAfterSelection.value,
                    decoration: InputDecoration(labelText: 'Typeahead Combo'),
                    selected: properties.selected.value,
                    itemBuilder: (context, item) =>
                        ListTile(title: Text(item ?? '')),
                    getItemText: (item) => item,
                    onItemTapped: (value) =>
                        setState(() => properties.selected.value = value),
                    popupBuilder: properties.position.value ==
                                PopupPosition.bottomMatch ||
                            properties.position.value == PopupPosition.topMatch
                        ? null
                        : (context, list, itemBuilder, onItemTapped, parameters,
                                mirrored, getIsSelectable) =>
                            ListPopup<String>(
                                list: list,
                                itemBuilder: itemBuilder,
                                onItemTapped: onItemTapped,
                                parameters: parameters,
                                width: properties.popupWidth.value.toDouble(),
                                getIsSelectable: getIsSelectable),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // menu
              DemoItem<MenuProperties>(
                properties: _menuProperties,
                childBuilder: (properties) => SizedBox(
                  width: properties.comboWidth.value?.toDouble(),
                  child: MenuItemCombo<String>(
                    itemBuilder: (context, item) => Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(item.item),
                    ),
                    onItemTapped: (value) {
                      final dialog =
                          AlertDialog(content: Text('${value.item} tapped!'));
                      showDialog(context: context, builder: (_) => dialog);
                    },
                    showSubmenuArrows: properties.showSubmenuArrows.value,
                    canTapOnFolder: properties.canTapOnFolder.value,
                    item: MenuItem(
                        'Menu Item Combo',
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
                                        MenuItem('Documents', () async {
                                          await Future.delayed(
                                              Duration(milliseconds: 500));
                                          return [];
                                        }),
                                      ]),
                              MenuItem.separator,
                              MenuItem('Exit'),
                            ]),
                  ),
                ),
              ),
            ]),
          ],
        ),
      );
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

class DemoItem<TProperties extends ComboProperties>
    extends DemoItemBase<TProperties> {
  const DemoItem({
    Key key,
    @required TProperties properties,
    @required ChildBuilder<TProperties> childBuilder,
  }) : super(key: key, properties: properties, childBuilder: childBuilder);
  @override
  DemoItemState<TProperties> createState() => DemoItemState<TProperties>();
}

class DemoItemState<TProperties extends ComboProperties>
    extends DemoItemStateBase<TProperties> {
  @override
  Widget buildChild() {
    final properties = widget.properties;
    final AwaitComboProperties awaitProperties =
        properties is AwaitComboProperties ? properties : null;
    return ComboContext(
        parameters: ComboParameters(
          position: properties.position.value,
          offset: Offset(
            properties.offsetX.value?.toDouble(),
            properties.offsetY.value?.toDouble(),
          ),
          autoMirror: properties.autoMirror.value,
          screenPadding: EdgeInsets.symmetric(
            horizontal: properties.screenPaddingHorizontal.value.toDouble(),
            vertical: properties.screenPaddingVertical.value.toDouble(),
          ),
          autoOpen: properties.autoOpen.value,
          autoClose: properties.autoClose.value,
          animation: properties.animation.value,
          refreshOnOpened: awaitProperties?.refreshOnOpened?.value ?? false,
          progressPosition: awaitProperties?.progressPosition?.value ??
              ProgressPosition.popup,
        ),
        child: super.buildChild());
  }

  @override
  Widget buildProperties() {
    final editors = widget.properties.editors;
    return EditorsContext(
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        shrinkWrap: true,
        physics: ClampingScrollPhysics(),
        itemCount: editors.length,
        itemBuilder: (context, index) => editors[index].build(),
        separatorBuilder: (context, index) => const SizedBox(height: 8),
      ),
    );
  }
}

class ComboProperties {
  final comboWidth = IntEditor(title: 'Combo Width', value: 200);
  final popupWidth = IntEditor(title: 'Popup Width', value: 300);
  final itemsCount = IntEditor(title: 'Items Count', value: 3);
  final position = EnumEditor<PopupPosition>(
      title: 'Position',
      value: PopupPosition.bottomMinMatch,
      getList: () => PopupPosition.values);
  final offsetX = IntEditor(title: 'Offset X', value: 0);
  final offsetY = IntEditor(title: 'Offset Y', value: 0);
  final autoMirror = BoolEditor(title: 'Auto Mirror', value: true);
  final requiredSpace = IntEditor(title: 'Req. Space');
  final screenPaddingHorizontal = IntEditor(title: 'S. Padding X', value: 16);
  final screenPaddingVertical = IntEditor(title: 'S. Padding Y', value: 16);
  final autoOpen = EnumEditor<ComboAutoOpen>(
      title: 'Auto Open',
      value: ComboAutoOpen.tap,
      getList: () => ComboAutoOpen.values);
  final autoClose = EnumEditor<ComboAutoClose>(
      title: 'Auto Close',
      value: ComboAutoClose.tapOutsideWithChildIgnorePointer,
      getList: () => ComboAutoClose.values);
  final animation = EnumEditor<PopupAnimation>(
      title: 'Animation',
      value: PopupAnimation.fade,
      getList: () => PopupAnimation.values);
  final animationDurationMs = IntEditor(
      title: 'A. Duration',
      value: ComboParameters.defaultAnimationDuration.inMilliseconds);

  List<Editor> get editors => [
        comboWidth,
        popupWidth,
        itemsCount,
        position,
        offsetX,
        offsetY,
        autoMirror,
        requiredSpace,
        screenPaddingHorizontal,
        screenPaddingVertical,
        autoOpen,
        autoClose,
        animation,
        animationDurationMs,
      ];
}

class AwaitComboProperties extends ComboProperties {
  final refreshOnOpened = BoolEditor(title: 'Refresh On Opened', value: false);
  final progressPosition = EnumEditor<ProgressPosition>(
      title: 'Progress Position',
      getList: () => ProgressPosition.values,
      value: ProgressPosition.popup);

  @override
  List<Editor> get editors =>
      [refreshOnOpened, progressPosition, ...super.editors];
}

class ListProperties extends AwaitComboProperties {}

class SelectorProperties extends ListProperties {
  SelectorProperties() {
    _selected = EnumEditor<String>(
        title: 'Selected',
        getList: () => Iterable.generate(itemsCount.value)
            .map((e) => 'Item ${e + 1}')
            .toList());
  }

  EnumEditor<String> _selected;
  EnumEditor<String> get selected => _selected;

  @override
  List<Editor> get editors => [selected, ...super.editors];
}

class TypeaheadProperties extends SelectorProperties {
  TypeaheadProperties() {
    _excludes = {autoOpen, autoClose, refreshOnOpened};
  }
  Set<Editor> _excludes;

  final enabled = BoolEditor(title: 'Enabled', value: true);
  final minTextLength =
      IntEditor(title: 'Min Text Length', minValue: 0, value: 1);
  final delayMs = IntEditor(title: 'Delay (ms)', minValue: 0, value: 300);
  final cleanAfterSelection =
      BoolEditor(title: 'Clean After Selection', value: false);

  @override
  List<Editor> get editors => [
        enabled,
        minTextLength,
        delayMs,
        cleanAfterSelection,
        ...super.editors.where((e) => !_excludes.contains(e))
      ];
}

class MenuProperties extends ListProperties {
  final showSubmenuArrows =
      BoolEditor(title: 'Show Submenu Arrows', value: true);
  final canTapOnFolder = BoolEditor(title: 'Can Tap On Folder', value: false);

  @override
  List<Editor> get editors =>
      [showSubmenuArrows, canTapOnFolder, ...super.editors];
}
