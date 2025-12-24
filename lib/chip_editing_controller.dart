import 'package:flutter/material.dart';
import 'chip_input_textfield.dart';

/// ChipTextController is a custom [TextEditingController] designed for use with chip_input_textfield.
///
/// This controller manages the text input and converts valid segments into chips.
/// It also handles cursor positioning and ensures that the cursor stays within the editable text area.
class ChipTextController extends TextEditingController {

  /// The raw text input.
  String pureText = '';

  ///The text that has been converted into chips and plain text segments.
  String convertedText = "";

  ///A function that builds chip widgets.
  Function chipBuilder;

  /// maintain ChipInputTextField state
  State state;

  ///A validation callback function to determine if text segments can be converted to chips.
  ValidationCallBack validate;

  ChipTextController(
    this.chipBuilder,
    this.state, {
    required this.validate,
  }) {
    addListener(() {
      if (value.selection.base.offset >= convertedText.length) {
        return;
      } else {
        if (value.text.length > convertedText.length) {
          selection =
              TextSelection(baseOffset: convertedText.length, extentOffset: convertedText.length);
        } else {
          selection = TextSelection(baseOffset: value.text.length, extentOffset: value.text.length);
        }
      }
    });
  }

  @override
  TextSpan buildTextSpan({required context, TextStyle? style, required bool withComposing}) {
    convertedText = "";
    pureText = value.text;
    final List<InlineSpan> children = [];
    int charCount = 0;
    List<ValidatedData> validatedDataList = validate(value.text);
    for (var data in validatedDataList) {
      if (data.canConvertToChip) {
        charCount++;
        children.add(TextSpan(style: style!.merge(TextStyle(color: Colors.black)), children: [
          WidgetSpan(
              baseline: TextBaseline.ideographic,
              alignment: PlaceholderAlignment.middle,
              child: Container(
                child: chipBuilder(context, state, data.value, this),
              )),
        ]));
      } else {
        charCount = charCount + data.value.length;
        children.add(TextSpan(text: data.value, style: style));
      }
    }
    return TextSpan(
        text: value.text.substring(0, value.text.length - (charCount)),
        style: TextStyle(color: Colors.transparent, fontSize: 0),
        children: children);
  }
}

/// Represents a segment of text input and whether it can be converted to a chip.
///
/// The value is the text segment, and canConvertToChip indicates whether it can be converted.

class ValidatedData {
  String value;
  bool canConvertToChip;

  ValidatedData({required this.value, required this.canConvertToChip});
}
