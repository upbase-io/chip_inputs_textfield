library chip_input_textfield;

import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'chip_editing_controller.dart';
import 'suggestion_box_controller.dart';

typedef InputSuggestions<T> = FutureOr<List<T>> Function(String query);

/// Signature for a function that builds a chip widget.
typedef ChipsBuilder<T> = Widget Function(BuildContext context, ChipInputTextFieldState state,
    String data, TextEditingController controller);
/// Signature for a function that builds a suggestion widget.
typedef SuggestionBuilder<T> = Widget Function(
    BuildContext context, ChipInputTextFieldState state, T data);
/// Signature for a function that validates input string and returns List`<ValidatedData>`
typedef ValidationCallBack<T> = List<ValidatedData> Function(String inputText);

/// A text field that allows users to input chips based on validation provided .
///
/// This widget provides allowing users to enter items and see suggestions as they type.
///
/// Example usage:
///  ChipInputTextField`<ContactInfo>`(
///               onChange: (value) {},
///              focusNode: chipFocusNode,
///               showSuggestions: true,
///              suggestionFinder: (query) {
///              //Process suggestions
///                 return ["Test 1", "Test 2"];
///               },
///               chipBuilder: (context, state, value, controller) {
///                 return InputChip(
///                   key: ObjectKey(value),
///                   label: Text(value),
///                 );
///               },
///               suggestionBuilder: (context, state, data) {
///                 return ListTile(
///                   key: ObjectKey(data),
///               title: Text(data),
///               onTap: () {
///                 state.selectSuggestion(data);
///               },
///             );
///           },
///           validate: (inputText) {
///           if(inputText=="Test 1"){
///             list.add(ValidatedData(value: inputText, canConvertToChip: true));
///             }else{
///             list.add(ValidatedData(value: inputText, canConvertToChip: true));
///             }
///              return list;
///           },
///         ),

class ChipInputTextField<T> extends StatefulWidget {

  /// Default padding for the content of the text field.
 final EdgeInsets defaultContentPadding = EdgeInsets.only(left: 10, top: 8);

 /// Creates a [ChipInputTextField].
  ChipInputTextField({
    Key? key,
    this.showSuggestions = false,
    this.initialValue = const [],
    this.decoration = const InputDecoration(),
    this.enabled = true,
    this.textStyle,
    this.suggestionsBoxMaxHeight,
    this.inputType = TextInputType.emailAddress,
    this.textOverflow = TextOverflow.clip,
    this.obscureText = false,
    this.autocorrect = true,
    this.elevation = 5,
    this.backgroundColor = Colors.white,
    this.borderColor = Colors.blue,
    this.borderWidth = 0.0,
    this.inputAction = TextInputAction.done,
    this.autofocus = false,
    this.allowChipEditing = false,
    this.focusNode,
    this.frequentSuggestions,
    this.maxLines = 5,
    required this.onChange,
    required this.suggestionFinder,
    required this.chipBuilder,
    required this.suggestionBuilder,
    required this.validate,
  }) : super(key: key);

  final int elevation;
  final Color borderColor;
  final double borderWidth;
  final int count = 1;
  final Color backgroundColor;
  final InputDecoration decoration;
  final TextStyle? textStyle;
  final bool enabled;
  final bool showSuggestions;
  final InputSuggestions<T> suggestionFinder;
  final List<T> initialValue;
  final ValueChanged<String>? onChange;
  final ChipsBuilder<T> chipBuilder;
  final SuggestionBuilder<T> suggestionBuilder;
  final double? suggestionsBoxMaxHeight;
  final TextInputType inputType;
  final TextOverflow textOverflow;
  final bool obscureText;
  final bool autocorrect;
  final TextInputAction inputAction;
  final bool autofocus;
  final bool allowChipEditing;
  final FocusNode? focusNode;
  final List<T>? frequentSuggestions;
  final ValidationCallBack<T> validate;
  final int maxLines;

  @override
  ChipInputTextFieldState createState() => ChipInputTextFieldState<T>();
}

class ChipInputTextFieldState<T> extends State<ChipInputTextField<T>> {
  late ChipTextController textEditingController;

  ValueNotifier<List<T>> _suggestions = ValueNotifier([]);
  final _suggestionsStreamController = StreamController<List>.broadcast();
  int _searchId = 0;
  late SuggestionsBoxController _suggestionsBoxController;
  final _layerLink = LayerLink();
  late FocusNode _focusNode;
  late FocusAttachment _nodeAttachment;

