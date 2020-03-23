library editors;

import 'package:combos/combos.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';

// * abstractions

const defaultEditorsDelay = Duration(milliseconds: 300);

enum TitlePlacement { none, label, placeholder, left, right, top }

/// Signature for [EditorParameters.titleBuilder]
typedef EditorTitleBuilder = Widget Function(BuildContext context,
    EditorParameters parameters, TitlePlacement titlePlacement, String title);

class EditorParameters {
  const EditorParameters({
    this.enabled,
    this.constraints,
    this.titlePlacement,
    this.titleStyle,
    this.titleBuilder,
  });

  static const defaultParameters = EditorParameters(
    enabled: true,
    titlePlacement: TitlePlacement.label,
    titleBuilder: defaultTitleBuilder,
  );

  final bool enabled;
  final BoxConstraints constraints;
  final TitlePlacement titlePlacement;
  final TextStyle titleStyle;
  final EditorTitleBuilder titleBuilder;

  EditorParameters copyWith({
    bool enabled,
    BoxConstraints constraints,
    TitlePlacement titlePlacement,
    TextStyle titleStyle,
    EditorTitleBuilder titleBuilder,
  }) =>
      EditorParameters(
        enabled: enabled ?? this.enabled,
        constraints: constraints ?? this.constraints,
        titlePlacement: titlePlacement ?? this.titlePlacement,
        titleStyle: titleStyle ?? this.titleStyle,
        titleBuilder: titleBuilder ?? this.titleBuilder,
      );

  static Widget defaultTitleBuilder(BuildContext context,
      EditorParameters parameters, TitlePlacement titlePlacement, String title,
      {EdgeInsets padding, String suffix, TextStyle style}) {
    title ??= '';
    suffix ??= titlePlacement == TitlePlacement.left ? ':' : null;
    if (suffix?.isNotEmpty == true) title += suffix;
    style = parameters.titleStyle;
    var color = style?.color ?? Theme.of(context).disabledColor;
    if (!parameters.enabled) color = color.withOpacity(color.opacity / 2);
    style =
        style == null ? TextStyle(color: color) : style.copyWith(color: color);
    Widget res = AnimatedDefaultTextStyle(
      duration: kThemeChangeDuration,
      style: style,
      child: Text(title, maxLines: 2, overflow: TextOverflow.ellipsis),
    );
    switch (titlePlacement) {
      case TitlePlacement.left:
        res = Padding(
            padding: padding ?? const EdgeInsets.only(right: 8.0), child: res);
        break;
      case TitlePlacement.right:
        res = Padding(
            padding: padding ?? const EdgeInsets.only(left: 8.0), child: res);
        break;
      case TitlePlacement.top:
        res = Padding(
            padding: padding ?? const EdgeInsets.only(bottom: 4.0), child: res);
        break;
      default:
        break;
    }

    return res;
  }
}

// Return true to cancel the notification bubbling. Return false (or null) to
// allow the notification to continue to be dispatched to further ancestors.
typedef EditorValueChanged = bool Function(Editor editor, dynamic value);
typedef EditorParametersGetter = EditorParameters Function();

class EditorsContext extends StatefulWidget {
  const EditorsContext({
    Key key,
    this.parameters,
    this.onValueChanged,
    this.onValuesChanged,
    this.ignoreParentContraints = false,
    @required this.child,
  })  : assert(ignoreParentContraints != null),
        super(key: key);

  final EditorParameters parameters;
  final EditorValueChanged onValueChanged;
  final VoidCallback onValuesChanged;
  final Widget child;

  /// if true, parent context constraints will not be merged with current
  final bool ignoreParentContraints;

  static EditorsContextData of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<EditorsContextData>();

  @override
  _EditorsContextState createState() => _EditorsContextState();
}

