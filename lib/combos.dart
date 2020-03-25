library combos;

import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

// * types

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
enum ComboAutoOpen {
  /// Without automatically opening
  none,

  /// Open when [Combo.child] tapped
  tap,

  /// Open when mouse enters on [Combo.child]
  hovered,
}

/// Determines automatically closing mode of the popup
enum ComboAutoClose {
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

/// Signature to build the progress decorator.
/// [waiting] indicates that the popup is getting by [AwaitPopupBuilder]
/// [mirrored] indicates that the popup position was changed due to screen edges
/// [child] is popup content
typedef ProgressDecoratorBuilder = Widget Function(
    BuildContext context, bool waiting, bool mirrored, Widget child);

/// Determine the progress container - [Combo.child] or [Combo.popup]
enum ProgressPosition { child, popup }

/// Signature to build the widget containing popup items
/// [list] of the popup items
/// [itemBuilder] builds the popup item widget
/// [onItemTapped] calls when user taps on the item
/// [mirrored] indicates that the popup position was changed due to screen edges
/// [getIsSelectable] determines if the popup item is active for tapping
typedef ListPopupBuilder = Widget Function(
    BuildContext context,
    ComboParameters parameters,
    List list,
    PopupListItemBuilder itemBuilder,
    GetIsSelectable getIsSelectable,
    void Function(dynamic value) onItemTapped,
    dynamic scrollToItem,
    bool mirrored);

/// Default widget for displaying list of popup items
class ListPopup extends StatefulWidget {
  /// Creates default widget for displaying popup items
  const ListPopup({
    Key key,
    @required this.parameters,
    @required this.list,
    @required this.itemBuilder,
    @required this.getIsSelectable,
    @required this.onItemTapped,
    @required this.scrollToItem,
  }) : super(key: key);

  /// Common parameters for combo widgets
  final ComboParameters parameters;

  /// List of the popup items
  final List list;

  /// Builds the popup item widget
  final PopupListItemBuilder itemBuilder;

  /// Determines if the popup item is active for tapping
  final GetIsSelectable getIsSelectable;

  /// Calls when user taps on the item
  final ValueSetter onItemTapped;

  /// Determines the list item to which you want to move the scroll position
  final dynamic scrollToItem;

  @override
  _ListPopupState createState() => _ListPopupState();
}

class _ListPopupState extends State<ListPopup> {
  ScrollController _scrollController;

  @override
  void didUpdateWidget(ListPopup oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.list != oldWidget.list) setState(() {});
  }

  List<Widget> _initController(BuildContext context) {
    var initialScrollOffset = 0.0;
    List<Widget> widgets;
    final scrollToItem = widget.scrollToItem;
    if (scrollToItem != null) {
      final parameters = widget.parameters;
      final itemBuilder = widget.itemBuilder;
      var totalHeight = 0.0;
      widgets = widget.list.map((item) {
        final widget = itemBuilder(context, parameters, item);
        if (totalHeight != null) {
          if (widget is PreferredSizeWidget) {
            if (item == scrollToItem) initialScrollOffset = totalHeight;
            totalHeight += widget.preferredSize.height;
          } else {
            totalHeight = null;
          }
        }
        return widget;
      }).toList();
      if (totalHeight != null) {
        final listMaxHeight = parameters.listMaxHeight;
        if (totalHeight <= listMaxHeight) {
          initialScrollOffset = 0;
        } else {
          if (totalHeight - initialScrollOffset < listMaxHeight) {
            initialScrollOffset = totalHeight - listMaxHeight;
          }
        }
      }
    }
    _scrollController =
        ScrollController(initialScrollOffset: initialScrollOffset);
    return widgets;
  }

  @override
  Widget build(BuildContext context) {
    final parameters = widget.parameters;
    final itemBuilder = widget.itemBuilder;
    final getIsSelectable = widget.getIsSelectable;
    final list = widget.list;
    if (list == null) return const SizedBox();
    if (list.isEmpty) return parameters.emptyListIndicator;
    List<Widget> widgets;
    if (_scrollController == null) widgets = _initController(context);
    final child = ListView.builder(
        padding: EdgeInsets.zero,
        controller: _scrollController,
        shrinkWrap: true,
        physics: ClampingScrollPhysics(),
        itemCount: widget.list?.length ?? 0,
        itemBuilder: (context, index) {
          final item = list[index];
          final itemWidget = widgets == null
              ? itemBuilder(context, parameters, item)
              : widgets[index];
          return getIsSelectable == null || getIsSelectable(item)
              ? InkWell(
                  child: itemWidget,
                  onTap: () => widget.onItemTapped(item),
                )
              : itemWidget;
        });

    return ConstrainedBox(
        constraints: BoxConstraints(maxHeight: parameters.listMaxHeight),
        child: child);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
}

/// Default widget for displaying list of the menu items
class MenuListPopup extends StatelessWidget {
  /// Creates default widget for displaying list of the menu items
  const MenuListPopup({
    Key key,
    @required this.parameters,
    @required this.list,
    @required this.itemBuilder,
    @required this.onItemTapped,
    this.getIsSelectable,
  })  : assert(itemBuilder != null),
        super(key: key);

  /// Common parameters for combo widgets
  final ComboParameters parameters;

  /// List of the menu items
  final List list;

  /// Builds the menu item widget
  final PopupListItemBuilder itemBuilder;

  /// Calls when user taps on the menu item
  final ValueSetter onItemTapped;

  /// Determines if the menu item is active for tapping
  final GetIsSelectable getIsSelectable;

  @override
  Widget build(BuildContext context) {
    final parameters = this.parameters;
    return LayoutBuilder(builder: (context, constraints) {
      final hasSize = constraints.maxWidth != double.infinity;
      final menu = Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (list?.isEmpty == true)
            parameters.emptyListIndicator ?? const SizedBox()
          else if (list != null)
            ...list.map((item) => itemBuilder(context, parameters, item))
        ],
      );
      return hasSize ? menu : IntrinsicWidth(child: menu);
    });
  }
}

/// Default widget to display menu divider
class MenuDivider extends StatelessWidget {
  /// Creates default widget to display menu divider
  const MenuDivider({Key key, this.color = Colors.black12}) : super(key: key);

  // Divider color
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
    return Stack(children: [
      widget.child,
      if (_waiting) ...[
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
      ]
    ]);
  }
}

/// Signature for building the [Combo.child] decorator.
/// Using for [ComboParameters.childDecoratorBuilder],
/// [ComboParameters.childContentDecoratorBuilder].
typedef ChildDecoratorBuilder = Widget Function(BuildContext context,
    ComboParameters parameters, bool opened, Widget child);

/// Signature for building [Combo.popup] decorator.
/// Using for [ComboParameters.popupDecoratorBuilder],
/// [ComboParameters.menuPopupDecoratorBuilder].
typedef PopupDecoratorBuilder = Widget Function(
    BuildContext context, ComboParameters parameters, Widget child);

// * context

/// Common parameters for combo widgets.
class ComboParameters {
  /// Creates common parameters for combo widgets.
  const ComboParameters({
    this.position,
    this.offset,
    this.autoMirror,
    this.requiredSpace,
    this.screenPadding,
    this.autoOpen,
    this.autoClose,
    this.enabled,
    this.animation,
    this.animationDuration,
    this.childContentDecoratorBuilder,
    this.childDecoratorBuilder,
    this.popupDecoratorBuilder,
    this.popupContraints,
    this.progressDecoratorBuilder,
    this.refreshOnOpened,
    this.progressPosition,
    this.listPopupBuilder,
    this.listMaxHeight,
    this.emptyListIndicator,
    this.inputThrottle,
    this.menuPopupBuilder,
    this.menuPopupDecoratorBuilder,
    this.menuDivider,
    this.menuShowArrows,
    this.menuCanTapOnFolder,
    this.menuProgressDecoratorBuilder,
    this.menuRefreshOnOpened,
    this.menuProgressPosition,
  });

