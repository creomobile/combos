library combos;

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:pedantic/pedantic.dart';

const _defaultAnimationDuration = Duration(milliseconds: 150);

enum PopupWidthConstraints { matchWidth, minMatchWidth, customWidth }

enum PopupAutoClose {
  none,
  tapDown,
  tapDownWithChildIgnorePointer,
  tapDownExceptChild
}

typedef PopupBuilder = Widget Function(BuildContext context, bool isAbove);

class Combo extends StatefulWidget {
  const Combo({
    Key key,
    this.child,
    this.popupBuilder,
    this.popupWidthConstraints = PopupWidthConstraints.minMatchWidth,
    this.popupAutoClose = PopupAutoClose.tapDownWithChildIgnorePointer,
    this.overlap = false,
    this.showAbove = true,
    this.animatedOpen = true,
    this.openingAnimationDuration = _defaultAnimationDuration,
    this.animatedClose = true,
    this.closingAnimationDuration = _defaultAnimationDuration,
    this.customAnimation = false,
    this.requiredUnderHeight,
    this.openedChanged,
  }) : super(key: key);

  final Widget child;
  final PopupBuilder popupBuilder;
  final PopupWidthConstraints popupWidthConstraints;
  final PopupAutoClose popupAutoClose;
  final bool overlap;
  final bool showAbove;
  final bool animatedOpen;
  final Duration openingAnimationDuration;
  final bool animatedClose;
  final Duration closingAnimationDuration;
  final bool customAnimation;
  final double requiredUnderHeight;
  final ValueChanged<bool> openedChanged;

  static void closeAll() => ComboState._closes.add(true);

  @override
  ComboState createState() => ComboState();
}

class ComboState extends State<Combo> {
  // ignore: close_sinks
  static final _closes = StreamController.broadcast();
  final _scrolls = StreamController.broadcast();
  final _layerLink = LayerLink();
  OverlayEntry _overlay;
  StreamSubscription _subscription;
  Completer<double> _closeCompleter;

  @override
  void initState() {
    super.initState();
    _subscription = _closes.stream.listen((_) => close());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    Scrollable.of(context)?.widget?.controller?.addListener(() {
      if (_overlay != null) _scrolls.add(true);
    });
  }

  Widget get child => widget.child;
  PopupBuilder get popupBuilder => widget.popupBuilder;
  bool get opened => _overlay != null;

  void open() {
    if (_overlay != null || popupBuilder == null) return;
    if (widget.openedChanged != null) widget.openedChanged(true);
    if (widget.animatedClose) _closeCompleter = Completer();
    _overlay = _createOverlay();
    Overlay.of(context).insert(_overlay);
    setState(() {});
  }

  void close() async {
    if (_overlay == null) return;
    final overlay = _overlay;
    _overlay = null;
    if (widget.animatedClose) _closeCompleter?.complete(0.0);
    if (widget.openedChanged != null) widget.openedChanged(false);
    if (widget.animatedClose || widget.customAnimation) {
      await Future.delayed(
          widget.closingAnimationDuration + Duration(milliseconds: 1));
    }
    overlay.remove();
    setState(() {});
  }