class _EditorsContextState extends State<EditorsContext> {
  Object _token;
  @override
  Widget build(BuildContext context) {
    final parentData = EditorsContext.of(context);
    final def = parentData == null
        ? EditorParameters.defaultParameters
        : parentData.parameters;
    final my = widget.parameters;
    final merged = my == null
        ? def
        : def == null
            ? my
            : EditorParameters(
                enabled: my.enabled ?? def.enabled,
                constraints: widget.ignoreParentContraints
                    ? my.constraints
                    : ComboContext.mergeConstraints(
                        my.constraints, def.constraints),
                titlePlacement: my.titlePlacement ?? def.titlePlacement,
                titleStyle: my.titleStyle ?? def.titleStyle,
                titleBuilder: my.titleBuilder ?? def.titleBuilder,
              );
    return EditorsContextData(
      widget,
      merged,
      // ignore: missing_return
      (editor, value) {
        final onValueChanged = widget.onValueChanged;
        if (onValueChanged == null || !onValueChanged(editor, value)) {
          parentData?.change(editor, value);
        }
        final onValuesChanged = widget.onValuesChanged;
        if (onValuesChanged != null) {
          final token = _token = Object();
          SchedulerBinding.instance.addPostFrameCallback((timeStamp) {
            if (token == _token && mounted) onValuesChanged();
          });
        }
      },
    );
  }
}

class EditorsContextData extends InheritedWidget {
  EditorsContextData(this.widget, this.parameters, this.change)
      : super(child: widget.child);
  final EditorsContext widget;
  final EditorParameters parameters;
  final EditorValueChanged change;

  @override
  bool updateShouldNotify(EditorsContextData oldWidget) =>
      widget.parameters != oldWidget.widget.parameters;
}

abstract class EditorsBuilder {
  Widget build();
}

class EditorsBuilderImpl implements EditorsBuilder {
  const EditorsBuilderImpl(this._builder);
  final WidgetBuilder _builder;
  @override
  Widget build() => Builder(builder: _builder);
}

class EditorsChildBuilder implements EditorsBuilder {
  const EditorsChildBuilder(this._child);
  static const separator = EditorsChildBuilder(SizedBox(width: 16, height: 16));
  final Widget _child;
  @override
  Widget build() => _child;
}

abstract class Editor<T> implements EditorsBuilder {
  Editor(
      {this.title, TitlePlacement titlePlacement, this.onChanged, this.value})
      : _titlePlacement = titlePlacement;
  final _key = GlobalKey<_EditorState>();
  String title;
  final ValueChanged<T> onChanged;
  T value;

  static Editor of(BuildContext context) =>
      context.findAncestorStateOfType<_EditorState>()?.editor;

  EditorsContextData getContextData() {
    final state = _key.currentState;
    return state?.mounted == true
        ? state.context.dependOnInheritedWidgetOfExactType<EditorsContextData>()
        : null;
  }

  EditorParameters _parameters;

  /// Editor parameters from current context.
  /// Available only after [build] called.
  @protected
  EditorParameters get parameters => _parameters;

  final TitlePlacement _titlePlacement;

  /// Gets the title placement from contructor or current context parameters.
  /// Used by [buildTitled] method, and can be overrided to
  /// change title build behavior
  @protected
  TitlePlacement get titlePlacement =>
      _titlePlacement ?? _parameters.titlePlacement;

  /// Changes the value of editor, raises 'onChanged' events
  /// and repaint editor view
  void change(T value) {
    if (this.value == value) return;
    this.value = value;
    if (onChanged != null) onChanged(value);
    final data = getContextData();
    if (data == null) return;
    data.change(this, value);
    _key.currentState.safeSetState();
  }

  @protected
  Widget buildBase(BuildContext context);

  @protected
  Widget buildConstrained(BuildContext context, [Widget child]) {
    final constraints = _parameters.constraints;
    child ??= buildBase(context);
    return constraints == null
        ? child
        : ConstrainedBox(constraints: constraints, child: child);
  }

  @protected
  // ignore: missing_return
  Widget buildTitled(BuildContext context, [TitlePlacement titlePlacement]) {
    final child = buildConstrained(context);
    titlePlacement ??= this.titlePlacement;
    switch (titlePlacement) {
      case TitlePlacement.left:
      case TitlePlacement.right:
      case TitlePlacement.top:
        final parameters = this.parameters;
        final title = parameters.titleBuilder(
            context, parameters, titlePlacement, this.title);

        // ignore: missing_enum_constant_in_switch
        switch (titlePlacement) {
          case TitlePlacement.left:
            return Row(children: [title, child]);
          case TitlePlacement.right:
            return Row(children: [child, title]);
          case TitlePlacement.top:
            return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [buildConstrained(context, title), child]);
        }
        break;
      default:
        return child;
    }
  }

  /// Builds editor widget.
  /// Can be showed only one widget per editor widget at the same time
  @override
  Widget build() => _Editor(
      key: _key,
      editor: this,
      builder: (context) {
        _parameters = context
                .dependOnInheritedWidgetOfExactType<EditorsContextData>()
                ?.parameters ??
            EditorParameters.defaultParameters;
        return buildTitled(context);
      });
}