  // Common parameters with dafault values for combo widgets
  static const defaultParameters = ComboParameters(
    autoMirror: true,
    screenPadding: defaultScreenPadding,
    autoOpen: ComboAutoOpen.tap,
    autoClose: ComboAutoClose.tapOutsideWithChildIgnorePointer,
    enabled: true,
    animation: PopupAnimation.fade,
    animationDuration: defaultAnimationDuration,
    childContentDecoratorBuilder: buildDefaultChildContentDecorator,
    childDecoratorBuilder: buildDefaultChildDecorator,
    popupDecoratorBuilder: buildDefaultPopupDecorator,
    progressDecoratorBuilder: buildDefaultProgressDecorator,
    refreshOnOpened: false,
    progressPosition: ProgressPosition.popup,
    listPopupBuilder: buildDefaultListPopup,
    listMaxHeight: 308.0,
    emptyListIndicator: Padding(
      padding: EdgeInsets.all(16),
      child: Text('No Items',
          textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
    ),
    inputThrottle: Duration(milliseconds: 300),
    menuPopupBuilder: buildDefaultMenuPopup,
    menuPopupDecoratorBuilder: buildDefaultMenuPopupDecorator,
    menuDivider: MenuDivider(),
    menuShowArrows: true,
    menuCanTapOnFolder: false,
    menuProgressDecoratorBuilder: buildDefaultMenuProgressDecorator,
    menuRefreshOnOpened: false,
    menuProgressPosition: ProgressPosition.child,
  );

  // * Combo parameters

  /// Determines popup position depend on [Combo.child] position.
  /// Default is [PopupPosition.bottomMatch] for [ListCombo]s and
  /// [PopupPosition.bottomMinMatch] for others.
  final PopupPosition position;

  /// The offset to apply to the popup position.
  final Offset offset;

  /// If true, popup position may depends on screen edges using [requiredSpace]
  /// and [screenPadding] values.
  /// Default is true
  final bool autoMirror;

  /// Determines required space between popup position and screen edge minus [screenPadding].
  /// If the popup height or width (depends on [position]) is longer the popup will be
  /// showed on opposite side of [Combo.child] and [Combo.popupBuilder]
  /// will be called with mirrored = true.
  /// Default is 1/3 of screen dimensions.
  final double requiredSpace;

  /// Determines the padding of screen edges and clipping popups.
  /// (may be useful for hiding popups in app bar area).
  /// Default is [defaultScreenPadding] value (EdgeInsets.all(16.0)).
  final EdgeInsets screenPadding;

  /// Determines automatically opening mode of the popup.
  /// Default is [ComboAutoOpen.tap].
  final ComboAutoOpen autoOpen;

  /// Determines automatically closing mode of the popup.
  /// Default is [ComboAutoClose.tapOutsideWithChildIgnorePointer]
  final ComboAutoClose autoClose;

  /// If false the combo is in "disabled" mode: it ignores taps.
  /// Setting it to false closes all combo popups in the context.
  final bool enabled;

  /// Determines [Combo.popup] open/close animation.
  /// Default is [PopupAnimation.fade].
  final PopupAnimation animation;

  /// Duration of open/close animation.
  /// Default is [defaultAnimationDuration] value (milliseconds: 150).
  final Duration animationDuration;

  /// Define decorator widget for all [Combo.child] widgets
  /// with [Combo.ignoreChildDecorator] = false in the context.
  final ChildDecoratorBuilder childContentDecoratorBuilder;

  /// Define decorator widget for all [Combo.child] with its [InkWell]
  /// with [Combo.ignoreChildDecorator] = false in the context.
  final ChildDecoratorBuilder childDecoratorBuilder;

  /// Define decorator widget for all [Combo] popup widgets in the context.
  final PopupDecoratorBuilder popupDecoratorBuilder;

  /// Define constraints for the combo popup content.
  /// (May be useful for [ListCombo] with position different of
  /// [PopupPosition.bottomMatch] or [PopupPosition.topMatch]
  /// because [ListView] cannot automatically calculate its width).
  final BoxConstraints popupContraints;

  // * AwaitCombo parameters

  /// Define the progress decorator widget.
  /// Default is [buildDefaultProgressDecorator] value.
  final ProgressDecoratorBuilder progressDecoratorBuilder;

  /// Indicates that the popup should call [AwaitCombo.awaitPopupBuilder]
  /// each time when popup is opened to update the content.
  /// Default is false.
  final bool refreshOnOpened;

  /// Determine the progress container - [Combo.child] or [Combo.popup].
  /// Default is [ProgressPosition.popup].
  final ProgressPosition progressPosition;

  // * ListCombo parameters

  /// Builder of widget for displaying popup items list.
  /// Default is [buildDefaultListPopup] value.
  final ListPopupBuilder listPopupBuilder;

  /// Maximum height of list popup.
  /// Default is 308.0
  final double listMaxHeight;

  /// Widget for empty list or sub-menus indication.
  /// Default is 'No Items' text caption.
  final Widget emptyListIndicator;

  // * TypeaheadCombo parameters

  /// Define delay between last text change to throttling user's inputs
  /// in [TypeaheadCombo].
  /// Default is Duration(milliseconds: 300)
  final Duration inputThrottle;

  // * MenuItemCombo parameters

  /// Builder of widget for displaying popup items list.
  /// Default is [buildDefaultMenuPopup] value.
  final ListPopupBuilder menuPopupBuilder;

  /// Define decorator widget for all [MenuCombo] popups in the context.
  final PopupDecoratorBuilder menuPopupDecoratorBuilder;

  /// Menu devider widget.
  /// Default is [MenuDivider].
  final Widget menuDivider;

  /// Indicates that the menu items that contains another items should
  /// display 'right arrow'.
  /// Default is true
  final bool menuShowArrows;

  /// Determines if the menu items that containing another items is selectable.
  /// Default is false.
  final bool menuCanTapOnFolder;

  /// Define default menu progress decorator.
  /// Default is [buildDefaultMenuProgressDecorator] value.
  final ProgressDecoratorBuilder menuProgressDecoratorBuilder;

  /// Indicates that the menu item should  update sub-items
  /// each time when menu is opened.
  /// Default is false.
  final bool menuRefreshOnOpened;

  /// Determine the menu progress container - [Combo.child] for menu item
  /// or [Combo.popup] for its subitems.
  /// Default is [ProgressPosition.child].
  final ProgressPosition menuProgressPosition;

  /// Creates a copy of this combo parameters but with the given fields replaced with
  /// the new values.
  ComboParameters copyWith({
    PopupPosition position,
    Offset offset,
    bool autoMirror,
    double requiredSpace,
    EdgeInsets screenPadding,
    ComboAutoOpen autoOpen,
    ComboAutoClose autoClose,
    bool enabled,
    PopupAnimation animation,
    Duration animationDuration,
    ChildDecoratorBuilder childContentDecoratorBuilder,
    ChildDecoratorBuilder childDecoratorBuilder,
    PopupDecoratorBuilder popupDecoratorBuilder,
    BoxConstraints popupContraints,
    Color focusColor,
    Color hoverColor,
    Color highlightColor,
    Color splashColor,
    ProgressDecoratorBuilder progressDecoratorBuilder,
    bool refreshOnOpened,
    ProgressPosition progressPosition,
    ListPopupBuilder listPopupBuilder,
    double listMaxHeight,
    Widget emptyListIndicator,
    Duration inputThrottle,
    ListPopupBuilder menuPopupBuilder,
    PopupDecoratorBuilder menuPopupDecoratorBuilder,
    Widget menuDivider,
    bool menuShowArrows,
    bool menuCanTapOnFolder,
    ProgressDecoratorBuilder menuProgressDecoratorBuilder,
    bool menuRefreshOnOpened,
    ProgressPosition menuProgressPosition,
    Color menuFocusColor,
    Color menuHoverColor,
    Color menuHighlightColor,
    Color menuSplashColor,
  }) =>
      ComboParameters(
        position: position ?? this.position,
        offset: offset ?? this.offset,
        autoMirror: autoMirror ?? this.autoMirror,
        requiredSpace: requiredSpace ?? this.requiredSpace,
        screenPadding: screenPadding ?? this.screenPadding,
        autoOpen: autoOpen ?? this.autoOpen,
        autoClose: autoClose ?? this.autoClose,
        enabled: enabled ?? this.enabled,
        animation: animation ?? this.animation,
        animationDuration: animationDuration ?? this.animationDuration,
        childContentDecoratorBuilder:
            childContentDecoratorBuilder ?? this.childContentDecoratorBuilder,
        childDecoratorBuilder:
            childDecoratorBuilder ?? this.childDecoratorBuilder,
        popupDecoratorBuilder:
            popupDecoratorBuilder ?? this.popupDecoratorBuilder,
        popupContraints: popupContraints ?? this.popupContraints,
        progressDecoratorBuilder:
            progressDecoratorBuilder ?? this.progressDecoratorBuilder,
        refreshOnOpened: refreshOnOpened ?? this.refreshOnOpened,
        progressPosition: progressPosition ?? this.progressPosition,
        listPopupBuilder: listPopupBuilder ?? this.listPopupBuilder,
        listMaxHeight: listMaxHeight ?? this.listMaxHeight,
        emptyListIndicator: emptyListIndicator ?? this.emptyListIndicator,
        inputThrottle: inputThrottle ?? this.inputThrottle,
        menuPopupBuilder: menuPopupBuilder ?? this.menuPopupBuilder,
        menuPopupDecoratorBuilder:
            menuPopupDecoratorBuilder ?? this.menuPopupDecoratorBuilder,
        menuDivider: menuDivider ?? this.menuDivider,
        menuShowArrows: menuShowArrows ?? this.menuShowArrows,
        menuCanTapOnFolder: menuCanTapOnFolder ?? this.menuCanTapOnFolder,
        menuProgressDecoratorBuilder:
            menuProgressDecoratorBuilder ?? this.menuProgressDecoratorBuilder,
        menuRefreshOnOpened: menuRefreshOnOpened ?? this.menuRefreshOnOpened,
        menuProgressPosition: menuProgressPosition ?? this.menuProgressPosition,
      );

  /// Default value of [animationDuration].
  static const defaultAnimationDuration = Duration(milliseconds: 150);

  /// Default value of [screenPadding].
  static const defaultScreenPadding = EdgeInsets.all(16.0);

  /// Default child decorator builder
  static Widget buildDefaultChildContentDecorator(
    BuildContext context,
    ComboParameters parameters,
    bool opened,
    Widget child, {
    IconData icon = Icons.arrow_drop_down,
    EdgeInsets iconPadding = const EdgeInsets.symmetric(horizontal: 8.0),
  }) =>
      Row(children: [
        Expanded(child: child),
        Padding(
            padding: iconPadding,
            child: AnimatedOpacity(
                duration: kThemeChangeDuration,
                opacity: parameters.enabled ? 1.0 : 0.5,
                child: Icon(icon, color: Theme.of(context).disabledColor))),
      ]);

  static Widget buildDefaultChildDecorator(BuildContext context,
      ComboParameters parameters, bool opened, Widget child) {
    final theme = Theme.of(context);
    final decoration = InputDecoration(border: OutlineInputBorder())
        .applyDefaults(theme.inputDecorationTheme)
        .copyWith(enabled: parameters.enabled, contentPadding: EdgeInsets.zero);
    return Material(
      borderRadius: (decoration.border as OutlineInputBorder).borderRadius,
      child: InputDecorator(
          decoration: decoration,
          isFocused: opened,
          isEmpty: true,
          expands: false,
          child: child),
    );
  }

  /// Default popup decorator builder
  static Widget buildDefaultPopupDecorator(
          BuildContext context, ComboParameters parameters, Widget child,
          {double elevation = 4,
          BorderRadiusGeometry borderRadius =
              const BorderRadius.all(Radius.circular(4))}) =>
      Material(
        elevation: elevation,
        borderRadius: borderRadius,
        child: child,
      );

  static Widget buildDefaultMenuPopupDecorator(
          BuildContext context, ComboParameters parameters, Widget child,
          {double elevation = 4,
          BorderRadiusGeometry borderRadius = BorderRadius.zero}) =>
      buildDefaultPopupDecorator(context, parameters, child,
          elevation: elevation, borderRadius: borderRadius);

  /// Builds defaut progress decorator
  static Widget buildDefaultProgressDecorator(
          BuildContext context, bool waiting, bool mirrored, Widget child) =>
      ProgressDecorator(waiting: waiting, mirrored: mirrored, child: child);

  /// Builds default menu progress decorator
  static Widget buildDefaultMenuProgressDecorator(
          BuildContext context, bool waiting, bool mirrored, Widget child) =>
      ProgressDecorator(
          waiting: waiting,
          mirrored: false,
          progressBackgroundColor: Colors.transparent,
          progressValueColor:
              AlwaysStoppedAnimation(Colors.blueAccent.withOpacity(0.2)),
          child: child,
          progressHeight: null);

  /// Builds default widget for displaying list of the popup items.
  static Widget buildDefaultListPopup(
          BuildContext context,
          ComboParameters parameters,
          List list,
          PopupListItemBuilder itemBuilder,
          GetIsSelectable getIsSelectable,
          void Function(dynamic value) onItemTapped,
          dynamic scrollToItem,
          bool mirrored) =>
      ListPopup(
          parameters: parameters,
          list: list,
          itemBuilder: itemBuilder,
          getIsSelectable: getIsSelectable,
          onItemTapped: onItemTapped,
          scrollToItem: scrollToItem);

  /// Builds default widget for displaying list of the menu items
  static Widget buildDefaultMenuPopup(
          BuildContext context,
          ComboParameters parameters,
          List list,
          PopupListItemBuilder itemBuilder,
          GetIsSelectable getIsSelectable,
          void Function(dynamic value) onItemTapped,
          dynamic scrollToItem,
          bool mirrored) =>
      MenuListPopup(
          parameters: parameters,
          list: list,
          itemBuilder: itemBuilder,
          onItemTapped: onItemTapped,
          getIsSelectable: getIsSelectable);
}

/// Specifies the context for all [Combo] widgets in the [child].
/// Allows to set [ComboParameters] and close combo popups in the context
/// with [ComboContextData.closeAll] method
class ComboContext extends StatefulWidget {
  const ComboContext({
    Key key,
    @required this.parameters,
    @required this.child,
    this.ignoreParentContraints = false,
  })  : assert(parameters != null),
        assert(child != null),
        assert(ignoreParentContraints != null),
        super(key: key);
  final ComboParameters parameters;
  final Widget child;

