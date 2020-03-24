library calendart;

import 'dart:async';
import 'dart:ui';

import 'package:combos/combos.dart';
import 'package:flutter/material.dart';

/// Determines type of the calendar day
/// [extraLow] - day from previous month
/// [current] - day from current month
/// [today] - day is today )
/// [extraHigh] -day from next month
enum DayType { extraLow, current, today, extraHigh }

/// Signature for calendar day builder.
/// [context] - current build context.
/// [parameters] - calendar parameters.
/// [date] - date of the day.
/// [type] - type of the day.
/// [column], [row] - position in calendar.
typedef DayBuilder = Widget Function(
    BuildContext context,
    CalendarParameters parameters,
    DateTime date,
    DayType type,
    int column,
    int row);

/// Signature for calendar visual selection builder.
/// [context] - current build context.
/// [parameters] - calendar parameters.
/// [date] - date of the day.
/// [type] - type of the day.
/// [column], [row] - position in calendar.
/// [day] - widget for the calendar day.
/// [preselect] - determine if selection is in preparing mode (hover).
/// [isSelected] - handler for check is date selected.
typedef SelectionBuilder = Widget Function(
    BuildContext context,
    CalendarParameters parameters,
    DateTime date,
    int column,
    int row,
    Widget day,
    bool preselect,
    bool Function(DateTime date) isSelected);

/// Signature for month decorator builder.
/// [context] - current build context.
/// [displayDate] - displaying calendar month.
/// [calendar] - calendar widget.
typedef MonthDecoratorBuilder = Widget Function(BuildContext context,
    CalendarParameters parameters, DateTime displayDate, Widget month);

/// Signature for calendar decorator builder.
/// [context] - current build context.
/// [displayDate] - displaying calendar month.
/// [calendar] - calendar widget.
typedef CalendarDecoratorBuilder = Widget Function(
    BuildContext context,
    CalendarParameters parameters,
    DateTime displayDate,
    Widget calendar,
    CalendarController controller);

/// Signature for combo calendar title builder
typedef SelectionTitleBuilder<TSelection> = Widget Function(
    BuildContext context, CalendarParameters parameters, TSelection selection);

/// Define combo calendar text title placement
/// [label] as [InputDecoration.labelText]
/// [placeholder] as [InputDecoration.hintText]
enum ComboTextTitlePlacement { label, placeholder }

/// Common parameters for calendar widgets.
class CalendarParameters {
  /// Creates common parameters for calendar widgets.
  const CalendarParameters({
    this.firstDayOfWeekIndex,
    this.showDaysOfWeek,
    this.dayOfWeekBuilder,
    this.dayBuilder,
    this.singleSelectionBuilder,
    this.multiSelectionBuilder,
    this.monthDecoratorBuilder,
    this.calendarDecoratorBuilder,
    this.horizontalSeparator,
    this.verticalSeparator,
    this.scrollDirection,
    this.comboTextTitlePlacement,
    this.singleSelectionTitleBuilder,
    this.multiSelectionTitleBuilder,
    this.rangeSelectionTitleBuilder,
    this.selectionTitleBuilder,
  });

  // Common parameters with dafault values for calendar widgets
  static const defaultParameters = CalendarParameters(
    showDaysOfWeek: true,
    dayOfWeekBuilder: buildDefaultDayOfWeek,
    dayBuilder: buildDefaultDay,
    singleSelectionBuilder: buildDefaultSingleSelection,
    multiSelectionBuilder: buildDefaultMultiSelection,
    horizontalSeparator: PreferredSize(
        preferredSize: Size.fromWidth(32), child: SizedBox(width: 32)),
    verticalSeparator: PreferredSize(
        preferredSize: Size.fromHeight(32), child: SizedBox(height: 32)),
    scrollDirection: Axis.horizontal,
    comboTextTitlePlacement: ComboTextTitlePlacement.label,
    singleSelectionTitleBuilder: buildDefaultSingleSelectionTitle,
    multiSelectionTitleBuilder: buildDefaultMultiSelectionTitle,
    rangeSelectionTitleBuilder: buildDefaultRangeSelectionTitle,
    selectionTitleBuilder: buildDefaultSelectionTitle,
  );

  /// Determines first day of week in calendar.
  /// By default it will be extracted from current locale
  final int firstDayOfWeekIndex;

  /// If false, calendar will not show days of week.
  /// Default is true.
  final bool showDaysOfWeek;

  /// Define day of week builder.
  final IndexedWidgetBuilder dayOfWeekBuilder;

  /// Define day builder.
  final DayBuilder dayBuilder;

  /// Define selection builder for single selections -
  /// [CalendarSingleSelection], [CalendarSingleOrNoneSelection].
  final SelectionBuilder singleSelectionBuilder;

  /// Define selection builder for multi selections -
  /// [CalendarMultiSelection], [CalendarRangeSelection].
  final SelectionBuilder multiSelectionBuilder;

  /// Define decorator builder for month widget of calendar.
  final MonthDecoratorBuilder monthDecoratorBuilder;

  /// Define decorator builder for whole calendar.
  final CalendarDecoratorBuilder calendarDecoratorBuilder;

  /// Widget for displaying horizontal separator between calendars.
  final PreferredSizeWidget horizontalSeparator;

  /// Widget for displaying vertical separator between calendars.
  final PreferredSizeWidget verticalSeparator;

  /// Define calendars scroll direction.
  final Axis scrollDirection;

  // * combo

  /// Define combo calendar text title placement
  /// [label] as [InputDecoration.labelText]
  /// [placeholder] as [InputDecoration.hintText]
  final ComboTextTitlePlacement comboTextTitlePlacement;

  /// Define combo title builder for single selections -
  /// [CalendarSingleSelection], [CalendarSingleOrNoneSelection].
  final SelectionTitleBuilder<DateTime> singleSelectionTitleBuilder;

  /// Define combo title builder for calendars with [CalendarMultiSelection].
  final SelectionTitleBuilder<Set<DateTime>> multiSelectionTitleBuilder;

  /// Define combo title builder for calendars with [CalendarRangeSelection].
  final SelectionTitleBuilder<DatesRange> rangeSelectionTitleBuilder;

