library combos;

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

const _defaultAnimationDuration = Duration(milliseconds: 150);
const _defaultScreenPadding = EdgeInsets.all(16);

enum PopupPosition {
  bottom,
  bottomMatch,
  bottomMinMatch,
  top,
  topMatch,
  topMinMatch,
  right,
  left
}

enum PopupWidthConstraints { matchWidth, minMatchWidth, customWidth }

enum PopupAutoOpen { none, tap, hovered }

enum PopupAutoClose {
  none,
  tapOutside,
  tapOutsideWithChildIgnorePointer,
  tapOutsideExceptChild,
  notHovered,
}

enum PopupAnimation { none, fade, fadeOpen, fadeClose, custom }

typedef PopupBuilder = Widget Function(BuildContext context, bool mirrored);

class Combo extends StatefulWidget {
  const Combo({
    Key key,
    this.child,
    this.popupBuilder,
    this.position = PopupPosition.bottomMinMatch,
    this.offset,
    this.requiredSpace,
    this.screenPadding = _defaultScreenPadding,
    this.autoClose = PopupAutoClose.tapOutsideWithChildIgnorePointer,
    this.autoOpen = PopupAutoOpen.tap,
    this.animation = PopupAnimation.fade,
    this.animationDuration = _defaultAnimationDuration,
    this.openedChanged,
    this.hoveredChanged,
    this.onTap,
    this.focusColor,
    this.hoverColor,
    this.highlightColor,
    this.splashColor,
  }) : super(key: key);

  final Widget child;
  final PopupBuilder popupBuilder;
  final PopupPosition position;
  final Offset offset;
  final double requiredSpace;
  final EdgeInsets screenPadding;
  final PopupAutoClose autoClose;
  final PopupAutoOpen autoOpen;
  final PopupAnimation animation;
  final Duration animationDuration;
  final ValueChanged<bool> openedChanged;
  final ValueChanged<bool> hoveredChanged;
  final GestureTapCallback onTap;
  final Color focusColor;
  final Color hoverColor;
  final Color highlightColor;
  final Color splashColor;

  static void closeAll() => ComboState._closes.add(true);

  @override
  ComboState createState() => ComboState();
}

class ComboState<T extends Combo> extends State<T> {
  // ignore: close_sinks
  static final _closes = StreamController.broadcast();
  final _scrolls = StreamController.broadcast();
  final _layerLink = LayerLink();
  OverlayEntry _overlay;
  StreamSubscription _subscription;
  Completer<double> _closeCompleter;
  var _hovered = false;
  var _popupHovered = false;
  ComboState _parent;

  // workaround for: https://github.com/flutter/flutter/issues/50800
  Completer<Offset> _sizeCompleter;

  bool get _fadeOpen =>
      widget.animation == PopupAnimation.fade ||
      widget.animation == PopupAnimation.fadeOpen;
  bool get _fadeClose =>
      widget.animation == PopupAnimation.fade ||
      widget.animation == PopupAnimation.fadeClose;
  bool get _delayedClose =>
      widget.animation == PopupAnimation.fade ||
      widget.animation == PopupAnimation.fadeClose ||
      widget.animation == PopupAnimation.custom;

  @override
  void initState() {
    super.initState();
    _subscription = _closes.stream.listen((_) => close());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _parent = context.findAncestorStateOfType<_ComboOverlayState>()?.comboState;
    Scrollable.of(context)?.widget?.controller?.addListener(() {
      if (_overlay != null) _scrolls.add(true);
    });
  }

  bool get opened => _overlay != null;
  bool get hasPopup => widget.popupBuilder != null;

  void open() {
    if (_overlay != null) return;
    if (widget.openedChanged != null) widget.openedChanged(true);
    if (_fadeClose) _closeCompleter = Completer();
    _overlay = _createOverlay();
    if (_overlay == null) return;
    Overlay.of(context).insert(_overlay);
    setState(() {});
  }

  void close() async {
    if (_overlay == null) return;
    final overlay = _overlay;
    _overlay = null;
    if (_fadeClose) _closeCompleter?.complete(0.0);
    if (widget.openedChanged != null) widget.openedChanged(false);
    if (_delayedClose) {
      await Future.delayed(widget.animationDuration == null
          ? Duration.zero
          : widget.animationDuration + Duration(milliseconds: 1));
    }
    overlay.remove();
    setState(() {});
  }

  bool get _catchHover =>
      widget.autoOpen == PopupAutoOpen.hovered ||
      widget.autoClose == PopupAutoClose.notHovered;

  void _setHovered(bool value) async {
    if (!value && opened && _popupHovered) return;
    _parent?._setHovered(value);
    if (value == _hovered || !mounted) return;
    _hovered = value;
    if (value) {
      if (widget.hoveredChanged != null) widget.hoveredChanged(true);
      if (!opened && widget.autoOpen == PopupAutoOpen.hovered) {
        open();
      }
    } else {
      await Future.delayed(const Duration(milliseconds: 50));
      if (_hovered) return;
      if (widget.hoveredChanged != null) widget.hoveredChanged(false);
      if (opened && widget.autoClose == PopupAutoClose.notHovered) {
        close();
      }
    }
  }

