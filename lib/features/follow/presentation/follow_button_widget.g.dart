// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'follow_button_widget.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$followerCountHash() => r'709d6509611ba05a1a920d87ff0fa7e1b534444b';

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

/// See also [followerCount].
@ProviderFor(followerCount)
const followerCountProvider = FollowerCountFamily();

/// See also [followerCount].
class FollowerCountFamily extends Family<AsyncValue<int>> {
  /// See also [followerCount].
  const FollowerCountFamily();

  /// See also [followerCount].
  FollowerCountProvider call(
    String userId,
  ) {
    return FollowerCountProvider(
      userId,
    );
  }

  @override
  FollowerCountProvider getProviderOverride(
    covariant FollowerCountProvider provider,
  ) {
    return call(
      provider.userId,
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
  String? get name => r'followerCountProvider';
}

/// See also [followerCount].
class FollowerCountProvider extends AutoDisposeFutureProvider<int> {
  /// See also [followerCount].
  FollowerCountProvider(
    String userId,
  ) : this._internal(
          (ref) => followerCount(
            ref as FollowerCountRef,
            userId,
          ),
          from: followerCountProvider,
          name: r'followerCountProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$followerCountHash,
          dependencies: FollowerCountFamily._dependencies,
          allTransitiveDependencies:
              FollowerCountFamily._allTransitiveDependencies,
          userId: userId,
        );

  FollowerCountProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.userId,
  }) : super.internal();

  final String userId;

  @override
  Override overrideWith(
    FutureOr<int> Function(FollowerCountRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: FollowerCountProvider._internal(
        (ref) => create(ref as FollowerCountRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        userId: userId,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<int> createElement() {
    return _FollowerCountProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is FollowerCountProvider && other.userId == userId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, userId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin FollowerCountRef on AutoDisposeFutureProviderRef<int> {
  /// The parameter `userId` of this provider.
  String get userId;
}

class _FollowerCountProviderElement
    extends AutoDisposeFutureProviderElement<int> with FollowerCountRef {
  _FollowerCountProviderElement(super.provider);

  @override
  String get userId => (origin as FollowerCountProvider).userId;
}

String _$followingCountHash() => r'a393d848dd6bce2dd5db52d381edf01063bf4905';

/// See also [followingCount].
@ProviderFor(followingCount)
const followingCountProvider = FollowingCountFamily();

/// See also [followingCount].
class FollowingCountFamily extends Family<AsyncValue<int>> {
  /// See also [followingCount].
  const FollowingCountFamily();

  /// See also [followingCount].
  FollowingCountProvider call(
    String userId,
  ) {
    return FollowingCountProvider(
      userId,
    );
  }

  @override
  FollowingCountProvider getProviderOverride(
    covariant FollowingCountProvider provider,
  ) {
    return call(
      provider.userId,
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
  String? get name => r'followingCountProvider';
}

/// See also [followingCount].
class FollowingCountProvider extends AutoDisposeFutureProvider<int> {
  /// See also [followingCount].
  FollowingCountProvider(
    String userId,
  ) : this._internal(
          (ref) => followingCount(
            ref as FollowingCountRef,
            userId,
          ),
          from: followingCountProvider,
          name: r'followingCountProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$followingCountHash,
          dependencies: FollowingCountFamily._dependencies,
          allTransitiveDependencies:
              FollowingCountFamily._allTransitiveDependencies,
          userId: userId,
        );

  FollowingCountProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.userId,
  }) : super.internal();

  final String userId;

  @override
  Override overrideWith(
    FutureOr<int> Function(FollowingCountRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: FollowingCountProvider._internal(
        (ref) => create(ref as FollowingCountRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        userId: userId,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<int> createElement() {
    return _FollowingCountProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is FollowingCountProvider && other.userId == userId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, userId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin FollowingCountRef on AutoDisposeFutureProviderRef<int> {
  /// The parameter `userId` of this provider.
  String get userId;
}

class _FollowingCountProviderElement
    extends AutoDisposeFutureProviderElement<int> with FollowingCountRef {
  _FollowingCountProviderElement(super.provider);

  @override
  String get userId => (origin as FollowingCountProvider).userId;
}

String _$isFollowingHash() => r'99742bd64d289c7c410ecda4148a92faed3342d9';

/// See also [isFollowing].
@ProviderFor(isFollowing)
const isFollowingProvider = IsFollowingFamily();

/// See also [isFollowing].
class IsFollowingFamily extends Family<AsyncValue<bool>> {
  /// See also [isFollowing].
  const IsFollowingFamily();

  /// See also [isFollowing].
  IsFollowingProvider call(
    String targetUserId,
  ) {
    return IsFollowingProvider(
      targetUserId,
    );
  }

  @override
  IsFollowingProvider getProviderOverride(
    covariant IsFollowingProvider provider,
  ) {
    return call(
      provider.targetUserId,
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
  String? get name => r'isFollowingProvider';
}

/// See also [isFollowing].
class IsFollowingProvider extends AutoDisposeFutureProvider<bool> {
  /// See also [isFollowing].
  IsFollowingProvider(
    String targetUserId,
  ) : this._internal(
          (ref) => isFollowing(
            ref as IsFollowingRef,
            targetUserId,
          ),
          from: isFollowingProvider,
          name: r'isFollowingProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$isFollowingHash,
          dependencies: IsFollowingFamily._dependencies,
          allTransitiveDependencies:
              IsFollowingFamily._allTransitiveDependencies,
          targetUserId: targetUserId,
        );

  IsFollowingProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.targetUserId,
  }) : super.internal();

  final String targetUserId;

  @override
  Override overrideWith(
    FutureOr<bool> Function(IsFollowingRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: IsFollowingProvider._internal(
        (ref) => create(ref as IsFollowingRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        targetUserId: targetUserId,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<bool> createElement() {
    return _IsFollowingProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is IsFollowingProvider && other.targetUserId == targetUserId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, targetUserId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin IsFollowingRef on AutoDisposeFutureProviderRef<bool> {
  /// The parameter `targetUserId` of this provider.
  String get targetUserId;
}

class _IsFollowingProviderElement extends AutoDisposeFutureProviderElement<bool>
    with IsFollowingRef {
  _IsFollowingProviderElement(super.provider);

  @override
  String get targetUserId => (origin as IsFollowingProvider).targetUserId;
}
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
