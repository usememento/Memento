import 'package:flutter/material.dart';

import '../components/appbar.dart';

class UnknownRoutePage extends StatelessWidget {
  const UnknownRoutePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if(Navigator.of(context).canPop())
          const Appbar(
            title: "Not Found",
          ),
        const Expanded(child: Center(
          child: Text("Not Found"),
        ),)
      ],
    );
  }
}