class _Editor extends StatefulWidget {
  const _Editor({Key key, @required this.editor, @required this.builder})
      : super(key: key);
  final Editor editor;
  final WidgetBuilder builder;
  @override
  _EditorState createState() => _EditorState();
}

class _EditorState extends State<_Editor> {
  void safeSetState() {
    if (mounted) setState(() {});
  }

  Editor get editor => widget.editor;
  @override
  Widget build(BuildContext context) => widget.builder(context);
}

// * string

abstract class StringEditorBase<T> extends Editor<T> {
  StringEditorBase({
    this.decoration,
    this.textAlign,
    this.delay = defaultEditorsDelay,
    String title,
    TitlePlacement titlePlacement,
    T value,
    ValueChanged<T> onChanged,
  }) : super(
          title: title,
          titlePlacement: titlePlacement,
          value: value,
          onChanged: onChanged,
        );

  final InputDecoration decoration;
  final TextAlign textAlign;
  final Duration delay;

  InputDecoration getDecoration() {
    final parameters = this.parameters;

    if (decoration != null) return decoration;
    InputDecoration createLabelDecoration() =>
        InputDecoration(labelText: title);

    switch (parameters.titlePlacement) {
      case TitlePlacement.label:
        return createLabelDecoration();
      case TitlePlacement.placeholder:
        return InputDecoration(hintText: title);
      default:
        return parameters.titlePlacement == null
            ? createLabelDecoration()
            : null;
    }
  }
}

class StringEditor extends StringEditorBase<String> {
  StringEditor({
    InputDecoration decoration,
    TextAlign textAlign,
    Duration delay = defaultEditorsDelay,
    String title,
    TitlePlacement titlePlacement,
    String value,
    ValueChanged<String> onChanged,
  }) : super(
          decoration: decoration,
          textAlign: textAlign,
          delay: delay,
          title: title,
          titlePlacement: titlePlacement,
          value: value,
          onChanged: onChanged,
        );

  @override
  Widget buildBase(BuildContext context) => StringEditorInput(
        value: value,
        onChanged: (value) => change(value),
        enabled: parameters.enabled,
        title: title,
        decoration: getDecoration(),
        textAlign: textAlign ?? TextAlign.left,
        delay: delay,
      );
}

class StringEditorInput extends StatefulWidget {
  const StringEditorInput({
    Key key,
    @required this.value,
    @required this.onChanged,
    @required this.enabled,
    @required this.title,
    @required this.textAlign,
    @required this.decoration,
    this.inputFormatters,
    @required this.delay,
  })  : assert(textAlign != null),
        assert(enabled != null),
        super(key: key);

  final String value;
  final ValueChanged<String> onChanged;
  final bool enabled;
  final String title;
  final TextAlign textAlign;
  final InputDecoration decoration;
  final List<TextInputFormatter> inputFormatters;
  final Duration delay;

  @override
  StringEditorInputState createState() => StringEditorInputState(value);
}

class StringEditorInputState extends State<StringEditorInput> {
  StringEditorInputState(String value)
      : _controller = TextEditingController(text: value);

  final TextEditingController _controller;
  String _previousValue;
  DateTime _timestamp;

  @override
  void initState() {
    super.initState();
    if (widget.onChanged != null) {
      _controller.addListener(() async {
        if (_controller.text == _previousValue) return;
        final value = _previousValue = _controller.text;
        final timestamp = _timestamp = DateTime.now();
        final delay = widget.delay;
        if (delay != null && delay != Duration.zero) {
          await Future.delayed(delay);
        }
        if (timestamp == _timestamp) widget.onChanged(value);
      });
    }
  }

  @override
  void didUpdateWidget(StringEditorInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    final value = widget.value;
    if (value != oldWidget.value && value != _controller.text) {
      _controller.text = value;
    }
    if (widget.enabled != oldWidget.enabled) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) => TextField(
        controller: _controller,
        enabled: widget.enabled,
        decoration: widget.decoration ?? const InputDecoration(),
        inputFormatters: widget.inputFormatters,
        textAlign: widget.textAlign,
      );