  OverlayEntry _createOverlay() => OverlayEntry(builder: (context) {
        final RenderBox renderBox = this.context.findRenderObject();
        final size = renderBox.size;
        final screenSize = MediaQuery.of(context).size;
        final requiredHeight =
            widget.requiredUnderHeight ?? screenSize.height / 3;
        var lastOffset = Offset.zero;

        // ! workaround: https://github.com/flutter/flutter/issues/50800
        final sizeCompleter = Completer<Offset>();

        final overlay = StreamBuilder(
            stream: _scrolls.stream,
            builder: (context, snapshot) {
              final offset = mounted
                  ? lastOffset = renderBox.localToGlobal(Offset.zero)
                  : lastOffset;
              final isAbove = widget.showAbove &&
                  screenSize.height -
                          (offset.dy + (widget.overlap ? 0 : size.height)) <
                      requiredHeight;

              var popup = popupBuilder(context, isAbove);

              switch (widget.popupWidthConstraints) {
                case PopupWidthConstraints.matchWidth:
                  popup = SizedBox(width: size.width, child: popup);
                  break;
                case PopupWidthConstraints.minMatchWidth:
                  popup = ConstrainedBox(
                      constraints: BoxConstraints(minWidth: size.width),
                      child: popup);
                  break;
                default:
                  break;
              }

              return Stack(
                key: ValueKey(screenSize),
                children: [
                  if (widget.popupAutoClose != PopupAutoClose.none)
                    GestureDetector(onPanDown: (_) {
                      if (widget.popupAutoClose !=
                              PopupAutoClose.tapDownExceptChild ||
                          !renderBox.hitTest(BoxHitTestResult(),
                              position:
                                  renderBox.globalToLocal(_.globalPosition))) {
                        close();
                      }
                    }),
                  FutureBuilder<Offset>(
                      future: sizeCompleter.future,
                      builder: (context, snapshot) {
                        return Positioned(
                          top: snapshot.data?.dy,
                          left: snapshot.data?.dx,
                          child: _DynamicTransformFollower(
                            key: ValueKey(isAbove),
                            link: _layerLink,
                            showWhenUnlinked: false,
                            offsetBuilder: (popupSize) {
                              final dx = widget.popupWidthConstraints ==
                                      PopupWidthConstraints.matchWidth
                                  ? 0.0
                                  : math.min(
                                      0.0,
                                      screenSize.width -
                                          offset.dx -
                                          popupSize.width);
                              final dy = isAbove
                                  ? (widget.overlap ? size.height : 0.0) -
                                      popupSize.height
                                  : widget.overlap ? 0 : size.height;

                              if (!sizeCompleter.isCompleted) {
                                sizeCompleter.complete(Offset(dx, dy));
                              }

                              return Offset(dx, dy);
                            },
                            child: widget.animatedOpen
                                ? popup
                                : Opacity(
                                    opacity: snapshot.data == null ? 0.01 : 1.0,
                                    child: popup),
                          ),
                        );
                      }),
                ],
              );
            });

        Widget animate(double from, Future<double> to, Widget child) =>
            FutureBuilder<double>(
              initialData: from,
              future: to,
              builder: (context, snapshot) => IgnorePointer(
                ignoring: snapshot.data != 1.0,
                child: AnimatedOpacity(
                  opacity: snapshot.data,
                  duration: widget.openingAnimationDuration,
                  child: child,
                ),
              ),
            );

        final openAnimated = widget.animatedOpen
            ? animate(0.01, sizeCompleter.future.then((_) => 1.0), overlay)
            : overlay;
        final closeAnimated = widget.animatedClose && _closeCompleter != null
            ? animate(1.0, _closeCompleter.future, openAnimated)
            : openAnimated;

        return closeAnimated;
      });

  @override
  Widget build(BuildContext context) => CompositedTransformTarget(
      link: _layerLink,
      child: IgnorePointer(
          ignoring: widget.popupAutoClose ==
                  PopupAutoClose.tapDownWithChildIgnorePointer &&
              _overlay != null,
          child: child ?? Container()));

  @override
  void dispose() {
    close();
    _scrolls.close();
    _subscription.cancel();
    super.dispose();
  }
}

typedef _OffsetBuilder = Offset Function(Size childSize);

class _DynamicTransformFollower extends CompositedTransformFollower {
  const _DynamicTransformFollower({
    Key key,
    @required LayerLink link,
    bool showWhenUnlinked = true,
    @required this.offsetBuilder,
    Widget child,
  }) : super(
          key: key,
          link: link,
          showWhenUnlinked: showWhenUnlinked,
          child: child,
        );

  final _OffsetBuilder offsetBuilder;

  @override
  _DynamicRenderFollowerLayer createRenderObject(BuildContext context) =>
      _DynamicRenderFollowerLayer(
          link: link,
          showWhenUnlinked: showWhenUnlinked,
          offsetBuilder: offsetBuilder);
}

class _DynamicRenderFollowerLayer extends RenderFollowerLayer {
  _DynamicRenderFollowerLayer({
    @required LayerLink link,
    bool showWhenUnlinked = true,
    @required this.offsetBuilder,
    RenderBox child,
  }) : super(
          link: link,
          showWhenUnlinked: showWhenUnlinked,
          child: child,
        );

  final _OffsetBuilder offsetBuilder;

  @override
  Offset get offset => offsetBuilder(child.size);
}