  /// Define combo title builder for all calendar selections.
  /// (selects one of [singleSelectionTitleBuilder], [multiSelectionTitleBuilder],
  /// [rangeSelectionTitleBuilder])
  final SelectionTitleBuilder selectionTitleBuilder;

  /// Creates a copy of this calendar parameters but with the given fields replaced with
  /// the new values.
  CalendarParameters copyWith({
    int firstDayOfWeekIndex,
    bool showDaysOfWeek,
    IndexedWidgetBuilder dayOfWeekBuilder,
    DayBuilder dayBuilder,
    SelectionBuilder singleSelectionBuilder,
    SelectionBuilder multiSelectionBuilder,
    MonthDecoratorBuilder monthDecoratorBuilder,
    CalendarDecoratorBuilder calendarDecoratorBuilder,
    PreferredSizeWidget horizontalSeparator,
    PreferredSizeWidget verticalSeparator,
    Axis scrollDirection,
    ComboTextTitlePlacement comboTextTitlePlacement,
    SelectionTitleBuilder<DateTime> singleSelectionTitleBuilder,
    SelectionTitleBuilder<Set<DateTime>> multiSelectionTitleBuilder,
    SelectionTitleBuilder<DatesRange> rangeSelectionTitleBuilder,
    SelectionTitleBuilder selectionTitleBuilder,
  }) =>
      CalendarParameters(
        firstDayOfWeekIndex: firstDayOfWeekIndex ?? this.firstDayOfWeekIndex,
        showDaysOfWeek: showDaysOfWeek ?? this.showDaysOfWeek,
        dayOfWeekBuilder: dayOfWeekBuilder ?? this.dayOfWeekBuilder,
        dayBuilder: dayBuilder ?? this.dayBuilder,
        singleSelectionBuilder:
            singleSelectionBuilder ?? this.singleSelectionBuilder,
        multiSelectionBuilder:
            multiSelectionBuilder ?? this.multiSelectionBuilder,
        monthDecoratorBuilder:
            monthDecoratorBuilder ?? this.monthDecoratorBuilder,
        calendarDecoratorBuilder:
            calendarDecoratorBuilder ?? this.calendarDecoratorBuilder,
        horizontalSeparator: horizontalSeparator ?? this.horizontalSeparator,
        verticalSeparator: verticalSeparator ?? this.verticalSeparator,
        scrollDirection: scrollDirection ?? this.scrollDirection,
        comboTextTitlePlacement:
            comboTextTitlePlacement ?? this.comboTextTitlePlacement,
        singleSelectionTitleBuilder:
            singleSelectionTitleBuilder ?? this.singleSelectionTitleBuilder,
        multiSelectionTitleBuilder:
            multiSelectionTitleBuilder ?? this.multiSelectionTitleBuilder,
        rangeSelectionTitleBuilder:
            rangeSelectionTitleBuilder ?? this.rangeSelectionTitleBuilder,
        selectionTitleBuilder:
            selectionTitleBuilder ?? this.selectionTitleBuilder,
      );

  /// Default builder for [dayOfWeekBuilder]
  static Widget buildDefaultDayOfWeek(BuildContext context, int index) =>
      Center(
          child: Text(MaterialLocalizations.of(context).narrowWeekdays[index],
              style: TextStyle(color: Colors.blueAccent)));

  /// Default builder for [dayBuilder]
  static Widget buildDefaultDay(
          BuildContext context,
          CalendarParameters parameters,
          DateTime date,
          DayType type,
          int column,
          int row) =>
      Center(
          child: Text(
        date.day.toString(),
        style: TextStyle(
          color: type == DayType.extraLow || type == DayType.extraHigh
              ? Colors.grey
              : null,
          decoration: type == DayType.today ? TextDecoration.underline : null,
        ),
      ));

  /// Default builder for [singleSelectionBuilder]
  static Widget buildDefaultSingleSelection(
      BuildContext context,
      CalendarParameters parameters,
      DateTime date,
      int column,
      int row,
      Widget day,
      bool preselect,
      bool Function(DateTime date) isSelected,
      {Color color}) {
    color ??= Theme.of(context).primaryColor;
    return isSelected(date)
        ? Container(
            child: DefaultTextStyle(child: day, style: TextStyle(color: color)),
            decoration: BoxDecoration(
              color:
                  preselect ? color.withOpacity(0.05) : color.withOpacity(0.1),
              border:
                  Border.all(color: preselect ? color.withOpacity(0.3) : color),
              borderRadius: const BorderRadius.all(Radius.circular(1000)),
            ),
          )
        : day;
    //return Container()
  }

  /// Default builder for [multiSelectionBuilder]
  static Widget buildDefaultMultiSelection(
      BuildContext context,
      CalendarParameters parameters,
      DateTime date,
      int column,
      int row,
      Widget day,
      bool preselect,
      bool Function(DateTime date) isSelected,
      {Color color}) {
    if (!isSelected(date)) return day;
    final leftSelected =
        column != 0 && isSelected(date.subtract(const Duration(days: 1)));
    final rightSelected = column != DateTime.daysPerWeek - 1 &&
        isSelected(date.add(const Duration(days: 1)));
    final topSelected = row != 0 &&
        isSelected(date.subtract(const Duration(days: DateTime.daysPerWeek)));
    final bottomSelected = row != 5 &&
        isSelected(date.add(const Duration(days: DateTime.daysPerWeek)));
    color ??= Theme.of(context).primaryColor;
    final borderSide =
        BorderSide(color: preselect ? color.withOpacity(0.3) : color);
    return Container(
      child: DefaultTextStyle(child: day, style: TextStyle(color: color)),
      decoration: BoxDecoration(
        color: preselect ? color.withOpacity(0.05) : color.withOpacity(0.1),
        border: Border(
          left: leftSelected ? BorderSide.none : borderSide,
          right: rightSelected ? BorderSide.none : borderSide,
          top: topSelected ? BorderSide.none : borderSide,
          bottom: bottomSelected ? BorderSide.none : borderSide,
        ),
      ),
    );
  }

