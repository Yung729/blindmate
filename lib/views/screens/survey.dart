import 'package:flutter/material.dart';

class SurveyPage extends StatefulWidget {
  @override
  _SurveyPageState createState() => _SurveyPageState();
}

class _SurveyPageState extends State<SurveyPage> {
  final _formKey = GlobalKey<FormState>();
  String? name;
  String? selectedOption;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Survey Form')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Text("1. What is your name?"),
              // TextFormField(
              //   onSaved: (value) => name = value,
              //   validator: (value) => value == null || value.isEmpty ? 'Required' : null,
              // ),
              // SizedBox(height: 20),
              Text("1. How are you feeling this week?"),
              RadioListTile<String>(
                title: Text("Very Satisfied"),
                value: "Very Satisfied",
                groupValue: selectedOption,
                onChanged: (value) => setState(() => selectedOption = value),
              ),
              RadioListTile<String>(
                title: Text("Satisfied"),
                value: "Satisfied",
                groupValue: selectedOption,
                onChanged: (value) => setState(() => selectedOption = value),
              ),
              RadioListTile<String>(
                title: Text("Unsatisfied"),
                value: "Unsatisfied",
                groupValue: selectedOption,
                onChanged: (value) => setState(() => selectedOption = value),
              ),
              SizedBox(height: 20),
              Center(
                child: ElevatedButton(
                  onPressed: () {
                    if (_formKey.currentState?.validate() ?? false) {
                      _formKey.currentState?.save();
                      // TODO: Submit to backend or process results
                      showDialog(
                        context: context,
                        builder: (_) => AlertDialog(
                          title: Text('Thank you!'),
                          content: Text('Survey submitted successfully.'),
                        ),
                      );
                    }
                  },
                  child: Text('Submit'),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
