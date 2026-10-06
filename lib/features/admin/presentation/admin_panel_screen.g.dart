// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'admin_panel_screen.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$adminStatsHash() => r'5468dfe3cb567d2456c7709315cc5ee0aa2edac0';

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

/// See also [adminStats].
@ProviderFor(adminStats)
const adminStatsProvider = AdminStatsFamily();

/// See also [adminStats].
class AdminStatsFamily extends Family<AsyncValue<AdminStats>> {
  /// See also [adminStats].
  const AdminStatsFamily();

  /// See also [adminStats].
  AdminStatsProvider call(
    String weekId,
  ) {
    return AdminStatsProvider(
      weekId,
    );
  }

  @override
  AdminStatsProvider getProviderOverride(
    covariant AdminStatsProvider provider,
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
  String? get name => r'adminStatsProvider';
}

/// See also [adminStats].
class AdminStatsProvider extends AutoDisposeFutureProvider<AdminStats> {
  /// See also [adminStats].
  AdminStatsProvider(
    String weekId,
  ) : this._internal(
          (ref) => adminStats(
            ref as AdminStatsRef,
            weekId,
          ),
          from: adminStatsProvider,
          name: r'adminStatsProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$adminStatsHash,
          dependencies: AdminStatsFamily._dependencies,
          allTransitiveDependencies:
              AdminStatsFamily._allTransitiveDependencies,
          weekId: weekId,
        );

  AdminStatsProvider._internal(
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
    FutureOr<AdminStats> Function(AdminStatsRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: AdminStatsProvider._internal(
        (ref) => create(ref as AdminStatsRef),
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
  AutoDisposeFutureProviderElement<AdminStats> createElement() {
    return _AdminStatsProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is AdminStatsProvider && other.weekId == weekId;
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
mixin AdminStatsRef on AutoDisposeFutureProviderRef<AdminStats> {
  /// The parameter `weekId` of this provider.
  String get weekId;
}

class _AdminStatsProviderElement
    extends AutoDisposeFutureProviderElement<AdminStats> with AdminStatsRef {
  _AdminStatsProviderElement(super.provider);

  @override
  String get weekId => (origin as AdminStatsProvider).weekId;
}

String _$reportedPostsHash() => r'da974f27650c5a3bd56131b6e768e6d35167984a';

/// See also [reportedPosts].
@ProviderFor(reportedPosts)
final reportedPostsProvider =
    AutoDisposeFutureProvider<List<ReportedPost>>.internal(
  reportedPosts,
  name: r'reportedPostsProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$reportedPostsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef ReportedPostsRef = AutoDisposeFutureProviderRef<List<ReportedPost>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