  /// Default builder for [singleSelectionTitleBuilder]
  static Widget buildDefaultSingleSelectionTitle(BuildContext context,
          CalendarParameters parameters, DateTime selected) =>
      Text(MaterialLocalizations.of(context).formatFullDate(selected),
          overflow: TextOverflow.ellipsis);

  /// Default builder for [multiSelectionTitleBuilder]
  static Widget buildDefaultMultiSelectionTitle(BuildContext context,
      CalendarParameters parameters, Set<DateTime> selected) {
    final localizations = MaterialLocalizations.of(context);
    final dates =
        selected?.map((e) => localizations.formatMediumDate(e))?.join(', ');
    return Text(dates?.isNotEmpty == true ? dates : '',
        overflow: TextOverflow.ellipsis);
  }

  /// Default builder for [rangeSelectionTitleBuilder]
  static Widget buildDefaultRangeSelectionTitle(BuildContext context,
      CalendarParameters parameters, DatesRange selected) {
    final localizations = MaterialLocalizations.of(context);
    final range = localizations.formatMediumDate(selected.from) +
        ' - ' +
        localizations.formatMediumDate(selected.to);
    return Text(range);
  }

  static Widget getSelectionTitle(
          BuildContext context, CalendarParameters parameters, selected) =>
      selected == null
          ? const SizedBox()
          : selected is DateTime
              ? parameters.singleSelectionTitleBuilder(
                  context, parameters, selected)
              : selected is Set<DateTime>
                  ? parameters.multiSelectionTitleBuilder(
                      context, parameters, selected)
                  : selected is DatesRange
                      ? parameters.rangeSelectionTitleBuilder(
                          context, parameters, selected)
                      : throw FormatException(
                          'Invalid calendar selection type.');

  /// Default builder for [selectionTitleBuilder]
  static Widget buildDefaultSelectionTitle(
          BuildContext context, CalendarParameters parameters, selected) =>
      ListTile(
          enabled: ComboContext.of(context)?.parameters?.enabled != false,
          title: selected == null
              ? const SizedBox()
              : getSelectionTitle(context, parameters, selected));
}

/// Allows to set [CalendarParameters] for all [Calendar], [CalendarCombo]
/// widgets in the [child].
class CalendarContext extends StatelessWidget {
  const CalendarContext({
    Key key,
    @required this.parameters,
    @required this.child,
  })  : assert(parameters != null),
        assert(child != null),
        super(key: key);

  final CalendarParameters parameters;
  final Widget child;

  static CalendarContextData of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<CalendarContextData>();

  @override
  Widget build(BuildContext context) {
    final parentData = CalendarContext.of(context);
    final def = parentData == null
        ? CalendarParameters.defaultParameters
        : parentData.parameters;
    final my = parameters;
    final merged = CalendarParameters(
      firstDayOfWeekIndex: my.firstDayOfWeekIndex ?? def.firstDayOfWeekIndex,
      showDaysOfWeek: my.showDaysOfWeek ?? def.showDaysOfWeek,
      dayOfWeekBuilder: my.dayOfWeekBuilder ?? def.dayOfWeekBuilder,
      dayBuilder: my.dayBuilder ?? def.dayBuilder,
      singleSelectionBuilder:
          my.singleSelectionBuilder ?? def.singleSelectionBuilder,
      multiSelectionBuilder:
          my.multiSelectionBuilder ?? def.multiSelectionBuilder,
      monthDecoratorBuilder:
          my.monthDecoratorBuilder ?? def.monthDecoratorBuilder,
      calendarDecoratorBuilder:
          my.calendarDecoratorBuilder ?? def.calendarDecoratorBuilder,
      horizontalSeparator: my.horizontalSeparator ?? def.horizontalSeparator,
      verticalSeparator: my.verticalSeparator ?? def.verticalSeparator,
      scrollDirection: my.scrollDirection ?? def.scrollDirection,
      comboTextTitlePlacement:
          my.comboTextTitlePlacement ?? def.comboTextTitlePlacement,
      singleSelectionTitleBuilder:
          my.singleSelectionTitleBuilder ?? def.singleSelectionTitleBuilder,
      multiSelectionTitleBuilder:
          my.multiSelectionTitleBuilder ?? def.multiSelectionTitleBuilder,
      rangeSelectionTitleBuilder:
          my.rangeSelectionTitleBuilder ?? def.rangeSelectionTitleBuilder,
      selectionTitleBuilder:
          my.selectionTitleBuilder ?? def.selectionTitleBuilder,
    );

    return CalendarContextData(this, child, merged);
  }
}

/// Provides [CalendarParameters] for the specified [CalendarContext].
class CalendarContextData extends InheritedWidget {
  const CalendarContextData(this._widget, Widget child, this.parameters)
      : super(child: child);

  final CalendarContext _widget;
  final CalendarParameters parameters;

  @override
  bool updateShouldNotify(CalendarContextData oldWidget) =>
      _widget.parameters != oldWidget._widget.parameters;
}

/// Signature for determining if specified date is selected.
/// [date] - date to check selection.
/// [type] - type of the calendar day.
/// [column], [row] - position in calendar.
typedef CalendarSelectionCanSelect = bool Function(
    DateTime date, DayType type, int column, int row);

/// Base class for calendar selections
abstract class CalendarSelectionBase {
  const CalendarSelectionBase({
    this.canSelectExtra = false,

    /// Handler to determine if user can select specified date.
    CalendarSelectionCanSelect canSelect,
    this.onDayTap,
    this.autoClosePopupAfterSelectionChanged = true,
  })  : assert(canSelectExtra != null),
        assert(autoClosePopupAfterSelectionChanged != null),
        _canSelect = canSelect;

  /// Determines if user can select the days which not in current month.
  final bool canSelectExtra;

  final CalendarSelectionCanSelect _canSelect;

  /// Callbacks when user tapped on calendar day.
  final ValueSetter<DateTime> onDayTap;

  /// Determines if [CalendarCombo] should automatically close popup
  /// when selection changed.
  final bool autoClosePopupAfterSelectionChanged;