  Widget getChild() => widget.child;
  Widget getPopup(BuildContext context, bool mirrored) =>
      widget.popupBuilder == null
          ? null
          : widget.popupBuilder(context, mirrored);

  OverlayEntry _createOverlay() => OverlayEntry(builder: (context) {
        _sizeCompleter = Completer<Offset>();
        final RenderBox renderBox = this.context.findRenderObject();
        final size = renderBox.size;
        final screenSize = MediaQuery.of(context).size;
        final requiredSpace = widget.requiredSpace ??
            (widget.position == PopupPosition.left ||
                    widget.position == PopupPosition.right
                ? screenSize.width / 3
                : screenSize.height / 3);

        Offset lastOffset;
        Offset offset;
        bool mirrored;
        Widget popup;

        void updatePopup() {
          offset = mounted
              ? lastOffset = renderBox.localToGlobal(Offset.zero)
              : lastOffset;
          mirrored = () {
            final offsetx = widget.offset?.dx ?? 0;
            final offsety = widget.offset?.dx ?? 0;

            return () {
                  switch (widget.position) {
                    case PopupPosition.left:
                      return offset.dx -
                          offsetx -
                          (widget.screenPadding?.left ?? 0);
                    case PopupPosition.right:
                      return screenSize.width -
                          offset.dx -
                          size.width -
                          offsetx -
                          (widget.screenPadding?.right ?? 0);
                    default:
                      return screenSize.height -
                          offset.dy -
                          (widget.position == PopupPosition.top ||
                                  widget.position == PopupPosition.topMatch ||
                                  widget.position == PopupPosition.topMinMatch
                              ? 0
                              : size.height) -
                          offsety -
                          (widget.screenPadding?.bottom ?? 0);
                  }
                }() <
                requiredSpace;
          }();
          popup = getPopup(context, mirrored);
          if (_catchHover) {
            popup = MouseRegion(
                onEnter: (_) {
                  _popupHovered = true;
                  _setHovered(true);
                },
                onExit: (_) {
                  _popupHovered = false;
                  _setHovered(false);
                },
                child: popup);
          }
        }

        updatePopup();

        if (popup == null) return null;

        final overlay = StreamBuilder(
            initialData: null,
            stream: _scrolls.stream,
            builder: (context, snapshot) {
              if (snapshot.data != null) updatePopup();

              switch (widget.position) {
                case PopupPosition.bottomMatch:
                case PopupPosition.topMatch:
                  popup = SizedBox(width: size.width, child: popup);
                  break;
                case PopupPosition.bottomMinMatch:
                case PopupPosition.topMinMatch:
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
                  if (widget.autoClose != PopupAutoClose.none &&
                      (widget.autoClose != PopupAutoClose.notHovered ||
                          !kIsWeb))
                    GestureDetector(onPanDown: (_) {
                      if (widget.autoClose !=
                              PopupAutoClose.tapOutsideExceptChild ||
                          !renderBox.hitTest(BoxHitTestResult(),
                              position:
                                  renderBox.globalToLocal(_.globalPosition))) {
                        close();
                      }
                    }),
                  FutureBuilder<Offset>(
                      future: _sizeCompleter.future,
                      builder: (context, snapshot) => Positioned(
                            top: snapshot.data?.dy ?? 0,
                            left: snapshot.data?.dx ?? 0,
                            child: _DynamicTransformFollower(
                              key: ValueKey(mirrored),
                              link: _layerLink,
                              showWhenUnlinked: false,
                              offsetBuilder: (popupSize) {
                                final offsetx = widget.offset?.dx ?? 0;
                                final offsety = widget.offset?.dy ?? 0;
                                final position = mirrored &&
                                        (widget.position ==
                                                PopupPosition.left ||
                                            widget.position ==
                                                PopupPosition.right)
                                    ? widget.position == PopupPosition.left
                                        ? PopupPosition.right
                                        : PopupPosition.left
                                    : widget.position;
                                final dx = () {
                                  switch (position) {
                                    case PopupPosition.left:
                                      return -popupSize.width - offsetx;
                                    case PopupPosition.right:
                                      return offsetx + size.width + offsetx;
                                    case PopupPosition.bottomMatch:
                                    case PopupPosition.topMatch:
                                      return offsetx;
                                    default:
                                      return math.min(
                                          offsetx,
                                          screenSize.width -
                                              offset.dx -
                                              popupSize.width -
                                              (widget.screenPadding?.right ??
                                                  0));
                                  }
                                }();
                                final dy = () {
                                  var overlapped = false;
                                  switch (position) {
                                    case PopupPosition.left:
                                    case PopupPosition.right:
                                      return math.min(
                                          offsety,
                                          screenSize.height -
                                              offset.dy -
                                              popupSize.height -
                                              (widget.screenPadding?.bottom ??
                                                  0));
                                    case PopupPosition.top:
                                    case PopupPosition.topMatch:
                                    case PopupPosition.topMinMatch:
                                      overlapped = true;
                                      break;
                                    default:
                                      break;
                                  }
                                  return mirrored
                                      ? ((overlapped ? size.height : 0.0) -
                                              popupSize.height) -
                                          offsety
                                      : (overlapped ? 0 : size.height) +
                                          offsety;
                                }();
                                final res = Offset(dx, dy);

                                if (!_sizeCompleter.isCompleted) {
                                  _sizeCompleter.complete(res);
                                }

                                return res;
                              },
                              child: popup,
                            ),
                          )),
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
                  duration: widget.animationDuration,
                  child: child,
                ),
              ),
            );

        final openAnimated =
            _fadeOpen ? animate(0.0, Future.value(1.0), overlay) : overlay;
        final closeAnimated = _fadeClose && _closeCompleter != null
            ? animate(1.0, _closeCompleter.future, openAnimated)
            : openAnimated;

        return _ComboOverlay(child: closeAnimated, comboState: this);
      });

