import 'package:flutter/material.dart';
import 'package:crm/providers/core_provider.dart';
import 'package:crm/util/consts.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:loading_overlay/loading_overlay.dart';

class Login extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<CoreProvider>(
      builder: (BuildContext context, CoreProvider coreProvider, Widget child) {
        return LoadingOverlay(
          child: Scaffold(
              appBar: AppBar(
                centerTitle: true,
                backgroundColor: Theme.of(context).primaryColor,
                title: Text(
                  "Login - ${Constants.appName}",
                  style: TextStyle(
                    fontSize: 25,
                  ),
                ),
              ),
              body: MyStatefulWidget()),
          isLoading: coreProvider.globalLoader,
        );
      },
    );
  }
}

class MyStatefulWidget extends StatefulWidget {
  MyStatefulWidget({Key key}) : super(key: key);

  @override
  _MyStatefulWidgetState createState() => _MyStatefulWidgetState();
}

class _MyStatefulWidgetState extends State<MyStatefulWidget> {
  final _formKey = GlobalKey<FormState>();

  bool otpSend = false;
  String mobileNo = "";
  String otp = "";

  Future<Map> getOPT(String mobileNo) async {
    var url = 'https://www.googleapis.com/books/v1/volumes?q={http}';

    // Await the http get response, then decode the json-formatted response.
    Provider.of<CoreProvider>(context, listen: false).setGlobalLoading(true);

    var response = await http.get(url);

    Provider.of<CoreProvider>(context, listen: false).setGlobalLoading(false);

    if (response.statusCode == 200) {
      var jsonResponse = jsonDecode(response.body);
      var itemCount = jsonResponse['totalItems'];
      Map parse = jsonResponse;
      print('Number of books about http: $itemCount.');
      return parse;
    } else {
      Map test = {};
      print('Request failed with status: ${response.statusCode}.');
      return test;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Center(
              child: Image.asset('assets/customer-relationship-management.png',
                  height: 150, fit: BoxFit.fill),
            ),
            SizedBox(height: 20.0),
            TextFormField(
              textInputAction: TextInputAction.next,
              autofocus: true,
              onSaved: (String value) {
                mobileNo = value;
              },
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                hintText: '10 Digit Mobile No',
                labelText: "Mobile No",
              ),
              validator: (value) {
                if (value.isEmpty || value.length != 10) {
                  return 'Please enter 10 digit mobile number';
                }
                return null;
              },
            ),
            Visibility(
              visible: otpSend,
              child: TextFormField(
                onSaved: (String value) {
                  otp = value;
                },
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  hintText: 'Enter OTP Number',
                  labelText: "OTP",
                ),
                validator: (value) {
                  if (value.isEmpty) {
                    return 'Please enter otp';
                  }
                  return null;
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              child: RaisedButton(
                color: Colors.blue,
                textColor: Colors.white,
                onPressed: () async {
                  // Validate will return true if the form is valid, or false if
                  // the form is invalid.
                  if (_formKey.currentState.validate()) {
                    // Process data.

                    _formKey.currentState.save();

                    print(mobileNo + " This is mobile numebr ");

                    Map jsonResponse = await getOPT(mobileNo);

                    setState(() {
                      otpSend = true;
                    });

                    Scaffold.of(context).showSnackBar(
                        SnackBar(content: Text('Processing Data')));
                  }
                },
                child: Text('Submit'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