  @protected
  bool canSelect(DateTime date, DayType type, int column, int row) =>
      (canSelectExtra ||
          (type != DayType.extraLow && type != DayType.extraHigh)) &&
      (_canSelect == null || _canSelect(date, type, column, row));

  @protected
  void callOnDayTap(DateTime date) {
    if (onDayTap != null) onDayTap(date);
  }

  @protected
  void select(DateTime date) => callOnDayTap(date);

  @protected
  bool isSelected(DateTime date, DayType type, int column, int row);

  /// Determines if there is at least one selected day.
  bool get hasSelection;
}

/// Not selectable calendar selection.
class CalendarNoneSelection extends CalendarSelectionBase {
  const CalendarNoneSelection({
    bool canSelectExtra = false,
    CalendarSelectionCanSelect canSelect,
    ValueSetter<DateTime> onDayTap,
    bool autoClosePopupAfterSelectionChanged = true,
  }) : super(
          canSelectExtra: canSelectExtra,
          canSelect: canSelect,
          onDayTap: onDayTap,
          autoClosePopupAfterSelectionChanged:
              autoClosePopupAfterSelectionChanged,
        );

  @override
  bool canSelect(DateTime date, DayType type, int column, int row) =>
      onDayTap != null && super.canSelect(date, type, column, row);

  @override
  bool isSelected(DateTime date, DayType type, int column, int row) => false;

  @override
  bool get hasSelection => false;
}

/// Base class for selectable calendar selections
abstract class CalendarSelection<T> extends CalendarSelectionBase {
  CalendarSelection({
    T selected,
    this.onSelectedChanged,
    bool canSelectExtra = false,
    CalendarSelectionCanSelect canSelect,
    ValueSetter<DateTime> onDayTap,
    bool autoClosePopupAfterSelectionChanged = true,
  })  : _selected = selected,
        super(
          canSelectExtra: canSelectExtra,
          canSelect: canSelect,
          onDayTap: onDayTap,
          autoClosePopupAfterSelectionChanged:
              autoClosePopupAfterSelectionChanged,
        );
  final _listeners = <ValueChanged<T>>[];
  void addListener(ValueChanged<T> listener) => _listeners.add(listener);
  void removeListener(ValueChanged<T> listener) => _listeners.remove(listener);

  bool get isSingle => false;

  T _selected;
  T get selected => _selected;
  set selected(T value) {
    _selected = value;
    if (onSelectedChanged != null) {
      onSelectedChanged(selected);
    }
    _listeners.forEach((e) => e(value));
  }

  void clear() => selected = null;

  final ValueChanged<T> onSelectedChanged;
  DateTime _hovered;
  @protected
  DateTime get hovered => _hovered;
  @protected
  set hovered(DateTime value) => _hovered = value;
  @protected
  bool get preselect => false;

  @override
  bool get hasSelection => _selected != null;
}

/// Single date selection.
class CalendarSingleSelection extends CalendarSelection<DateTime> {
  CalendarSingleSelection({
    DateTime selected,
    ValueChanged<DateTime> onSelectedChanged,
    bool canSelectExtra = false,
    CalendarSelectionCanSelect canSelect,
    ValueSetter<DateTime> onDayTap,
    bool autoClosePopupAfterSelectionChanged = true,
  }) : super(
          selected: selected,
          onSelectedChanged: onSelectedChanged,
          canSelectExtra: canSelectExtra,
          canSelect: canSelect,
          onDayTap: onDayTap,
          autoClosePopupAfterSelectionChanged:
              autoClosePopupAfterSelectionChanged,
        );

  @override
  bool get isSingle => true;

  @override
  bool isSelected(DateTime date, DayType type, int column, int row) =>
      canSelect(date, type, column, row) && date == selected;

  @override
  void select(DateTime date) {
    selected = date;
    super.select(date);
  }
}

/// Single date selection with the possibility to unselect.
class CalendarSingleOrNoneSelection extends CalendarSingleSelection {
  CalendarSingleOrNoneSelection({
    DateTime selected,
    ValueChanged<DateTime> onSelectedChanged,
    bool canSelectExtra = false,
    CalendarSelectionCanSelect canSelect,
    ValueSetter<DateTime> onDayTap,
    bool autoClosePopupAfterSelectionChanged = true,
  }) : super(
          selected: selected,
          onSelectedChanged: onSelectedChanged,
          canSelectExtra: canSelectExtra,
          canSelect: canSelect,
          onDayTap: onDayTap,
          autoClosePopupAfterSelectionChanged:
              autoClosePopupAfterSelectionChanged,
        );

  @override
  void select(DateTime date) {
    selected = date == selected ? null : date;
    callOnDayTap(date);
  }
}

/// Multi dates selection.
class CalendarMultiSelection extends CalendarSelection<Set<DateTime>> {
  CalendarMultiSelection({
    Set<DateTime> selected,
    ValueChanged<Set<DateTime>> onSelectedChanged,
    bool canSelectExtra = false,
    CalendarSelectionCanSelect canSelect,
    ValueSetter<DateTime> onDayTap,
    bool autoClosePopupAfterSelectionChanged = false,
  }) : super(
          selected: selected,
          onSelectedChanged: onSelectedChanged,
          canSelectExtra: canSelectExtra,
          canSelect: canSelect,
          onDayTap: onDayTap,
          autoClosePopupAfterSelectionChanged:
              autoClosePopupAfterSelectionChanged,
        );

  @override
  void clear() => selected = {};

  @override
  bool isSelected(DateTime date, DayType type, int column, int row) =>
      canSelect(date, type, column, row) && selected?.contains(date) == true;

  @override
  void select(DateTime date) {
    final selected = this.selected ?? {};
    (selected?.contains(date) == true ? selected.remove : selected.add)(date);
    this.selected = selected;
    super.select(date);
  }

  @override
  bool get hasSelection => super.hasSelection && selected.isNotEmpty;
}

/// Define range of dates.
class DatesRange {
  DatesRange(this.from, this.to)
      : assert(from != null),
        assert(to != null);

  /// Start date of range.
  final DateTime from;

  /// End date of range.
  final DateTime to;
}