  @override
  void dispose() {
    super.dispose();
    _controller.dispose();
  }
}

// * int

typedef IncrementerDecoratorBuilder = Widget Function(
    BuildContext context,
    Widget input,
    IntEditor editor,
    EditorParameters parameters,
    WidgetBuilder titleBuilder,
    VoidCallback inc,
    VoidCallback dec);

class IntEditor extends StringEditorBase<int> {
  IntEditor({
    this.minValue = 0,
    this.maxValue,
    this.withIncrementer = true,
    this.incrementerDecoratorBuilder = buildDefaultIncrementerDecorator,
    InputDecoration decoration,
    TextAlign textAlign,
    Duration delay = defaultEditorsDelay,
    String title,
    TitlePlacement titlePlacement,
    int value,
    ValueChanged<int> onChanged,
  })  : assert(withIncrementer != null),
        assert(!withIncrementer || incrementerDecoratorBuilder != null),
        super(
          decoration: decoration,
          textAlign: textAlign,
          delay: delay,
          title: title,
          titlePlacement: titlePlacement,
          value: value,
          onChanged: onChanged,
        );

  int minValue;
  int maxValue;
  bool withIncrementer;
  final IncrementerDecoratorBuilder incrementerDecoratorBuilder;

  @override
  Widget buildBase(BuildContext context) {
    final parameters = this.parameters;
    final enabled = parameters.enabled;
    final input = StringEditorInput(
      key: ValueKey(minValue),
      value: value?.toString() ?? '',
      onChanged: change == null ? null : (_) => change(int.tryParse(_)),
      enabled: parameters.enabled,
      title: title,
      decoration: getDecoration(),
      textAlign:
          textAlign ?? withIncrementer ? TextAlign.center : TextAlign.right,
      inputFormatters: [
        _IntTextInputFormatter(minValue: minValue, maxValue: maxValue)
      ],
      delay: delay,
    );
    return withIncrementer && incrementerDecoratorBuilder != null
        ? incrementerDecoratorBuilder(
            context,
            input,
            this,
            parameters,
            (context) => parameters.titleBuilder(
                context, parameters, titlePlacement, title),
            enabled && (value == null || maxValue == null || value < maxValue)
                ? () => change((value ?? minValue ?? 0) + 1)
                : null,
            enabled && (value == null || minValue == null || value > minValue)
                ? () => change((value ?? (minValue + 1) ?? 0) - 1)
                : null,
          )
        : input;
  }

  @override
  Widget buildTitled(BuildContext context, [TitlePlacement titlePlacement]) {
    titlePlacement ??= this.titlePlacement;
    return super.buildTitled(
        context,
        titlePlacement == TitlePlacement.top && withIncrementer
            ? TitlePlacement.none
            : titlePlacement);
  }

  static Widget buildDefaultIncrementerDecorator(
      BuildContext context,
      Widget input,
      IntEditor editor,
      EditorParameters parameters,
      WidgetBuilder titleBuilder,
      VoidCallback inc,
      VoidCallback dec) {
    return Row(children: [
      IconButton(icon: Icon(Icons.remove), onPressed: dec),
      Expanded(
          child: parameters?.titlePlacement == TitlePlacement.top
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [titleBuilder(context), input])
              : input),
      IconButton(icon: Icon(Icons.add), onPressed: inc),
    ]);
  }
}

// * double

class DoubleEditor extends StringEditorBase<double> {
  DoubleEditor({
    this.fractionDigits,
    this.maxValue,
    InputDecoration decoration,
    TextAlign textAlign,
    Duration delay = defaultEditorsDelay,
    String title,
    TitlePlacement titlePlacement,
    double value,
    ValueChanged<double> onChanged,
  }) : super(
          decoration: decoration,
          textAlign: textAlign,
          delay: delay,
          title: title,
          titlePlacement: titlePlacement,
          value: value,
          onChanged: onChanged,
        );

  final int fractionDigits;
  final double maxValue;

  @override
  Widget buildBase(BuildContext context) {
    final parameters = this.parameters;
    return StringEditorInput(
      value: value?.toString() ?? '',
      onChanged: change == null ? null : (_) => change(double.tryParse(_)),
      enabled: parameters.enabled,
      title: title,
      decoration: getDecoration(),
      textAlign: textAlign,
      inputFormatters: [
        _NumTextInputFormatter(
            fractionDigits: fractionDigits, maxValue: maxValue)
      ],
      delay: delay,
    );
  }

