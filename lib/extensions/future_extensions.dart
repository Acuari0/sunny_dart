//ignore_for_file: unnecessary_cast
import 'dart:async';

import 'package:stream_transform/stream_transform.dart';

import '../helpers.dart';
import '../streams.dart';

export 'package:stream_transform/stream_transform.dart';

extension FutureIterableExt<T> on Iterable<Future<T>> {
  Future<List<T>> waitAll({bool eagerError = true}) async {
    return await Future.wait(this.map((each) => Future.value(each)),
        eagerError: eagerError);
  }
}

extension IterableFutureExt<T> on FutureOr<Iterable<T>> {
  FutureOr<Iterable<R>> thenMap<R>(R mapper(T input)) {
    return this.thenOr((_) {
      return _.map(mapper);
    } as Iterable<R> Function(Iterable<T>?));
  }
}

extension FutureOrIterableNullExt<T> on Iterable<FutureOr<T>>? {
  List<T> completed() {
    if (this == null) return [];
    return <T>[...this!.whereType()];
  }
}

extension FutureOrIterableExt<T> on Iterable<FutureOr<T>> {
  Future<List<T>> awaitAll({bool eagerError = true}) {
    return Future.wait(
        this.map(((v) => v.futureValue()!) as Future<T> Function(FutureOr<T>)),
        eagerError: eagerError);
  }

  FutureOr<List<T>> awaitOr() {
    if (this.any((_) => _ is Future)) {
      return Future.wait(this
          .map(((v) => v.futureValue()!) as Future<T> Function(FutureOr<T>)));
    } else {
      return this.toList().cast<T>();
    }
  }
}

Future<Tuple<A, B>> awaitBoth<A, B>(FutureOr<A> a, FutureOr<B> b) async {
  return Tuple(await Future.value(a), await Future.value(b));
}

extension NestedFutureOr<T> on FutureOr<FutureOr<T>> {
  /// Unboxes a Future/FutureOr
  FutureOr<T> unbox() {
    return this as FutureOr<T>;
  }
}

extension NestedFuture<T> on Future<Future<T>?> {
  /// Unboxes a Future/Future
  Future<T?> unboxFuture() async {
    final a = await Future.value(this);
    if (a != null) {
      return await a;
    } else {
      return null;
    }
  }
}

extension NestedNullableFutureOr<T> on FutureOr<FutureOr<T>?>? {
  /// Unboxes a Future/FutureOr
  FutureOr<T?> unbox() {
    if (this == null) return null;

    return this as FutureOr<T>;
  }
}

extension FutureNullableExtensions<T> on Future<T?> {
  void ignore() {}

  Future<Tuple<T, R>?> to<R>(FutureOr<R> mapper(T? input)) async {
    final resolved = await this;
    if (resolved == null) {
      return null;
    }
    final b = await mapper(resolved);
    if (b != null) {
      return Tuple(resolved, b);
    } else {
      return null;
    }
  }
}

extension FutureExtensions<T> on Future<T> {
  FutureOr<Tuple<T, R>> to<R>(FutureOr<R> mapper(T input)) {
    final other = this.then((resolved) {
      return mapper(resolved).thenOr((second) {
        return Tuple<T, R>(resolved, second);
      });
    });
    return other.unbox();
  }
}

extension ObjectTupleExt<X> on X {
  Tuple<X, Y> to<Y>(Y other) {
    return Tuple(this, other);
  }
}

extension FutureOrExts<T> on FutureOr<T> {
  FutureOr<R> thenOr<R>(R after(T resolved)) => (this is Future<T>)
      ? futureValue().then(after) as FutureOr<R>
      : after(this as T);

  Future<T> futureValue() =>
      (this is Future<T>) ? this as Future<T> : Future.value(this as T);
}

extension FutureOrNullableExts<T> on FutureOr<T?> {
  FutureOr<T> filterNotNull() {
    return this.thenOrNull((resolved) => resolved!);
  }

  ValueStream<T> toVStream() =>
      this == null ? ValueStream.empty() : ValueStream.of(this);

  T? resolve([T? or]) =>
      resolveOrNull(or) ??
      ((this is Future)
          ? illegalState<T>("Attempting to resolve a future.")
          : null);

  T? resolveOrNull([T? or]) => this is Future<T>
      ? (or == null)
          ? null
          : or
      : (this as T? ?? or);

  FutureOr<R?> thenCast<R>() => thenOr((self) => self as R?);

  FutureOr<Tuple<T, R>> and<R>(FutureOr<R> mapper(T input)) {
    final other = filterNotNull().thenOr((resolved) {
      return mapper(resolved).thenOr<Tuple<T, R>>((R second) {
        return Tuple<T, R>(resolved, second);
      });
    });
    return other.unbox();
  }

  FutureOr<T?> also(void consumer(T? input)) {
    final self = this;

    if (self is Future<T?>) {
      return self.then((resolved) {
        consumer(resolved);
        return resolved;
      });
    } else {
      consumer(self);
      return self;
    }
  }

  Future<T?> futureValueOrNull() =>
      (this is Future<T?>) ? this as Future<T?> : Future.value(this as T?);

  FutureOr<R> thenOrNull<R>(R after(T? resolved)) => (this is Future<T?>)
      ? futureValue().then(after) as FutureOr<R>
      : after(this as T);

  FutureOr<R?> nonNull<R>(FutureOr<R> block(T nonNullValue)) {
    final self = this;
    if (self is Future<T?>) {
      return self.then((nonNull) {
        return nonNull == null ? null : block(nonNull);
      });
    } else {
      final v = this as T?;
      return v == null ? null : block(v);
    }
  }
}

extension StreamTxrNullableExtensions<X> on Stream<X>? {
  Stream<X> orEmpty() {
    return this ?? Stream<X>.empty();
  }

  Stream<X> combine(Stream<X> other) {
    return orEmpty().merge(other);
  }
}