/// Range dates selection.
class CalendarRangeSelection extends CalendarSelection<DatesRange> {
  CalendarRangeSelection({
    DatesRange selected,
    ValueChanged<DatesRange> onSelectedChanged,
    bool canSelectExtra = false,
    ValueSetter<DateTime> onDayTap,
    bool autoClosePopupAfterSelectionChanged = true,
  })  : _from = selected?.from,
        _to = selected?.to,
        super(
          selected: selected,
          onSelectedChanged: onSelectedChanged,
          canSelectExtra: canSelectExtra,
          onDayTap: onDayTap,
          autoClosePopupAfterSelectionChanged:
              autoClosePopupAfterSelectionChanged,
        );

  DateTime _from;
  DateTime _to;

  @override
  bool get preselect => _from != null && _to == null;

  @override
  bool isSelected(DateTime date, DayType type, int column, int row) {
    if (!canSelect(date, type, column, row) || (_to == null && _from == null)) {
      return false;
    }
    DateTime from;
    DateTime to;
    if (_to == null) {
      final hovered = this.hovered ?? _from;
      final isBefore = hovered.isBefore(_from);
      from = isBefore ? hovered : _from;
      to = isBefore ? _from : hovered;
    } else {
      from = _from;
      to = _to;
    }
    return !date.isBefore(from) && !date.isAfter(to);
  }

  @override
  void select(DateTime date) {
    if (preselect) {
      if (date.isBefore(_from)) {
        _to = _from;
        _from = date;
      } else {
        _to = date;
      }
      selected = DatesRange(
          _from, DateTime.utc(_to.year, _to.month, _to.day, 23, 59, 59, 999));
    } else {
      _from = date;
      _to = null;
      hovered = null;
    }
    super.select(date);
  }
}

/// Helper to build calendar selections.
class CalendarSelections {
  static CalendarNoneSelection none({
    bool canSelectExtra = false,
    CalendarSelectionCanSelect canSelect,
    ValueSetter<DateTime> onDayTap,
    bool autoClosePopupAfterSelectionChanged = true,
  }) =>
      CalendarNoneSelection(
        canSelectExtra: canSelectExtra,
        canSelect: canSelect,
        onDayTap: onDayTap,
        autoClosePopupAfterSelectionChanged:
            autoClosePopupAfterSelectionChanged,
      );

  static CalendarSingleSelection single({
    DateTime selected,
    ValueChanged<DateTime> onSelectedChanged,
    bool canSelectExtra = false,
    CalendarSelectionCanSelect canSelect,
    ValueSetter<DateTime> onDayTap,
    bool autoClosePopupAfterSelectionChanged = true,
  }) =>
      CalendarSingleSelection(
        selected: selected,
        onSelectedChanged: onSelectedChanged,
        canSelectExtra: canSelectExtra,
        canSelect: canSelect,
        onDayTap: onDayTap,
        autoClosePopupAfterSelectionChanged:
            autoClosePopupAfterSelectionChanged,
      );

  static CalendarSingleOrNoneSelection singleOrNone({
    DateTime selected,
    ValueChanged<DateTime> onSelectedChanged,
    bool canSelectExtra = false,
    CalendarSelectionCanSelect canSelect,
    ValueSetter<DateTime> onDayTap,
    bool autoClosePopupAfterSelectionChanged = true,
  }) =>
      CalendarSingleOrNoneSelection(
        selected: selected,
        onSelectedChanged: onSelectedChanged,
        canSelectExtra: canSelectExtra,
        canSelect: canSelect,
        onDayTap: onDayTap,
        autoClosePopupAfterSelectionChanged:
            autoClosePopupAfterSelectionChanged,
      );

  static CalendarMultiSelection multi({
    Set<DateTime> selected,
    ValueChanged<Set<DateTime>> onSelectedChanged,
    bool canSelectExtra = false,
    CalendarSelectionCanSelect canSelect,
    ValueSetter<DateTime> onDayTap,
    bool autoClosePopupAfterSelectionChanged = false,
  }) =>
      CalendarMultiSelection(
        selected: selected,
        onSelectedChanged: onSelectedChanged,
        canSelectExtra: canSelectExtra,
        canSelect: canSelect,
        onDayTap: onDayTap,
        autoClosePopupAfterSelectionChanged:
            autoClosePopupAfterSelectionChanged,
      );

  static CalendarRangeSelection range({
    DatesRange selected,
    ValueChanged<DatesRange> onSelectedChanged,
    bool canSelectExtra = false,
    ValueSetter<DateTime> onDayTap,
    bool autoClosePopupAfterSelectionChanged = true,
  }) =>
      CalendarRangeSelection(
        selected: selected,
        onSelectedChanged: onSelectedChanged,
        canSelectExtra: canSelectExtra,
        onDayTap: onDayTap,
        autoClosePopupAfterSelectionChanged:
            autoClosePopupAfterSelectionChanged,
      );
}

class _Calendar extends StatelessWidget {
  const _Calendar({
    Key key,
    @required this.parameters,
    this.displayDate,
    @required this.dayBuilder,
  })  : assert(parameters != null),
        assert(dayBuilder != null),
        super(key: key);

  final CalendarParameters parameters;
  final DateTime displayDate;
  final DayBuilder dayBuilder;