  static Widget buildDefaultIncrementerDecorator(
      BuildContext context,
      Widget input,
      IntEditor editor,
      EditorParameters parameters,
      WidgetBuilder titleBuilder,
      VoidCallback inc,
      VoidCallback dec) {
    return Row(children: [
      IconButton(icon: Icon(Icons.remove), onPressed: dec),
      Expanded(
          child: parameters?.titlePlacement == TitlePlacement.top
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [titleBuilder(context), input])
              : input),
      IconButton(icon: Icon(Icons.add), onPressed: inc),
    ]);
  }
}

// * bool

class BoolEditor extends Editor<bool> {
  BoolEditor({
    String title,
    TitlePlacement titlePlacement,
    bool value = false,
    ValueChanged<bool> onChanged,
  })  : assert(value != null),
        super(
          title: title,
          titlePlacement: titlePlacement,
          value: value,
          onChanged: onChanged,
        );

  @override
  Widget buildTitled(BuildContext context, [TitlePlacement titlePlacement]) =>
      super.buildConstrained(context);

  ListTileControlAffinity getBoolPlacement(BuildContext context) {
    switch (parameters.titlePlacement) {
      case TitlePlacement.left:
        return ListTileControlAffinity.trailing;
      case TitlePlacement.right:
        return ListTileControlAffinity.leading;
      default:
        return kIsWeb
            ? ListTileControlAffinity.leading
            : ListTileControlAffinity.platform;
    }
  }

  @override
  Widget buildBase(BuildContext context) => CheckboxListTile(
        value: value,
        onChanged: parameters.enabled ? change : null,
        title: title == null ? null : Text(title),
        controlAffinity: getBoolPlacement(context),
      );
}

// * enum

/// Signature for [EnumEditor.childBuilder], [EnumEditor.itemBuilder].
/// May return [Widget] or any object.
/// If it returns [Widget] it will be use to display the object
/// If it returns non [Widget] or null, returned object will be displayed as
/// [ListTile] with the title as [Object.toString] text
/// If [Object.toString] value contains one '.' symbol it will be parsed as
/// enum value
typedef EnumItemBuilder<T> = Function(BuildContext context, T item);

class EnumEditor<T> extends Editor<T> implements ComboController {
  EnumEditor({
    @required this.getList,
    this.itemBuilder = defaultItemBuilder,
    this.childBuilder = defaultChildBuilder,
    this.getIsSelectable,
    String title,
    TitlePlacement titlePlacement,
    T value,
    ValueChanged<T> onChanged,
  })  : assert(getList != null),
        super(
          title: title,
          titlePlacement: titlePlacement,
          value: value,
          onChanged: onChanged,
        );

  final PopupGetList<T> getList;
  final EnumItemBuilder<T> childBuilder;
  final EnumItemBuilder<T> itemBuilder;
  final GetIsSelectable<T> getIsSelectable;

  final _comboKey = GlobalKey<SelectorComboState>();

  @override
  bool get opened => _comboKey.currentState?.opened == true;
  @override
  void open() => _comboKey.currentState?.open();
  @override
  void close() => _comboKey.currentState?.close();

  @override
  Widget buildBase(BuildContext context) {
    final parameters = this.parameters;
    final enabled = parameters.enabled;
    final titlePlacement = parameters.titlePlacement;
    return ComboContext(
      parameters: ComboParameters(
        enabled: enabled,
        childDecoratorBuilder: (context, comboParameters, opened, child) {
          final theme = Theme.of(context);
          final decoration = InputDecoration(
                  labelText: titlePlacement == null ||
                          titlePlacement == TitlePlacement.label
                      ? title
                      : null,
                  hintText: titlePlacement == TitlePlacement.placeholder
                      ? title
                      : null,
                  border: OutlineInputBorder())
              .applyDefaults(theme.inputDecorationTheme)
              .copyWith(enabled: enabled);
          return Stack(
            children: [
              Material(
                  borderRadius:
                      (decoration.border as OutlineInputBorder).borderRadius,
                  child: child),
              Positioned.fill(
                child: IgnorePointer(
                  child: InputDecorator(
                      decoration: decoration,
                      isFocused: opened,
                      isEmpty: value == null,
                      expands: true),
                ),
              ),
            ],
          );
        },
      ),
      child: SelectorCombo<T>(
        key: _comboKey,
        selected: value,
        getList: getList,
        itemBuilder: (context, parameters, item, selected) => buildItem(
            context, item, (context, item) => itemBuilder(context, item)),
        childBuilder: (context, parameters, item) => buildItem(
            context, item, (context, item) => childBuilder(context, item),
            enabled: enabled),
        onItemTapped: change,
      ),
    );
  }

