import 'dart:developer' as developer;
import 'dart:typed_data';

import 'package:flutter_libserialport/flutter_libserialport.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_uart_riverpod/feature/uart/uart_state.dart';

final uartProvider = StateNotifierProvider<UartNotifier, UartState>((ref) {
  return UartNotifier();
});

class UartNotifier extends StateNotifier<UartState> {
  SerialPort? _serialPort;
  bool _inEscapeSequence = false;
  String _escapeSequence = '';

  UartNotifier() : super(UartState());

  Future<void> connectToPort(String portName) async {
    try {
      _serialPort = SerialPort(portName);
      if (!_serialPort!.openReadWrite()) {
        state = state.copyWith(
          errorMessage: 'Failed to open port: ${SerialPort.lastError}',
        );
        return;
      }

      final config =
          SerialPortConfig()
            ..baudRate = 115200
            ..bits = 8
            ..parity = 0
            ..stopBits = 1;
      _serialPort!.config = config;

      state = state.copyWith(
        isConnected: true,
        portName: portName,
        errorMessage: '',
      );

      _listenToPort();
    } catch (e) {
      state = state.copyWith(errorMessage: 'Error connecting to port: $e');
    }
  }

  void _listenToPort() {
    final reader = SerialPortReader(_serialPort!);
    reader.stream.listen(
      (data) {
        // developer.log('Raw UART data: $data');
        // String received = '';
        String received = String.fromCharCodes(data);

        // for (int byte in data) {
        //   developer.log('Processing byte: $byte');

        //   if (_inEscapeSequence) {
        //     _escapeSequence += String.fromCharCode(byte);
        //     developer.log('Building escape sequence: $_escapeSequence');

        //     // Check if this byte terminates the sequence (A-Z, a-z, etc.)
        //     if (byte >= 64 && byte <= 126) {
        //       developer.log('Completed ANSI sequence: $_escapeSequence');
        //       _inEscapeSequence = false;
        //       _escapeSequence = '';
        //     }
        //   } else if (byte == 27) {
        //     // ESC character
        //     _inEscapeSequence = true;
        //     _escapeSequence = '\x1B';
        //     developer.log('Started escape sequence: $_escapeSequence');
        //   } else {
        //     // Printable character or allowed control
        //     if (byte >= 32 && byte <= 126 ||
        //         byte == 9 ||
        //         byte == 10 ||
        //         byte == 13) {
        //       received += String.fromCharCode(byte);
        //     }
        //   }
        // }

        // developer.log('Processed received data: $received');
        if (received.isNotEmpty) {
          state = state.copyWith(receivedData: state.receivedData + received);
          // state = state.copyWith(receivedData: received);
        }
      },
      onError: (e) {
        state = state.copyWith(errorMessage: 'Error reading data: $e');
      },
    );
  }

  Future<void> sendData(String data) async {
    if (_serialPort != null && state.isConnected) {
      _serialPort!.write(Uint8List.fromList(data.codeUnits));
    }
  }

  void disconnect() {
    if (_serialPort != null) {
      _serialPort!.close();
      _serialPort = null;
      state = state.copyWith(
        isConnected: false,
        portName: null,
        receivedData: '',
        errorMessage: '',
      );
    }
  }

  // Inside your UartNotifier class in uart_notifier.dart
  // void setSelectedPort(String portName) {
  //   state = state.copyWith(
  //     portName: portName,
  //   );
  // Assuming your UartState has a copyWith method
  // Or if you don't have copyWith:
  // state = UartState(
  //   portName: portName,
  //   isConnected: state.isConnected,
  //   receivedData: state.receivedData,
  //   errorMessage: state.errorMessage,
  //   // copy other existing state properties
  // );
  Future setSelectedPort(String portName) async {
    state = state.copyWith(portName: portName);
  }
}