  @override
  Widget build(BuildContext context) {
    var child = getChild();
    if (child == null) {
      child = const SizedBox();
    } else {
      if (widget.autoOpen != PopupAutoOpen.none) {
        final catchHover = _catchHover;
        final openOnHover = widget.autoOpen == PopupAutoOpen.hovered;

        if (widget.onTap == null && (openOnHover && (kIsWeb || !hasPopup))) {
          child = MouseRegion(
            onEnter: (_) => _setHovered(true),
            onExit: (_) => _setHovered(false),
            child: child,
          );
        } else {
          child = InkWell(
            child: child,
            focusColor: widget.focusColor,
            hoverColor: widget.hoverColor,
            highlightColor: widget.highlightColor,
            splashColor: widget.splashColor,
            onTap: () {
              if (!openOnHover || (openOnHover && !kIsWeb && hasPopup)) open();
              if (widget.onTap != null &&
                  (kIsWeb || !openOnHover || !hasPopup)) {
                widget.onTap();
              }
            },
            onLongPress:
                openOnHover && !kIsWeb && hasPopup ? widget.onTap : null,
            onHover: catchHover ? _setHovered : null,
          );
        }
      }
      if (widget.autoClose == PopupAutoClose.tapOutsideWithChildIgnorePointer) {
        child = IgnorePointer(ignoring: _overlay != null, child: child);
      }
    }
    return CompositedTransformTarget(link: _layerLink, child: child);
  }

  @override
  void dispose() {
    close();
    _scrolls.close();
    _subscription.cancel();
    super.dispose();
  }
}

class _ComboOverlay extends StatefulWidget {
  const _ComboOverlay(
      {Key key, @required this.child, @required this.comboState})
      : super(key: key);

  final Widget child;
  final ComboState comboState;

  @override
  _ComboOverlayState createState() => _ComboOverlayState(comboState);
}

class _ComboOverlayState extends State<_ComboOverlay> {
  _ComboOverlayState(this.comboState);
  final ComboState comboState;
  @override
  Widget build(BuildContext context) => widget.child;
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

typedef AwaitPopupBuilder = FutureOr<Widget> Function(BuildContext context);
typedef ProgressDecoratorBuilder = Widget Function(
    BuildContext context, bool waiting, bool mirrored, Widget child);

enum ProgressPosition { child, popup }

class ProgressDecorator extends StatefulWidget {
  const ProgressDecorator({
    Key key,
    @required this.child,
    this.waiting = false,
    this.mirrored = false,
    this.progressBackgroundColor,
    this.progressValueColor,
    this.progressHeight = 2.0,
  }) : super(key: key);

  final Widget child;
  final bool waiting;
  final bool mirrored;
  final Color progressBackgroundColor;
  final Animation<Color> progressValueColor;
  final double progressHeight;

  @override
  _ProgressDecoratorState createState() => _ProgressDecoratorState(waiting);
}

class _ProgressDecoratorState extends State<ProgressDecorator> {
  _ProgressDecoratorState(this._waiting);
  bool _waiting;

  @override
  void didUpdateWidget(ProgressDecorator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.waiting != _waiting) {
      setState(() => _waiting = widget.waiting);
    }
  }

  @override
  Widget build(BuildContext context) {
    final fill = widget.progressHeight == null;
    final indicator = IgnorePointer(
        child: LinearProgressIndicator(
      backgroundColor: widget.progressBackgroundColor,
      valueColor: widget.progressValueColor,
    ));
    return _waiting
        ? Stack(children: [
            widget.child,
            SizedBox(height: widget.progressHeight),
            Positioned.fill(
                child: fill
                    ? indicator
                    : Align(
                        alignment: widget.mirrored
                            ? Alignment.bottomCenter
                            : Alignment.topCenter,
                        child: SizedBox(
                            height: widget.progressHeight, child: indicator),
                      )),
          ])
        : widget.child;
  }
}