  static String _getItemText(item) {
    final value = item?.toString();
    if (value?.isNotEmpty != true) return '';
    final values = value.split('.');
    return values.length == 2 ? _TextHelper.camelToWords(values[1]) : value;
  }

  static Widget buildItem(BuildContext context, item, EnumItemBuilder builder,
      {bool enabled = true}) {
    item = builder(context, item);
    return item is Widget
        ? item
        : ListTile(enabled: enabled, title: Text(_getItemText(item)));
  }

  static dynamic defaultItemBuilder(BuildContext context, item,
          {bool enabled = true}) =>
      _getItemText(item);

  static dynamic defaultChildBuilder(BuildContext context, item) =>
      defaultItemBuilder(context, item,
          enabled: Editor.of(context).parameters.enabled);
}

// * typeahead

class TypeaheadEditor<T> extends Editor<T> implements ComboController {
  TypeaheadEditor({
    @required this.getList,
    this.decoration,
    this.autofocus = false,
    @required this.getItemText,
    this.minTextLength = 1,
    this.focusNode,
    this.cleanAfterSelection = false,
    @required this.itemBuilder,
    this.onItemTapped,
    this.getIsSelectable,
    this.waitChanged,
    this.openedChanged,
    this.hoveredChanged,
    this.onTap,
    String title,
    TitlePlacement titlePlacement,
    T value,
    ValueChanged<T> onChanged,
  })  : assert(getList != null),
        assert(getItemText != null),
        assert(minTextLength >= 0),
        assert(cleanAfterSelection != null),
        assert(itemBuilder != null),
        super(
          title: title,
          titlePlacement: titlePlacement,
          value: value,
          onChanged: onChanged,
        );

  final _comboKey = GlobalKey<TypeaheadComboState>();

  TypeaheadGetList<T> getList;
  InputDecoration decoration;
  bool autofocus;
  PopupGetItemText<T> getItemText;
  int minTextLength;
  FocusNode focusNode;
  bool cleanAfterSelection;
  EnumItemBuilder<T> itemBuilder;
  ValueSetter<T> onItemTapped;
  GetIsSelectable<T> getIsSelectable;
  ValueChanged<bool> waitChanged;
  ValueChanged<bool> openedChanged;
  ValueChanged<bool> hoveredChanged;
  GestureTapCallback onTap;

  @override
  bool get opened => _comboKey.currentState?.opened == true;
  @override
  void open() => _comboKey.currentState?.open();
  @override
  void close() => _comboKey.currentState?.close();

  @override
  Widget buildBase(BuildContext context) {
    final parameters = this.parameters;
    final enabled = parameters.enabled;
    return ComboContext(
      parameters: ComboParameters(enabled: enabled),
      child: TypeaheadCombo<T>(
        key: _comboKey,
        getList: getList,
        decoration: decoration,
        autofocus: autofocus,
        getItemText: getItemText,
        minTextLength: minTextLength,
        focusNode: focusNode,
        cleanAfterSelection: cleanAfterSelection,
        selected: value,
        itemBuilder: (context, parameters, item, selected) =>
            EnumEditor.buildItem(context, item, itemBuilder),
        onItemTapped: change,
        getIsSelectable: getIsSelectable,
        waitChanged: waitChanged,
        openedChanged: openedChanged,
        hoveredChanged: hoveredChanged,
        onTap: onTap,
      ),
    );
  }
}

