import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:flutter_uart_riverpod/screen/uart_screen.dart';

void main() {
  runApp(
    ProviderScope(
      child: MaterialApp(home: UartScreen(), debugShowCheckedModeBanner: false),
    ),
  );
}