  @override
  Widget build(BuildContext context) {
    final parameters = this.parameters;
    final firstDayOfWeekIndex = parameters.firstDayOfWeekIndex ??
        MaterialLocalizations.of(context).firstDayOfWeekIndex ??
        0;
    final daysOfWeekFactor = parameters.showDaysOfWeek ? 1 : 0;

    DateTime getDate(DateTime date) =>
        DateTime.utc(date.year, date.month, date.day);

    final today = getDate(DateTime.now());
    final date = this.displayDate ?? today;
    final displayDate = DateTime.utc(date.year, date.month);

    var firstDate = DateTime.utc(displayDate.year, displayDate.month, 1);
    final shift =
        (firstDate.weekday == DateTime.sunday ? 0 : firstDate.weekday) -
            firstDayOfWeekIndex;
    firstDate = firstDate.subtract(
        Duration(days: shift < 0 ? shift + DateTime.daysPerWeek : shift));
    if (firstDate.month == 2 &&
        firstDate.day == 1 &&
        DateTime.utc(firstDate.year, 3, 1).difference(firstDate).inDays == 28) {
      firstDate =
          firstDate.subtract(const Duration(days: DateTime.daysPerWeek));
    }

    Widget buildDay(int column, int row) {
      final date =
          firstDate.add(Duration(days: row * DateTime.daysPerWeek + column));
      final type = date.isBefore(displayDate)
          ? DayType.extraLow
          : date.month == displayDate.month
              ? date == today ? DayType.today : DayType.current
              : DayType.extraHigh;

      return dayBuilder(context, parameters, date, type, column, row);
    }

    return Column(
      children: Iterable.generate(6 + daysOfWeekFactor)
          .map(
            (row) => Expanded(
              child: Row(
                children: Iterable.generate(DateTime.daysPerWeek)
                    .map(
                      (column) => Expanded(
                          child: parameters.showDaysOfWeek && row == 0
                              ? parameters.dayOfWeekBuilder(
                                  context,
                                  (column + firstDayOfWeekIndex) %
                                      DateTime.daysPerWeek)
                              : buildDay(column, row - daysOfWeekFactor)),
                    )
                    .toList(),
              ),
            ),
          )
          .toList(),
    );
  }
}

abstract class _Selectable implements StatefulWidget {
  CalendarSelectionBase get selection;
}

mixin _SelectionListenerMixin<T extends _Selectable> on State<T> {
  @override
  void initState() {
    super.initState();
    subscribe();
  }

  @override
  void didUpdateWidget(_Selectable oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selection != oldWidget.selection) {
      unsubscribe(oldWidget);
      subscribe();
    }
  }

  @protected
  void subscribe() {
    if (widget.selection is CalendarSelection) {
      (widget.selection as CalendarSelection).addListener(didSelectionChanged);
    }
  }

  @protected
  void unsubscribe(_Selectable widget) {
    if (widget.selection is CalendarSelection) {
      (widget.selection as CalendarSelection)
          .removeListener(didSelectionChanged);
    }
  }

  @protected
  void didSelectionChanged(_) {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    unsubscribe(widget);
    super.dispose();
  }
}

/// Multi-calendar widget.
class Calendar extends StatefulWidget implements _Selectable {
  /// Creates multi-calendar widget.
  const Calendar({
    Key key,
    this.displayDate,
    this.onDisplayDateChanged,
    this.columns = 1,
    this.rows = 1,
    this.selection = const CalendarNoneSelection(),
    this.monthSize = const Size.square(300),
  })  : assert(columns > 0),
        assert(rows > 0),
        assert(selection != null),
        super(key: key);

  /// First month of calendars set.
  final DateTime displayDate;

  /// Callbacks when first month of calendars set is changed.
  final ValueChanged<DateTime> onDisplayDateChanged;

  /// Number of months by horizontal.
  final int columns;

  /// Number of months by vertical.
  final int rows;

  /// Determines dates selection method.
  @override
  final CalendarSelectionBase selection;

  /// Determine the size of one month of the calendar.
  /// If null, calendar will be layouted at the whole
  /// available area
  final Size monthSize;

  @override
  CalendarState createState() => CalendarState(displayDate);
}

/// Allows to paginate months by [inc], [dec] methods.
abstract class CalendarController {
  /// Move scroll forward by one position of months.
  void inc();

  /// Move scroll backward by one position of months.
  void dec();

  void setDisplayDate(DateTime date);
}