// * dates
/*
class DatesEditor<T> extends Editor<T> implements CalendarComboController {
  DatesEditor({
    this.isCombo = true,
    this.canDeselect = false,
    this.displayDate,
    this.onDisplayDateChanged,
    this.columns = 1,
    this.rows = 1,
    this.monthSize = const Size.square(300),
    this.canSelectExtra = false,
    this.canSelect,
    this.onDayTap,
    this.autoClosePopupAfterSelectionChanged,
    this.openedChanged,
    this.hoveredChanged,
    this.onTap,
    String title,
    TitlePlacement titlePlacement,
    T value,
    ValueChanged<T> onChanged,
  })  : assert(T == DateTime || T == DatesRange || const <DateTime>{} is T),
        assert(isCombo != null),
        assert(canDeselect != null),
        assert(columns > 0),
        assert(rows > 0),
        assert(monthSize != null),
        assert(canSelectExtra != null),
        super(
          title: title,
          titlePlacement: titlePlacement,
          value: value,
          onChanged: onChanged,
        );

  bool isCombo;
  bool canDeselect;
  DateTime displayDate;
  ValueChanged<DateTime> onDisplayDateChanged;
  int columns;
  int rows;
  Size monthSize;
  bool canSelectExtra;
  CalendarSelectionCanSelect canSelect;
  ValueSetter<DateTime> onDayTap;
  bool autoClosePopupAfterSelectionChanged;
  ValueChanged<bool> openedChanged;
  ValueChanged<bool> hoveredChanged;
  GestureTapCallback onTap;

  Key __calendarKey;
  bool _saveIsCombo;
  int _saveColumns;
  int _saveRows;
  Size _saveMonthSize;
  double _saveSeparatorWidth;
  double _saveSeparatorHeight;
  Key _getCalendarKey(BuildContext context) {
    // update calendar widget if size changed
    final calendarParameters = CalendarContext.of(context)?.parameters ??
        CalendarParameters.defaultParameters;
    final separatorWidth =
        calendarParameters.horizontalSeparator.preferredSize.width;
    final separatorHeight =
        calendarParameters.verticalSeparator.preferredSize.height;
    if (isCombo != _saveIsCombo ||
        (!isCombo &&
            (_saveColumns != columns ||
                _saveRows != rows ||
                _saveMonthSize != monthSize ||
                _saveSeparatorWidth != separatorWidth ||
                _saveSeparatorHeight != separatorHeight))) {
      _saveIsCombo = isCombo;
      _saveColumns = columns;
      _saveRows = rows;
      _saveMonthSize = monthSize;
      _saveSeparatorWidth = separatorWidth;
      _saveSeparatorHeight = separatorHeight;
      __calendarKey = null;
    }
    return __calendarKey ?? isCombo
        ? GlobalKey<CalendarComboState>()
        : GlobalKey<CalendarState>();
  }

  @override
  bool get opened =>
      __calendarKey is GlobalKey<CalendarComboState> &&
      (__calendarKey as GlobalKey<CalendarComboState>).currentState?.opened ==
          true;

  @override
  void open() {
    if (__calendarKey is GlobalKey<CalendarComboState>) {
      (__calendarKey as GlobalKey<CalendarComboState>).currentState?.open();
    }
  }

  @override
  void close() {
    if (__calendarKey is GlobalKey<CalendarComboState>) {
      (__calendarKey as GlobalKey<CalendarComboState>).currentState?.close();
    }
  }

  @override
  void inc() =>
      ((__calendarKey as GlobalKey)?.currentState as CalendarController)?.inc();

  @override
  void dec() =>
      ((__calendarKey as GlobalKey)?.currentState as CalendarController)?.dec();

  @override
  void setDisplayDate(DateTime date) =>
      ((__calendarKey as GlobalKey)?.currentState as CalendarController)
          ?.setDisplayDate(date);

  CalendarSelectionBase _createSelection() {
    if (T == DateTime) {
      return canDeselect
          ? CalendarSingleOrNoneSelection(
              selected: value as DateTime,
              onSelectedChanged: (value) => change(value as T),
              canSelectExtra: canSelectExtra,
              canSelect: canSelect,
              onDayTap: onDayTap,
              autoClosePopupAfterSelectionChanged:
                  autoClosePopupAfterSelectionChanged ?? true,
            )
          : CalendarSingleSelection(
              selected: value as DateTime,
              onSelectedChanged: (value) => change(value as T),
              canSelectExtra: canSelectExtra,
              canSelect: canSelect,
              onDayTap: onDayTap,
              autoClosePopupAfterSelectionChanged:
                  autoClosePopupAfterSelectionChanged ?? true,
            );
    } else if (T == DatesRange) {
      return CalendarRangeSelection(
        selected: value as DatesRange,
        onSelectedChanged: (value) => change(value as T),
        canSelectExtra: canSelectExtra,
        onDayTap: onDayTap,
        autoClosePopupAfterSelectionChanged:
            autoClosePopupAfterSelectionChanged ?? true,
      );
      // Set<DateTime>
    } else {
      return CalendarMultiSelection(
        selected: value as Set<DateTime>,
        onSelectedChanged: (value) => change(value as T),
        canSelectExtra: canSelectExtra,
        canSelect: canSelect,
        onDayTap: onDayTap,
        autoClosePopupAfterSelectionChanged:
            autoClosePopupAfterSelectionChanged ?? false,
      );
    }
  }

  @override
  Widget buildBase(BuildContext context) {
    final selection = _createSelection();
    if (isCombo) {
      final parameters = this.parameters;
      ComboTextTitlePlacement comboTitlePlacement;
      if (this.title?.isNotEmpty == true) {
        switch (titlePlacement ?? parameters.titlePlacement) {
          case TitlePlacement.label:
            comboTitlePlacement = ComboTextTitlePlacement.label;
            break;
          case TitlePlacement.placeholder:
            comboTitlePlacement = ComboTextTitlePlacement.placeholder;
            break;
          default:
            break;
        }
      }
      final title = comboTitlePlacement == null ? null : this.title;
      final calendar = CalendarCombo(
        key: _getCalendarKey(context),
        displayDate: displayDate,
        onDisplayDateChanged: onDisplayDateChanged,
        columns: columns,
        rows: rows,
        title: title,
        selection: selection,
        monthSize: monthSize,
        openedChanged: openedChanged,
        hoveredChanged: hoveredChanged,
        onTap: onTap,
      );
      return comboTitlePlacement == null
          ? calendar
          : CalendarContext(
              parameters: CalendarParameters(
                  comboTextTitlePlacement: comboTitlePlacement),
              child: calendar);
    } else {
      return Calendar(
        key: _getCalendarKey(context),
        displayDate: displayDate,
        onDisplayDateChanged: onDisplayDateChanged,
        columns: columns,
        rows: rows,
        selection: selection,
        monthSize: monthSize,
      );
    }
  }
}
*/
// * helpers

