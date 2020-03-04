import 'dart:async';
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
  final _hoverComboKey = GlobalKey<ComboState>();
  final _popupKey = GlobalKey<_TestPopupState>();
  final _hoverPopupKey = GlobalKey<_TestPopupState>();
  final _openingDurationController = TextEditingController(text: '150');
  final _closingDurationController = TextEditingController(text: '150');
  final _requiredUnderHeightController = TextEditingController(text: '300');
  final _popupWidthController = TextEditingController(text: '300');
  final _popupHeightController = TextEditingController(text: '300');
  final _spaceAboveController = TextEditingController(text: '100');
  final _comboWidthController = TextEditingController(text: '200');

  var _widthConstraints = PopupWidthConstraints.minMatchWidth;
  var _popupAutoClose = PopupAutoClose.tapDownWithChildIgnorePointer;
  var _overlap = false;
  var _showAbove = true;
  var _animatedOpen = true;
  var _openingDurationMs = 150;
  var _animatedClose = true;
  var _closingDurationMs = 150;
  var _customAnimation = false;
  var _requiredUnderHeight = 300;
  var _popupWidth = 300;
  var _popupHeight = 300;
  var _spaceAbove = 100;
  var _comboWidth = 200;
  var _comboAlignment = CrossAxisAlignment.center;

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
                // width constraints
                buildEnumSelector<PopupWidthConstraints>(
                    'Width Constraints:',
                    PopupWidthConstraints.values,
                    _widthConstraints,
                    (_) => _widthConstraints = _),

                // auto close
                buildEnumSelector<PopupAutoClose>(
                    'Width Constraints:',
                    PopupAutoClose.values,
                    _popupAutoClose,
                    (_) => _popupAutoClose = _),

                // overlap
                buildBoolSelector('Overlap', _overlap, (_) => _overlap = _),

                // showAbove
                buildBoolSelector(
                    'Show Above', _showAbove, (_) => _showAbove = _),

                // animatedOpen
                buildBoolSelector('Animated Open', _animatedOpen, (_) {
                  if (_animatedOpen = _) _customAnimation = false;
                }),

                // animatedOpenDuration
                buildIntSelector(_openingDurationController,
                    'Open Duration (Ms)', (_) => _openingDurationMs = _),

                // animatedClose
                buildBoolSelector('Animated Close', _animatedClose, (_) {
                  if (_animatedClose = _) _customAnimation = false;
                }),

                // animatedCloseDuration
                buildIntSelector(
                    _closingDurationController,
                    'Close Duration (Ms)',
                    (_) => _closingDurationMs = _,
                    !_customAnimation),

                // customAnimation
                buildBoolSelector('Custom Animation', _customAnimation, (_) {
                  if (_customAnimation = _) {
                    _animatedOpen = false;
                    _animatedClose = false;
                    _closingDurationController.text =
                        _customAnimationDurationMs.toString();
                  } else {
                    _closingDurationController.text =
                        _closingDurationMs.toString();
                  }
                }),

                // requiredHeight
                buildIntSelector(_requiredUnderHeightController,
                    'Required Under Height', (_) => _requiredUnderHeight = _),

                // popup width
                buildIntSelector(_popupWidthController, 'Popup Width',
                    (_) => _popupWidth = _),

                // popup height
                buildIntSelector(_popupHeightController, 'Popup Height',
                    (_) => _popupHeight = _),

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
                      onPressed: Combo.close),
                )
              ]),
            ),

            // combos
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                  key: UniqueKey(),
                  crossAxisAlignment: _comboAlignment,
                  children: [
                    // space
                    SizedBox(
                        key: ValueKey(_spaceAbove),
                        height: _spaceAbove.toDouble()),

                    Combo(
                      key: _comboKey,
                      popupWidthConstraints: _widthConstraints,
                      overlap: _overlap,
                      showAbove: _showAbove,
                      popupAutoClose: _popupAutoClose,
                      animatedOpen: _animatedOpen,
                      openingAnimationDuration:
                          Duration(milliseconds: _openingDurationMs),
                      animatedClose: _animatedClose,
                      closingAnimationDuration: Duration(
                          milliseconds: _customAnimation
                              ? _customAnimationDurationMs
                              : _closingDurationMs),
                      customAnimation: _customAnimation,
                      requiredUnderHeight: _requiredUnderHeight.toDouble(),
                      openedChanged: (isOpened) {
                        if (isOpened) {
                          HoverCombo.blockOpenOnHover();
                        } else {
                          HoverCombo.unblockOpenOnHover();
                          if (_customAnimation) {
                            _popupKey.currentState?.animatedClose();
                          }
                        }
                      },
                      child: Container(
                        width: _comboWidth.toDouble(),
                        height: 48,
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
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: Colors.blueAccent),
                        ),
                        child: Material(
                            borderRadius: BorderRadius.circular(24),
                            color: Colors.transparent,
                            child: InkWell(
                              highlightColor:
                                  Colors.blueAccent.withOpacity(0.1),
                              splashColor: Colors.blueAccent.withOpacity(0.1),
                              hoverColor: Colors.blueAccent.withOpacity(0.1),
                              onTap: () => _comboKey.currentState?.open(),
                              child: Row(
                                children: [
                                  const Expanded(
                                      child: Text('Combo Child',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                              color: Colors.blueAccent))),
                                  const Padding(
                                    padding:
                                        EdgeInsets.symmetric(horizontal: 16),
                                    child: Icon(Icons.arrow_drop_down,
                                        color: Colors.blueAccent),
                                  ),
                                ],
                              ),
                            )),
                      ),
                      popupBuilder: (context, isAbove) => TestPopup(
                          key: _popupKey,
                          isAbove: isAbove,
                          width: _popupWidth.toDouble(),
                          height: _popupHeight.toDouble(),
                          onClose: () => _comboKey.currentState?.close(),
                          animated: _customAnimation,
                          radius: const Radius.circular(24)),
                    ),

                    const SizedBox(height: 16),

                    HoverCombo(
                      key: _hoverComboKey,
                      horizontalBehavior: _widthConstraints,
                      overlap: _overlap,
                      showAbove: _showAbove,
                      animatedOpen: _animatedOpen,
                      openingAnimationDuration:
                          Duration(milliseconds: _openingDurationMs),
                      animatedClose: _animatedClose,
                      closingAnimationDuration: Duration(
                          milliseconds: _customAnimation
                              ? _customAnimationDurationMs
                              : _closingDurationMs),
                      customAnimation: _customAnimation,
                      requiredHeight: _requiredUnderHeight.toDouble(),
                      openedChanged: _customAnimation
                          ? (isOpened) {
                              if (!isOpened) {
                                _hoverPopupKey.currentState?.animatedClose();
                              }
                            }
                          : null,
                      highlightColor: Colors.blueAccent.withOpacity(0.1),
                      splashColor: Colors.blueAccent.withOpacity(0.1),
                      hoverColor: Colors.blueAccent.withOpacity(0.1),
                      onTap: () {
                        final dialog =
                            AlertDialog(content: Text('HoverCombo tapped'));
                        showDialog(context: context, builder: (_) => dialog);
                      },
                      child: Container(
                        width: _comboWidth.toDouble(),
                        height: 48,
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
                          border: Border.all(color: Colors.blueAccent),
                        ),
                        child: Row(
                          children: [
                            const Expanded(
                                child: Text('HoverCombo Child',
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
                      popupBuilder: (context, isAbove) => TestPopup(
                        key: _hoverPopupKey,
                        isAbove: isAbove,
                        width: _popupWidth.toDouble(),
                        height: _popupHeight.toDouble(),
                        onClose: () => _hoverComboKey.currentState?.close(),
                        animated: _customAnimation,
                      ),
                    ),

                    const SizedBox(height: 16),

                    SizedBox(
                      width: _comboWidth.toDouble(),
                      child: Typeahead<String>(
                        getItems: (text) async {
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
                        buildItem: (context, item) =>
                            SizedBox(child: ListTile(title: Text(item))),
                        getItemText: (item) => item,
                        //minTextLength: 0,
                        //popupWidth: _popupWidth.toDouble(),
                        popupMaxHeight: _popupHeight.toDouble(),
                        decoration: InputDecoration(
                          labelText: 'Sample Typeahead',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(4),
                            borderSide: BorderSide(color: Colors.blueAccent),
                          ),
                          labelStyle: TextStyle(color: Colors.blueAccent),
                        ),
                        buildInputDecorator: (context, input) => Theme(
                          data: Theme.of(context)
                              .copyWith(accentColor: Colors.blueAccent),
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(4),
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
                            child: input,
                          ),
                        ),
                        showAbove: _showAbove,
                        popupAutoClose: _popupAutoClose,
                        animatedOpen: _animatedOpen,
                        openingAnimationDuration:
                            Duration(milliseconds: _openingDurationMs),
                        animatedClose: _animatedClose,
                        closingAnimationDuration: Duration(
                            milliseconds: _customAnimation
                                ? _customAnimationDurationMs
                                : _closingDurationMs),
                        customAnimation: _customAnimation,
                        requiredHeight: _requiredUnderHeight.toDouble(),
                        openedChanged: (isOpened) {
                          if (isOpened) {
                            HoverCombo.blockOpenOnHover();
                          } else {
                            HoverCombo.unblockOpenOnHover();
                            if (_customAnimation) {
                              _popupKey.currentState?.animatedClose();
                            }
                          }
                        },
                      ),
                    ),
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
    @required this.isAbove,
    @required this.width,
    @required this.height,
    @required this.onClose,
    @required this.animated,
    this.radius = Radius.zero,
  }) : super(key: key);

  final bool isAbove;
  final double width;
  final double height;
  final VoidCallback onClose;
  final bool animated;
  final Radius radius;

  @override
  _TestPopupState createState() => _TestPopupState(width, height);
}