/// State for a [Calendar].
/// Implements [CalendarController].
class CalendarState extends State<Calendar>
    with _SelectionListenerMixin
    implements CalendarController {
  CalendarState(DateTime displayDate)
      : _displayDate = _getMonthDate(displayDate);
  static const _itemsBefore = 2;

  UniqueKey _listKey;
  ScrollController _controller;
  DateTime _displayDate;
  double _calendarWidth;
  double _calendarHeight;
  Axis _scrollDirection;
  double get _lenght =>
      _scrollDirection == Axis.horizontal ? _calendarWidth : _calendarHeight;

  static DateTime _getMonthDate(DateTime date) {
    final d = date ?? DateTime.now();
    return DateTime.utc(d.year, d.month);
  }

  @override
  void didUpdateWidget(Calendar oldWidget) {
    super.didUpdateWidget(oldWidget);
    final displayDate = _getMonthDate(widget.displayDate);
    if ((displayDate != _getMonthDate(oldWidget.displayDate) &&
            displayDate != _displayDate) ||
        (CalendarContext.of(context)?.parameters ??
                    CalendarParameters.defaultParameters)
                .scrollDirection !=
            _scrollDirection ||
        oldWidget.columns != widget.columns ||
        oldWidget.rows != widget.rows) {
      setDisplayDate(displayDate);
    }
  }

  void _move(double offset) =>
      _controller.animateTo(_controller.position.pixels + offset,
          duration: const Duration(milliseconds: 300), curve: Curves.bounceOut);

  @override
  void inc() => _move(_lenght);

  @override
  void dec() => _move(-_lenght);

  @override
  void setDisplayDate(DateTime date) => setState(() {
        _controller.dispose();
        _controller = null;
        _listKey = null;
        _displayDate = date;
      });

  DateTime _getDate(int row, [int column = 0]) {
    final crossFactor =
        _scrollDirection == Axis.horizontal ? 1 : widget.columns;
    final monthCount = _displayDate.year * DateTime.monthsPerYear +
        _displayDate.month -
        _itemsBefore * crossFactor -
        1 +
        row * crossFactor +
        column;
    final month = (monthCount + 1) % DateTime.monthsPerYear;
    return DateTime.utc(
        monthCount ~/ DateTime.monthsPerYear, month == 0 ? 12 : month);
  }

  @protected
  Widget buildDay(BuildContext context, CalendarParameters parameters,
      DateTime date, DayType type, int column, int row) {
    final selection = widget.selection;
    final modifiableSelection =
        selection is CalendarSelection ? selection : null;
    var day =
        parameters.dayBuilder(context, parameters, date, type, column, row);
    final month = date.month +
        (type == DayType.extraLow
            ? date.month == 12 ? -11 : 1
            : type == DayType.extraHigh ? date.month == 1 ? 11 : -1 : 0);
    if (!(selection is CalendarNoneSelection)) {
      day = ((modifiableSelection?.isSingle ?? true)
          ? parameters.singleSelectionBuilder
          : parameters.multiSelectionBuilder)(
        context,
        parameters,
        date,
        column,
        row,
        day,
        modifiableSelection?.preselect == true,
        (e) =>
            modifiableSelection?.isSelected(
                e,
                // today is not provided to avoid DateTime.now() calls
                e.month == month
                    ? DayType.current
                    : (e.month == 1 && month == 12) || e.month < month
                        ? DayType.extraLow
                        : DayType.extraHigh,
                column,
                row) ==
            true,
      );
    }

    return selection.canSelect(date, type, column, row)
        ? InkResponse(
            child: day,
            onTap: () => setState(() => selection.select(date)),
            onHover: modifiableSelection == null
                ? null
                : (hovered) {
                    if (hovered) {
                      setState(() => modifiableSelection.hovered = date);
                    }
                  },
          )
        : day;
  }

  @override
  Widget build(BuildContext context) {
    final parameters = CalendarContext.of(context)?.parameters ??
        CalendarParameters.defaultParameters;
    _scrollDirection = parameters.scrollDirection;

    final horizontalSeparator = parameters.horizontalSeparator;
    final verticalSeparator = parameters.verticalSeparator;
    final separatorWidth = horizontalSeparator?.preferredSize?.width ?? 0.0;
    final separatorHeight = verticalSeparator?.preferredSize?.height ?? 0.0;
    final scrollDirection = parameters.scrollDirection;
    final horizontal = scrollDirection == Axis.horizontal;
    final columns = widget.columns;
    final rows = widget.rows;

    Widget calendar = LayoutBuilder(builder: (context, constrants) {
      final maxWidth =
          constrants.maxWidth + (horizontal ? separatorWidth : 0.0);
      final maxHeight =
          constrants.maxHeight + (!horizontal ? separatorHeight : 0.0);

      _calendarWidth = maxWidth / columns;
      _calendarHeight = maxHeight / rows;

      return NotificationListener<ScrollEndNotification>(
        onNotification: (_) {
          final date = _getDate(_controller.position.pixels ~/ _lenght);
          if (date != _displayDate) {
            setDisplayDate(date);
            if (widget.onDisplayDateChanged != null) {
              widget.onDisplayDateChanged(date);
            }
          }
          return true;
        },
        child: ListView.builder(
          key: _listKey ??= UniqueKey(),
          controller: _controller ??=
              ScrollController(initialScrollOffset: _itemsBefore * _lenght),
          physics: _SnapScrollPhysics(itemSize: _lenght),
          scrollDirection: scrollDirection,
          itemBuilder: (context, index) {
            Widget build(int row, [int column = 0]) {
              final date = _getDate(row, column);
              Widget calendar = _Calendar(
                parameters: parameters,
                displayDate: date,
                dayBuilder: buildDay,
              );
              if (parameters.monthDecoratorBuilder != null) {
                calendar = parameters.monthDecoratorBuilder(
                    context, parameters, date, calendar);
              }
              final separator =
                  horizontal ? horizontalSeparator : verticalSeparator;
              if (separator != null) {
                final separatedItems = [Expanded(child: calendar), separator];
                calendar = horizontal
                    ? Row(children: separatedItems)
                    : Column(children: separatedItems);
              }

              return SizedBox(
                  width: _calendarWidth,
                  height: _calendarHeight,
                  child: calendar);
            }

            var calendars = Iterable.generate(horizontal ? rows : columns)
                .map((_) => build(horizontal ? index + _ * columns : index,
                    horizontal ? 0 : _))
                .toList();
            if (calendars.length == 1) return calendars[0];

            final separator = horizontal
                ? verticalSeparator == null
                    ? null
                    : SizedBox(
                        width: _calendarWidth - separatorWidth,
                        child: verticalSeparator)
                : horizontalSeparator == null
                    ? null
                    : SizedBox(
                        height: _calendarHeight - separatorHeight,
                        child: horizontalSeparator);
            if (separator != null) {
              calendars = calendars
                  .map((e) =>
                      [if (e != calendars[0]) separator, Expanded(child: e)])
                  .expand((e) => e)
                  .toList();
            }

            return horizontal
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: calendars)
                : Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: calendars);
          },
        ),
      );
    });

    final decoratorBuilder = parameters.calendarDecoratorBuilder;
    if (decoratorBuilder != null) {
      calendar =
          decoratorBuilder(context, parameters, _displayDate, calendar, this);
    }

    final monthSize = widget.monthSize;
    return monthSize == null
        ? calendar
        : ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth:
                  columns * (monthSize.width + separatorWidth) - separatorWidth,
              maxHeight:
                  rows * (monthSize.height + separatorHeight) - separatorHeight,
            ),
            child: calendar);
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }
}

class _SnapScrollPhysics extends ScrollPhysics {
  const _SnapScrollPhysics({ScrollPhysics parent, @required this.itemSize})
      : assert(itemSize > 0),
        super(parent: parent);

  final double itemSize;

  @override
  _SnapScrollPhysics applyTo(ScrollPhysics ancestor) =>
      _SnapScrollPhysics(parent: buildParent(ancestor), itemSize: itemSize);

  @override
  Simulation createBallisticSimulation(
      ScrollMetrics position, double velocity) {
    if ((velocity <= 0.0 && position.pixels <= position.minScrollExtent) ||
        (velocity >= 0.0 && position.pixels >= position.maxScrollExtent)) {
      return super.createBallisticSimulation(position, velocity);
    }
    final tolerance = this.tolerance;
    final target = (position.pixels / itemSize +
                ((velocity < -tolerance.velocity)
                    ? -0.5
                    : velocity > tolerance.velocity ? 0.5 : 0))
            .roundToDouble() *
        itemSize;
    return target == position.pixels
        ? null
        : ScrollSpringSimulation(spring, position.pixels, target, velocity,
            tolerance: tolerance);
  }

  @override
  bool get allowImplicitScrolling => false;
}