class HoverCombo extends Combo {
  const HoverCombo({
    Key key,
    @required Widget child,
    PopupBuilder popupBuilder,
    PopupWidthConstraints horizontalBehavior =
        PopupWidthConstraints.minMatchWidth,
    bool overlap = false,
    bool showAbove = true,
    bool animatedOpen = true,
    Duration openingAnimationDuration = _defaultAnimationDuration,
    bool animatedClose = true,
    Duration closingAnimationDuration = _defaultAnimationDuration,
    bool customAnimation = false,
    double requiredHeight,
    ValueChanged<bool> openedChanged,
    this.onTap,
    this.highlightColor,
    this.splashColor,
    this.hoverColor,
    this.focusColor,
  }) : super(
          key: key,
          child: child,
          popupBuilder: popupBuilder,
          popupWidthConstraints: horizontalBehavior,
          popupAutoClose: kIsWeb ? PopupAutoClose.none : PopupAutoClose.tapDown,
          overlap: overlap,
          showAbove: showAbove,
          animatedOpen: animatedOpen,
          openingAnimationDuration: openingAnimationDuration,
          animatedClose: animatedClose,
          closingAnimationDuration: closingAnimationDuration,
          customAnimation: customAnimation,
          requiredUnderHeight: requiredHeight,
          openedChanged: openedChanged,
        );

  final GestureTapCallback onTap;
  final Color highlightColor;
  final Color splashColor;
  final Color hoverColor;
  final Color focusColor;

  static var _blockCounter = 0;
  static void blockOpenOnHover() => _blockCounter++;
  static void unblockOpenOnHover() =>
      _blockCounter = math.max(0, _blockCounter - 1);
  static void unblockAllOpenOnHover() => _blockCounter = 0;

  @override
  _HoverComboState createState() => _HoverComboState();
}

class _HoverComboState extends ComboState {
  var _hovered = false;

  void _setHovered(bool value) async {
    if (value == _hovered || !mounted) return;
    _hovered = value;
    if (value) {
      if (!opened && HoverCombo._blockCounter == 0) open();
    } else {
      await Future.delayed(const Duration(milliseconds: 50));
      if (!_hovered && opened) close();
    }
  }

  @override
  HoverCombo get widget => super.widget;

  @override
  Widget get child => widget.onTap == null
      ? super.popupBuilder != null && kIsWeb
          ? MouseRegion(
              onEnter: (_) => _setHovered(true),
              onExit: (_) => _setHovered(false),
              child: super.child)
          : super.child
      : InkWell(
          onHover: super.popupBuilder != null && kIsWeb
              ? (_) => _setHovered(_)
              : null,
          child: super.child,
          highlightColor: widget.highlightColor,
          splashColor: widget.splashColor,
          hoverColor: widget.hoverColor,
          focusColor: widget.focusColor,
          onTap: kIsWeb ? widget.onTap : open,
          onLongPress: kIsWeb ? null : widget.onTap,
        );

  @override
  PopupBuilder get popupBuilder => super.popupBuilder == null
      ? null
      : (context, isAbove) => MouseRegion(
            onEnter: (_) => _setHovered(true),
            onExit: (_) => _setHovered(false),
            child: super.popupBuilder(context, isAbove),
          );
}

typedef GetItems<T> = FutureOr<List<T>> Function();
typedef ItemBuilder<T> = Widget Function(BuildContext context, T item);
typedef ItemsDecoratorBuilder<T> = Widget Function(
    BuildContext context, bool isAbove, List<T> list, Widget items);

const Widget defaultEmptyMessage = Padding(
  padding: EdgeInsets.all(16),
  child: Text(
    'No Items',
    textAlign: TextAlign.center,
    style: TextStyle(color: Colors.grey),
  ),
);

