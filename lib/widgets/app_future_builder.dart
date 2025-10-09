import 'package:flutter/material.dart';

class AppFutureBuilder<T> extends StatelessWidget {
  final Future<T> future;
  final Widget Function(BuildContext context, T data) builder;
  final Widget? loading;
  final Widget Function(BuildContext context, Object error)? errorBuilder;
  final Widget? empty;

  const AppFutureBuilder({
    super.key,
    required this.future,
    required this.builder,
    this.loading,
    this.errorBuilder,
    this.empty,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<T>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return loading ?? const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return errorBuilder?.call(context, snapshot.error!) ??
              Center(child: Text('Error: ${snapshot.error}'));
        } else if (snapshot.hasData) {
          final data = snapshot.data as T;
          if (data is Iterable && data.isEmpty) {
            return empty ?? const Center(child: Text('No data available.'));
          }
          return builder(context, data);
        }
        return empty ?? const SizedBox.shrink();
      },
    );
  }
}