/// Combo widget with calendars popup.
class CalendarCombo extends StatefulWidget implements _Selectable {
  /// Creates combo widget with calendars popup.
  const CalendarCombo({
    Key key,
    this.displayDate,
    this.onDisplayDateChanged,
    this.columns = 1,
    this.rows = 1,
    this.title,
    this.selection = const CalendarNoneSelection(),
    this.monthSize = const Size.square(300),
    this.openedChanged,
    this.hoveredChanged,
    this.onTap,
  })  : assert(columns > 0),
        assert(rows > 0),
        assert(selection != null),
        assert(monthSize != null),
        super(key: key);

  /// First month of calendars set.
  final DateTime displayDate;

  /// Callbacks when first month of calendars set is changed.
  final ValueChanged<DateTime> onDisplayDateChanged;

  /// Number of months by horizontal.
  final int columns;

  /// Number of months by vertical.
  final int rows;

  /// Combo text title.
  /// See also: [CalendarParameters.comboTextTitlePlacement]
  final String title;

  /// Determines dates selection method.
  @override
  final CalendarSelectionBase selection;

  /// Determine the size of one month of the calendar.
  final Size monthSize;

  /// Callbacks when the popup is opening or closing
  final ValueChanged<bool> openedChanged;

  /// Callbacks when the mouse pointer enters on or exits from child or popup.
  final ValueChanged<bool> hoveredChanged;

  /// Called when the user taps on [child].
  /// Also can be called by 'long tap' event if [ComboParameters.autoOpen]
  /// is set to [ComboAutoOpen.hovered] and platform is not 'Web'
  final GestureTapCallback onTap;

  @override
  CalendarComboState createState() => CalendarComboState(displayDate);
}

/// Allows to [open] and to [close] the combo popup,
/// and determines if the popup is [opened].
/// Allows to paginate months by [inc], [dec] methods.
abstract class CalendarComboController
    implements CalendarController, ComboController {}

/// State for a [CalendarCombo].
/// Implements [CalendarComboController].
class CalendarComboState<TSelection> extends State<CalendarCombo>
    with _SelectionListenerMixin
    implements CalendarComboController {
  CalendarComboState(this._displayDate);
  final _comboKey = GlobalKey<ComboState>();
  final _calendarKey = GlobalKey<CalendarState>();
  DateTime _displayDate;
  final _selections = StreamController<CalendarSelectionBase>.broadcast();

  @override
  void didUpdateWidget(CalendarCombo oldWidget) {
    super.didUpdateWidget(oldWidget);
    if ((widget.displayDate != oldWidget.displayDate &&
            widget.displayDate != _displayDate) ||
        widget.columns != oldWidget.columns ||
        widget.rows != oldWidget.rows ||
        widget.monthSize != oldWidget.monthSize) {
      setState(() => _displayDate = widget.displayDate);
    }
    if (widget.selection != oldWidget.selection) {
      _selections.add(widget.selection);
    }
  }

  @override
  bool get opened => _comboKey.currentState?.opened == true;

  @override
  void open() => _comboKey.currentState?.open();

  @override
  void close() => _comboKey.currentState?.close();

  @override
  void inc() => _calendarKey.currentState.inc();

  @override
  void dec() => _calendarKey.currentState.dec();

  @override
  void setDisplayDate(DateTime date) => _displayDate = date;

  @override
  void didSelectionChanged(_) {
    super.didSelectionChanged(_);
    if (widget.selection.autoClosePopupAfterSelectionChanged) {
      close();
      if (_ is DateTime) _displayDate = _;
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = CalendarContext.of(context);
    final parameters = data?.parameters ?? CalendarParameters.defaultParameters;
    final comboParameters = ComboContext.of(context)?.parameters ??
        ComboParameters.defaultParameters;
    final popupDecorator = comboParameters.popupDecoratorBuilder;
    final selection = widget.selection;

    return ComboContext(
      parameters: ComboParameters(
        childDecoratorBuilder: (context, comboParameters, opened, child) {
          final theme = Theme.of(context);
          final title = widget.title;
          final titlePlacement = parameters.comboTextTitlePlacement;
          final decoration = InputDecoration(
                  labelText: titlePlacement == null ||
                          titlePlacement == ComboTextTitlePlacement.label
                      ? title
                      : null,
                  hintText:
                      titlePlacement == ComboTextTitlePlacement.placeholder
                          ? title
                          : null,
                  border: OutlineInputBorder())
              .applyDefaults(theme.inputDecorationTheme)
              .copyWith(
                enabled: comboParameters.enabled,
              );
          return Stack(
            children: [
              Material(
                  borderRadius: (decoration.enabledBorder as OutlineInputBorder)
                      ?.borderRadius,
                  child: child),
              Positioned.fill(
                child: IgnorePointer(
                  child: InputDecorator(
                      decoration: decoration,
                      isFocused: opened,
                      isEmpty: !widget.selection.hasSelection,
                      expands: true),
                ),
              ),
            ],
          );
        },
      ),
      child: Combo(
        key: _comboKey,
        child: parameters.selectionTitleBuilder(
            context, parameters, (selection as CalendarSelection).selected),
        popupBuilder: (context, mirrored) {
          Widget calendar = StreamBuilder<CalendarSelectionBase>(
              initialData: widget.selection,
              stream: _selections.stream,
              builder: (context, snapshot) => Calendar(
                    key: _calendarKey,
                    displayDate: _displayDate,
                    onDisplayDateChanged: (date) {
                      _displayDate = date;
                      if (widget.onDisplayDateChanged != null) {
                        widget.onDisplayDateChanged(date);
                      }
                    },
                    columns: widget.columns,
                    rows: widget.rows,
                    selection: snapshot.data,
                    monthSize: widget.monthSize,
                  ));

          if (popupDecorator == null) {
            calendar = Material(elevation: 4, child: calendar);
          }

          return data == null
              ? calendar
              : CalendarContext(parameters: parameters, child: calendar);
        },
        openedChanged: widget.openedChanged,
        hoveredChanged: widget.hoveredChanged,
        onTap: widget.onTap,
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
    _selections.close();
  }
}