class ListCombo<T> extends Combo {
  const ListCombo({
    Key key,
    @required this.getItems,
    @required this.buildItem,
    @required this.onItemTapped,
    this.autoOpen = true,
    this.refreshListOnOpened = false,
    this.emptyMessage = defaultEmptyMessage,
    this.buildItemsDecorator,
    this.popupWidth,
    this.popupMaxHeight = 300,
    this.highlightColor,
    this.splashColor,
    this.hoverColor,
    this.focusColor,
    Widget child,
    PopupAutoClose popupAutoClose =
        PopupAutoClose.tapDownWithChildIgnorePointer,
    bool overlap = false,
    bool showAbove = true,
    bool animatedOpen = true,
    Duration openingAnimationDuration = _defaultAnimationDuration,
    bool animatedClose = true,
    Duration closingAnimationDuration = _defaultAnimationDuration,
    bool customAnimation = false,
    bool closeOnTapOver = true,
    double requiredUnderHeight,
    ValueChanged<bool> openedChanged,
  }) : super(
          key: key,
          child: child,
          popupWidthConstraints: popupWidth == null
              ? PopupWidthConstraints.matchWidth
              : PopupWidthConstraints.customWidth,
          popupAutoClose: popupAutoClose,
          overlap: overlap,
          showAbove: showAbove,
          animatedOpen: animatedOpen,
          openingAnimationDuration: openingAnimationDuration,
          animatedClose: animatedClose,
          closingAnimationDuration: closingAnimationDuration,
          customAnimation: customAnimation,
          requiredUnderHeight: requiredUnderHeight,
          openedChanged: openedChanged,
        );

  final GetItems<T> getItems;
  final ItemBuilder<T> buildItem;
  final ValueChanged<T> onItemTapped;
  final bool autoOpen;
  final bool refreshListOnOpened;
  final Widget emptyMessage;
  final ItemsDecoratorBuilder buildItemsDecorator;
  final double popupWidth;
  final double popupMaxHeight;
  final Color highlightColor;
  final Color splashColor;
  final Color hoverColor;
  final Color focusColor;

  @override
  ListComboState<T> createState() => ListComboState<T>();
}

class ListComboState<T> extends ComboState {
  final _scrollController = ScrollController();
  List<T> _items;
  List<T> get items => _items;
  final _itemsController = StreamController<List<T>>.broadcast();
  var _inProgressCount = 0;
  final _inProgressController = StreamController<int>.broadcast();
  DateTime _lastTimestamp;

  @override
  ListCombo<T> get widget => super.widget;

  void itemTapped(T value) {
    if (widget.onItemTapped != null) {
      widget.onItemTapped(value);
    }
  }

  FutureOr getItems() => widget.getItems();

  void fillItems() async {
    final timestamp = _lastTimestamp = DateTime.now();
    List<T> items;
    final future = getItems();
    super.open();
    unawaited((() async => items = await future)());
    if (items == null) {
      try {
        _inProgressController.add(++_inProgressCount);
        await future;
      } catch (e) {
        return;
      } finally {
        _inProgressController.add(--_inProgressCount);
      }
    }
    if (items != null && _lastTimestamp == timestamp) {
      _itemsController.add(_items = items);
      await _scrollController.animateTo(0,
          duration: const Duration(milliseconds: 1), curve: Curves.linear);
    }
  }

  void clearItems() => _items = null;

  @override
  void open({bool refresh = false}) {
    if (refresh || _items == null) {
      fillItems();
    } else {
      super.open();
    }
  }

  Widget buildChild() => super.child;

  @override
  Widget get child => widget.autoOpen
      ? InkWell(
          highlightColor: widget.highlightColor,
          splashColor: widget.splashColor,
          hoverColor: widget.hoverColor,
          focusColor: widget.focusColor,
          child: buildChild(),
          onTap: () => open(refresh: widget.refreshListOnOpened))
      : buildChild();

  @override
  PopupBuilder get popupBuilder => (context, isAbove) {
        final items = StreamBuilder<int>(
          initialData: _inProgressCount,
          stream: _inProgressController.stream,
          builder: (context, snapshot) {
            final inProgress = snapshot.data != 0;
            return ConstrainedBox(
              constraints: BoxConstraints(
                  maxHeight: widget.popupMaxHeight,
                  maxWidth: widget.popupWidth ?? double.infinity),
              child: Stack(children: [
                StreamBuilder<List<T>>(
                  initialData: _items,
                  stream: _itemsController.stream,
                  builder: (context, snapshot) => snapshot.data?.isEmpty == true
                      ? Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [widget.emptyMessage],
                        )
                      : ListView.builder(
                          shrinkWrap: true,
                          controller: _scrollController,
                          physics: ClampingScrollPhysics(),
                          itemCount: snapshot.data?.length ?? 0,
                          itemBuilder: (context, index) {
                            final item = snapshot.data[index];
                            return InkWell(
                              child: widget.buildItem(context, item),
                              onTap: () {
                                itemTapped(item);
                                super.close();
                              },
                            );
                          }),
                ),
                const SizedBox(height: 2),
                if (inProgress)
                  Positioned.fill(
                      child: Align(
                    alignment:
                        isAbove ? Alignment.bottomCenter : Alignment.topCenter,
                    child:
                        SizedBox(height: 2, child: LinearProgressIndicator()),
                  )),
              ]),
            );
          },
        );
        return widget.buildItemsDecorator == null
            ? Material(elevation: 4, child: items)
            : widget.buildItemsDecorator(context, isAbove, _items, items);
      };

  @override
  void dispose() {
    super.dispose();
    _scrollController.dispose();
    _itemsController.close();
    _inProgressController.close();
  }
}

