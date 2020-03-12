library combos;

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

/// Determines how the popup should be placed depent on [Combo.child] position
enum PopupPosition {
  /// Place the popup on the bottom of the [Combo.child] with custom width
  bottom,

  /// Place the popup on the bottom of the [Combo.child] with same width
  bottomMatch,

  /// Place the popup on the bottom of the [Combo.child] with the equal or bigger width
  bottomMinMatch,

  /// Place the popup on the top of the [Combo.child] with custom width
  top,

  /// Place the popup on the top of the [Combo.child] with same width
  topMatch,

  /// Place the popup on the top of the [Combo.child] with the equal or bigger width
  topMinMatch,

  /// Place the popup on the right of the [Combo.child] with custom width
  right,

  /// Place the popup on the left of the [Combo.child] with custom width
  left,
}

/// Determines automatically opening mode of the popup
enum PopupAutoOpen {
  /// Without automatically opening
  none,

  /// Open when [Combo.child] tapped
  tap,

  /// Open when mouse enters on [Combo.child]
  hovered,
}

/// Determines automatically closing mode of the popup
enum PopupAutoClose {
  /// Without automatically closing
  none,

  /// Close when user tapped on the outside area of the popup
  tapOutside,

  /// Close when user tapped on the outside area of the popup and decorates
  /// [Combo.child] with [IgnorePointer] to prevent repeated opening
  tapOutsideWithChildIgnorePointer,

  /// Close when user tapped on the outside area of the popup except
  /// [Combo.child] area
  tapOutsideExceptChild,

  /// Close when mouse exits from [Combo.child] and [Combo.popup]
  /// and another popups opened by the [Combo] widgets
  /// which [Combo.popup] contains.
  notHovered,
}

/// Determines [Combo.popup] open/close animation
enum PopupAnimation {
  /// Without animation
  none,

  /// Faded opening and closing
  fade,

  /// Faded opening
  fadeOpen,

  /// Faded closing
  fadeClose,

  /// Indicates that popup contains custom animation.
  /// Afects only closing delay
  custom,
}

/// Signature for popup builder.
/// If [mirrored] is true, then popup position was changed due to screen edges
typedef PopupBuilder = Widget Function(BuildContext context, bool mirrored);

