class ExecutionResult {
  final String stdout;
  final String stderr;
  final String? executionTime;
  final String? memory;
  final String? error;
  final bool isSuccess;

  ExecutionResult({
    this.stdout = '',
    this.stderr = '',
    this.executionTime,
    this.memory,
    this.error,
    this.isSuccess = true,
  });

  @override
  String toString() {
    return 'ExecutionResult(stdout: $stdout, stderr: $stderr, error: $error)';
  }
}
