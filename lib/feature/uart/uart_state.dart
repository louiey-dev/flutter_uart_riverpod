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
