class ExecutionResult {
  final String stdout;
  final String stderr;
  final String? error;
  final String? executionTime;
  final String? memory;
  final bool isSuccess;

  ExecutionResult({
    this.stdout = '',
    this.stderr = '',
    this.error,
    this.executionTime,
    this.memory,
    this.isSuccess = true,
  });

  bool get hasError => error != null && error!.isNotEmpty;
  bool get hasStderr => stderr.isNotEmpty;
}
