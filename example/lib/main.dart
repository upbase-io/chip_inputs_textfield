import 'package:chip_inputs_textfield/chip_editing_controller.dart';
import 'package:chip_inputs_textfield/chip_input_textfield.dart';
import 'package:flutter/material.dart';


void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  List usersList = [];
  final emailRegex = RegExp(
      r'^(([^<>()[\]\\.,;:\s@\"]+(\.[^<>()[\]\\.,;:\s@\"]+)*)|(\".+\"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$');
  FocusNode chipFocusNode = FocusNode();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Chip input Textfield')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            ChipInputTextField<ContactInfo>(
              onChange: (value) {},
              focusNode: chipFocusNode,
              showSuggestions: true,
              suggestionFinder: (query) {
                return <ContactInfo>[ContactInfo(email: "test@zylker.com", name: "test", id: 100)];
              },
              chipBuilder: (context, state, value, controller) {
                ContactInfo data = ContactInfo(email: value, name: value.split("@").first, id: -1);
                return InputChip(
                  key: ObjectKey(data),
                  label: Text(data.name),
                  avatar: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(borderRadius: BorderRadius.circular(12)),
                    child: const Icon(Icons.account_circle),
                  ),
                  onDeleted: () {
                    state.deleteZTChip(data.email, controller);
                    usersList[0].emails.remove(data.email);
                  },
                  // materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                );
              },
              suggestionBuilder: (context, state, data) {
                return ListTile(
                  key: ObjectKey(data),
                  leading: const CircleAvatar(
                      backgroundColor: Colors.white,
                      child: CircleAvatar(child: Icon(Icons.account_circle))),
                  title: Text(data.name),
                  subtitle: Text(data.email),
                  onTap: () {
                    state.selectSuggestion(data);
                  },
                );
              },
              validate: (inputText) {
                String? inValidEmail, validEmail;
                List<ValidatedData> list = [];
                String emailString = inputText.replaceAll(",", " ");
                if (emailString.contains(" ")) {
                  validEmail = emailString.substring(0, emailString.lastIndexOf(" "));
                  inValidEmail =
                      emailString.substring(emailString.lastIndexOf(" "), emailString.length);
                } else {
                  inValidEmail = emailString;
                }
                if (validEmail != null) {
                  List<String> emailList = validEmail.split(" ");
                  for (var email in emailList) {
                    var emailValid = emailRegex.hasMatch(email);

                    if (emailValid) {
                      list.add(ValidatedData(value: email, canConvertToChip: true));
                    } else {
                      list.add(ValidatedData(value: email, canConvertToChip: false));
                    }
                  }
                }
                list.add(ValidatedData(value: inValidEmail, canConvertToChip: false));
                              return list;
              },
            ),
          ],
        ),
      ),
    );
  }
}
class ContactInfo {
  late String email, name;
  late int id;
  ContactInfo({this.email = "", this.name = "", this.id = -1});

  @override
  String toString() {
    return email;
  }
}