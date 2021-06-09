import 'either.dart';
import 'function.dart';
import 'tuple.dart';
import 'typeclass/alt.dart';
import 'typeclass/extend.dart';
import 'typeclass/filterable.dart';
import 'typeclass/foldable.dart';
import 'typeclass/hkt.dart';
import 'typeclass/monad.dart';

/// Tag the `HKT` interface for the actual `Maybe`
abstract class MaybeHKT {}

/// `Maybe<A> implements Functor<MaybeHKT, A>` expresses correctly the
/// return type of the `map` function as `HKT<MaybeHKT, B>`.
/// This tells us that the actual type parameter changed from `A` to `B`,
/// according to the types `A` and `B` of the callable we actually passed as a parameter of `map`.
///
/// Moreover, it informs us that we are still considering an higher kinded type
/// with respect to the `MaybeHKT` tag
abstract class Maybe<A> extends HKT<MaybeHKT, A>
    with
        Monad<MaybeHKT, A>,
        Foldable<MaybeHKT, A>,
        Alt<MaybeHKT, A>,
        Extend<MaybeHKT, A>,
        Filterable<MaybeHKT, A> {
  @override
  Maybe<B> map<B>(B Function(A a) f);

  @override
  Maybe<B> ap<B>(covariant Maybe<B Function(A a)> a) =>
      a.match((f) => map(f), () => Nothing());

  @override
  Maybe<B> pure<B>(B b) => Just(b);

  @override
  Maybe<B> flatMap<B>(covariant Maybe<B> Function(A a) f);

  /// If `Just` then return the value inside, otherwise return the result of `orElse`.
  A getOrElse(A Function() orElse);

  /// Return the current `Maybe` if it is a `Just`, otherwise return the result of `orElse`.
  @override
  Maybe<A> alt(covariant Maybe<A> Function() orElse);

  @override
  Maybe<Z> extend<Z>(Z Function(Maybe<A> t) f);

  @override
  Maybe<A> filter(bool Function(A a) f);

  @override
  Maybe<Z> filterMap<Z>(Maybe<Z> Function(A a) f);

  @override
  Tuple2<Maybe<A>, Maybe<A>> partition(bool Function(A a) f) =>
      Tuple2(filter((a) => !f(a)), filter(f));

  @override
  Tuple2<Maybe<Z>, Maybe<Y>> partitionMap<Z, Y>(Either<Z, Y> Function(A a) f) =>
      Maybe.separate(map(f));

  B match<B>(B Function(A just) onJust, B Function() onNothing);
  bool isJust();
  bool isNothing();

  static Maybe<A> of<A>(A a) => Just(a);
  static Maybe<A> flatten<A>(Maybe<Maybe<A>> m) => m.flatMap(identity);
  static Tuple2<Maybe<A>, Maybe<B>> separate<A, B>(Maybe<Either<A, B>> m) =>
      m.match((just) => Tuple2(just.getLeft(), just.getRight()),
          () => Tuple2(Nothing(), Nothing()));
}

class Just<A> extends Maybe<A> {
  final A a;
  Just(this.a);

  @override
  Maybe<B> map<B>(B Function(A a) f) => Just(f(a));

  @override
  B foldRight<B>(B b, B Function(A a, B b) f) => f(a, b);

  @override
  Maybe<B> flatMap<B>(covariant Maybe<B> Function(A a) f) => f(a);

  @override
  A getOrElse(A Function() orElse) => a;

  @override
  Maybe<A> alt(Maybe<A> Function() orElse) => this;

  @override
  B match<B>(B Function(A just) onJust, B Function() onNothing) => onJust(a);

  @override
  Maybe<Z> extend<Z>(Z Function(Maybe<A> t) f) => Just(f(this));

  @override
  bool isJust() => true;

  @override
  bool isNothing() => false;

  @override
  Maybe<A> filter(bool Function(A a) f) => f(a) ? this : Nothing();

  @override
  Maybe<Z> filterMap<Z>(Maybe<Z> Function(A a) f) =>
      f(a).match((just) => Just(just), () => Nothing());
}

class Nothing<A> extends Maybe<A> {
  @override
  Maybe<B> map<B>(B Function(A a) f) => Nothing();

  @override
  B foldRight<B>(B b, B Function(A a, B b) f) => b;

  @override
  Maybe<B> flatMap<B>(covariant Maybe<B> Function(A a) f) => Nothing();

  @override
  A getOrElse(A Function() orElse) => orElse();

  @override
  Maybe<A> alt(Maybe<A> Function() orElse) => orElse();

  @override
  B match<B>(B Function(A just) onJust, B Function() onNothing) => onNothing();

  @override
  Maybe<Z> extend<Z>(Z Function(Maybe<A> t) f) => Nothing();

  @override
  bool isJust() => false;

  @override
  bool isNothing() => true;

  @override
  Maybe<A> filter(bool Function(A a) f) => Nothing();

  @override
  Maybe<Z> filterMap<Z>(Maybe<Z> Function(A a) f) => Nothing();
}