/// Simple combo box widget
///
/// Use [Combo] to link a widget with a popup setting [child] ans [popupBuilder] properties.
/// The [child] and [popupBuilder] properties is not required.
/// Popup can be opened or closed automatically by [autoOpen] and [autoClose] properties
/// or programmatically by [ComboState.open] and [ComboState.close] methods.
///
/// Popup position is determined by [position] property with the [offset]
/// If [autoMirror] is true, popup position may depends on screen edges using
/// [requiredSpace] and [screenPadding] predefined values, [screenPadding] also affects popup clipping.
///
/// You can apply 'fade' or custom animation to the popup using [animation] and [animationDuration]
/// properties. In case of custom animation popup will not be closed immediattely, but will wait for
/// animationDuration with [IgnorePointer].
///
/// [openedChanged] is raised when popup is opening or closing with appropriate bool value.
/// [hoveredChanged] is raised when mouse pointer enters on or exits from child or popup
/// and its children - when popup contains another [Combo] widgets.
/// [onTap] is raised when the user taps on popup and don't paint [InkWell] when it's null.
/// [onTap] also can be raised by 'long tap' event when [autoOpen] is set to [PopupAutoOpen.hovered]
/// and platform is not 'Web'
/// [focusColor], [hoverColor], [highlightColor], [splashColor] are [InkWell] parameters
///
/// See also:
///
///  * [AwaitCombo]
///  * [ListCombo]
///  * [SelectorCombo]
///  * [TypeaheadCombo]
///  * [MenuItemCombo]
class Combo extends StatefulWidget {
  /// Creates simple combo box widget
  ///
  /// Links a [child] widget with a popup that builds by [popupBuilder].
  /// The [child] and [popupBuilder] properties is not required.
  /// Popup can be opened or closed automatically by [autoOpen] and [autoClose] properties
  /// or programmatically by [ComboState.open] and [ComboState.close] methods.
  ///
  /// Popup position is determined by [position] property with the [offset]
  /// If [autoMirror] is true, popup position may depends on screen edges using
  /// [requiredSpace] and [screenPadding] predefined values, [screenPadding] also affects popup clipping.
  ///
  /// You can apply 'fade' or custom animation to the popup using [animation] and [animationDuration]
  /// properties. In case of custom animation popup will not be closed immediattely, but will wait for
  /// animationDuration with [IgnorePointer].
  ///
  /// [openedChanged] is raised when popup is opening or closing with appropriate bool value.
  /// [hoveredChanged] is raised when mouse pointer enters on or exits from child or popup
  /// and its children - when popup contains another [Combo] widgets.
  /// [onTap] is raised when the user taps on popup and don't paint [InkWell] when it's null.
  /// [onTap] also can be raised by 'long tap' event when [autoOpen] is set to [PopupAutoOpen.hovered]
  /// and platform is not 'Web'
  /// [focusColor], [hoverColor], [highlightColor], [splashColor] are [InkWell] parameters
  ///
  ///
  /// See also:
  ///
  ///  * [AwaitCombo]
  ///  * [ListCombo]
  ///  * [SelectorCombo]
  ///  * [TypeaheadCombo]
  ///  * [MenuItemCombo]
  const Combo({
    Key key,
    this.child,
    this.popupBuilder,
    this.position = PopupPosition.bottomMinMatch,
    this.offset,
    this.autoMirror = true,
    this.requiredSpace,
    this.screenPadding = defaultScreenPadding,
    this.autoOpen = PopupAutoOpen.tap,
    this.autoClose = PopupAutoClose.tapOutsideWithChildIgnorePointer,
    this.animation = PopupAnimation.fade,
    this.animationDuration = defaultAnimationDuration,
    this.openedChanged,
    this.hoveredChanged,
    this.onTap,
    this.focusColor,
    this.hoverColor,
    this.highlightColor,
    this.splashColor,
  })  : assert(position != null),
        assert(autoMirror != null),
        assert(autoClose != null),
        assert(animation != null),
        super(key: key);

  /// The widget below this widget in the tree.
  ///
  /// {@macro flutter.widgets.child}
  final Widget child;

  /// Called to obtain the popup widget.
  final PopupBuilder popupBuilder;

  /// Determines popup position depend on [child]
  final PopupPosition position;

  /// The offset to apply to the popup position
  final Offset offset;

  /// If true, popup position may depends on screen edges using [requiredSpace]
  /// and [screenPadding] values.
  final bool autoMirror;

  /// Determines required space between popup position and screen edge minus [screenPadding].
  /// If the popup height or width (depends on [position]) is longer the popup will be
  /// showed on opposite side of [child] and [popupBuilder] will be called with mirrored = true
  final double requiredSpace;

  /// Determines the padding of screen edges and clipping popups.
  /// (may be useful for hiding popups in app bar area)
  final EdgeInsets screenPadding;

  /// Determines automatically opening mode of the popup
  final PopupAutoOpen autoOpen;

  /// Determines automatically closing mode of the popup
  final PopupAutoClose autoClose;

  /// Determines [Combo.popup] open/close animation
  final PopupAnimation animation;

  /// Duration of open/close animation
  final Duration animationDuration;

  /// Callbacks when the popup is opening or closing
  final ValueChanged<bool> openedChanged;

  /// Callbacks when the mouse pointer enters on or exits from child or popup
  /// and its children - when popup contains another [Combo] widgets.
  final ValueChanged<bool> hoveredChanged;