class AwaitCombo extends Combo {
  const AwaitCombo({
    Key key,
    this.progressDecoratorBuilder = buildDefaultProgressDecorator,
    this.refreshOnOpened = false,
    this.waitChanged,
    this.progressPosition = ProgressPosition.popup,

    // inherited
    Widget child,
    AwaitPopupBuilder popupBuilder,
    PopupPosition position = PopupPosition.bottomMinMatch,
    Offset offset,
    double requiredSpace,
    EdgeInsets screenPadding = _defaultScreenPadding,
    PopupAutoClose autoClose = PopupAutoClose.tapOutsideWithChildIgnorePointer,
    PopupAutoOpen autoOpen = PopupAutoOpen.tap,
    PopupAnimation animation = PopupAnimation.fade,
    Duration animationDuration = _defaultAnimationDuration,
    ValueChanged<bool> openedChanged,
    ValueChanged<bool> hoveredChanged,
    GestureTapCallback onTap,
    Color focusColor,
    Color hoverColor,
    Color highlightColor,
    Color splashColor,
  })  : awaitPopupBuilder = popupBuilder,
        super(
          key: key,
          child: child,
          position: position,
          offset: offset,
          requiredSpace: requiredSpace,
          screenPadding: screenPadding,
          autoClose: autoClose,
          autoOpen: autoOpen,
          animation: animation,
          animationDuration: animationDuration,
          openedChanged: openedChanged,
          hoveredChanged: hoveredChanged,
          onTap: onTap,
          focusColor: focusColor,
          hoverColor: hoverColor,
          highlightColor: highlightColor,
          splashColor: splashColor,
        );

  final ProgressDecoratorBuilder progressDecoratorBuilder;
  final AwaitPopupBuilder awaitPopupBuilder;
  final bool refreshOnOpened;
  final ValueChanged<bool> waitChanged;
  final ProgressPosition progressPosition;

  @override
  AwaitComboStateBase createState() => AwaitComboState();

  static Widget buildDefaultProgressDecorator(
          BuildContext context, bool waiting, bool mirrored, Widget child) =>
      ProgressDecorator(waiting: waiting, mirrored: mirrored, child: child);
}

class AwaitComboState extends AwaitComboStateBase<AwaitCombo, Widget> {
  @override
  FutureOr<Widget> getContent(BuildContext context) =>
      widget.awaitPopupBuilder == null
          ? null
          : widget.awaitPopupBuilder(context);

  @override
  Widget buildContent(Widget content, bool mirrored) => content;
}

abstract class AwaitComboStateBase<W extends AwaitCombo, C>
    extends ComboState<W> {
  var _waitCount = 0;
  final _waitController = StreamController<int>.broadcast();
  C _content;
  C get content => _content;
  final _contentController = StreamController<C>.broadcast();
  DateTime _timestamp;

  @override
  bool get hasPopup => widget.popupBuilder != null;

  FutureOr<C> getContent(BuildContext context);
  Widget buildContent(C content, bool mirrored);
  @protected
  void clearContent() => _content = null;

  @override
  Widget getChild() => widget.progressDecoratorBuilder == null ||
          widget.progressPosition != ProgressPosition.child
      ? super.getChild()
      : StreamBuilder<int>(
          initialData: _waitCount,
          stream: _waitController.stream,
          builder: (context, snapshot) => widget.progressDecoratorBuilder(
              context, snapshot.data != 0, false, super.getChild()));

  @override
  Widget getPopup(BuildContext context, bool mirrored) => StreamBuilder<int>(
        initialData: _waitCount,
        stream: _waitController.stream,
        builder: (context, snapshot) {
          final content = StreamBuilder<C>(
            initialData: _content,
            stream: _contentController.stream,
            builder: (context, snapshot) =>
                buildContent(snapshot.data, mirrored) ?? const SizedBox(),
          );
          return widget.progressDecoratorBuilder == null ||
                  widget.progressPosition != ProgressPosition.popup
              ? content
              : widget.progressDecoratorBuilder(
                  context, snapshot.data != 0, mirrored, content);
        },
      );

  Future fill() async {
    final future = getContent(context);
    if (future == null) return;
    var content = future is C ? future : null;
    void update() => _contentController.add(_content = content);
    if (content == null) {
      final timestamp = _timestamp = DateTime.now();
      try {
        _waitController.add(++_waitCount);
        if (_waitCount == 1 && widget.waitChanged != null) {
          widget.waitChanged(true);
        }
        super.open();
        content = await future;
        if (content != null && _timestamp == timestamp) update();
      } finally {
        _waitController.add(--_waitCount);
        if (_waitCount == 0 && widget.waitChanged != null) {
          widget.waitChanged(false);
        }
      }
    } else {
      update();
      super.open();
    }
  }

  @override
  void open() =>
      (widget.refreshOnOpened || _content == null ? fill : super.open)();

  @override
  void dispose() {
    super.dispose();
    _waitController.close();
    _contentController.close();
  }
}

typedef PopupGetList<T> = FutureOr<List<T>> Function();
typedef PopupListItemBuilder<T> = Widget Function(BuildContext context, T item);
typedef GetIsSelectable<T> = bool Function(T item);
typedef ListPopupBuilder<T> = Widget Function(
    BuildContext context,
    List<T> list,
    PopupListItemBuilder<T> itemBuilder,
    void Function(T value) onItemTapped,
    bool mirrored,
    GetIsSelectable<T> getIsSelectable);

