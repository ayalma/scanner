// ignore_for_file: prefer_function_declarations_over_variables

import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/services.dart';

part 'scanner_state.dart';

typedef _KeyBoardListener = void Function(RawKeyEvent);

class ScannerCubit extends Cubit<ScannerState> {
  ScannerCubit() : super(ScannerInitial());
  final StreamController<RawKeyEvent> _keyboardStreamCtrl = StreamController();
  StreamSubscription<List<RawKeyEvent>>? _keyboardStreamSubscription;
  _KeyBoardListener? _keyboardListenerInstance;
  get _keyboardListener =>
      _keyboardListenerInstance ??= (event) => _keyboardStreamCtrl.add(event);

  ///
  ///Watch raw keyboard listener
  ///
  watch() {
    _keyboardStreamSubscription?.cancel();
    _keyboardStreamSubscription = _keyboardStreamCtrl.stream
        .transform(RawKeyEventTransform())
        .listen(_watchKeyBoardStream);
    RawKeyboard.instance.addListener(_keyboardListener);
  }

  void _watchKeyBoardStream(List<RawKeyEvent> events) async {
    final StringBuffer buffer = StringBuffer();
    for (var event in events) {
      buffer.write(event.data.keyLabel);
    }
    await write('file.txt', buffer.toString());
  }

  Future<File> write(String name, String data) =>
      File('C:/test/$name').writeAsString(data);

  ///
  ///unWatch raw keyboard listener
  ///
  unWatch() => RawKeyboard.instance.removeListener(_keyboardListener);
}

class RawKeyEventTransform
    implements StreamTransformer<RawKeyEvent, List<RawKeyEvent>> {
  @override
  Stream<List<RawKeyEvent>> bind(Stream<RawKeyEvent> source) async* {
    List<RawKeyEvent> buffer = List.empty(growable: true);
    await for (RawKeyEvent event in source) {
      if (event.isKeyPressed(LogicalKeyboardKey.enter)) {
        yield buffer;
        buffer.clear();
      } else {
        buffer.add(event);
      }
    }
  }

  @override
  StreamTransformer<RS, RT> cast<RS, RT>() => StreamTransformer.castFrom(this);
}
