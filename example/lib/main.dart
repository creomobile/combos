import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui';

import 'package:combos/combos.dart';
import 'package:demo_items/demo_items.dart';
import 'package:editors/editors.dart';
import 'package:english_words/english_words.dart' as words;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

const _customAnimationDurationMs = 150;

void main() {
  if (_PlatformHelper.platform == _Platform.desktop) {
    debugDefaultTargetPlatformOverride = TargetPlatform.fuchsia;
  }
  runApp(_App());
}

class _App extends StatelessWidget {
  @override
  Widget build(BuildContext context) => MaterialApp(
        theme: ThemeData(
          highlightColor: Colors.blueAccent.withOpacity(0.1),
          splashColor: Colors.blueAccent.withOpacity(0.3),
        ),
        title: 'Combo Samples',
        home: CombosExamplePage(),
      );
}

class CombosExamplePage extends StatefulWidget {
  @override
  _CombosExamplePageState createState() => _CombosExamplePageState();
}

class _CombosExamplePageState extends State<CombosExamplePage> {
  final _comboKey = GlobalKey<ComboState>();
  final _awaitComboKey = GlobalKey<ComboState>();
  GlobalKey<_TestPopupState> _popupKey2;
  GlobalKey<_TestPopupState> _awaitPopupKey2;

  final _comboProperties = ComboProperties(withCustomAnimation: true);
  final _awaitComboProperties = AwaitComboProperties(withCustomAnimation: true);
  final _listComboProperties = ListProperties();
  final _selectorProperties = SelectorProperties();
  final _typeaheadProperties = TypeaheadProperties();
  final _menuProperties = MenuProperties();