  /// if true, parent context constraints will not be merged with current
  final bool ignoreParentContraints;

  static ComboContextData of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<ComboContextData>();

  @override
  _ComboContextState createState() => _ComboContextState();

  static BoxConstraints mergeConstraints(
      BoxConstraints myConstraints, BoxConstraints parentConstraints) {
    if (myConstraints == null) return parentConstraints;
    if (parentConstraints == null) return myConstraints;
    final maxWidth =
        math.min(myConstraints.maxWidth, parentConstraints.maxWidth);
    final maxHeight =
        math.min(myConstraints.maxHeight, parentConstraints.maxHeight);
    return BoxConstraints(
      minWidth: math.min(myConstraints.minWidth, maxWidth),
      maxWidth: maxWidth,
      minHeight: math.min(myConstraints.minHeight, maxHeight),
      maxHeight: maxHeight,
    );
  }
}

class _ComboContextState extends State<ComboContext> {
  final _closes = StreamController.broadcast();
  var _saveEnabled = true;

  @override
  Widget build(BuildContext context) {
    final parentData = ComboContext.of(context);
    final def = parentData == null
        ? ComboParameters.defaultParameters
        : parentData.parameters;
    final my = widget.parameters;

    final merged = ComboParameters(
      position: my.position ?? def.position,
      offset: my.offset ?? def.offset,
      autoMirror: my.autoMirror ?? def.autoMirror,
      requiredSpace: my.requiredSpace ?? def.requiredSpace,
      screenPadding: my.screenPadding ?? def.screenPadding,
      autoOpen: my.autoOpen ?? def.autoOpen,
      autoClose: my.autoClose ?? def.autoClose,
      enabled: (my.enabled ?? true) && def.enabled,
      animation: my.animation ?? def.animation,
      animationDuration: my.animationDuration ?? def.animationDuration,
      childContentDecoratorBuilder:
          my.childContentDecoratorBuilder ?? def.childContentDecoratorBuilder,
      childDecoratorBuilder:
          my.childDecoratorBuilder ?? def.childDecoratorBuilder,
      popupDecoratorBuilder:
          my.popupDecoratorBuilder ?? def.popupDecoratorBuilder,
      popupContraints: widget.ignoreParentContraints
          ? my.popupContraints
          : ComboContext.mergeConstraints(
              my.popupContraints, def.popupContraints),
      progressDecoratorBuilder:
          my.progressDecoratorBuilder ?? def.progressDecoratorBuilder,
      refreshOnOpened: my.refreshOnOpened ?? def.refreshOnOpened,
      progressPosition: my.progressPosition ?? def.progressPosition,
      listPopupBuilder: my.listPopupBuilder ?? def.listPopupBuilder,
      listMaxHeight: my.listMaxHeight ?? def.listMaxHeight,
      emptyListIndicator: my.emptyListIndicator ?? def.emptyListIndicator,
      inputThrottle: my.inputThrottle ?? def.inputThrottle,
      menuPopupBuilder: my.menuPopupBuilder ?? def.menuPopupBuilder,
      menuPopupDecoratorBuilder:
          my.menuPopupDecoratorBuilder ?? def.menuPopupDecoratorBuilder,
      menuDivider: my.menuDivider ?? def.menuDivider,
      menuShowArrows: my.menuShowArrows ?? def.menuShowArrows,
      menuCanTapOnFolder: my.menuCanTapOnFolder ?? def.menuCanTapOnFolder,
      menuProgressDecoratorBuilder:
          my.menuProgressDecoratorBuilder ?? def.menuProgressDecoratorBuilder,
      menuRefreshOnOpened: my.menuRefreshOnOpened ?? def.menuRefreshOnOpened,
      menuProgressPosition: my.menuProgressPosition ?? def.menuProgressPosition,
    );
    if (merged.enabled != _saveEnabled && !(_saveEnabled = merged.enabled)) {
      _closes.add(true);
    }
    return ComboContextData(widget, widget.child, merged, _closes);
  }