  /// Called when the user taps on [child].
  /// Also can be called by 'long tap' event if [autoOpen] is set to [PopupAutoOpen.hovered]
  /// and platform is not 'Web'
  final GestureTapCallback onTap;

  /// The color of the ink response when the parent widget is focused.
  final Color focusColor;

  /// The color of the ink response when a pointer is hovering over it.
  final Color hoverColor;

  /// The highlight color of the ink response when pressed.
  final Color highlightColor;

  /// The splash color of the ink response.
  final Color splashColor;

  /// Default value of [Combo.animationDuration]
  static const defaultAnimationDuration = Duration(milliseconds: 150);

  /// Default value of [Combo.screenPadding]
  static const defaultScreenPadding = EdgeInsets.all(16);

  /// Closes all opened by [Combo] popups
  static void closeAll() => ComboState._closes.add(true);

  @override
  ComboState createState() => ComboState();
}

/// State for a [Combo].
///
/// Can [open] and [close] popups.
class ComboState<T extends Combo> extends State<T> {
  // ignore: close_sinks
  static final _closes = StreamController.broadcast();
  final _scrolls = StreamController.broadcast();
  final _layerLink = LayerLink();
  OverlayEntry _overlay;
  StreamSubscription _subscription;
  Completer<double> _closeCompleter;
  var _hovered = false;
  bool _lastHovered;
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

  /// Opens the popup
  void open() {
    if (_overlay != null) return;
    if (widget.openedChanged != null) widget.openedChanged(true);
    if (_fadeClose) _closeCompleter = Completer();
    _overlay = _createOverlay();
    if (_overlay == null) return;
    Overlay.of(context).insert(_overlay);
    setState(() {});
  }

  /// Closes the popup
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
      if (widget.hoveredChanged != null && _lastHovered != true) {
        _lastHovered = true;
        widget.hoveredChanged(true);
      }
      if (!opened && widget.autoOpen == PopupAutoOpen.hovered) {
        open();
      }
    } else {
      await Future.delayed(const Duration(milliseconds: 50));
      if (_hovered) return;
      if (widget.hoveredChanged != null && _lastHovered != false) {
        _lastHovered = false;
        widget.hoveredChanged(false);
      }
      if (opened && widget.autoClose == PopupAutoClose.notHovered) {
        close();
      }
    }
  }

  @protected
  Widget getChild() => widget.child;
  @protected
  Widget getPopup(BuildContext context, bool mirrored) =>
      widget.popupBuilder == null
          ? null
          : widget.popupBuilder(context, mirrored);

  OverlayEntry _createOverlay() => OverlayEntry(builder: (context) {
        if (this.context == null) return null;
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
          mirrored = widget.autoMirror
              ? () {
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
                                        widget.position ==
                                            PopupPosition.topMatch ||
                                        widget.position ==
                                            PopupPosition.topMinMatch
                                    ? 0
                                    : size.height) -
                                offsety -
                                (widget.screenPadding?.bottom ?? 0);
                        }
                      }() <
                      requiredSpace;
                }()
              : false;
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

        Widget overlay = StreamBuilder(
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
                  FutureBuilder<Offset>(
                      future: _sizeCompleter.future,
                      builder: (context, snapshot) => Positioned(
                            top: (snapshot.data?.dy ?? 0) -
                                (widget.screenPadding?.top ?? 0),
                            left: (snapshot.data?.dx ?? 0) -
                                (widget.screenPadding?.left ?? 0),
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
                  duration: widget.animationDuration ?? Duration.zero,
                  child: child,
                ),
              ),
            );
        if (_fadeOpen) overlay = animate(0.0, Future.value(1.0), overlay);
        if (_fadeClose && _closeCompleter != null) {
          overlay = animate(1.0, _closeCompleter.future, overlay);
        }

        if (widget.screenPadding != null) {
          overlay = Padding(
              padding: widget.screenPadding, child: ClipRect(child: overlay));
        }

        if (widget.autoClose != PopupAutoClose.none &&
            (widget.autoClose != PopupAutoClose.notHovered || !kIsWeb)) {
          overlay = Stack(children: [
            GestureDetector(onPanDown: (_) {
              if (widget.autoClose != PopupAutoClose.tapOutsideExceptChild ||
                  !renderBox.hitTest(BoxHitTestResult(),
                      position: renderBox.globalToLocal(_.globalPosition))) {
                close();
              }
            }),
            overlay,
          ]);
        }

        return _ComboOverlay(child: overlay, comboState: this);
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