class SelectorCombo<T> extends ListCombo<T> {
  const SelectorCombo({
    Key key,
    @required this.selected,
    this.buildChild,
    @required GetItems<T> getItems,
    @required ItemBuilder<T> buildItem,
    @required ValueChanged<T> onItemTapped,
    bool autoOpen = true,
    bool refreshListOnOpened = false,
    Widget emptyMessage = defaultEmptyMessage,
    ItemsDecoratorBuilder buildItemsDecorator,
    double popupWidth,
    double popupMaxHeight = 300,
    Color highlightColor,
    Color splashColor,
    Color hoverColor,
    Color focusColor,
    PopupAutoClose popupAutoClose =
        PopupAutoClose.tapDownWithChildIgnorePointer,
    bool overlap = false,
    bool showAbove = true,
    bool animatedOpen = true,
    Duration openingAnimationDuration = _defaultAnimationDuration,
    bool animatedClose = true,
    Duration closingAnimationDuration = _defaultAnimationDuration,
    bool customAnimation = false,
    bool closeOnTapOver = true,
    double requiredUnderHeight,
    ValueChanged<bool> openedChanged,
  }) : super(
          key: key,
          getItems: getItems,
          buildItem: buildItem,
          onItemTapped: onItemTapped,
          autoOpen: autoOpen,
          refreshListOnOpened: refreshListOnOpened,
          emptyMessage: emptyMessage,
          buildItemsDecorator: buildItemsDecorator,
          popupWidth: popupWidth,
          popupMaxHeight: popupMaxHeight,
          highlightColor: highlightColor,
          splashColor: splashColor,
          hoverColor: hoverColor,
          focusColor: focusColor,
          popupAutoClose: popupAutoClose,
          overlap: overlap,
          showAbove: showAbove,
          animatedOpen: animatedOpen,
          openingAnimationDuration: openingAnimationDuration,
          animatedClose: animatedClose,
          closingAnimationDuration: closingAnimationDuration,
          customAnimation: customAnimation,
          requiredUnderHeight: requiredUnderHeight,
          openedChanged: openedChanged,
        );

  final T selected;
  final ItemBuilder<T> buildChild;

  @override
  SelectorComboState<T> createState() => SelectorComboState<T>(selected);
}

class SelectorComboState<T> extends ListComboState<T> {
  SelectorComboState(this._selected);
  T _selected;
  T get selected => _selected;

  @protected
  void clearSelected() => _selected = null;

  @override
  SelectorCombo<T> get widget => super.widget;

  @override
  void didUpdateWidget(Combo oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selected != _selected) {
      setState(() => _selected = widget.selected);
    }
  }

  @override
  Widget buildChild() =>
      (widget.buildChild ?? widget.buildItem)(context, _selected);
}

typedef TypeaheadGetItems<T> = FutureOr<List<T>> Function(String text);
typedef GetItemText<T> = String Function(T item);

