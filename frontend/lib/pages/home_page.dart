import 'package:flutter/material.dart';
// import 'package:frontend/foundation/widget_utils.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Center(
            child: Container(
      constraints: const BoxConstraints(maxWidth: 275 + 620 + 400),
      child: Row(
        children: [
          mainMenu(),
          Container(
            color: Colors.orange,
            width: 620,
            child: Stack(
              children: [
                Container(
                    color: Colors.orange,
                    child: ListView(
                      children: [
                        Column(children: getContent()),
                      ],
                    )),
                Container(
                  color: Colors.purple,
                  height: 55,
                )
              ],
            ),
          ),
          Container(
            color: Colors.green,
            width: 400,
          ),
        ],
      ),
    )));
  }
}

Container mainMenu() {
  return Container(
    color: Colors.yellow,
    width: 275,
    alignment: Alignment.topLeft,
    child: Column(
      children: [
        Container(
          height: 50,
          width: 50,
          color: Colors.black,
        ),
        mainMenuItem("Home"),
        mainMenuItem("Explore"),
        mainMenuItem("Notification"),
        mainMenuItem("Messages"),
        mainMenuItem("Grok"),
        mainMenuItem("List"),
        mainMenuItem("Bookmark"),
        mainMenuItem("More"),
        mainMenuPostButton(),
        const Spacer(),
        mainMenuProfile()
      ],
    ),
  );
}

InkWell mainMenuPostButton() {
  return InkWell(
    onTap: () {
      print("post button clicked");
    },
    onHover: (hovering) {
      // print('hovering');
    },
    child: Container(
        margin: const EdgeInsets.fromLTRB(15, 30, 15, 0),
        width: 350,
        height: 50,
        decoration: const BoxDecoration(
            color: Colors.blue,
            borderRadius: BorderRadius.all(Radius.circular(30))),
        child: const Center(
            child: Text("Post",
                style: TextStyle(fontSize: 20, color: Colors.white)))),
  );
}

InkWell mainMenuItem(String text) {
  return InkWell(
      onTap: () {
        print("main menu $text clicked");
      },
      child: Container(
        decoration: const BoxDecoration(
            color: Colors.grey,
            borderRadius: BorderRadius.all(Radius.circular(30))),
        height: 50,
        width: 250,
        margin: const EdgeInsets.fromLTRB(0, 5, 0, 5),
        child: Row(
          children: [
            Container(
              height: 25,
              width: 25,
              color: Colors.pink,
              margin: const EdgeInsets.fromLTRB(30, 0, 15, 0),
            ),
            Text(text)
          ],
        ),
      ));
}

Container mainMenuProfile() {
  return Container(
    decoration: const BoxDecoration(
      color: Colors.grey,
      borderRadius: BorderRadius.all(Radius.circular(30))
    ),
    height: 60,
    margin: const EdgeInsets.fromLTRB(20, 0, 10, 5),
    child: InkWell(
      onTap: () {
        print("main menu profile clicked");
      },
      child: Container(
          child: Row(
            children: [
              Container(
                height: 40,
                width: 40,
                decoration: const BoxDecoration(
                    color: Colors.blue,
                    borderRadius: BorderRadius.all(Radius.circular(20))
                ),
                margin: const EdgeInsets.fromLTRB(10, 0, 0, 0),
              ),
              Container(
                margin: const EdgeInsets.fromLTRB(10, 7, 0, 0),
                child:
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [Text("usernicknameeeeeeeee"), Text("@username")],
                ),
              ),
              const Spacer(),
              Container(
                margin: const EdgeInsets.fromLTRB(0, 0, 20, 0),
                child: const Text("..."),

              )
            ],
          )),
    ),
  );
}

List<Container> getContent() {
  List<Container> ret = [];
  for (var i = 0; i < 10; i++) {
    ret.add(Container(
      height: 400,
      decoration: const BoxDecoration(
          border: Border(
              top: BorderSide(),
              left: BorderSide(),
              right: BorderSide(),
              bottom: BorderSide())),
    ));
  }
  return ret;
}
