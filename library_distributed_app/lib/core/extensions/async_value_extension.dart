import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:library_distributed_app/presentation/widgets/loading_widget.dart';
import 'package:library_distributed_app/presentation/widgets/retry_widget.dart';

extension AsyncValueExtension<T> on AsyncValue<T> {
  bool get isReloading => isLoading && hasValue;

  bool get isInitialLoading => isLoading && !hasValue;

  T? get valueOrPrevious => when(
    data: (data) => data,
    loading: () => asData?.value,
    error: (_, _) => asData?.value,
  );

  bool get hasValueOrPrevious => valueOrPrevious != null;

  AsyncValue<R> mapWithPrevious<R>(R Function(T data) mapper) {
    return when(
      data: (data) => AsyncValue.data(mapper(data)),
      loading: () {
        final previousData = asData?.value;
        if (previousData != null) {
          return AsyncValue.data(mapper(previousData));
        }
        return const AsyncValue.loading();
      },
      error: (error, stackTrace) {
        final previousData = asData?.value;
        if (previousData != null) {
          return AsyncValue.data(mapper(previousData));
        }
        return AsyncValue.error(error, stackTrace);
      },
    );
  }

  Widget whenDataOrPreviousWidget(
    Widget Function(T data) onData, {
    Widget Function()? onLoading,
    Widget Function(Object error, StackTrace stackTrace)? onError,
    VoidCallback? onRetry,
  }) {
    return whenDataOrPrevious<Widget>(
      onData,
      onLoading: onLoading ?? () => const LoadingWidget(),
      onError:
          onError ??
          (error, stackTrace) =>
              RetryWidget(message: error.toString(), onRetry: onRetry),
    );
  }

  R whenDataOrPrevious<R>(
    R Function(T data) onData, {
    required R Function() onLoading,
    required R Function(Object error, StackTrace stackTrace) onError,
  }) {
    return when(
      data: onData,
      loading: () {
        final previousData = asData?.value;
        if (previousData != null) {
          return onData(previousData);
        }
        return onLoading.call();
      },
      error: (error, stackTrace) {
        final previousData = asData?.value;
        if (previousData != null) {
          return onData(previousData);
        }
        return onError.call(error, stackTrace);
      },
    );
  }

  AsyncValue<T> loadingWithPrevious() {
    if (valueOrPrevious != null) {
      return AsyncValue<T>.loading().copyWithPrevious(
        AsyncValue.data(valueOrPrevious as T),
      );
    }
    return AsyncValue<T>.loading();
  }

  bool get hasErrorWithPrevious => hasError && hasValue;

  String? get errorMessage =>
      maybeWhen(error: (error, _) => error.toString(), orElse: () => null);
}
