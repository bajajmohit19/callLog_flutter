import 'package:crm/screens/splash.dart';
import 'package:flutter/material.dart';
import 'package:crm/providers/core_provider.dart';
import 'package:crm/util/consts.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:loading_overlay/loading_overlay.dart';
import 'package:page_transition/page_transition.dart';

class UserObj {
  String user_id;
  String mobileNo;
  String token;
  String recordingPath;

  UserObj({this.user_id, this.mobileNo, this.token, this.recordingPath});

  toJSONEncodable() {
    Map<String, dynamic> m = new Map();
    m['user_id'] = user_id;
    m['mobileNo'] = mobileNo;
    m['token'] = token;
    m['recordingPath'] = recordingPath;
    return jsonEncode(m);
  }
}

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
          isLoading: coreProvider.syncGlobalLoader,
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

  Future<dynamic> getOPT(String mobileNo) async {
    // var url = 'https://www.googleapis.com/books/v1/volumes?q={http}';

    // Await the http get response, then decode the json-formatted response.
    Provider.of<CoreProvider>(context, listen: false).setGlobalLoading(true);
    var body = jsonEncode({'mobile': mobileNo});
    var response = await http.post(
        new Uri.https(Constants.apiUrl, "/loginWithOtp"),
        body: body,
        headers: {"Content-Type": "application/json"});

    Provider.of<CoreProvider>(context, listen: false).setGlobalLoading(false);

    if (response.statusCode == 200) {
      var jsonResponse = jsonDecode(response.body);
      if (jsonResponse['error'] == false) {
        return true;
      }
      Fluttertoast.showToast(msg: jsonResponse['message']);
      return false;
    } else {
      Fluttertoast.showToast(msg: 'Something went wrong.');
      return false;
    }
  }

  Future<dynamic> verifyOPT(String mobileNo, String otp) async {
    // var url = 'https://www.googleapis.com/books/v1/volumes?q={http}';

    // Await the http get response, then decode the json-formatted response.
    Provider.of<CoreProvider>(context, listen: false).setGlobalLoading(true);
    var body = jsonEncode({'mobile': mobileNo, 'otp': otp});
    var response = await http.post(
        new Uri.https(Constants.apiUrl, "/verifyOtp"),
        body: body,
        headers: {"Content-Type": "application/json"});

    Provider.of<CoreProvider>(context, listen: false).setGlobalLoading(false);

    if (response.statusCode == 200) {
      var jsonResponse = jsonDecode(response.body);
      if (jsonResponse['error'] == false) {
        final prefs = await SharedPreferences.getInstance();
        UserObj user = UserObj()
          ..mobileNo = jsonResponse['user']['mobile']
          ..token = jsonResponse['token']
          ..user_id = jsonResponse['user']['_id']
          ..recordingPath = jsonResponse['user']['recordingPath'];
        prefs.setString('currentUser', user.toJSONEncodable());
        Navigator.pushReplacement(
          context,
          PageTransition(
            type: PageTransitionType.rightToLeft,
            child: Splash(),
          ),
        );
        return;
      }
      Fluttertoast.showToast(msg: 'Invalid OTP');
      return false;
    } else {
      Fluttertoast.showToast(msg: 'Invalid OTP');
      return false;
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
              enabled: !otpSend,
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
                child: new Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: <Widget>[
                      //Padding between these please
                      Padding(
                        padding: EdgeInsets.only(right: 10),
                        child: RaisedButton(
                          color: Colors.blue,
                          textColor: Colors.white,
                          onPressed: () async {
                            // Validate will return true if the form is valid, or false if
                            // the form is invalid.
                            if (_formKey.currentState.validate()) {
                              // Process data.

                              _formKey.currentState.save();

                              // print(mobileNo + " This is mobile numebr ");
                              if (otpSend == true) {
                                await verifyOPT(mobileNo, otp);
                              } else {
                                bool resp = await getOPT(mobileNo);
                                if (resp == true) {
                                  setState(() {
                                    otpSend = true;
                                  });
                                }
                              }

                              // Scaffold.of(context).showSnackBar(
                              // SnackBar(content: Text('Processing Data')));
                            }
                          },
                          child: Text('Submit'),
                        ),
                      ),
                      Visibility(
                        visible: otpSend,
                        child: RaisedButton(
                          color: Colors.blue,
                          textColor: Colors.white,
                          onPressed: () async {
                            setState(() {
                              otpSend = false;
                            });
                          },
                          child: Text('Change Mobile No.'),
                        ),
                      )
                    ])),
            // Visibility(
            //   visible: otpSend,
            //   child:
            // ),
          ],
        ),
      ),
    );
  }
}
