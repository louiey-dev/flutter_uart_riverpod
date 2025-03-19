import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_libserialport/flutter_libserialport.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:developer' as developer;

class UartState {
  final bool isConnected;
  final String? portName;
  final String receivedData;
  final String errorMessage;

  UartState({
    this.isConnected = false,
    this.portName,
    this.receivedData = '',
    this.errorMessage = '',
  });

  UartState copyWith({
    bool? isConnected,
    String? portName,
    String? receivedData,
    String? errorMessage,
  }) {
    return UartState(
      isConnected: isConnected ?? this.isConnected,
      portName: portName ?? this.portName,
      receivedData: receivedData ?? this.receivedData,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

class UartNotifier extends StateNotifier<UartState> {
  SerialPort? _serialPort;
  bool _inEscapeSequence = false;
  bool _inEscapeParameter = false;
  String _receivedBuffer = '';
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
        developer.log('Raw UART data: $data');
        String received = '';

        for (int byte in data) {
          developer.log('Processing byte: $byte');

          if (_inEscapeSequence) {
            _escapeSequence += String.fromCharCode(byte);
            developer.log('Building escape sequence: $_escapeSequence');

            // Check if this byte terminates the sequence (A-Z, a-z, etc.)
            if (byte >= 64 && byte <= 126) {
              developer.log('Completed ANSI sequence: $_escapeSequence');
              _inEscapeSequence = false;
              _escapeSequence = '';
            }
          } else if (byte == 27) {
            // ESC character
            _inEscapeSequence = true;
            _escapeSequence = '\x1B';
            developer.log('Started escape sequence: $_escapeSequence');
          } else {
            // Printable character or allowed control
            if (byte >= 32 && byte <= 126 ||
                byte == 9 ||
                byte == 10 ||
                byte == 13) {
              received += String.fromCharCode(byte);
            }
          }
        }

        developer.log('Processed received data: $received');
        if (received.isNotEmpty) {
          state = state.copyWith(receivedData: state.receivedData + received);
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
}

final uartProvider = StateNotifierProvider<UartNotifier, UartState>((ref) {
  return UartNotifier();
});

class UartScreen extends ConsumerStatefulWidget {
  const UartScreen({super.key});

  @override
  _UartScreenState createState() => _UartScreenState();
}

class _UartScreenState extends ConsumerState<UartScreen> {
  final TextEditingController _terminalController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _terminalFocusNode = FocusNode();
  bool _isUserTyping = false;
  String _lastReceivedData = '';

  @override
  void dispose() {
    _terminalController.dispose();
    _scrollController.dispose();
    _terminalFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final uartState = ref.watch(uartProvider);

    if (!_isUserTyping && uartState.receivedData != _lastReceivedData) {
      _terminalController.text = uartState.receivedData;
      _terminalController.selection = TextSelection.fromPosition(
        TextPosition(offset: _terminalController.text.length),
      );
      _lastReceivedData = uartState.receivedData;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients && !_isUserTyping) {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      }
    });

    return Scaffold(
      appBar: AppBar(title: Text('UART Terminal with Riverpod')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DropdownButton<String>(
              hint: Text('Select Port'),
              value: uartState.portName,
              items:
                  SerialPort.availablePorts
                      .map(
                        (port) =>
                            DropdownMenuItem(value: port, child: Text(port)),
                      )
                      .toList(),
              onChanged: (value) {
                if (value != null) {
                  ref.read(uartProvider.notifier).connectToPort(value);
                }
              },
            ),
            SizedBox(height: 16),
            Text(
              uartState.isConnected
                  ? 'Connected to ${uartState.portName}'
                  : 'Disconnected',
              style: TextStyle(
                color: uartState.isConnected ? Colors.green : Colors.red,
              ),
            ),
            SizedBox(height: 16),
            Expanded(
              child: Focus(
                focusNode: _terminalFocusNode,
                onKeyEvent: (FocusNode node, KeyEvent event) {
                  if (event is KeyDownEvent) {
                    if (event.logicalKey == LogicalKeyboardKey.tab) {
                      developer.log('Tab key intercepted by Focus');
                      if (uartState.isConnected) {
                        _isUserTyping = true;
                        final currentText = _terminalController.text;
                        _terminalController.text = '$currentText\t';
                        _terminalController
                            .selection = TextSelection.fromPosition(
                          TextPosition(offset: _terminalController.text.length),
                        );
                        ref.read(uartProvider.notifier).sendData('\t');
                        _isUserTyping = false;
                      }
                      return KeyEventResult.handled;
                    } else if (event.logicalKey == LogicalKeyboardKey.enter) {
                      developer.log('Enter key intercepted by Focus');
                      if (uartState.isConnected) {
                        _isUserTyping = true;
                        final currentText = _terminalController.text;
                        _terminalController.text = '$currentText\n';
                        _terminalController
                            .selection = TextSelection.fromPosition(
                          TextPosition(offset: _terminalController.text.length),
                        );
                        ref.read(uartProvider.notifier).sendData('\r');
                        _isUserTyping = false;
                      }
                      return KeyEventResult.handled;
                    } else if (event.logicalKey == LogicalKeyboardKey.keyC &&
                        HardwareKeyboard.instance.logicalKeysPressed.contains(
                          LogicalKeyboardKey.controlLeft,
                        )) {
                      developer.log('Ctrl+C intercepted by Focus');
                      if (uartState.isConnected) {
                        ref
                            .read(uartProvider.notifier)
                            .sendData('\x03'); // Send ETX (Ctrl+C)
                      }
                      return KeyEventResult.handled;
                    }
                  }
                  return KeyEventResult.ignored;
                },
                child: SingleChildScrollView(
                  controller: _scrollController,
                  child: TextField(
                    controller: _terminalController,
                    maxLines: null,
                    decoration: InputDecoration(
                      labelText: 'Terminal',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) {
                      if (uartState.isConnected &&
                          value.length > uartState.receivedData.length) {
                        _isUserTyping = true;
                        final newChar = value.substring(
                          uartState.receivedData.length,
                        );
                        if (newChar != '\t' && newChar != '\n') {
                          ref.read(uartProvider.notifier).sendData(newChar);
                        }
                        _isUserTyping = false;
                      }
                    },
                  ),
                ),
              ),
            ),
            if (uartState.errorMessage.isNotEmpty)
              Text(
                'Error: ${uartState.errorMessage}',
                style: TextStyle(color: Colors.red),
              ),
            SizedBox(height: 16),
            if (uartState.isConnected)
              ElevatedButton(
                onPressed: () => ref.read(uartProvider.notifier).disconnect(),
                child: Text('Disconnect'),
              ),
          ],
        ),
      ),
    );
  }
}

void main() {
  runApp(ProviderScope(child: MaterialApp(home: UartScreen())));
}