  @override
  void dispose() {
    super.dispose();
    _closes.close();
  }
}

/// Provides [ComboParameters] and [closeAll] method for the specified [ComboContext].
class ComboContextData extends InheritedWidget {
  const ComboContextData(
      this._widget, Widget child, this.parameters, this._closes)
      : super(child: child);

  final ComboContext _widget;

  // Common parameters for combo widgets
  final ComboParameters parameters;

  final StreamController _closes;

  /// Closes all opened by [Combo] popups in the current combo context
  void closeAll() => _closes.add(true);

  @override
  bool updateShouldNotify(ComboContextData oldWidget) =>
      _widget.parameters != oldWidget._widget.parameters;
}

// * combo

/// Simple combo box widget
///
/// Use [Combo] to link a widget with a popup setting [child] ans [popupBuilder] properties.
/// The [child] and [popupBuilder] properties is not required.
/// [Combo] can be tunned by uses [ComboParameters] from set by [ComboContext].
/// Popup can be opened or closed automatically by [ComboParameters.autoOpen]
/// and [ComboParameters.autoClose] properties or programmatically by
/// [ComboState.open] and [ComboState.close] methods. Also can be used [Combo.closeAll]
/// and [ComboContextData.closeAll] for closing
///
/// Popup position is determined by [ComboParameters.position] property
/// with the [ComboParameters.offset].
/// If [ComboParameters.autoMirror] is true, popup position may depends on screen edges using
/// [ComboParameters.requiredSpace] and [ComboParameters.screenPadding] values,
/// [ComboParameters.screenPadding] also affects popup clipping.
///
/// You can apply 'fade' or custom animation to the popup using [ComboParameters.animation]
/// and [ComboParameters.animationDuration] properties.
/// In case of custom animation popup will not be closed immediattely, but will wait for
/// animationDuration with [IgnorePointer].
///
/// [openedChanged] is raised when popup is opening or closing with appropriate bool value.
/// [hoveredChanged] is raised when mouse pointer enters on or exits from child or popup
/// and its children - when popup contains another [Combo] widgets.
/// [onTap] is raised when the user taps on popup and don't paint [InkWell] when it's null.
/// [onTap] also can be raised by 'long tap' event when [ComboParameters.autoOpen]
/// is set to [ComboAutoOpen.hovered] and platform is not 'Web'
/// [ComboParameters.focusColor], [ComboParameters.hoverColor],
/// [ComboParameters.highlightColor], [ComboParameters.splashColor] are combo [InkWell]
/// parameters
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
  /// Also can be used [Combo.closeAll] and [ComboContextData.closeAll] for closing
  ///
  /// Popup position is determined by [ComboParameters.position] property
  /// with the [ComboParameters.offset].
  /// If [ComboParameters.autoMirror] is true, popup position may depends on screen edges using
  /// [ComboParameters.requiredSpace] and [ComboParameters.screenPadding] values,
  /// [ComboParameters.screenPadding] also affects popup clipping.
  ///
  /// You can apply 'fade' or custom animation to the popup using [ComboParameters.animation]
  /// and [ComboParameters.animationDuration] properties.
  /// In case of custom animation popup will not be closed immediattely, but will wait for
  /// animationDuration with [IgnorePointer].
  ///
  /// [openedChanged] is raised when popup is opening or closing with appropriate bool value.
  /// [hoveredChanged] is raised when mouse pointer enters on or exits from child or popup
  /// and its children - when popup contains another [Combo] widgets.
  /// [onTap] is raised when the user taps on popup and don't paint [InkWell] when it's null.
  /// [onTap] also can be raised by 'long tap' event when [ComboParameters.autoOpen]
  /// is set to [ComboAutoOpen.hovered] and platform is not 'Web'
  /// [ComboParameters.focusColor], [ComboParameters.hoverColor],
  /// [ComboParameters.highlightColor], [ComboParameters.splashColor] are combo [InkWell]
  /// parameters
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
    this.openedChanged,
    this.hoveredChanged,
    this.onTap,
    this.ignoreChildDecorator = false,
  })  : assert(ignoreChildDecorator != null),
        super(key: key);

  /// The widget below this widget in the tree.
  ///
  /// {@macro flutter.widgets.child}
  final Widget child;

  /// Called to obtain the popup widget.
  final PopupBuilder popupBuilder;

  /// Callbacks when the popup is opening or closing
  final ValueChanged<bool> openedChanged;

  /// Callbacks when the mouse pointer enters on or exits from child or popup
  /// and its children - when popup contains another [Combo] widgets.
  final ValueChanged<bool> hoveredChanged;

  /// Called when the user taps on [child].
  /// Also can be called by 'long tap' event if [ComboParameters.autoOpen]
  /// is set to [ComboAutoOpen.hovered] and platform is not 'Web'
  final GestureTapCallback onTap;

  /// if true, [ComboParameters.childDecoratorBuilder] will not be applied.
  final bool ignoreChildDecorator;

  /// Closes all opened by [Combo] popups
  static void closeAll() => ComboState._closes.add(true);

  @override
  ComboState createState() => ComboState();
}

/// Allows to [open] and to [close] the combo popup,
/// and determines if the popup is [opened].
abstract class ComboController {
  /// determines if popup is opened
  bool get opened;