class _TestPopupState extends State<TestPopup> {
  _TestPopupState(this._width, this._height);

  static const _minHeight = 108.0;

  double _width;
  final double _height;
  final _closeCompleter = Completer<bool>();

  void animatedClose() => _closeCompleter.complete(true);

  @override
  Widget build(BuildContext context) {
    final close = Ink(
      decoration: BoxDecoration(
        color: Colors.blueAccent,
        borderRadius: BorderRadius.only(
          topLeft: !widget.isAbove ? widget.radius : Radius.zero,
          topRight: !widget.isAbove ? widget.radius : Radius.zero,
          bottomLeft: widget.isAbove ? widget.radius : Radius.zero,
          bottomRight: widget.isAbove ? widget.radius : Radius.zero,
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
    final content = const Expanded(
        child: Center(
            child: Text('Combo Popup',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.blueAccent))));

    Widget buildContainer(double height) => Material(
          elevation: 4,
          borderRadius: BorderRadius.all(widget.radius),
          child: AnimatedContainer(
            width: _width,
            height: height,
            duration: const Duration(milliseconds: _customAnimationDurationMs),
            decoration:
                BoxDecoration(borderRadius: BorderRadius.all(widget.radius)),
            child: Column(children: [
              if (widget.isAbove) ...[
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

    return widget.animated
        ? FutureBuilder<bool>(
            initialData: false,
            future: Future.value(true),
            builder: (context, opening) => FutureBuilder<bool>(
                initialData: false,
                future: _closeCompleter.future,
                builder: (context, closing) => buildContainer(
                    !opening.data || closing.data ? _minHeight : _height)))
        : buildContainer(_height);
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