const Widget defaultEmptyMessage = Padding(
  padding: EdgeInsets.all(16),
  child: Text(
    'No Items',
    textAlign: TextAlign.center,
    style: TextStyle(color: Colors.grey),
  ),
);

class ListPopup<T> extends StatelessWidget {
  const ListPopup({
    Key key,
    @required this.list,
    @required this.itemBuilder,
    @required this.onItemTapped,
    this.width,
    this.maxHeight = 300.0,
    this.emptyMessage = defaultEmptyMessage,
    this.getIsSelectable,
  }) : super(key: key);

  final List<T> list;
  final PopupListItemBuilder<T> itemBuilder;
  final ValueSetter<T> onItemTapped;
  final double width;
  final double maxHeight;
  final Widget emptyMessage;
  final GetIsSelectable<T> getIsSelectable;

  @override
  Widget build(BuildContext context) => ConstrainedBox(
        constraints: BoxConstraints(
            maxWidth: width ?? double.infinity,
            maxHeight: maxHeight ?? double.infinity),
        child: Material(
          elevation: 4,
          child: list?.isEmpty == true
              ? Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [emptyMessage],
                )
              : ListView.builder(
                  shrinkWrap: true,
                  physics: ClampingScrollPhysics(),
                  itemCount: list?.length ?? 0,
                  itemBuilder: (context, index) {
                    final item = list[index];
                    final itemWidget = itemBuilder(context, item);
                    return getIsSelectable == null || getIsSelectable(item)
                        ? InkWell(
                            child: itemWidget,
                            onTap: () => onItemTapped(item),
                          )
                        : itemWidget;
                  }),
        ),
      );
}

class ListCombo<T> extends AwaitCombo {
  const ListCombo({
    Key key,
    @required this.getList,
    @required this.itemBuilder,
    @required this.onItemTapped,
    ListPopupBuilder<T> popupBuilder,
    this.getIsSelectable,

    // inherited
    ProgressDecoratorBuilder progressDecoratorBuilder =
        AwaitCombo.buildDefaultProgressDecorator,
    bool refreshOnOpened = false,
    ValueChanged<bool> waitChanged,
    ProgressPosition progressPosition = ProgressPosition.popup,
    Widget child,
    PopupPosition position = PopupPosition.bottomMatch,
    Offset offset,
    double requiredSpace,
    EdgeInsets screenPadding = _defaultScreenPadding,
    PopupAutoClose autoClose = PopupAutoClose.tapOutsideWithChildIgnorePointer,
    PopupAutoOpen autoOpen = PopupAutoOpen.tap,
    PopupAnimation animation = PopupAnimation.fade,
    Duration animationDuration = _defaultAnimationDuration,
    ValueChanged<bool> openedChanged,
    ValueChanged<bool> hoveredChanged,
    GestureTapCallback onTap,
    Color focusColor,
    Color hoverColor,
    Color highlightColor,
    Color splashColor,
  })  : listPopupBuilder = popupBuilder ?? buildDefaultPopup,
        super(
          key: key,
          progressDecoratorBuilder: progressDecoratorBuilder,
          refreshOnOpened: refreshOnOpened,
          waitChanged: waitChanged,
          progressPosition: progressPosition,
          child: child,
          position: position,
          offset: offset,
          requiredSpace: requiredSpace,
          screenPadding: screenPadding,
          autoClose: autoClose,
          autoOpen: autoOpen,
          animation: animation,
          animationDuration: animationDuration,
          openedChanged: openedChanged,
          hoveredChanged: hoveredChanged,
          onTap: onTap,
          focusColor: focusColor,
          hoverColor: hoverColor,
          highlightColor: highlightColor,
          splashColor: splashColor,
        );

  final PopupGetList<T> getList;
  final PopupListItemBuilder<T> itemBuilder;
  final ValueSetter<T> onItemTapped;
  final ListPopupBuilder<T> listPopupBuilder;
  final GetIsSelectable<T> getIsSelectable;

  @override
  ListComboState<ListCombo<T>, T> createState() =>
      ListComboState<ListCombo<T>, T>();

  static Widget buildDefaultPopup<T>(
          BuildContext context,
          List<T> list,
          PopupListItemBuilder<T> itemBuilder,
          void Function(T value) onItemTapped,
          bool mirrored,
          GetIsSelectable<T> getIsSelectable) =>
      ListPopup<T>(
          list: list,
          itemBuilder: itemBuilder,
          onItemTapped: onItemTapped,
          getIsSelectable: getIsSelectable);
}

class ListComboState<W extends ListCombo<T>, T>
    extends AwaitComboStateBase<W, List<T>> {
  @override
  Widget buildContent(List<T> list, bool mirrored) => widget.listPopupBuilder(
      context,
      list,
      widget.itemBuilder,
      itemTapped,
      mirrored,
      widget.getIsSelectable);

  @override
  bool get hasPopup => widget.getList != null;

  @override
  FutureOr<List<T>> getContent(BuildContext context) => widget.getList();

  void itemTapped(T item) {
    if (widget.onItemTapped != null) {
      widget.onItemTapped(item);
    }
    super.close();
  }
}