abstract class _SimpleInputFormatter extends TextInputFormatter {
  String format(String oldValue, String newValue);

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

class _IntTextInputFormatter extends _SimpleInputFormatter {
  _IntTextInputFormatter({this.minValue, this.maxValue});

  final int minValue;
  final int maxValue;

  @override
  String format(String oldValue, String newValue) {
    if (newValue?.isNotEmpty != true) return '';
    if (newValue.contains('-')) return oldValue;

    var i = int.tryParse(newValue);
    if (i == null) return oldValue;
    if (minValue != null && i < minValue) i = minValue;
    if (maxValue != null && i > maxValue) i = maxValue;

    return i.toString();
  }
}

class _NumTextInputFormatter extends _SimpleInputFormatter {
  _NumTextInputFormatter({this.fractionDigits = 2, this.maxValue})
      : _maxValueStr = maxValue.toInt() == maxValue
            ? maxValue.toInt().toString()
            : maxValue.toStringAsFixed(fractionDigits);
  final int fractionDigits;
  final num maxValue;
  final String _maxValueStr;

  @override
  String format(String oldValue, String newValue) {
    // allow symbols removing
    if (newValue.length < oldValue.length) return newValue;

    final n = num.tryParse(newValue);

    // check for parse error and negative
    if (n == null || n < 0) return oldValue;

    // check for maximum allowed
    if (n <= maxValue) {
      final index = newValue.indexOf('.');
      // check fraction
      return index == -1 || newValue.length - index - 1 <= fractionDigits
          ? newValue
          : oldValue;
    }

    return _maxValueStr;
  }
}

class _TextHelper {
  static String camelToWords(String value) {
    final codes = value.runes
        .skip(1)
        .map((_) => String.fromCharCode(_))
        .map((_) => _.toUpperCase() == _ ? ' $_' : _)
        .expand((_) => _.runes);

    return value[0].toUpperCase() + String.fromCharCodes(codes);
  }
}
