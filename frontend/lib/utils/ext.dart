import 'package:frontend/utils/translation.dart';

extension ListExt<T> on List<T>{
  /// Remove all blank value and return the list.
  List<T> getNoBlankList(){
    List<T> newList = [];
    for(var value in this){
      if(value.toString() != ""){
        newList.add(value);
      }
    }
    return newList;
  }

  T? firstWhereOrNull(bool Function(T element) test){
    for(var element in this){
      if(test(element)){
        return element;
      }
    }
    return null;
  }

  void addIfNotNull(T? value){
    if(value != null){
      add(value);
    }
  }
}

extension StringExt on String{
  ///Remove all value that would display blank on the screen.
  String get removeAllBlank => replaceAll("\n", "").replaceAll(" ", "").replaceAll("\t", "");

  /// convert this to a one-element list.
  List<String> toList() => [this];

  String _nums(){
    String res = "";
    for(int i=0; i<length; i++){
      res += this[i].isNum?this[i]:"";
    }
    return res;
  }

  String get nums => _nums();

  String setValueAt(String value, int index){
    return replaceRange(index, index+1, value);
  }

  String? subStringOrNull(int start, [int? end]){
    if(start < 0 || (end != null && end > length)){
      return null;
    }
    return substring(start, end);
  }

  String replaceLast(String from, String to) {
    if (isEmpty || from.isEmpty) {
      return this;
    }

    final lastIndex = lastIndexOf(from);
    if (lastIndex == -1) {
      return this;
    }

    final before = substring(0, lastIndex);
    final after = substring(lastIndex + from.length);
    return '$before$to$after';
  }

  static bool hasMatch(String? value, String pattern) {
    return (value == null) ? false : RegExp(pattern).hasMatch(value);
  }

  bool _isURL(){
    final regex = RegExp(
        r'^((http|https|ftp)://)?[\w-]+(\.[\w-]+)+([\w.,@?^=%&:/~+#-|]*[\w@?^=%&/~+#-])?$',
        caseSensitive: false);
    return regex.hasMatch(this);
  }

  bool get isURL => _isURL();

  bool get isNum => double.tryParse(this) != null;

  String limitLine(int line){
    if(line <= 0){
      return "";
    }
    var lines = split("\n");
    if(lines.length <= line){
      return this;
    }
    return lines.sublist(0, line).join("\n");
  }
}

extension TimeExt on DateTime {
  String toCompareString(){
    var now = DateTime.now();
    var offset = now.difference(this);
    if(offset > const Duration(days: 365)) {
      return "$year-$month-$day";
    } else if (offset > const Duration(days: 30)) {
      int month = offset.inDays ~/ 30;
      return "{0} months ago".tlParams([month]);
    } else if (offset > const Duration(days: 1)) {
      int day = offset.inDays;
      return "{0} days ago".tlParams([day]);
    } else if (offset > const Duration(hours: 1)) {
      int hour = offset.inHours;
      return "{0} hours ago".tlParams([hour]);
    } else if (offset > const Duration(minutes: 1)) {
      int minute = offset.inMinutes;
      return "{0} minutes ago".tlParams([minute]);
    } else {
      return "Just now".tl;
    }
  }
}