class SelectorCombo<T> extends ListCombo<T> {
  const SelectorCombo({
    Key key,
    this.selected,
    this.childBuilder,

    // inherited
    @required PopupGetList<T> getList,
    @required PopupListItemBuilder<T> itemBuilder,
    @required ValueSetter<T> onItemTapped,
    ListPopupBuilder<T> popupBuilder,
    GetIsSelectable<T> getIsSelectable,
    ProgressDecoratorBuilder progressDecoratorBuilder =
        AwaitCombo.buildDefaultProgressDecorator,
    bool refreshOnOpened = false,
    ValueChanged<bool> waitChanged,
    ProgressPosition progressPosition = ProgressPosition.popup,
    PopupPosition position = PopupPosition.bottomMatch,
    Offset offset,
    double requiredSpace,
    EdgeInsets screenPadding = _defaultScreenPadding,
    PopupAutoClose autoClose = PopupAutoClose.tapOutsideWithChildIgnorePointer,
    PopupAutoOpen autoOpen = PopupAutoOpen.tap,
    PopupAnimation animation = PopupAnimation.fade,
    Duration animationDuration = _defaultAnimationDuration,
    ValueChanged<bool> openedChanged,
    ValueChanged<bool> hoveredChanged,
    GestureTapCallback onTap,
    Color focusColor,
    Color hoverColor,
    Color highlightColor,
    Color splashColor,
  }) : super(
          key: key,
          getList: getList,
          itemBuilder: itemBuilder,
          onItemTapped: onItemTapped,
          popupBuilder: popupBuilder,
          getIsSelectable: getIsSelectable,
          progressDecoratorBuilder: progressDecoratorBuilder,
          refreshOnOpened: refreshOnOpened,
          waitChanged: waitChanged,
          progressPosition: progressPosition,
          position: position,
          offset: offset,
          requiredSpace: requiredSpace,
          screenPadding: screenPadding,
          autoClose: autoClose,
          autoOpen: autoOpen,
          animation: animation,
          animationDuration: animationDuration,
          openedChanged: openedChanged,
          hoveredChanged: hoveredChanged,
          onTap: onTap,
          focusColor: focusColor,
          hoverColor: hoverColor,
          highlightColor: highlightColor,
          splashColor: splashColor,
        );

  final T selected;
  final PopupListItemBuilder<T> childBuilder;

  @override
  SelectorComboState<SelectorCombo<T>, T> createState() =>
      SelectorComboState<SelectorCombo<T>, T>(selected);
}

class SelectorComboState<W extends SelectorCombo<T>, T>
    extends ListComboState<W, T> {
  SelectorComboState(this._selected);
  T _selected;
  T get selected => _selected;

  @protected
  void clearSelected() => _selected = null;

  @override
  void didUpdateWidget(SelectorCombo<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selected != _selected) {
      setState(() => _selected = widget.selected);
    }
  }

  @override
  Widget getChild() =>
      (widget.childBuilder ?? widget.itemBuilder)(context, _selected);
}

typedef TypeaheadGetList<T> = FutureOr<List<T>> Function(String text);
typedef PopupGetItemText<T> = String Function(T item);

class TypeaheadCombo<T> extends SelectorCombo<T> {
  const TypeaheadCombo({
    Key key,
    TypeaheadGetList<T> getList,
    this.decoration,
    this.enabled = true,
    this.autofocus = false,
    @required this.getItemText,
    this.minTextLength = 1,
    this.focusNode,
    this.delay = const Duration(milliseconds: 300),
    this.cleanAfterSelection = false,

    // inherited
    T selected,
    @required PopupListItemBuilder<T> itemBuilder,
    @required ValueSetter<T> onItemTapped,
    ListPopupBuilder<T> popupBuilder,
    GetIsSelectable<T> getIsSelectable,
    ProgressDecoratorBuilder progressDecoratorBuilder =
        AwaitCombo.buildDefaultProgressDecorator,
    ValueChanged<bool> waitChanged,
    ProgressPosition progressPosition = ProgressPosition.popup,
    PopupPosition position = PopupPosition.bottomMatch,
    Offset offset,
    double requiredSpace,
    EdgeInsets screenPadding = _defaultScreenPadding,
    PopupAnimation animation = PopupAnimation.fade,
    Duration animationDuration = _defaultAnimationDuration,
    ValueChanged<bool> openedChanged,
    ValueChanged<bool> hoveredChanged,
    GestureTapCallback onTap,
    Color focusColor,
    Color hoverColor,
    Color highlightColor,
    Color splashColor,
  })  : typeaheadGetList = getList,
        // ignore: missing_required_param
        super(
          key: key,
          selected: selected,
          itemBuilder: itemBuilder,
          onItemTapped: onItemTapped,
          popupBuilder: popupBuilder,
          getIsSelectable: getIsSelectable,
          progressDecoratorBuilder: progressDecoratorBuilder,
          refreshOnOpened: false,
          waitChanged: waitChanged,
          progressPosition: progressPosition,
          position: position,
          offset: offset,
          requiredSpace: requiredSpace,
          screenPadding: screenPadding,
          autoClose: PopupAutoClose.tapOutsideExceptChild,
          autoOpen: PopupAutoOpen.none,
          animation: animation,
          animationDuration: animationDuration,
          openedChanged: openedChanged,
          hoveredChanged: hoveredChanged,
          onTap: onTap,
          focusColor: focusColor,
          hoverColor: hoverColor,
          highlightColor: highlightColor,
          splashColor: splashColor,
        );

