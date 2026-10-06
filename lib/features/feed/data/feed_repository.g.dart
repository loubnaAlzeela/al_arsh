// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'feed_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$feedRepositoryHash() => r'28860a33d29101f11e362da7f142976bfef1b812';

/// See also [feedRepository].
@ProviderFor(feedRepository)
final feedRepositoryProvider = AutoDisposeProvider<FeedRepository>.internal(
  feedRepository,
  name: r'feedRepositoryProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$feedRepositoryHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef FeedRepositoryRef = AutoDisposeProviderRef<FeedRepository>;
String _$myVoteForWeekHash() => r'15b40125e01642dcced86c8bfea72c798019954e';

/// Copied from Dart SDK
class _SystemHash {
  _SystemHash._();

  static int combine(int hash, int value) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + value);
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x0007ffff & hash) << 10));
    return hash ^ (hash >> 6);
  }

  static int finish(int hash) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x03ffffff & hash) << 3));
    // ignore: parameter_assignments
    hash = hash ^ (hash >> 11);
    return 0x1fffffff & (hash + ((0x00003fff & hash) << 15));
  }
}

/// See also [myVoteForWeek].
@ProviderFor(myVoteForWeek)
const myVoteForWeekProvider = MyVoteForWeekFamily();

/// See also [myVoteForWeek].
class MyVoteForWeekFamily extends Family<AsyncValue<Map<String, String>?>> {
  /// See also [myVoteForWeek].
  const MyVoteForWeekFamily();

  /// See also [myVoteForWeek].
  MyVoteForWeekProvider call(
    String weekId,
  ) {
    return MyVoteForWeekProvider(
      weekId,
    );
  }

  @override
  MyVoteForWeekProvider getProviderOverride(
    covariant MyVoteForWeekProvider provider,
  ) {
    return call(
      provider.weekId,
    );
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'myVoteForWeekProvider';
}

/// See also [myVoteForWeek].
class MyVoteForWeekProvider
    extends AutoDisposeFutureProvider<Map<String, String>?> {
  /// See also [myVoteForWeek].
  MyVoteForWeekProvider(
    String weekId,
  ) : this._internal(
          (ref) => myVoteForWeek(
            ref as MyVoteForWeekRef,
            weekId,
          ),
          from: myVoteForWeekProvider,
          name: r'myVoteForWeekProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$myVoteForWeekHash,
          dependencies: MyVoteForWeekFamily._dependencies,
          allTransitiveDependencies:
              MyVoteForWeekFamily._allTransitiveDependencies,
          weekId: weekId,
        );

  MyVoteForWeekProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.weekId,
  }) : super.internal();

  final String weekId;

  @override
  Override overrideWith(
    FutureOr<Map<String, String>?> Function(MyVoteForWeekRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: MyVoteForWeekProvider._internal(
        (ref) => create(ref as MyVoteForWeekRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        weekId: weekId,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<Map<String, String>?> createElement() {
    return _MyVoteForWeekProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is MyVoteForWeekProvider && other.weekId == weekId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, weekId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin MyVoteForWeekRef on AutoDisposeFutureProviderRef<Map<String, String>?> {
  /// The parameter `weekId` of this provider.
  String get weekId;
}

class _MyVoteForWeekProviderElement
    extends AutoDisposeFutureProviderElement<Map<String, String>?>
    with MyVoteForWeekRef {
  _MyVoteForWeekProviderElement(super.provider);

  @override
  String get weekId => (origin as MyVoteForWeekProvider).weekId;
}

String _$feedNotifierHash() => r'd77e87b6ab54ae32722512c3d78f780582f6778a';

/// See also [FeedNotifier].
@ProviderFor(FeedNotifier)
final feedNotifierProvider =
    AutoDisposeAsyncNotifierProvider<FeedNotifier, List<PostModel>>.internal(
  FeedNotifier.new,
  name: r'feedNotifierProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$feedNotifierHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$FeedNotifier = AutoDisposeAsyncNotifier<List<PostModel>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