  ///RenderBox object is used to position the suggestion box
  RenderBox get renderBox => context.findRenderObject() as RenderBox;

  /// Resets the text controller.
  void resetTextController() {
    textEditingController.text = "";
  }

  @override
  void initState() {
    super.initState();

    textEditingController = ChipTextController(widget.chipBuilder, this, validate: widget.validate);

    String initialtext =
        widget.initialValue.isNotEmpty ? (widget.initialValue.join(",") + " ") : "";

    textEditingController.text = "";
    textEditingController.selection =
        TextSelection(baseOffset: initialtext.length, extentOffset: 0);

    _suggestionsBoxController = SuggestionsBoxController(context);

    _focusNode = widget.focusNode ?? FocusNode();
    _focusNode.addListener(_handleFocusChanged);
    _nodeAttachment = _focusNode.attach(context);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      _showOverLay();
      if (mounted && widget.autofocus) {
        FocusScope.of(context).autofocus(_focusNode);
      }
    });
  }

  @override
  void dispose() {
    _suggestionsStreamController.close();
    _suggestionsBoxController.close();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
  }

  /// To show suggestion box as a overlay.
  void _showOverLay() {
    _suggestionsBoxController.overlayEntry = OverlayEntry(
      builder: (context) {
        final size = renderBox.size;
        final renderBoxOffset = renderBox.localToGlobal(Offset.zero);
        final topAvailableSpace = renderBoxOffset.dy;
        final mq = MediaQuery.of(context);
        final bottomAvailableSpace =
            mq.size.height - mq.viewInsets.bottom - renderBoxOffset.dy - size.height;
        var _suggestionBoxHeight = max(topAvailableSpace, bottomAvailableSpace);
        if (null != widget.suggestionsBoxMaxHeight) {
          _suggestionBoxHeight = min(_suggestionBoxHeight, widget.suggestionsBoxMaxHeight!);
        }
        final showTop = topAvailableSpace > bottomAvailableSpace;

        final compositedTransformFollowerOffset = showTop ? Offset(0, -size.height) : Offset.zero;

        return ValueListenableBuilder(
            valueListenable: _suggestions,
            builder: (context, value, child) {
              return StreamBuilder<List>(
                stream: _suggestionsStreamController.stream,
                initialData: _suggestions.value,
                builder: (context, snapshot) {
                  if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                    final suggestionsListView = Material(
                      elevation: 0,
                      child: Card(
                        elevation: 5,
                        child: Container(
                            constraints: BoxConstraints(
                              maxHeight: _suggestionBoxHeight,
                            ),
                            decoration: BoxDecoration(
                                color: widget.backgroundColor,
                                border: Border.all(
                                    color: widget.borderColor, width: widget.borderWidth)),
                            child: ListView.builder(
                              shrinkWrap: true,
                              padding: EdgeInsets.zero,
                              itemCount: snapshot.data!.length,
                              itemBuilder: (BuildContext context, int index) {
                                return widget.suggestionBuilder(
                                  context,
                                  this,
                                  _suggestions.value[index],
                                );
                              },
                            )),
                      ),
                    );
                    return Positioned(
                      width: size.width,
                      child: CompositedTransformFollower(
                        link: _layerLink,
                        showWhenUnlinked: false,
                        offset: compositedTransformFollowerOffset,
                        child: !showTop
                            ? suggestionsListView
                            : FractionalTranslation(
                                translation: const Offset(0, -1),
                                child: suggestionsListView,
                              ),
                      ),
                    );
                  }
                  return Container();
                },
              );
            });
      },
    );
  }

  ///Suggestion will only be displayed if the textField has focus
  void _handleFocusChanged() {
    if (_focusNode.hasFocus) {
      _suggestionsBoxController.open();
    } else {
      _suggestionsBoxController.close();
    }
  }
  ///on tapping a item on the suggestions textEditingController will be updated with the string
  void selectSuggestion(T data) {
    _suggestions.value = [];
    _suggestionsStreamController.add([]);
    if (textEditingController.text.contains(" ")) {
      textEditingController.text =
          textEditingController.text.substring(0, textEditingController.text.lastIndexOf(" "));
    } else {
      textEditingController.text = "";
    }

    textEditingController.text = textEditingController.text + " " + data.toString() + " ";
    textEditingController.selection = TextSelection(
        baseOffset: textEditingController.text.length,
        extentOffset: textEditingController.text.length);
    setState(() {});
  }
  ///to Handle chip deletion while tapping on the close button
  void deleteZTChip(String deletedValue, TextEditingController controller) {
    if (widget.enabled) {
      textEditingController.convertedText = textEditingController.convertedText
          .replaceAll("$deletedValue", "")
          .trim(); //to remove the extra spacing we give for the last chip
      ///trim() applied to remove the extra spacing we give for the last chip
      textEditingController.value = TextEditingValue(
          text: controller.text.replaceAll("$deletedValue", ""),
          selection: TextSelection(
              baseOffset: ((textEditingController.text.length - 1) - deletedValue.length),
              extentOffset: ((textEditingController.text.length - 1) - deletedValue.length)));
    }
  }

  void _onSearchUpdate(String value) async {
    final localId = ++_searchId;
    final results = await widget.suggestionFinder(value.trim());
    _suggestions.value = [];

    if (_searchId == localId && mounted && textEditingController.text.trim().length > 0) {
      _suggestions.value = results
          .where((r) => !textEditingController.text.contains(r.toString()))
          .cast<T>()
          .toList(growable: false);
    }

    _suggestionsStreamController.add(_suggestions.value);
  }

  @override
  Widget build(BuildContext context) {
    _nodeAttachment.reparent();
    final theme = Theme.of(context);

    return NotificationListener<SizeChangedLayoutNotification>(
      onNotification: (SizeChangedLayoutNotification val) {
        WidgetsBinding.instance.addPostFrameCallback((_) async {
          _suggestionsBoxController.overlayEntry?.markNeedsBuild();
        });
        return true;
      },
      child: SizeChangedLayoutNotifier(
          child: Column(
        children: <Widget>[
          ConstrainedBox(
            constraints: BoxConstraints(minHeight: 48, maxHeight: 144),
            child: Stack(
              children: [
                TextField(
                  focusNode: _focusNode,
                  minLines: 1,
                  maxLines: widget.maxLines,
                  style: widget.textStyle ?? theme.textTheme.bodyLarge!.copyWith(height: 2.5),
                  controller: textEditingController,
                  keyboardType: widget.inputType,
                  textAlignVertical: TextAlignVertical.center,
                  cursorHeight: 24,
                  selectionControls: CustomMaterialTextSelectionControl(onPaste: (value) async {
                    final ClipboardData? data = await Clipboard.getData(Clipboard.kTextPlain);
                    String clipboardText = data!.text!;
                    textEditingController.text =
                        textEditingController.text + " " + clipboardText + " ";
                    textEditingController.selection = TextSelection(
                        baseOffset: textEditingController.text.length,
                        extentOffset: textEditingController.text.length);
                  }),
                  decoration: widget.decoration.copyWith(
                    contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  ),
                  onChanged: (value) {
                    if (value.contains("  ")) {
                      value = value.replaceAll("  ", " ");
                      textEditingController.text = value;
                      textEditingController.selection = TextSelection(
                          baseOffset: textEditingController.text.length,
                          extentOffset: textEditingController.text.length);
                    }
                    String latestString;
                    if (value.contains(" ")) {
                      latestString = value.substring(value.lastIndexOf(" "), value.length);
                    } else {
                      latestString = value;
                    }
                    _onSearchUpdate(latestString);
                    widget.onChange!(value);
                  },
                  onEditingComplete: () {
                    if (!textEditingController.text.endsWith(" ") ||
                        !textEditingController.text.endsWith(",")) {
                      textEditingController.text = textEditingController.text + " ";
                    }
                    FocusManager.instance.primaryFocus?.unfocus();
                  },
                ),
              ],
            ),
          ),
          CompositedTransformTarget(
            link: _layerLink,
            child: Container(),
          ),
        ],
      )),
    );
  }
}

class CustomMaterialTextSelectionControl extends MaterialTextSelectionControls {
  ValueChanged<TextSelectionDelegate> onPaste;

  CustomMaterialTextSelectionControl({
    required this.onPaste,
  });

  @override
  Future<void> handlePaste(final TextSelectionDelegate delegate) async {
    delegate.hideToolbar();
    onPaste(delegate);
  }
}