  final TypeaheadGetList<T> typeaheadGetList;
  final InputDecoration decoration;
  final bool enabled;
  final bool autofocus;
  final PopupGetItemText<T> getItemText;
  final int minTextLength;
  final FocusNode focusNode;
  final Duration delay;
  final bool cleanAfterSelection;

  @override
  TypeaheadComboState<TypeaheadCombo<T>, T> createState() =>
      TypeaheadComboState<TypeaheadCombo<T>, T>(
          selected,
          selected == null ? '' : getItemText(selected),
          focusNode ?? FocusNode());
}

class TypeaheadComboState<W extends TypeaheadCombo<T>, T>
    extends SelectorComboState<W, T> {
  TypeaheadComboState(T selected, String text, this._focusNode)
      : _controller = TextEditingController(text: text),
        _text = text,
        super(selected);

  final TextEditingController _controller;
  final FocusNode _focusNode;
  String _text;
  int get _textLength => _controller.text?.length ?? 0;

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
        if (text == _controller.text) await fill();
      }
    });

    _focusNode.addListener(() {
      if (mounted &&
          _focusNode.hasFocus &&
          _textLength >= widget.minTextLength) {
        (content == null ? fill : open)();
      }
    });
  }

  @override
  void didUpdateWidget(TypeaheadCombo<T> oldWidget) {
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
  FutureOr<List<T>> getContent(BuildContext context) =>
      widget.typeaheadGetList(_text);

  @override
  void itemTapped(T item) {
    if (item == selected) return;
    if (widget.cleanAfterSelection) {
      _controller.text = _text = '';
      clearContent();
    }
    super.itemTapped(item);
  }

  @override
  Widget getChild() => TextField(
        controller: _controller,
        focusNode: _focusNode,
        enabled: widget.enabled,
        autofocus: widget.autofocus,
        decoration: widget.decoration ?? const InputDecoration(),
        onTap: () {
          if (!opened &&
              content != null &&
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

class MenuItem<T> {
  const MenuItem(this.item, [this.getChildren]);
  static const separator = MenuItem(null);
  final T item;
  final PopupGetList<MenuItem<T>> getChildren;
}

typedef MenuItemPopupBuilder<T> = Widget Function(
    BuildContext context,
    List<T> list,
    PopupListItemBuilder<T> itemBuilder,
    void Function(T value) onItemTapped,
    bool mirrored,
    GetIsSelectable<T> getIsSelectable,
    bool canTapOnFolder);

class MenuDivider extends StatelessWidget {
  const MenuDivider({Key key, this.color = Colors.black12}) : super(key: key);

  final Color color;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Container(
          height: 1,
          color: Colors.black12,
        ),
      );
}

const Widget _defaultMenuDivider = MenuDivider();

class _ArrowedItem extends StatelessWidget {
  const _ArrowedItem({Key key, this.child}) : super(key: key);
  final Widget child;
  @override
  Widget build(BuildContext context) => Row(children: [
        Expanded(child: child),
        const SizedBox(width: 16),
        Icon(Icons.arrow_right,
            color: Theme.of(context)?.textTheme?.body1?.color?.withOpacity(0.5))
      ]);
}

class MenuListPopup<T extends MenuItem> extends StatelessWidget {
  const MenuListPopup({
    Key key,
    @required this.list,
    @required this.itemBuilder,
    @required this.onItemTapped,
    this.emptyMessage = defaultEmptyMessage,
    this.getIsSelectable,
    this.canTapOnFolder = true,
  }) : super(key: key);

  final List<T> list;
  final PopupListItemBuilder<T> itemBuilder;
  final ValueSetter<T> onItemTapped;
  final Widget emptyMessage;
  final GetIsSelectable<T> getIsSelectable;
  final bool canTapOnFolder;

  @override
  Widget build(BuildContext context) => Material(
      elevation: 4,
      child: Center(
        child: IntrinsicWidth(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (list?.isEmpty == true)
                emptyMessage
              else if (list != null)
                ...list?.map((item) {
                  final itemWidget = itemBuilder(context, item);
                  return itemWidget;
                  // return item != MenuItem.separator &&
                  //         (canTapOnFolder || item.getChildren == null) &&
                  //         (getIsSelectable == null || getIsSelectable(item))
                  //     ? InkWell(
                  //         child: itemWidget,
                  //         onTap: () => onItemTapped(item),
                  //       )
                  //     : itemWidget;
                })
            ],
          ),
        ),
      ));
}

class MenuItemCombo<T> extends ListCombo<MenuItem<T>> {
  MenuItemCombo({
    @required MenuItem<T> item,
    Widget divider = _defaultMenuDivider,
    bool showSubmenuArrows = true,
    bool canTapOnFolder = false,

    // inherited
    Key key,
    @required PopupListItemBuilder<MenuItem<T>> itemBuilder,
    @required ValueSetter<MenuItem<T>> onItemTapped,
    MenuItemPopupBuilder<MenuItem<T>> popupBuilder,
    GetIsSelectable<MenuItem<T>> getIsSelectable,
    ProgressDecoratorBuilder progressDecoratorBuilder =
        buildDefaultProgressDecorator,
    bool refreshOnOpened = false,
    ValueChanged<bool> waitChanged,
    ProgressPosition progressPosition = ProgressPosition.child,
    PopupPosition position = PopupPosition.bottomMinMatch,
    Offset offset,
    double requiredSpace,
    EdgeInsets screenPadding = _defaultScreenPadding,
    PopupAutoClose autoClose = PopupAutoClose.notHovered,
    PopupAutoOpen autoOpen = PopupAutoOpen.tap,
    PopupAnimation animation = PopupAnimation.fade,
    Duration animationDuration = _defaultAnimationDuration,
    ValueChanged<bool> openedChanged,
    ValueChanged<bool> hoveredChanged,
    GestureTapCallback onTap,
    Color focusColor,
    Color hoverColor,
    Color highlightColor,
    Color splashColor,
  }) : super(
          key: key,
          getList: item.getChildren,
          itemBuilder: (context, item) => item == MenuItem.separator
              ? divider
              : MenuItemCombo<T>(
                  item: item,
                  divider: divider,
                  itemBuilder: showSubmenuArrows
                      ? (context, item) {
                          final widget = itemBuilder(context, item);
                          return item.getChildren == null ||
                                  widget is _ArrowedItem
                              ? widget
                              : _ArrowedItem(child: widget);
                        }
                      : itemBuilder,
                  onItemTapped: onItemTapped,
                  popupBuilder: popupBuilder ?? buildDefaultPopup,
                  getIsSelectable: getIsSelectable,
                  progressDecoratorBuilder: progressDecoratorBuilder,
                  refreshOnOpened: refreshOnOpened,
                  waitChanged: waitChanged,
                  progressPosition: progressPosition,
                  position: PopupPosition.right,
                  offset: offset,
                  requiredSpace: requiredSpace,
                  screenPadding: screenPadding,
                  autoClose: PopupAutoClose.notHovered,
                  autoOpen: PopupAutoOpen.hovered,
                  animation: animation,
                  animationDuration: animationDuration,
                  openedChanged: openedChanged,
                  onTap: canTapOnFolder || item.getChildren == null
                      ? () {
                          Combo.closeAll();
                          onItemTapped(item);
                        }
                      : null,
                  focusColor: focusColor,
                  hoverColor: hoverColor,
                  highlightColor: highlightColor,
                  splashColor: splashColor,
                ),
          onItemTapped: onItemTapped,
          popupBuilder: (context, list, itemBuilder, onItemTapped, mirrored,
                  getIsSelectable) =>
              (popupBuilder ?? buildDefaultPopup)(context, list, itemBuilder,
                  onItemTapped, mirrored, getIsSelectable, canTapOnFolder),
          getIsSelectable: getIsSelectable,
          progressDecoratorBuilder: progressDecoratorBuilder,
          refreshOnOpened: refreshOnOpened,
          waitChanged: waitChanged,
          progressPosition: progressPosition,
          child: itemBuilder(null, item),
          position: position,
          offset: offset,
          requiredSpace: requiredSpace,
          screenPadding: screenPadding,
          autoClose: autoClose,
          autoOpen: autoOpen,
          animation: animation,
          animationDuration: animationDuration,
          openedChanged: openedChanged,
          hoveredChanged: hoveredChanged,
          onTap: onTap,
          focusColor: focusColor,
          hoverColor: hoverColor,
          highlightColor: highlightColor,
          splashColor: splashColor,
        );

  static Widget buildDefaultPopup<T extends MenuItem>(
          BuildContext context,
          List<T> list,
          PopupListItemBuilder<T> itemBuilder,
          void Function(T value) onItemTapped,
          bool mirrored,
          GetIsSelectable<T> getIsSelectable,
          bool canTapOnFolder) =>
      MenuListPopup<T>(
          list: list,
          itemBuilder: itemBuilder,
          onItemTapped: onItemTapped,
          getIsSelectable: getIsSelectable,
          canTapOnFolder: canTapOnFolder);

  static Widget buildDefaultProgressDecorator(
          BuildContext context, bool waiting, bool mirrored, Widget child) =>
      ProgressDecorator(
          waiting: waiting,
          mirrored: false,
          progressBackgroundColor: Colors.transparent,
          progressValueColor:
              AlwaysStoppedAnimation(Colors.blueAccent.withOpacity(0.2)),
          child: child,
          progressHeight: null);
}
