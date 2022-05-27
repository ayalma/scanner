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
  StreamSubscription<String>? _keyboardStreamSubscription;
  _KeyBoardListener? _keyboardListenerInstance;
  get _keyboardListener =>
      _keyboardListenerInstance ??= (event) => _keyboardStreamCtrl.add(event);

  ///
  ///Watch raw keyboard listener
  ///
  watch() {
    _keyboardStreamSubscription?.cancel();
    _keyboardStreamSubscription = _keyboardStreamCtrl.stream
        .transform(RawKeyEventBufferTransform())
        .transform(RawKeyEventProccessTransform())
        .listen(_watchKeyBoardStream);
    RawKeyboard.instance.addListener(_keyboardListener);
  }

  void _watchKeyBoardStream(String scanedData) async {
    //emit(state);
    print(scanedData);
  }

  Future<File> write(String name, String data) =>
      File('C:/test/$name').writeAsString(data);

  ///
  ///unWatch raw keyboard listener
  ///
  unWatch() => RawKeyboard.instance.removeListener(_keyboardListener);
}

class RawKeyEventBufferTransform
    implements StreamTransformer<RawKeyEvent, List<RawKeyEvent>> {
  @override
  Stream<List<RawKeyEvent>> bind(Stream<RawKeyEvent> source) async* {
    List<RawKeyEvent> buffer = List.empty(growable: true);

    await for (RawKeyEvent event in source) {
      if (event.runtimeType.toString() == "RawKeyDownEvent") {
        if (event.isKeyPressed(LogicalKeyboardKey.enter)) {
          yield buffer;
          buffer.clear();
        } else if (buffer.isNotEmpty &&
            !(buffer.first.logicalKey == LogicalKeyboardKey.f1) &&
            event.logicalKey == LogicalKeyboardKey.f1) {
          buffer.clear();
          buffer.add(event);
        } else {
          buffer.add(event);
        }
      }
    }
  }

  @override
  StreamTransformer<RS, RT> cast<RS, RT>() => StreamTransformer.castFrom(this);
}

class RawKeyEventProccessTransform
    implements StreamTransformer<List<RawKeyEvent>, String> {
  @override
  Stream<String> bind(Stream<List<RawKeyEvent>> stream) async* {
    StringBuffer barcodeStringBuffer = StringBuffer();
    await for (List<RawKeyEvent> eventList in stream) {
      if (eventList.first.logicalKey == LogicalKeyboardKey.f1) {
        for (int index = 0; index < eventList.length; index++) {
          barcodeStringBuffer.write(eventList[index].data.keyLabel);
        }
        final barcodeString = barcodeStringBuffer.toString();
        yield barcodeString.trim();
      }
      barcodeStringBuffer.clear();
    }
  }

  @override
  StreamTransformer<RS, RT> cast<RS, RT>() => StreamTransformer.castFrom(this);
}