class Typeahead<T> extends SelectorCombo<T> {
  const Typeahead({
    Key key,
    this.decoration,
    this.enabled = true,
    this.autofocus = false,
    @required this.getItemText,
    this.minTextLength = 1,
    this.focusNode,
    this.delay = const Duration(milliseconds: 300),
    this.cleanAfterSelection = false,
    T selected,
    ItemBuilder<T> buildChild,
    @required TypeaheadGetItems<T> getItems,
    @required ItemBuilder<T> buildItem,
    @required ValueChanged<T> onItemTapped,
    bool refreshListOnOpened = false,
    Widget emptyMessage = defaultEmptyMessage,
    ItemsDecoratorBuilder buildItemsDecorator,
    double popupWidth,
    double popupMaxHeight = 300,
    Color highlightColor,
    Color splashColor,
    Color hoverColor,
    Color focusColor,
    bool overlap = false,
    bool showAbove = true,
    bool animatedOpen = true,
    Duration openingAnimationDuration = _defaultAnimationDuration,
    bool animatedClose = true,
    Duration closingAnimationDuration = _defaultAnimationDuration,
    bool customAnimation = false,
    bool closeOnTapOver = true,
    double requiredUnderHeight,
    ValueChanged<bool> openedChanged,
  })  : typeaheadGetItems = getItems,
        super(
          key: key,
          selected: selected,
          buildChild: buildChild,
          getItems: null,
          buildItem: buildItem,
          onItemTapped: onItemTapped,
          autoOpen: false,
          refreshListOnOpened: refreshListOnOpened,
          emptyMessage: emptyMessage,
          buildItemsDecorator: buildItemsDecorator,
          popupWidth: popupWidth,
          popupMaxHeight: popupMaxHeight,
          highlightColor: highlightColor,
          splashColor: splashColor,
          hoverColor: hoverColor,
          focusColor: focusColor,
          popupAutoClose: PopupAutoClose.tapDownExceptChild,
          overlap: overlap,
          showAbove: showAbove,
          animatedOpen: animatedOpen,
          openingAnimationDuration: openingAnimationDuration,
          animatedClose: animatedClose,
          closingAnimationDuration: closingAnimationDuration,
          customAnimation: customAnimation,
          requiredUnderHeight: requiredUnderHeight,
          openedChanged: openedChanged,
        );

  final TypeaheadGetItems<T> typeaheadGetItems;
  final InputDecoration decoration;
  final bool enabled;
  final bool autofocus;
  final GetItemText<T> getItemText;
  final int minTextLength;
  final FocusNode focusNode;
  final Duration delay;
  final bool cleanAfterSelection;

  @override
  TypeaheadState<T> createState() => TypeaheadState<T>(selected,
      selected == null ? '' : getItemText(selected), focusNode ?? FocusNode());
}

class TypeaheadState<T> extends SelectorComboState<T> {
  TypeaheadState(T selected, String text, this._focusNode)
      : _controller = TextEditingController(text: text),
        _text = text,
        super(selected);

  final TextEditingController _controller;
  final FocusNode _focusNode;

  String _text;
  int get _textLength => _controller.text?.length ?? 0;

  @override
  Typeahead<T> get widget => super.widget;

  @override
  void initState() {
    super.initState();

    _controller.addListener(() async {
      if (!mounted || _text == _controller.text || !_focusNode.hasFocus) {
        return;
      }

      clearSelected();
      if (widget.selected != null) super.itemTapped(null);

      final text = _text = _controller.text;
      if (_textLength < widget.minTextLength) {
        super.close();
      } else {
        await Future.delayed(widget.delay);
        if (text == _controller.text) fillItems();
      }
    });

    _focusNode.addListener(() {
      if (mounted &&
          _focusNode.hasFocus &&
          _textLength >= widget.minTextLength) {
        (items == null ? fillItems : open)();
      }
    });
  }

  @override
  void didUpdateWidget(Typeahead<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selected != null) {
      final text = widget.getItemText(selected);
      if (text != _controller.text) {
        _controller.text = _text = text;
      }
    }
    if (oldWidget.enabled != widget.enabled) {
      setState(() {});
    }
  }

  @override
  FutureOr getItems() => widget.typeaheadGetItems(_text);

  @override
  void itemTapped(T value) {
    if (value == selected) return;
    if (widget.cleanAfterSelection) {
      _controller.text = _text = '';
      clearItems();
    }

    super.itemTapped(value);
  }

  @override
  Widget get child => TextField(
        controller: _controller,
        focusNode: _focusNode,
        enabled: widget.enabled,
        autofocus: widget.autofocus,
        decoration: widget.decoration ?? const InputDecoration(),
        onTap: () {
          if (!opened &&
              _items != null &&
              _textLength >= widget.minTextLength) {
            open();
          }
        },
      );

  @override
  void dispose() {
    super.dispose();
    _controller.dispose();
    if (widget.focusNode == null) _focusNode.dispose();
  }
}