  double _tileHeight;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _WidgetsHelper.getWidgetSize(context, const ListTile())
        .then((size) => _tileHeight = size.height);
  }

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
              _CombosDemoItem<ComboProperties>(
                properties: _comboProperties,
                childBuilder: (properties, modifiedEditor) => SizedBox(
                  width: properties.comboWidth.value?.toDouble(),
                  child: Combo(
                    key: _comboKey,
                    child: ListTile(
                        enabled: properties.enabled.value,
                        title: Text('Combo')),
                    popupBuilder: (context, mirrored) => _TestPopup(
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
              _CombosDemoItem<AwaitComboProperties>(
                properties: _awaitComboProperties,
                childBuilder: (properties, modifiedEditor) => SizedBox(
                  width: properties.comboWidth.value?.toDouble(),
                  child: AwaitCombo(
                    key: _awaitComboKey,
                    child: ListTile(
                        enabled: properties.enabled.value,
                        title: Text('Await Combo')),
                    popupBuilder: (context) async {
                      await Future.delayed(const Duration(milliseconds: 500));
                      return _TestPopup(
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
              _CombosDemoItem<ListProperties>(
                properties: _listComboProperties,
                childBuilder: (properties, modifiedEditor) => SizedBox(
                  width: properties.comboWidth.value?.toDouble(),
                  child: ComboContext(
                    parameters: ComboParameters(
                      popupContraints: properties.hasSize
                          ? null
                          : BoxConstraints(
                              maxWidth: properties.popupWidth.value.toDouble()),
                    ),
                    child: ListCombo<String>(
                      getList: () async {
                        await Future.delayed(const Duration(milliseconds: 500));
                        return Iterable.generate(properties.itemsCount.value)
                            .map((e) => 'Item ${e + 1}')
                            .toList();
                      },
                      itemBuilder: (context, parameters, item) =>
                          ListTile(title: Text(item ?? '')),
                      child: ListTile(
                          enabled: properties.enabled.value,
                          title: Text('List Combo')),
                      onItemTapped: (value) {},
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // selector
              _CombosDemoItem<SelectorProperties>(
                properties: _selectorProperties,
                childBuilder: (properties, modifiedEditor) => SizedBox(
                  width: properties.comboWidth.value?.toDouble(),
                  child: ComboContext(
                    parameters: ComboParameters(
                      popupContraints: properties.hasSize
                          ? null
                          : BoxConstraints(
                              maxWidth: properties.popupWidth.value.toDouble()),
                    ),
                    child: SelectorCombo<String>(
                      getList: () async {
                        await Future.delayed(const Duration(milliseconds: 500));
                        return Iterable.generate(properties.itemsCount.value)
                            .map((e) => 'Item ${e + 1}')
                            .toList();
                      },
                      selected: properties.selected.value,
                      itemBuilder: (context, parameters, item, selected) =>
                          PreferredSize(
                              preferredSize: Size(0, _tileHeight),
                              child: ListTile(
                                  selected: selected, title: Text(item ?? ''))),
                      childBuilder: (context, parameters, item) => ListTile(
                          enabled: properties.enabled.value,
                          title: Text(item ?? 'Selector Combo')),
                      onSelectedChanged: (value) =>
                          setState(() => properties.selected.value = value),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // typeahead
              _CombosDemoItem<TypeaheadProperties>(
                properties: _typeaheadProperties,
                childBuilder: (properties, modifiedEditor) => SizedBox(
                  width: properties.comboWidth.value?.toDouble(),
                  child: ComboContext(
                    parameters: ComboParameters(
                      inputThrottle: Duration(
                          milliseconds: properties.inputThrottleMs.value),
                      popupContraints: properties.hasSize
                          ? null
                          : BoxConstraints(
                              maxWidth: properties.popupWidth.value.toDouble()),
                    ),
                    child: TypeaheadCombo<String>(
                      getList: (text) async {
                        await Future.delayed(const Duration(milliseconds: 500));
                        return words.all
                            .where((word) =>
                                word.length > 4 &&
                                word.contains((text ?? '').toLowerCase()))
                            .take(20)
                            .toList();
                      },
                      minTextLength: properties.minTextLength.value,
                      cleanAfterSelection: properties.cleanAfterSelection.value,
                      decoration: InputDecoration(
                        labelText: 'Typeahead Combo',
                        border: OutlineInputBorder(),
                      ),
                      selected: properties.selected.value,
                      itemBuilder:
                          (context, parameters, item, selected, text) =>
                              PreferredSize(
                        preferredSize: Size(0, _tileHeight),
                        child: ListTile(
                          selected: selected,
                          title: SizedBox(
                            width: 200,
                            child: TypeaheadCombo.markText(
                              item,
                              text,
                              const TextStyle(
                                  decoration: TextDecoration.underline,
                                  decorationColor: Colors.grey),
                            ),
                          ),
                        ),
                      ),
                      getItemText: (item) => item,
                      onSelectedChanged: (value) =>
                          setState(() => properties.selected.value = value),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // menu
              _CombosDemoItem<MenuProperties>(
                properties: _menuProperties,
                childBuilder: (properties, modifiedEditor) => SizedBox(
                  width: properties.comboWidth.value?.toDouble(),
                  child: MenuItemCombo<String>(
                    itemBuilder: (context, parameters, item) => Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(item.item),
                    ),
                    onItemTapped: (value) {
                      final dialog =
                          AlertDialog(content: Text('${value.item} tapped!'));
                      showDialog(context: context, builder: (_) => dialog);
                    },
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

class _TestPopup extends StatefulWidget {
  const _TestPopup({
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

class _TestPopupState extends State<_TestPopup>
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

    return AnimatedContainer(
      width: _width,
      duration: const Duration(milliseconds: _customAnimationDurationMs),
      decoration: BoxDecoration(borderRadius: BorderRadius.all(widget.radius)),
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
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

class _CombosDemoItem<TProperties extends ComboProperties>
    extends DemoItemBase<TProperties> {
  const _CombosDemoItem({
    Key key,
    @required TProperties properties,
    @required ChildBuilder<TProperties> childBuilder,
  }) : super(key: key, properties: properties, childBuilder: childBuilder);
  @override
  _CombosDemoItemState<TProperties> createState() =>
      _CombosDemoItemState<TProperties>();
}

class _CombosDemoItemState<TProperties extends ComboProperties>
    extends DemoItemStateBase<TProperties> {
  @override
  Widget buildChild() => widget.properties.apply(child: super.buildChild());

  @override
  Widget buildProperties() {
    final editors = widget.properties.editors;
    return Theme(
      data: ThemeData(
          inputDecorationTheme:
              InputDecorationTheme(border: OutlineInputBorder())),
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        shrinkWrap: true,
        physics: ClampingScrollPhysics(),
        itemCount: editors.length,
        itemBuilder: (context, index) => editors[index].build(),
        separatorBuilder: (context, index) => const SizedBox(height: 16),
      ),
    );
  }
}

class ComboProperties {
  ComboProperties({
    bool withCustomAnimation = false,
    bool withChildDecorator = true,
    PopupPosition defaultPosition = PopupPosition.bottomMinMatch,
  })  : animation = EnumEditor<PopupAnimation>(
            title: 'Animation',
            value: PopupAnimation.fade,
            getList: () => PopupAnimation.values
                .where((e) => withCustomAnimation || e != PopupAnimation.custom)
                .toList()),
        position = EnumEditor<PopupPosition>(
            title: 'Position',
            value: defaultPosition,
            getList: () => PopupPosition.values) {
    if (!withChildDecorator) _excludes.add(useChildDecorator);
  }

  final _excludes = <EditorsBuilder>{};

  final comboWidth = IntEditor(title: 'Combo Width', value: 200);
  final popupWidth = IntEditor(title: 'Popup Width', value: 300);
  final itemsCount = IntEditor(title: 'Items Count', value: 3);
  final EnumEditor<PopupPosition> position;

  bool get hasSize =>
      position.value == PopupPosition.bottomMatch ||
      position.value == PopupPosition.topMatch;

  final offsetX = IntEditor(title: 'Offset X', value: 0);
  final offsetY = IntEditor(title: 'Offset Y', value: 0);
  final autoMirror = BoolEditor(title: 'Auto Mirror', value: true);
  final requiredSpace = IntEditor(title: 'Required Space');
  final screenPaddingHorizontal =
      IntEditor(title: 'Screen Padding X', value: 16);
  final screenPaddingVertical = IntEditor(title: 'Screen Padding Y', value: 16);
  final autoOpen = EnumEditor<ComboAutoOpen>(
      title: 'Auto Open',
      value: ComboAutoOpen.tap,
      getList: () => ComboAutoOpen.values);
  final autoClose = EnumEditor<ComboAutoClose>(
      title: 'Auto Close',
      value: ComboAutoClose.tapOutsideWithChildIgnorePointer,
      getList: () => ComboAutoClose.values);
  final enabled = BoolEditor(title: 'Enabled', value: true);
  final EnumEditor<PopupAnimation> animation;
  final animationDurationMs = IntEditor(
      title: 'Animation Duration',
      value: ComboParameters.defaultAnimationDuration.inMilliseconds);
  final useChildDecorator =
      BoolEditor(title: 'Use Custom Child Decorator', value: false);
  final usePopupDecorator =
      BoolEditor(title: 'Use Custom Popup Decorator', value: false);

  List<EditorsBuilder> get _editors => [
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
        enabled,
        animation,
        animationDurationMs,
        useChildDecorator,
        usePopupDecorator,
      ];
  List<EditorsBuilder> get editors =>
      _editors.where((e) => !_excludes.contains(e)).toList();
}

class AwaitComboProperties extends ComboProperties {
  AwaitComboProperties({
    bool withCustomAnimation = false,
    PopupPosition defaultPosition = PopupPosition.bottomMinMatch,
  }) : super(
          withCustomAnimation: withCustomAnimation,
          defaultPosition: defaultPosition,
        );

  final refreshOnOpened = BoolEditor(title: 'Refresh On Opened', value: false);
  final progressPosition = EnumEditor<ProgressPosition>(
      title: 'Progress Position',
      getList: () => ProgressPosition.values,
      value: ProgressPosition.popup);

  @override
  List<EditorsBuilder> get editors =>
      [refreshOnOpened, progressPosition, ...super.editors];
}

class ListProperties extends AwaitComboProperties {
  ListProperties({PopupPosition defaultPosition = PopupPosition.bottomMinMatch})
      : super(defaultPosition: defaultPosition);
}

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
  List<EditorsBuilder> get editors => [selected, ...super.editors];
}

class TypeaheadProperties extends SelectorProperties {
  TypeaheadProperties() {
    _excludes.addAll([autoOpen, autoClose, refreshOnOpened, useChildDecorator]);
  }

  final minTextLength =
      IntEditor(title: 'Min Text Length', minValue: 0, value: 1);
  final inputThrottleMs =
      IntEditor(title: 'Throttle (ms)', minValue: 0, value: 300);
  final cleanAfterSelection =
      BoolEditor(title: 'Clean After Selection', value: false);

  @override
  List<EditorsBuilder> get editors => [
        minTextLength,
        inputThrottleMs,
        cleanAfterSelection,
        ...super.editors,
      ];
}

class MenuProperties extends ListProperties {
  MenuProperties() : super(defaultPosition: PopupPosition.bottomMatch);
  final showArrows = BoolEditor(title: 'Show Arrows', value: true);
  final canTapOnFolder = BoolEditor(title: 'Can Tap On Folder', value: false);
  final menuRefreshOnOpened =
      BoolEditor(title: 'Menu Refresh On Opened', value: false);
  final menuProgressPosition = EnumEditor<ProgressPosition>(
      title: 'Menu Progress Position',
      getList: () => ProgressPosition.values,
      value: ProgressPosition.child);
  @override
  List<EditorsBuilder> get editors => [
        showArrows,
        canTapOnFolder,
        menuRefreshOnOpened,
        menuProgressPosition,
        ...super.editors.where((e) => e != useChildDecorator)
      ];
}

extension ComboPropertiesExtension on ComboProperties {
  static Widget _buildChildDecoration(
          BuildContext context,
          ComboParameters parameters,
          ComboController controller,
          Widget child) =>
      Container(
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          clipBehavior: Clip.antiAlias,
          child: child,
        ),
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.blueAccent),
          borderRadius: BorderRadius.circular(16),
        ),
      );
  static Widget _buildPopupDecoration(
          BuildContext context,
          ComboParameters parameters,
          ComboController controller,
          Widget child) =>
      Material(
        elevation: 4,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.blueAccent),
            gradient: LinearGradient(colors: [
              Colors.blueAccent.withOpacity(0.1),
              Colors.blueAccent.withOpacity(0.0),
              Colors.blueAccent.withOpacity(0.1),
            ]),
          ),
          child: Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(16),
              clipBehavior: Clip.antiAlias,
              child: Theme(
                  data: ThemeData(
                    highlightColor: Colors.blueAccent.withOpacity(0.1),
                    splashColor: Colors.blueAccent.withOpacity(0.3),
                  ),
                  child: child)),
        ),
      );

  Widget apply({
    @required Widget child,
    ComboDecoratorBuilder popupDecoratorBuilder = _buildPopupDecoration,
  }) {
    final AwaitComboProperties awaitProperties =
        this is AwaitComboProperties ? this : null;
    final MenuProperties menuProperties = this is MenuProperties ? this : null;
    return ComboContext(
        parameters: ComboParameters(
          position: position.value,
          offset: Offset(
            offsetX.value?.toDouble(),
            offsetY.value?.toDouble(),
          ),
          autoMirror: autoMirror.value,
          screenPadding: EdgeInsets.symmetric(
            horizontal: screenPaddingHorizontal.value.toDouble(),
            vertical: screenPaddingVertical.value.toDouble(),
          ),
          autoOpen: autoOpen.value,
          autoClose: autoClose.value,
          enabled: enabled.value,
          animation: animation.value,
          animationDuration: Duration(milliseconds: animationDurationMs.value),
          childContentDecoratorBuilder:
              useChildDecorator.value ? _buildChildDecoration : null,
          childDecoratorBuilder: useChildDecorator.value
              ? (context, parameters, opened, child) => Material(
                  borderRadius: BorderRadius.circular(16),
                  clipBehavior: Clip.antiAlias,
                  child: child)
              : null,
          popupDecoratorBuilder:
              usePopupDecorator.value ? popupDecoratorBuilder : null,
          refreshOnOpened: awaitProperties?.refreshOnOpened?.value ?? false,
          progressPosition: awaitProperties?.progressPosition?.value ??
              ProgressPosition.popup,
          menuPopupDecoratorBuilder:
              usePopupDecorator.value ? popupDecoratorBuilder : null,
          menuShowArrows: menuProperties?.showArrows?.value,
          menuCanTapOnFolder: menuProperties?.canTapOnFolder?.value,
          menuRefreshOnOpened: menuProperties?.menuRefreshOnOpened?.value,
          menuProgressPosition: menuProperties?.menuProgressPosition?.value,
        ),
        child: child);
  }
}

class _WidgetsHelper {
  static Future<Size> getWidgetSize(BuildContext context, Widget widget) {
    final completer = Completer<Size>();
    SchedulerBinding.instance.addPostFrameCallback((_) {
      OverlayEntry entry;
      entry = OverlayEntry(
          builder: (context) => Center(
                child: Builder(builder: (context) {
                  SchedulerBinding.instance.addPostFrameCallback((_) {
                    completer.complete(context.size);
                    entry.remove();
                  });
                  return Opacity(opacity: 0.0, child: Material(child: widget));
                }),
              ));
      Overlay.of(context).insert(entry);
    });
    return completer.future;
  }
}

enum _Platform { mobile, web, desktop }

class _PlatformHelper {
  static _Platform _platform;
  static _Platform get platform => _platform ??= kIsWeb
      ? _Platform.web
      : Platform.isAndroid || Platform.isIOS
          ? _Platform.mobile
          : _Platform.desktop;
}
