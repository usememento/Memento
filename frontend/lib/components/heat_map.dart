import 'dart:math';

import 'package:flutter/material.dart';
import 'package:frontend/foundation/app.dart';
import 'package:frontend/utils/translation.dart';

/// Data for the heat map.
///
/// The key is the date in the format of `yyyy-MM-dd`.
typedef HeatMapData = Map<String, int>;

// TODO: remove this function and replace it with real data.
HeatMapData getTestData() {
  var time = DateTime.now();

  var data = <String, int>{};

  for (var i = 0; i < 365; i++) {
    var key = time.toIso8601String().substring(0, 10);
    data[key] = Random().nextInt(8);
    time = time.subtract(const Duration(days: 1));
  }

  return data;
}

class HeatMap extends StatelessWidget {
  const HeatMap({super.key, required this.data});

  final HeatMapData data;

  static const _kSquareSize = 12.0;

  static const _kPadding = 2.0;

  @override
  Widget build(BuildContext context) {
    var time = DateTime.now();
    if (time.weekday != DateTime.sunday) {
      time = time.subtract(Duration(days: time.weekday));
    }
    return LayoutBuilder(builder: (context, constrains) {
      var width = constrains.maxWidth;
      var maxColumns = (width / (_kSquareSize + _kPadding * 2)).floor();

      var columns = <Widget>[];
      Map<int, int> monthInfo = {};
      for (var i = 0; i < maxColumns; i++) {
        columns.add(buildColumn(time, context, i, monthInfo));
        time = time.subtract(const Duration(days: 7));
      }

      return Column(
        children: [
          Row(
            children: columns.reversed.toList(),
          ),
          buildMonthInfo(monthInfo, maxColumns),
        ],
      ).fixWidth(_kSquareSize*maxColumns + _kPadding*(maxColumns)*2).toCenter();
    }).fixWidth(double.infinity);
  }

  Widget buildOneDay(String time, int count, Color primary, Color bg) {
    primary = primary.withOpacity(count.clamp(0, 5) * 0.2);
    Widget child = ColoredBox(
      color: primary,
      child: const SizedBox.square(
        dimension: _kSquareSize,
      ),
    );
    if(count == 0) {
      child = ColoredBox(
        color: bg,
        child: const SizedBox.square(
          dimension: _kSquareSize,
        ),
      );
    }
    child = Tooltip(
      message: "$time\n$count Memos",
      textAlign: TextAlign.center,
      child: child
    );
    return ClipRRect(
      borderRadius: BorderRadius.circular(2),
      child: child,
    ).paddingAll(_kPadding);
  }

  Column buildColumn(DateTime start, BuildContext context, int columnIndex, Map<int, int> monthInfo) {
    if (start.weekday != DateTime.sunday) {
      throw ArgumentError('start must be a Sunday');
    }

    var children = <Widget>[];

    for (var i = 0; i < 7; i++) {
      var date = start.add(Duration(days: i));
      if(date.day == 1) {
        monthInfo[date.month] = columnIndex;
      }
      var key = date.toIso8601String().substring(0, 10);
      var count = data[key] ?? 0;
      var primary = App.mainColor;
      var bg = context.colorScheme.surfaceContainer;
      var time = "${date.month}-${date.day}";
      children.add(buildOneDay(time, count, primary, bg));
    }

    return Column(
      children: children,
    );
  }

  Widget buildMonthInfo(Map<int, int> monthInfo, int maxColumns) {
    var children = <Widget>[];
    int lastIndex = -1;
    for(var month in monthInfo.keys) {
      var columnIndex = monthInfo[month]!;
      const months = [
        "Jan", "Feb", "Mar", "Apr", "May", "Jun",
        "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"
      ];
      var monthName = months[month-1];
      if(columnIndex -lastIndex == 1) {
        columnIndex++;
      }
      var columns = (columnIndex - lastIndex);
      children.add(SizedBox(
        width: (_kSquareSize + _kPadding * 2) * columns,
        child: Align(
          alignment: Alignment.centerLeft,
          child: Text(
            monthName.tl,
            style: const TextStyle(
              fontSize: 12,
            ),
          ).paddingLeft(_kPadding),
        ),
      ));
      lastIndex = columnIndex;
    }

    children.add(SizedBox(
      width: (_kSquareSize + _kPadding * 2) * (maxColumns - lastIndex - 1),
    ));
    return Row(
      children: children.reversed.toList(),
    );
  }
}