  /// Opens the popup.
  void open();

  /// Closes the popup.
  void close();
}

/// State for a [Combo].
/// Implements [ComboController].
class ComboState<T extends Combo> extends State<T> implements ComboController {
  // ignore: close_sinks
  static final _closes = StreamController.broadcast();
  final _scrolls = StreamController.broadcast();
  final _layerLink = LayerLink();
  OverlayEntry _overlay;
  StreamSubscription _widgetClosesSubscription;
  StreamSubscription _contextClosesSubscription;
  Completer<double> _closeCompleter;
  var _hovered = false;
  bool _lastHovered;
  var _popupHovered = false;
  ComboState _parent;

  // workaround for: https://github.com/flutter/flutter/issues/50800
  Completer<Offset> _sizeCompleter;

  bool get _fadeOpen {
    final animation = parameters.animation;
    return animation == PopupAnimation.fade ||
        animation == PopupAnimation.fadeOpen;
  }

  bool get _fadeClose {
    final animation = parameters.animation;
    return animation == PopupAnimation.fade ||
        animation == PopupAnimation.fadeClose;
  }

  bool get _delayedClose {
    final animation = parameters.animation;
    return animation == PopupAnimation.fade ||
        animation == PopupAnimation.fadeClose ||
        animation == PopupAnimation.custom;
  }

  @protected
  ComboParameters getParameters(ComboParameters contextParameters) {
    final parameters = contextParameters ?? ComboParameters.defaultParameters;
    return parameters.position == null
        ? parameters.copyWith(position: PopupPosition.bottomMinMatch)
        : parameters;
  }

  ComboParameters _parameters;
  @protected
  ComboParameters get parameters => _parameters;
  ThemeData _theme;

  @override
  void initState() {
    super.initState();
    _widgetClosesSubscription = _closes.stream.listen((_) => close());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _parent = context.findAncestorStateOfType<_ComboOverlayState>()?.comboState;
    Scrollable.of(context)?.widget?.controller?.addListener(() {
      if (_overlay != null) _scrolls.add(true);
    });
  }

  @override
  bool get opened => _overlay != null;

  @protected
  bool get hasPopup => widget.popupBuilder != null;

  @override
  void open() {
    if (_overlay != null) return;
    if (widget.openedChanged != null) widget.openedChanged(true);
    if (_fadeClose) _closeCompleter = Completer();
    _overlay = _createOverlay();
    if (_overlay == null) return;
    Overlay.of(context).insert(_overlay);
    setState(() {});
  }

  @override
  void close() async {
    if (_overlay == null) return;
    final overlay = _overlay;
    _overlay = null;
    setState(() {});
    if (_fadeClose) _closeCompleter?.complete(0.0);
    if (widget.openedChanged != null) widget.openedChanged(false);
    if (_delayedClose) {
      final animationDuration = parameters.animationDuration;
      await Future.delayed(animationDuration == null
          ? Duration.zero
          : animationDuration + Duration(milliseconds: 1));
    }
    overlay.remove();
    setState(() {});
  }

  bool get _catchHover {
    final parameters = this.parameters;
    return parameters.autoOpen == ComboAutoOpen.hovered ||
        parameters.autoClose == ComboAutoClose.notHovered;
  }

