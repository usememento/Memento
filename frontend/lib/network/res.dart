class Res<T>{
  ///error info
  final String? errorMessage;

  String get message => errorMessage??"Unknown Error";

  /// data
  final T? _data;

  /// is there an error
  bool get error => errorMessage!=null || _data==null;

  /// whether succeed
  bool get success => !error;

  /// data
  ///
  /// must be called when no error happened, or it will throw error
  T get data => _data ?? (throw Exception(errorMessage));

  /// get data, or null if there is an error
  T? get dataOrNull => _data;

  final dynamic subData;

  @override
  String toString() => _data.toString();

  Res.fromErrorRes(Res another, {this.subData}):
        _data=null,errorMessage=another.message;

  /// network result
  const Res(this._data,{this.errorMessage, this.subData});

  const Res.error(this.errorMessage):_data=null, subData=null;
}