/// Signature for futured popup builder.
/// ('Mirrored' flag cannot be passed as there is no possibility to get popup size immediately)
typedef AwaitPopupBuilder = FutureOr<Widget> Function(BuildContext context);

/// Signature to build the progress decorator.
/// [waiting] indicates that the popup is getting by [AwaitPopupBuilder]
/// [mirrored] indicates that the popup position was changed due to screen edges
/// [child] is popup content
typedef ProgressDecoratorBuilder = Widget Function(
    BuildContext context, bool waiting, bool mirrored, Widget child);

/// Determine the progress container - [Combo.child] or [Combo.popup]
enum ProgressPosition { child, popup }

/// Default widget for progress indication for futured popups
class ProgressDecorator extends StatefulWidget {
  /// Creates the progress decorator
  const ProgressDecorator({
    Key key,
    @required this.child,
    this.waiting = false,
    this.mirrored = false,
    this.progressBackgroundColor,
    this.progressValueColor,
    this.progressHeight = 2.0,
  })  : assert(child != null),
        super(key: key);

  /// The widget below this widget in the tree.
  ///
  /// {@macro flutter.widgets.child}
  final Widget child;

  /// Indicates that the popup getting is in progress
  final bool waiting;

  /// Indicates that the popup position was changed due to screen edges
  final bool mirrored;

  /// The progress indicator's background color.
  final Color progressBackgroundColor;

  /// The progress indicator's color as an animated value.
  final Animation<Color> progressValueColor;

  /// Height of the progress indicator.
  /// If null, indicator stretches by the popup area
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

/// Combo widget with the delayed getting of the popup content and progress indication
/// See also:
///
///  * [Combo]
///  * [ListCombo]
///  * [SelectorCombo]
///  * [TypeaheadCombo]
///  * [MenuItemCombo]
class AwaitCombo extends Combo {
  /// Creates combo widget with the delayed getting of the popup content and progress indication
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
    bool autoMirror = true,
    double requiredSpace,
    EdgeInsets screenPadding = Combo.defaultScreenPadding,
    PopupAutoOpen autoOpen = PopupAutoOpen.tap,
    PopupAutoClose autoClose = PopupAutoClose.tapOutsideWithChildIgnorePointer,
    PopupAnimation animation = PopupAnimation.fade,
    Duration animationDuration = Combo.defaultAnimationDuration,
    ValueChanged<bool> openedChanged,
    ValueChanged<bool> hoveredChanged,
    GestureTapCallback onTap,
    Color focusColor,
    Color hoverColor,
    Color highlightColor,
    Color splashColor,
  })  : awaitPopupBuilder = popupBuilder,
        assert(refreshOnOpened != null),
        super(
          key: key,
          child: child,
          position: position,
          offset: offset,
          autoMirror: autoMirror,
          requiredSpace: requiredSpace,
          screenPadding: screenPadding,
          autoOpen: autoOpen,
          autoClose: autoClose,
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

  /// Define the progress decorator widget
  final ProgressDecoratorBuilder progressDecoratorBuilder;

  /// Called to obtain the futured popup content.
  final AwaitPopupBuilder awaitPopupBuilder;

  /// Indicates that the popup should call [awaitPopupBuilder]
  /// each time when popup is opened to update the content
  final bool refreshOnOpened;

  /// Called when the popup content is getting or got
  final ValueChanged<bool> waitChanged;

  /// Determine the progress container - [Combo.child] or [Combo.popup]
  final ProgressPosition progressPosition;

  @override
  AwaitComboStateBase createState() => AwaitComboState();

  /// Builds defaut progress decorator
  static Widget buildDefaultProgressDecorator(
          BuildContext context, bool waiting, bool mirrored, Widget child) =>
      ProgressDecorator(waiting: waiting, mirrored: mirrored, child: child);
}