  void _setHovered(bool value) async {
    if (!value && opened && _popupHovered) return;
    final parameters = this.parameters;
    _parent?._setHovered(value);
    if (value == _hovered || !mounted) return;
    _hovered = value;
    if (value) {
      if (widget.hoveredChanged != null && _lastHovered != true) {
        _lastHovered = true;
        widget.hoveredChanged(true);
      }
      if (!opened && parameters.autoOpen == ComboAutoOpen.hovered) {
        open();
      }
    } else {
      await Future.delayed(const Duration(milliseconds: 50));
      if (_hovered) return;
      if (widget.hoveredChanged != null && _lastHovered != false) {
        _lastHovered = false;
        widget.hoveredChanged(false);
      }
      if (opened && parameters.autoClose == ComboAutoClose.notHovered) {
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
        final parameters = this.parameters;
        final position = parameters.position;
        final mediaQuery = MediaQuery.of(context);
        final screenPadding = parameters.screenPadding.copyWith(
            top:
                math.max(parameters.screenPadding.top, mediaQuery.padding.top));
        final RenderBox renderBox = this.context.findRenderObject();
        final size = renderBox.size;
        final mediaQuerySize = mediaQuery.size;
        final screenSize = Size(mediaQuerySize.width,
            mediaQuerySize.height - mediaQuery.viewInsets.bottom);
        final requiredSpace = parameters.requiredSpace ??
            (position == PopupPosition.left || position == PopupPosition.right
                ? screenSize.width / 3
                : screenSize.height / 3);

        Offset lastOffset;
        Offset offset;
        bool mirrored;
        Widget popup;

        void updatePopup() {
          offset = renderBox.attached
              ? lastOffset = renderBox.localToGlobal(Offset.zero)
              : lastOffset ?? Offset.zero;
          mirrored = parameters.autoMirror
              ? () {
                  final offsetx = parameters.offset?.dx ?? 0;
                  final offsety = parameters.offset?.dx ?? 0;

                  return () {
                        switch (position) {
                          case PopupPosition.left:
                            return offset.dx -
                                offsetx -
                                (screenPadding?.left ?? 0);
                          case PopupPosition.right:
                            return screenSize.width -
                                offset.dx -
                                size.width -
                                offsetx -
                                (screenPadding?.right ?? 0);
                          default:
                            return screenSize.height -
                                offset.dy -
                                (position == PopupPosition.top ||
                                        position == PopupPosition.topMatch ||
                                        position == PopupPosition.topMinMatch
                                    ? 0
                                    : size.height) -
                                offsety -
                                (screenPadding?.bottom ?? 0);
                        }
                      }() <
                      requiredSpace;
                }()
              : false;
          popup = getPopup(context, mirrored);

          final constraints = parameters.popupContraints;
          if (constraints != null) {
            popup = ConstrainedBox(constraints: constraints, child: popup);
          }

          popup = parameters.popupDecoratorBuilder(context, parameters, popup);

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

              switch (position) {
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
                                (screenPadding?.top ?? 0),
                            left: (snapshot.data?.dx ?? 0) -
                                (screenPadding?.left ?? 0),
                            child: _DynamicTransformFollower(
                              key: ValueKey(mirrored),
                              link: _layerLink,
                              showWhenUnlinked: false,
                              offsetBuilder: (popupSize) {
                                final offsetx = parameters.offset?.dx ?? 0;
                                final offsety = parameters.offset?.dy ?? 0;
                                final pos = mirrored &&
                                        (position == PopupPosition.left ||
                                            position == PopupPosition.right)
                                    ? position == PopupPosition.left
                                        ? PopupPosition.right
                                        : PopupPosition.left
                                    : position;
                                final dx = () {
                                  switch (pos) {
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
                                              (screenPadding?.right ?? 0));
                                  }
                                }();
                                final dy = () {
                                  var overlapped = false;
                                  switch (pos) {
                                    case PopupPosition.left:
                                    case PopupPosition.right:
                                      return math.min(
                                          offsety,
                                          screenSize.height -
                                              offset.dy -
                                              popupSize.height -
                                              (screenPadding?.bottom ?? 0));
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
                  duration: parameters.animationDuration ?? Duration.zero,
                  child: child,
                ),
              ),
            );
        if (_fadeOpen) overlay = animate(0.0, Future.value(1.0), overlay);
        if (_fadeClose && _closeCompleter != null) {
          overlay = animate(1.0, _closeCompleter.future, overlay);
        }

        if (screenPadding != null) {
          overlay =
              Padding(padding: screenPadding, child: ClipRect(child: overlay));
        }

        if (parameters.autoClose != ComboAutoClose.none &&
            (parameters.autoClose != ComboAutoClose.notHovered ||
                !_PlatformHelper.canHover)) {
          overlay = Stack(children: [
            GestureDetector(onPanDown: (_) {
              if (parameters.autoClose !=
                      ComboAutoClose.tapOutsideExceptChild ||
                  !renderBox.hitTest(BoxHitTestResult(),
                      position: renderBox.globalToLocal(_.globalPosition))) {
                close();
              }
            }),
            overlay,
          ]);
        }

        return _ComboOverlay(
            child: Theme(data: _theme, child: overlay), comboState: this);
      });

  @override
  Widget build(BuildContext context) {
    _theme = Theme.of(this.context);
    final contextData = ComboContext.of(context);
    _contextClosesSubscription ??=
        contextData?._closes?.stream?.listen((_) => close());
    final parameters = _parameters = getParameters(contextData?.parameters);
    final enabled = parameters.enabled;
    var child = getChild();
    void decorate() {
      if (!widget.ignoreChildDecorator) {
        child = parameters.childContentDecoratorBuilder(
            context, parameters, opened, child);
      }
    }

    if (child == null) {
      child = const SizedBox();
      decorate();
    } else {
      decorate();
      if (parameters.autoOpen != ComboAutoOpen.none) {
        final catchHover = _catchHover;
        final openOnHover = parameters.autoOpen == ComboAutoOpen.hovered;
        final canHover = _PlatformHelper.canHover;

        if ((widget.onTap == null || !enabled) &&
            (openOnHover && (canHover || !hasPopup))) {
          child = MouseRegion(
            onEnter: (_) {
              if (enabled) _setHovered(true);
            },
            onExit: (_) {
              if (enabled) _setHovered(false);
            },
            child: child,
          );
        } else {
          child = InkWell(
            child: child,
            onTap: enabled
                ? () {
                    if (!openOnHover ||
                        (openOnHover && !canHover && hasPopup)) {
                      open();
                    }
                    if (widget.onTap != null &&
                        (canHover || !openOnHover || !hasPopup)) {
                      widget.onTap();
                    }
                  }
                : null,
            onLongPress: enabled && openOnHover && !canHover && hasPopup
                ? widget.onTap
                : null,
            onHover:
                catchHover && enabled ? (value) => _setHovered(value) : null,
          );
        }
        if (!widget.ignoreChildDecorator) {
          child = parameters.childDecoratorBuilder(
              context, parameters, opened, child);
        }
      }
      if (parameters.autoClose ==
          ComboAutoClose.tapOutsideWithChildIgnorePointer) {
        child = IgnorePointer(ignoring: _overlay != null, child: child);
      }
    }
    return CompositedTransformTarget(link: _layerLink, child: child);
  }

  @override
  void dispose() {
    close();
    _scrolls.close();
    _widgetClosesSubscription.cancel();
    _contextClosesSubscription?.cancel();
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

// * await

/// Signature for futured popup builder.
/// ('Mirrored' flag cannot be passed as there is no possibility to get popup size immediately)
typedef AwaitPopupBuilder = FutureOr<Widget> Function(BuildContext context);

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
    this.waitChanged,

    // inherited
    Widget child,
    AwaitPopupBuilder popupBuilder,
    ValueChanged<bool> openedChanged,
    ValueChanged<bool> hoveredChanged,
    GestureTapCallback onTap,
    bool ignoreChildDecorator = false,
  })  : awaitPopupBuilder = popupBuilder,
        super(
          key: key,
          child: child,
          openedChanged: openedChanged,
          hoveredChanged: hoveredChanged,
          onTap: onTap,
          ignoreChildDecorator: ignoreChildDecorator,
        );

  /// Called to obtain the futured popup content.
  final AwaitPopupBuilder awaitPopupBuilder;

  /// Called when the popup content is getting or got
  final ValueChanged<bool> waitChanged;

  @override
  AwaitComboStateBase createState() => AwaitComboState();
}

/// Base state for the combo widgets with the futured popup content builder.
abstract class AwaitComboStateBase<TWidget extends AwaitCombo, TContent>
    extends ComboState<TWidget> {
  var _waitCount = 0;
  final _waitController = StreamController<int>.broadcast();
  TContent _content;
  TContent get content => _content;
  final _contentController = StreamController<TContent>.broadcast();
  DateTime _timestamp;

  @override
  bool get hasPopup => widget.popupBuilder != null;

  @protected
  FutureOr<TContent> getContent(BuildContext context);
  @protected
  Widget buildContent(TContent content, bool mirrored);
  @protected
  void clearContent() => _content = null;
  @protected
  void updateContent(TContent content) =>
      _contentController.add(_content = content);

  @override
  Widget getChild() {
    final parameters = this.parameters;
    return parameters.progressDecoratorBuilder == null ||
            parameters.progressPosition != ProgressPosition.child
        ? super.getChild()
        : StreamBuilder<int>(
            initialData: _waitCount,
            stream: _waitController.stream,
            builder: (context, snapshot) => parameters.progressDecoratorBuilder(
                context, snapshot.data != 0, false, super.getChild()));
  }

  @override
  Widget getPopup(BuildContext context, bool mirrored) {
    final parameters = this.parameters;
    return StreamBuilder<int>(
      initialData: _waitCount,
      stream: _waitController.stream,
      builder: (context, snapshot) {
        final content = StreamBuilder<TContent>(
          initialData: _content,
          stream: _contentController.stream,
          builder: (context, snapshot) =>
              buildContent(snapshot.data, mirrored) ?? const SizedBox(),
        );
        return parameters.progressDecoratorBuilder == null ||
                parameters.progressPosition != ProgressPosition.popup
            ? content
            : parameters.progressDecoratorBuilder(
                context, snapshot.data != 0, mirrored, content);
      },
    );
  }

  @protected
  Future fill() async {
    final future = getContent(context);
    if (future == null) return;
    var content = future is TContent ? future : null;
    if (content == null) {
      final timestamp = _timestamp = DateTime.now();
      try {
        _waitController.add(++_waitCount);
        if (_waitCount == 1 && widget.waitChanged != null) {
          widget.waitChanged(true);
        }
        super.open();
        content = await future;
        if (content != null && _timestamp == timestamp) updateContent(content);
      } finally {
        _waitController.add(--_waitCount);
        if (_waitCount == 0 && widget.waitChanged != null) {
          widget.waitChanged(false);
        }
      }
    } else {
      updateContent(content);
      super.open();
    }
  }

  @override
  void open() =>
      (parameters.refreshOnOpened || _content == null ? fill : super.open)();

  @override
  void dispose() {
    super.dispose();
    _waitController.close();
    _contentController.close();
  }
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

// * list

/// Signature to get the popup items.
typedef PopupGetList<T> = FutureOr<List<T>> Function();

/// Signature to build the list popup item widget.
typedef PopupListItemBuilder<T> = Widget Function(
    BuildContext context, ComboParameters parameters, T item);

/// Signature to determine if the popup item is active for tapping
typedef GetIsSelectable<T> = bool Function(T item);

/// Combo widget for displaying the items list
/// Combo widget with the delayed getting of the popup content and progress indication
/// If [ComboParameters.position] is different of
/// [PopupPosition.bottomMatch] or [PopupPosition.topMatch]
/// you need to define [ComboParameters.popupContraints]
/// because [ListView] cannot automatically calculate its width.
///
/// See also:
///
///  * [Combo]
///  * [AwaitCombo]
///  * [SelectorCombo]
///  * [TypeaheadCombo]
///  * [MenuItemCombo]
class ListCombo<TItem> extends AwaitCombo {
  /// Creates combo widget for displaying the items list
  const ListCombo({
    Key key,
    @required this.getList,
    @required this.itemBuilder,
    @required this.onItemTapped,
    this.getIsSelectable,

    // inherited
    ValueChanged<bool> waitChanged,
    Widget child,
    ValueChanged<bool> openedChanged,
    ValueChanged<bool> hoveredChanged,
    GestureTapCallback onTap,
    bool ignoreChildDecorator = false,
  }) : super(
          key: key,
          waitChanged: waitChanged,
          child: child,
          openedChanged: openedChanged,
          hoveredChanged: hoveredChanged,
          onTap: onTap,
          ignoreChildDecorator: ignoreChildDecorator,
        );

  /// Popup items getter.
  final PopupGetList<TItem> getList;

  /// Popup item widget builder.
  final PopupListItemBuilder<TItem> itemBuilder;

  /// Calls when the user taps on the item.
  final ValueSetter<TItem> onItemTapped;

  /// Determines if the popup item is active for tapping
  final GetIsSelectable<TItem> getIsSelectable;

  @override
  ListComboState<ListCombo<TItem>, TItem> createState() =>
      ListComboState<ListCombo<TItem>, TItem>();
}

/// State for a [ListCombo].
class ListComboState<TWidget extends ListCombo<TItem>, TItem>
    extends AwaitComboStateBase<TWidget, List<TItem>> {
  @override
  ComboParameters getParameters(ComboParameters contextParameters) {
    final parameters = contextParameters ?? ComboParameters.defaultParameters;
    return parameters.position == null
        ? parameters.copyWith(position: PopupPosition.bottomMatch)
        : parameters;
  }

  @protected
  Widget buildItem(
          BuildContext context, ComboParameters parameters, TItem item) =>
      widget.itemBuilder(context, parameters, item);

  @override
  Widget buildContent(List<TItem> list, bool mirrored, [scrollToItem]) =>
      parameters.listPopupBuilder(
          context,
          parameters,
          list,
          (context, parameters, item) => buildItem(context, parameters, item),
          widget.getIsSelectable,
          itemTapped,
          scrollToItem,
          mirrored);

  @override
  void updateContent(List<TItem> content) {
    if (content != this.content &&
        ((this.content == null && content != null) ||
            !listEquals(content ?? [], this.content ?? []))) {
      super.updateContent(content);
    }
  }

  @override
  bool get hasPopup => widget.getList != null;

  @override
  FutureOr<List<TItem>> getContent(BuildContext context) => widget.getList();

  @protected
  void itemTapped(TItem item) {
    if (widget.onItemTapped != null) {
      widget.onItemTapped(item);
    }
    super.close();
  }
}

// * selector

/// Signature to build the selector popup item widget.
typedef PopupSelectorItemBuilder<T> = Widget Function(
    BuildContext context, ComboParameters parameters, T item, bool selected);

/// Combo widget for displaying the items list and selected item
/// Combo widget with the delayed getting of the popup content and progress indication
/// See also:
///
///  * [Combo]
///  * [AwaitCombo]
///  * [ListCombo]
///  * [TypeaheadCombo]
///  * [MenuItemCombo]
class SelectorCombo<TItem> extends ListCombo<TItem> {
  /// Creates combo widget for displaying the items list and selected item
  const SelectorCombo({
    Key key,
    this.selected,
    this.childBuilder,
    @required PopupSelectorItemBuilder<TItem> itemBuilder,

    // inherited
    @required PopupGetList<TItem> getList,
    @required ValueSetter<TItem> onItemTapped,
    GetIsSelectable<TItem> getIsSelectable,
    ValueChanged<bool> waitChanged,
    ValueChanged<bool> openedChanged,
    ValueChanged<bool> hoveredChanged,
    GestureTapCallback onTap,
    bool ignoreChildDecorator = false,
  })  : selectorItemBuilder = itemBuilder,
        // ignore: missing_required_param
        super(
          key: key,
          getList: getList,
          onItemTapped: onItemTapped,
          getIsSelectable: getIsSelectable,
          waitChanged: waitChanged,
          openedChanged: openedChanged,
          hoveredChanged: hoveredChanged,
          onTap: onTap,
          ignoreChildDecorator: ignoreChildDecorator,
        );

  /// The 'selected' item to display in [Combo.child] area
  final TItem selected;

  /// Builds the thid widget for [selected] item
  /// If null uses [ListCombo.itemBuilder]
  final PopupListItemBuilder<TItem> childBuilder;

  /// Popup item widget builder.
  final PopupSelectorItemBuilder<TItem> selectorItemBuilder;

  @override
  SelectorComboState<SelectorCombo<TItem>, TItem> createState() =>
      SelectorComboState<SelectorCombo<TItem>, TItem>(selected);
}

/// State for a [SelectorCombo].
class SelectorComboState<TWidget extends SelectorCombo<TItem>, TItem>
    extends ListComboState<TWidget, TItem> {
  SelectorComboState(this._selected);
  TItem _selected;
  TItem get selected => _selected;

  @override
  Widget buildItem(
          BuildContext context, ComboParameters parameters, TItem item) =>
      widget.selectorItemBuilder(context, parameters, item, item == _selected);

  @override
  Widget buildContent(List<TItem> list, bool mirrored, [scrollToItem]) =>
      super.buildContent(list, mirrored, _selected);

  @protected
  void clearSelected() => _selected = null;

  @override
  void didUpdateWidget(SelectorCombo<TItem> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selected != _selected) {
      setState(() => _selected = widget.selected);
    }
  }

  @override
  Widget getChild() => (widget.childBuilder ?? widget.itemBuilder)(
      context, parameters, _selected);
}

// * typeahead

/// Signature to get the popup items using the text from [TypeaheadCombo].
typedef TypeaheadGetList<T> = FutureOr<List<T>> Function(String text);

/// Signature to get the text that corresponds to popup item
typedef PopupGetItemText<T> = String Function(T item);

typedef PopupTypeaheadItemBuilder<T> = Widget Function(BuildContext context,
    ComboParameters parameters, T item, bool selected, String text);

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
class TypeaheadCombo<TItem> extends SelectorCombo<TItem> {
  /// Creates combo widget for displaying the items list and selected item
  const TypeaheadCombo({
    Key key,
    @required TypeaheadGetList<TItem> getList,
    @required PopupTypeaheadItemBuilder<TItem> itemBuilder,
    this.decoration,
    this.autofocus = false,
    @required this.getItemText,
    this.minTextLength = 1,
    this.focusNode,
    this.cleanAfterSelection = false,

    // inherited
    TItem selected,
    @required ValueSetter<TItem> onItemTapped,
    GetIsSelectable<TItem> getIsSelectable,
    ValueChanged<bool> waitChanged,
    ValueChanged<bool> openedChanged,
    ValueChanged<bool> hoveredChanged,
    GestureTapCallback onTap,
  })  : typeaheadItemBuilder = itemBuilder,
        typeaheadGetList = getList,
        assert(getList != null),
        assert(autofocus != null),
        assert(getItemText != null),
        assert(minTextLength >= 0),
        assert(cleanAfterSelection != null),
        // ignore: missing_required_param
        super(
          key: key,
          selected: selected,
          onItemTapped: onItemTapped,
          getIsSelectable: getIsSelectable,
          waitChanged: waitChanged,
          openedChanged: openedChanged,
          hoveredChanged: hoveredChanged,
          onTap: onTap,
          ignoreChildDecorator: true,
        );

  /// Popup items getter using user's text.
  final TypeaheadGetList<TItem> typeaheadGetList;

  /// Popup item widget builder.
  final PopupTypeaheadItemBuilder<TItem> typeaheadItemBuilder;

  /// The decoration to show around the text field.
  final InputDecoration decoration;

  /// {@macro flutter.widgets.editableText.autofocus}
  final bool autofocus;

  /// Gets the text that corresponds to popup item
  final PopupGetItemText<TItem> getItemText;

  /// Minimum text length to start getting the list
  /// if [minTextLength] = 0, shows the popup immediatelly on focus
  final int minTextLength;

  /// Defines the keyboard focus for this widget.
  final FocusNode focusNode;

  /// Determine if text should be cleared when user select the item
  final bool cleanAfterSelection;

  @override
  TypeaheadComboState<TypeaheadCombo<TItem>, TItem> createState() =>
      TypeaheadComboState<TypeaheadCombo<TItem>, TItem>(
          selected,
          selected == null ? '' : getItemText(selected),
          focusNode ?? FocusNode());

  static Text markText(String item, String text, TextStyle markedStyle) {
    if (item?.isNotEmpty != true || text?.isNotEmpty != true) {
      return Text(item ?? '', overflow: TextOverflow.ellipsis);
    }
    text = text.trim().toLowerCase();
    final lower = item.toLowerCase();
    final textLength = text.length;
    final itemLength = item.length;
    final spans = <TextSpan>[];
    var count = 0;
    int index;
    while ((index = lower.indexOf(text, count)) >= 0 && index < itemLength) {
      spans.addAll([
        TextSpan(text: item.substring(count, index)),
        TextSpan(
            text: item.substring(index, index + textLength),
            style: markedStyle),
      ]);
      count = index + textLength;
    }
    if (count == 0) return Text(item);
    if (count < item.length) {
      spans.add(TextSpan(text: item.substring(count)));
    }
    return Text.rich(TextSpan(children: spans),
        overflow: TextOverflow.ellipsis);
  }
}

/// State for [TypeaheadCombo]
class TypeaheadComboState<TWidget extends TypeaheadCombo<TItem>, TItem>
    extends SelectorComboState<TWidget, TItem> {
  TypeaheadComboState(TItem selected, String text, this._focusNode)
      : _controller = TextEditingController(text: text),
        _text = text,
        super(selected);

  final TextEditingController _controller;
  final FocusNode _focusNode;
  String _lastSearched;
  String _text;
  int get _textLength => _controller.text?.length ?? 0;

  @override
  Widget buildItem(
          BuildContext context, ComboParameters parameters, TItem item) =>
      widget.typeaheadItemBuilder(
          context, parameters, item, item == _selected, _lastSearched);

  @override
  ComboParameters getParameters(ComboParameters contextParameters) =>
      super.getParameters(contextParameters).copyWith(
          autoOpen: ComboAutoOpen.none,
          autoClose: ComboAutoClose.tapOutsideExceptChild,
          refreshOnOpened: false);

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
        if ((parameters.inputThrottle ?? Duration.zero) != Duration.zero) {
          await Future.delayed(parameters.inputThrottle);
        }
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
  void didUpdateWidget(TypeaheadCombo<TItem> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selected != null) {
      final text = widget.getItemText(selected);
      if (text != _controller.text) {
        _controller.text = _text = text;
      }
    }
  }

  @override
  FutureOr<List<TItem>> getContent(BuildContext context) =>
      widget.typeaheadGetList(_lastSearched = _text);

  @override
  void itemTapped(TItem item) {
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
        enabled: parameters.enabled,
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

// * menu

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

class _ArrowedItem extends StatelessWidget {
  const _ArrowedItem({Key key, this.child}) : super(key: key);
  final Widget child;
  @override
  Widget build(BuildContext context) => Row(children: [
        Expanded(child: child),
        const SizedBox(width: 16),
        Icon(
          Icons.arrow_right,
          // move back from bodyText1 to update rating on pub.dev !!!
          // ignore: deprecated_member_use
          color: Theme.of(context)?.textTheme?.body1?.color?.withOpacity(0.5),
        )
      ]);
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
class MenuItemCombo<T> extends StatelessWidget {
  /// Creates combo widget for displaying the menu
  const MenuItemCombo({
    Key key,
    @required this.item,
    this.child,

    // inherited
    this.itemBuilder,
    this.onItemTapped,
    this.getIsSelectable,
    this.waitChanged,
    this.openedChanged,
    this.hoveredChanged,
    this.onTap,
  }) : assert(item != null);

  /// Menu item
  final MenuItem<T> item;

  /// Defines menu item child, if null uses itemBuilder to build child item
  final Widget child;

  // * ListCombo properties

  /// Menu item widget builder.
  final PopupListItemBuilder<MenuItem<T>> itemBuilder;

  /// Calls when the user taps on the menu item.
  final ValueSetter<MenuItem<T>> onItemTapped;

  /// Determines if the menu item is active for tapping
  final GetIsSelectable<MenuItem<T>> getIsSelectable;

  /// Called when the menu items is getting or got
  final ValueChanged<bool> waitChanged;

  /// Callbacks when the menu is opening or closing
  final ValueChanged<bool> openedChanged;

  /// Callbacks when the mouse pointer enters on or exits from child or menu
  /// and its sub-menus
  final ValueChanged<bool> hoveredChanged;

  /// Called when the user taps on [child].
  /// Also can be called by 'long tap' event if [autoOpen] is set to [ComboAutoOpen.hovered]
  /// and platform is not 'Web'
  final GestureTapCallback onTap;

  @override
  Widget build(BuildContext context) {
    var parameters = ComboContext.of(context)?.parameters ??
        ComboParameters.defaultParameters;
    if (parameters.position == null) {
      parameters = parameters.copyWith(position: PopupPosition.bottomMatch);
    }

    final divider = parameters.menuDivider;
    final showArrows = parameters.menuShowArrows;
    final canTapOnFolder = parameters.menuCanTapOnFolder;
    ComboParameters menuParameters;
    menuParameters = parameters.copyWith(
      position: PopupPosition.right,
      autoOpen: ComboAutoOpen.hovered,
      autoClose: ComboAutoClose.notHovered,
      progressDecoratorBuilder: parameters.menuProgressDecoratorBuilder,
      refreshOnOpened: parameters.menuRefreshOnOpened,
      progressPosition: parameters.menuProgressPosition,
      listPopupBuilder: (context, parameters, list, itemBuilder,
              getIsSelectable, onItemTapped, scrollToItem, mirrored) =>
          ComboContext(
        parameters: menuParameters,
        child: parameters.menuPopupBuilder(context, parameters, list,
            itemBuilder, getIsSelectable, onItemTapped, scrollToItem, mirrored),
      ),
      popupDecoratorBuilder: parameters.menuPopupDecoratorBuilder,
    );

    return ComboContext(
      parameters: ComboParameters(
          listPopupBuilder: menuParameters.listPopupBuilder,
          popupDecoratorBuilder: parameters.menuPopupDecoratorBuilder),
      child: ListCombo<MenuItem<T>>(
        key: key,
        getList: item.getChildren ?? () => null,
        itemBuilder: (context, parameters, item) => item == MenuItem.separator
            ? divider
            : ComboContext(
                parameters: menuParameters,
                child: MenuItemCombo<T>(
                  item: item,
                  itemBuilder: showArrows
                      ? (context, parameters, item) {
                          final widget = itemBuilder(context, parameters, item);
                          return item.getChildren == null ||
                                  widget is _ArrowedItem
                              ? widget
                              : _ArrowedItem(child: widget);
                        }
                      : itemBuilder,
                  onItemTapped: onItemTapped,
                  getIsSelectable: getIsSelectable,
                  waitChanged: waitChanged,
                  openedChanged: openedChanged,
                  onTap: canTapOnFolder || item.getChildren == null
                      ? () {
                          Combo.closeAll();
                          onItemTapped(item);
                        }
                      : null,
                ),
              ),
        onItemTapped: onItemTapped,
        getIsSelectable: getIsSelectable,
        waitChanged: waitChanged,
        child: child ?? itemBuilder(context, parameters, item),
        openedChanged: openedChanged,
        hoveredChanged: hoveredChanged,
        onTap: onTap,
        ignoreChildDecorator: true,
      ),
    );
  }
}

// * helpers

enum _Platform { mobile, web, desktop }

class _PlatformHelper {
  static _Platform _platform;
  static _Platform get platform => _platform ??= kIsWeb
      ? _Platform.web
      : Platform.isAndroid || Platform.isIOS
          ? _Platform.mobile
          : _Platform.desktop;
  static bool _canHover;
  static bool get canHover => _canHover ??= platform != _Platform.mobile;
}
