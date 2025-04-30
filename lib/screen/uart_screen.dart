import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_libserialport/flutter_libserialport.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_uart_riverpod/feature/uart/uart_notifier.dart';
import 'dart:developer' as developer;

import '../feature/log/my_utils.dart';

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
  String openCloseStr = "Open";

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
      // appBar: AppBar(
      // title: Text('UART Terminal with Riverpod'),
      // ), // louiey, 2025.03.25. Disabled to display title
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                DropdownButton<String>(
                  hint: Text('Select Port'),
                  value: uartState.portName,
                  items:
                      SerialPort.availablePorts
                          .map(
                            (port) => DropdownMenuItem(
                              value: port,
                              child: Text(port),
                            ),
                          )
                          .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      ref.read(uartProvider.notifier).setSelectedPort(value);
                      utils.log(
                        "Selected port : $value, ${uartState.portName}",
                      );
                    }
                  },
                ),
                SizedBox(width: 8),
                ElevatedButton(
                  child: Text("COM"),
                  onPressed: () {
                    // await ref.read(uartProvider.notifier).connectToPort('COM1');
                    utils.log("check com ports");

                    SerialPort.availablePorts
                        .map(
                          (port) =>
                              DropdownMenuItem(value: port, child: Text(port)),
                        )
                        .toList();
                  },
                ),
                SizedBox(width: 8),
                SizedBox(
                  width: 90,
                  height: 30,
                  child: Expanded(
                    child: ElevatedButton(
                      child: Text(uartState.isConnected ? 'Close' : 'Open'),
                      onPressed: () {
                        developer.log("Open pressed, ${uartState.isConnected}");
                        try {
                          if (uartState.isConnected) {
                            ref.read(uartProvider.notifier).disconnect();
                            openCloseStr = "Open";
                            utils.log("port closed, ${uartState.portName}");
                          } else {
                            if (uartState.portName == null) {
                              utils.log("port is null");
                            } else {
                              ref
                                  .read(uartProvider.notifier)
                                  .connectToPort(uartState.portName ?? '');
                              openCloseStr = "Close";
                              utils.log("port opened, ${uartState.portName}");
                            }
                          }
                        } catch (e) {
                          utils.log(e.toString());
                        }
                      },
                    ),
                  ),
                ),
              ],
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
