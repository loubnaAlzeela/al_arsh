// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'rankings_screen.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$tierRankingsHash() => r'a9c8b54f8adb3f94c4ee035e4645920eb75c942b';

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

/// See also [tierRankings].
@ProviderFor(tierRankings)
const tierRankingsProvider = TierRankingsFamily();

/// See also [tierRankings].
class TierRankingsFamily extends Family<AsyncValue<List<PostModel>>> {
  /// See also [tierRankings].
  const TierRankingsFamily();

  /// See also [tierRankings].
  TierRankingsProvider call(
    String weekId,
    String tier,
  ) {
    return TierRankingsProvider(
      weekId,
      tier,
    );
  }

  @override
  TierRankingsProvider getProviderOverride(
    covariant TierRankingsProvider provider,
  ) {
    return call(
      provider.weekId,
      provider.tier,
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
  String? get name => r'tierRankingsProvider';
}

/// See also [tierRankings].
class TierRankingsProvider extends AutoDisposeFutureProvider<List<PostModel>> {
  /// See also [tierRankings].
  TierRankingsProvider(
    String weekId,
    String tier,
  ) : this._internal(
          (ref) => tierRankings(
            ref as TierRankingsRef,
            weekId,
            tier,
          ),
          from: tierRankingsProvider,
          name: r'tierRankingsProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$tierRankingsHash,
          dependencies: TierRankingsFamily._dependencies,
          allTransitiveDependencies:
              TierRankingsFamily._allTransitiveDependencies,
          weekId: weekId,
          tier: tier,
        );

  TierRankingsProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.weekId,
    required this.tier,
  }) : super.internal();

  final String weekId;
  final String tier;

  @override
  Override overrideWith(
    FutureOr<List<PostModel>> Function(TierRankingsRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: TierRankingsProvider._internal(
        (ref) => create(ref as TierRankingsRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        weekId: weekId,
        tier: tier,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<List<PostModel>> createElement() {
    return _TierRankingsProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is TierRankingsProvider &&
        other.weekId == weekId &&
        other.tier == tier;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, weekId.hashCode);
    hash = _SystemHash.combine(hash, tier.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin TierRankingsRef on AutoDisposeFutureProviderRef<List<PostModel>> {
  /// The parameter `weekId` of this provider.
  String get weekId;

  /// The parameter `tier` of this provider.
  String get tier;
}

class _TierRankingsProviderElement
    extends AutoDisposeFutureProviderElement<List<PostModel>>
    with TierRankingsRef {
  _TierRankingsProviderElement(super.provider);

  @override
  String get weekId => (origin as TierRankingsProvider).weekId;
  @override
  String get tier => (origin as TierRankingsProvider).tier;
}
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