/// State for a [AwaitCombo].
class AwaitComboState extends AwaitComboStateBase<AwaitCombo, Widget> {
  @override
  FutureOr<Widget> getContent(BuildContext context) =>
      widget.awaitPopupBuilder == null
          ? null
          : widget.awaitPopupBuilder(context);

  @override
  Widget buildContent(Widget content, bool mirrored) => content;
}

/// Base state for the combo widgets with the futured popup content builder.
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

  @protected
  FutureOr<C> getContent(BuildContext context);
  @protected
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

  @protected
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

/// Signature to get the popup items.
typedef PopupGetList<T> = FutureOr<List<T>> Function();

/// Signature to build the popup item widget.
typedef PopupListItemBuilder<T> = Widget Function(BuildContext context, T item);

/// Signature to determine if the popup item is active for tapping
typedef GetIsSelectable<T> = bool Function(T item);

/// Signature to build the widget containing popup items
/// [list] of the popup items
/// [itemBuilder] builds the popup item widget
/// [onItemTapped] calls when user taps on the item
/// [mirrored] indicates that the popup position was changed due to screen edges
/// [getIsSelectable] determines if the popup item is active for tapping
typedef ListPopupBuilder<T> = Widget Function(
    BuildContext context,
    List<T> list,
    PopupListItemBuilder<T> itemBuilder,
    void Function(T value) onItemTapped,
    bool mirrored,
    GetIsSelectable<T> getIsSelectable);

/// Default widget for empty list indication
const Widget defaultEmptyMessage = Padding(
  padding: EdgeInsets.all(16),
  child: Text(
    'No Items',
    textAlign: TextAlign.center,
    style: TextStyle(color: Colors.grey),
  ),
);

/// Default widget for displaying popup items
class ListPopup<T> extends StatelessWidget {
  /// Creates default widget for displaying popup items
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

  /// List of the popup items
  final List<T> list;

  /// Builds the popup item widget
  final PopupListItemBuilder<T> itemBuilder;

  /// Calls when user taps on the item
  final ValueSetter<T> onItemTapped;

  /// The width of the list content
  /// Must be setted if [Combo.position] not is [PopupPosition.bottomMatch]
  /// or [PopupPosition.topMatch] (ListView cannot be stretched by its content)
  final double width;

  /// Maximum height of popup
  final double maxHeight;

  /// Widget for empty list indication
  final Widget emptyMessage;

  /// Determines if the popup item is active for tapping
  final GetIsSelectable<T> getIsSelectable;

