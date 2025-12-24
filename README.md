ChipInputTextField is a TextField widget which is used to convert the give input to a Chip based on
the validation provided.
User must return a List`<ValidatedData>` from the Validate function. ValidatedData contains the value
and meta data that denotes chip can be created with the item or the item must be a String.
The chip can be customized based on the user needs.

This component also help with custom suggestionBuilder based on the last input.

| Attributes        | Input                                                                  | Description                                                             |
|-------------------|------------------------------------------------------------------------|-------------------------------------------------------------------------|
| validate          | (inputText) {// return list of ValidatedData based on the requirement} | The returned list will be iterated and renders chip for the valid items |
| chipBuilder       | (context, state, value, controller) { //return a Chip Widget }         | Used to build a custom chip UI                                          |
| suggestionFinder  | (query) {//return a List of required data}                             | Used to provide suggestions based on the latest input                   |
| suggestionBuilder | (context, state, data){ // return widgets to show suggestions}         | Used to build a custom UI for suggestions                               |

