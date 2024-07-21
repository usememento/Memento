import 'package:highlight/languages/main.dart';
import 'package:highlight/src/highlight.dart';

export 'package:highlight/src/highlight.dart';
export 'package:highlight/src/node.dart';
export 'package:highlight/src/mode.dart';
export 'package:highlight/src/result.dart';

final highlight = Highlight()..registerLanguages(mainLanguages);