  @override
  Widget build(BuildContext context) => ConstrainedBox(
        constraints: BoxConstraints(
            maxWidth: width ?? double.infinity,
            maxHeight: maxHeight ?? double.infinity),
        child: Material(
          elevation: 4,
          child: list?.isEmpty == true
              ? emptyMessage == null
                  ? null
                  : Column(
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

/// Combo widget for displaying the items list
/// Combo widget with the delayed getting of the popup content and progress indication
/// See also:
///
///  * [Combo]
///  * [AwaitCombo]
///  * [SelectorCombo]
///  * [TypeaheadCombo]
///  * [MenuItemCombo]
class ListCombo<T> extends AwaitCombo {
  /// Creates combo widget for displaying the items list
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
    bool autoMirror = true,
    double requiredSpace,
    EdgeInsets screenPadding = Combo.defaultScreenPadding,
    PopupAutoOpen autoOpen = PopupAutoOpen.tap,
    PopupAutoClose autoClose = PopupAutoClose.tapOutsideWithChildIgnorePointer,
    PopupAnimation animation = PopupAnimation.fade,
    Duration animationDuration = Combo.defaultAnimationDuration,
    ValueChanged<bool> openedChanged,
    ValueChanged<bool> hoveredChanged,
    GestureTapCallback onTap,
    Color focusColor,
    Color hoverColor,
    Color highlightColor,
    Color splashColor,
  })  : listPopupBuilder = popupBuilder ?? buildDefaultPopup,
        assert(itemBuilder != null),
        super(
          key: key,
          progressDecoratorBuilder: progressDecoratorBuilder,
          refreshOnOpened: refreshOnOpened,
          waitChanged: waitChanged,
          progressPosition: progressPosition,
          child: child,
          position: position,
          offset: offset,
          autoMirror: autoMirror,
          requiredSpace: requiredSpace,
          screenPadding: screenPadding,
          autoOpen: autoOpen,
          autoClose: autoClose,
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

  /// Popup items getter.
  final PopupGetList<T> getList;

  /// Popup item widget builder.
  final PopupListItemBuilder<T> itemBuilder;

  /// Calls when the user taps on the item.
  final ValueSetter<T> onItemTapped;

  /// Builder of widget for displaying popup items list.
  final ListPopupBuilder<T> listPopupBuilder;

  /// Determines if the popup item is active for tapping
  final GetIsSelectable<T> getIsSelectable;

  @override
  ListComboState<ListCombo<T>, T> createState() =>
      ListComboState<ListCombo<T>, T>();

  /// Builds default widget for displaying popup items.
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

/// State for a [ListCombo].
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

  @protected
  void itemTapped(T item) {
    if (widget.onItemTapped != null) {
      widget.onItemTapped(item);
    }
    super.close();
  }
}

/// Combo widget for displaying the items list and selected item
/// Combo widget with the delayed getting of the popup content and progress indication
/// See also:
///
///  * [Combo]
///  * [AwaitCombo]
///  * [ListCombo]
///  * [TypeaheadCombo]
///  * [MenuItemCombo]
class SelectorCombo<T> extends ListCombo<T> {
  /// Creates combo widget for displaying the items list and selected item
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
    bool autoMirror = true,
    double requiredSpace,
    EdgeInsets screenPadding = Combo.defaultScreenPadding,
    PopupAutoOpen autoOpen = PopupAutoOpen.tap,
    PopupAutoClose autoClose = PopupAutoClose.tapOutsideWithChildIgnorePointer,
    PopupAnimation animation = PopupAnimation.fade,
    Duration animationDuration = Combo.defaultAnimationDuration,
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
          autoMirror: autoMirror,
          requiredSpace: requiredSpace,
          screenPadding: screenPadding,
          autoOpen: autoOpen,
          autoClose: autoClose,
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

  /// The 'selected' item to display in [Combo.child] area
  final T selected;

  /// Builds the thid widget for [selected] item
  /// If null uses [ListCombo.itemBuilder]
  final PopupListItemBuilder<T> childBuilder;

  @override
  SelectorComboState<SelectorCombo<T>, T> createState() =>
      SelectorComboState<SelectorCombo<T>, T>(selected);
}

/// State for a [SelectorCombo].
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

/// Signature to get the popup items using the text from [TypeaheadCombo].
typedef TypeaheadGetList<T> = FutureOr<List<T>> Function(String text);

/// Signature to get the text that corresponds to popup item
typedef PopupGetItemText<T> = String Function(T item);

/// Combo widget for displaying the items list and selected item
/// Combo widget with the delayed getting of the popup content and progress indication
/// See also:
///
///  * [Combo]
///  * [AwaitCombo]
///  * [ListCombo]
///  * [SelectorCombo]
///  * [MenuItemCombo]
/// corresponds to the user's text
class TypeaheadCombo<T> extends SelectorCombo<T> {
  /// Creates combo widget for displaying the items list and selected item
  const TypeaheadCombo({
    Key key,
    @required TypeaheadGetList<T> getList,
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
    bool autoMirror = true,
    double requiredSpace,
    EdgeInsets screenPadding = Combo.defaultScreenPadding,
    PopupAnimation animation = PopupAnimation.fade,
    Duration animationDuration = Combo.defaultAnimationDuration,
    ValueChanged<bool> openedChanged,
    ValueChanged<bool> hoveredChanged,
    GestureTapCallback onTap,
    Color focusColor,
    Color hoverColor,
    Color highlightColor,
    Color splashColor,
  })  : typeaheadGetList = getList,
        assert(getList != null),
        assert(enabled != null),
        assert(autofocus != null),
        assert(getItemText != null),
        assert(minTextLength >= 0),
        assert(cleanAfterSelection != null),
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
          autoMirror: autoMirror,
          requiredSpace: requiredSpace,
          screenPadding: screenPadding,
          autoOpen: PopupAutoOpen.none,
          autoClose: PopupAutoClose.tapOutsideExceptChild,
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

  /// Popup items getter using user's text.
  final TypeaheadGetList<T> typeaheadGetList;

  /// The decoration to show around the text field.
  final InputDecoration decoration;

  /// If false the text field is "disabled": it ignores taps and its
  /// [decoration] is rendered in grey.
  final bool enabled;

  /// {@macro flutter.widgets.editableText.autofocus}
  final bool autofocus;

  /// Gets the text that corresponds to popup item
  final PopupGetItemText<T> getItemText;

  /// Minimum text length to start getting the list
  /// if [minTextLength] = 0, shows the popup immediatelly on focus
  final int minTextLength;

  /// Defines the keyboard focus for this widget.
  final FocusNode focusNode;

  /// Delay between last text change to throttling user's inputs
  final Duration delay;

  /// Determine if text should be cleared when user select the item
  final bool cleanAfterSelection;

  @override
  TypeaheadComboState<TypeaheadCombo<T>, T> createState() =>
      TypeaheadComboState<TypeaheadCombo<T>, T>(
          selected,
          selected == null ? '' : getItemText(selected),
          focusNode ?? FocusNode());
}

/// State for [TypeaheadCombo]
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
        await Future.delayed(widget.delay ?? Duration.zero);
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

/// Menu items container
class MenuItem<T> {
  /// Creates menu items container
  const MenuItem(this.item, [this.getChildren]);

  /// Widget to designate a menu items separator
  static const separator = MenuItem(null);

  /// Menu item
  final T item;

  /// Menu item children getter
  final PopupGetList<MenuItem<T>> getChildren;
}

/// Signature to build the widget containing menu items
/// [list] of the menu items
/// [itemBuilder] builds the menu item widget
/// [onItemTapped] calls when user taps on the menu item
/// [mirrored] indicates that the popup position was changed due to screen edges
/// [getIsSelectable] determines if the menu item is active for tapping
/// [canTapOnFolder] determines if the menu items that containing another items is selectable
typedef MenuItemPopupBuilder<T> = Widget Function(
    BuildContext context,
    List<T> list,
    PopupListItemBuilder<T> itemBuilder,
    void Function(T value) onItemTapped,
    bool mirrored,
    GetIsSelectable<T> getIsSelectable,
    bool canTapOnFolder);

/// Default widget to display menu separator
class MenuDivider extends StatelessWidget {
  /// Creates default widget to display menu separator
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

/// Default widget for displaying list of the menu items
class MenuListPopup<T extends MenuItem> extends StatelessWidget {
  /// Creates default widget for displaying list of the menu items
  const MenuListPopup(
      {Key key,
      @required this.list,
      @required this.itemBuilder,
      @required this.onItemTapped,
      this.emptyMessage = defaultEmptyMessage,
      this.getIsSelectable,
      this.canTapOnFolder = true,
      this.backgroundColor = Colors.white,
      this.borderRadius,
      this.elevation = 4})
      : assert(itemBuilder != null),
        assert(canTapOnFolder != null),
        super(key: key);

  /// List of the menu items
  final List<T> list;

  /// Builds the menu item widget
  final PopupListItemBuilder<T> itemBuilder;

  /// Calls when user taps on the menu item
  final ValueSetter<T> onItemTapped;

  /// Widget to displaying empty menu list
  final Widget emptyMessage;

  /// Determines if the menu item is active for tapping
  final GetIsSelectable<T> getIsSelectable;

  /// Determines if the menu items that containing another items is selectable
  final bool canTapOnFolder;

  /// Menu bachground color
  final Color backgroundColor;

  /// The corners of the menu are rounded by this value
  final BorderRadius borderRadius;

  /// The z-coordinate at which to place the menu relative to its parent.
  final double elevation;

  @override
  Widget build(BuildContext context) => Material(
      color: backgroundColor,
      borderRadius: borderRadius,
      elevation: elevation,
      child: IntrinsicWidth(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (list?.isEmpty == true)
              emptyMessage ?? const SizedBox()
            else if (list != null)
              ...list?.map((item) => itemBuilder(context, item))
          ],
        ),
      ));
}

/// Combo widget for displaying the menu
/// Combo widget with the delayed getting of the popup content and progress indication
/// See also:
///
///  * [Combo]
///  * [AwaitCombo]
///  * [ListCombo]
///  * [SelectorCombo]
///  * [TypeaheadCombo]
class MenuItemCombo<T> extends ListCombo<MenuItem<T>> {
  /// Creates combo widget for displaying the menu
  MenuItemCombo({
    Key key,

    /// Menu item
    @required MenuItem<T> item,

    /// Menu separator widget
    Widget divider = _defaultMenuDivider,

    /// Indicates that the menu items that contains another items should display 'right arrow'
    bool showSubmenuArrows = true,

    /// Determines if the menu items that containing another items is selectable
    bool canTapOnFolder = false,

    // inherited
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
    bool autoMirror = true,
    double requiredSpace,
    EdgeInsets screenPadding = Combo.defaultScreenPadding,
    PopupAutoOpen autoOpen = PopupAutoOpen.tap,
    PopupAutoClose autoClose = PopupAutoClose.notHovered,
    PopupAnimation animation = PopupAnimation.fade,
    Duration animationDuration = Combo.defaultAnimationDuration,
    ValueChanged<bool> openedChanged,
    ValueChanged<bool> hoveredChanged,
    GestureTapCallback onTap,
    Color focusColor,
    Color hoverColor,
    Color highlightColor,
    Color splashColor,
    Color rootFocusColor,
    Color rootHoverColor,
    Color rootHighlightColor,
    Color rootSplashColor,
  })  : assert(item != null),
        assert(divider != null),
        assert(showSubmenuArrows != null),
        assert(canTapOnFolder != null),
        super(
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
                  autoMirror: true,
                  requiredSpace: requiredSpace,
                  screenPadding: screenPadding,
                  autoOpen: PopupAutoOpen.hovered,
                  autoClose: PopupAutoClose.notHovered,
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
          autoMirror: autoMirror,
          requiredSpace: requiredSpace,
          screenPadding: screenPadding,
          autoOpen: autoOpen,
          autoClose: autoClose,
          animation: animation,
          animationDuration: animationDuration,
          openedChanged: openedChanged,
          hoveredChanged: hoveredChanged,
          onTap: onTap,
          focusColor: rootFocusColor ?? focusColor,
          hoverColor: rootHoverColor ?? hoverColor,
          highlightColor: rootHighlightColor ?? highlightColor,
          splashColor: rootSplashColor ?? splashColor,
        );

  /// Builds default widget to display list of the menu items
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

  /// Builds default separator widget
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
