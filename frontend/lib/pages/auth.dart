import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:frontend/components/button.dart';
import 'package:frontend/foundation/app.dart';
import 'package:frontend/network/network.dart';
import 'package:frontend/utils/translation.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  String username = '';

  String password = '';

  var domainController =
      TextEditingController(text: appdata.settings['domain']);

  bool isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 400,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      decoration: BoxDecoration(
        color: context.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: context.colorScheme.outlineVariant,
            offset: const Offset(0, 1),
            blurRadius: 4,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text("Log in".tl,
              style:
                  const TextStyle(fontWeight: FontWeight.bold, fontSize: 26)),
          const SizedBox(height: 12),
          if (!App.isWeb)
            buildTextField("Domain".tl, (value) {
              appdata.settings['domain'] = value;
            }, Icons.language, domainController),
          buildTextField("Username".tl, (value) {
            username = value;
          }, Icons.person),
          buildTextField("Password".tl, (value) {
            password = value;
          }, Icons.lock),
          const SizedBox(height: 12),
          Button.filled(
              isLoading: isLoading,
              onPressed: login,
              width: double.infinity,
              height: 38,
              child: Text("Continue".tl).toCenter()),
          Text.rich(
            TextSpan(
              text: "No account? ".tl,
              children: [
                TextSpan(
                  text: "Register".tl,
                  style: TextStyle(color: context.colorScheme.primary),
                  recognizer: TapGestureRecognizer()
                    ..onTap = () {
                      context.toAndRemoveAll('/register');
                    },
                )
              ],
            ),
          ).paddingTop(8).paddingBottom(4),
          Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: "Continue with no account".tl,
                  style: TextStyle(color: context.colorScheme.primary),
                  recognizer: TapGestureRecognizer()
                    ..onTap = () {
                      context.toAndRemoveAll('/');
                    },
                )
              ],
            ),
          ).paddingVertical(8),
        ],
      ),
    ).toCenter().withSurface(context.colorScheme.surfaceContainer);
  }

  Widget buildTextField(
      String hintText, void Function(String) onChanged, IconData icon,
      [TextEditingController? controller]) {
    return TextField(
      onChanged: onChanged,
      controller: controller,
      obscureText: hintText == "Password".tl,
      decoration: InputDecoration(
        labelText: hintText,
        border: const OutlineInputBorder(),
        prefixIcon: Icon(icon),
      ),
      onSubmitted: (_) {
        login();
      },
    ).paddingVertical(8);
  }

  void login() async {
    setState(() {
      isLoading = true;
    });
    var res = await Network().login(username, password);
    if (mounted) {
      if (res.error) {
        context.showMessage(res.message);
        setState(() {
          isLoading = false;
        });
      } else {
        appdata.user = res.data;
        App.initialRoute = '/';
        context.toAndRemoveAll('/');
      }
    }
  }
}

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  String username = '';

  String password = '';

  bool isLoading = false;

  var domainController =
      TextEditingController(text: appdata.settings['domain']);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 400,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      decoration: BoxDecoration(
        color: context.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: context.colorScheme.outlineVariant,
            offset: const Offset(0, 1),
            blurRadius: 4,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text("Register".tl,
              style:
                  const TextStyle(fontWeight: FontWeight.bold, fontSize: 26)),
          const SizedBox(height: 12),
          if (!App.isWeb)
            buildTextField("Domain".tl, (value) {
              appdata.settings['domain'] = value;
            }, Icons.language, domainController),
          buildTextField("Username".tl, (value) {
            username = value;
          }, Icons.person),
          buildTextField("Password".tl, (value) {
            password = value;
          }, Icons.lock),
          const SizedBox(height: 12),
          Button.filled(
              isLoading: isLoading,
              onPressed: register,
              width: double.infinity,
              height: 38,
              child: Text("Continue".tl).toCenter().expanded()),
          Text.rich(
            TextSpan(
              text: "Already have an account? ".tl,
              children: [
                TextSpan(
                  text: "log in".tl,
                  style: TextStyle(color: context.colorScheme.primary),
                  recognizer: TapGestureRecognizer()
                    ..onTap = () {
                      context.toAndRemoveAll('/login');
                    },
                )
              ],
            ),
          ).paddingVertical(8),
        ],
      ),
    ).toCenter().withSurface(context.colorScheme.surfaceContainer);
  }

  Widget buildTextField(
      String hintText, void Function(String) onChanged, IconData icon,
      [TextEditingController? controller]) {
    return TextField(
      onChanged: onChanged,
      controller: controller,
      obscureText: hintText == "Password".tl,
      onSubmitted: (_) {
        register();
      },
      decoration: InputDecoration(
        labelText: hintText,
        border: const OutlineInputBorder(),
        prefixIcon: Icon(icon),
      ),
    ).paddingVertical(8);
  }

  void register() async {
    setState(() {
      isLoading = true;
    });
    var res = await Network().register(username, password);
    if (mounted) {
      if (res.error) {
        context.showMessage(res.message);
        setState(() {
          isLoading = false;
        });
      } else {
        appdata.user = res.data;
        App.initialRoute = '/';
        context.toAndRemoveAll('/');
      }
    }
  }
}
