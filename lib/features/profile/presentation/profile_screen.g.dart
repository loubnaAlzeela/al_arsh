// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'profile_screen.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$userProfileHash() => r'a0c3eece868b2c0ee68180a28ed49420cbe85b48';

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

/// See also [userProfile].
@ProviderFor(userProfile)
const userProfileProvider = UserProfileFamily();

/// See also [userProfile].
class UserProfileFamily extends Family<AsyncValue<UserModel?>> {
  /// See also [userProfile].
  const UserProfileFamily();

  /// See also [userProfile].
  UserProfileProvider call(
    String? userId,
  ) {
    return UserProfileProvider(
      userId,
    );
  }

  @override
  UserProfileProvider getProviderOverride(
    covariant UserProfileProvider provider,
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
  String? get name => r'userProfileProvider';
}

/// See also [userProfile].
class UserProfileProvider extends AutoDisposeFutureProvider<UserModel?> {
  /// See also [userProfile].
  UserProfileProvider(
    String? userId,
  ) : this._internal(
          (ref) => userProfile(
            ref as UserProfileRef,
            userId,
          ),
          from: userProfileProvider,
          name: r'userProfileProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$userProfileHash,
          dependencies: UserProfileFamily._dependencies,
          allTransitiveDependencies:
              UserProfileFamily._allTransitiveDependencies,
          userId: userId,
        );

  UserProfileProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.userId,
  }) : super.internal();

  final String? userId;

  @override
  Override overrideWith(
    FutureOr<UserModel?> Function(UserProfileRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: UserProfileProvider._internal(
        (ref) => create(ref as UserProfileRef),
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
  AutoDisposeFutureProviderElement<UserModel?> createElement() {
    return _UserProfileProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is UserProfileProvider && other.userId == userId;
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
mixin UserProfileRef on AutoDisposeFutureProviderRef<UserModel?> {
  /// The parameter `userId` of this provider.
  String? get userId;
}

class _UserProfileProviderElement
    extends AutoDisposeFutureProviderElement<UserModel?> with UserProfileRef {
  _UserProfileProviderElement(super.provider);

  @override
  String? get userId => (origin as UserProfileProvider).userId;
}

String _$userPostsHash() => r'734063f3ec6fe500901716928436f3853f1aa4a9';

/// See also [userPosts].
@ProviderFor(userPosts)
const userPostsProvider = UserPostsFamily();

/// See also [userPosts].
class UserPostsFamily extends Family<AsyncValue<List<PostModel>>> {
  /// See also [userPosts].
  const UserPostsFamily();

  /// See also [userPosts].
  UserPostsProvider call(
    String userId,
  ) {
    return UserPostsProvider(
      userId,
    );
  }

  @override
  UserPostsProvider getProviderOverride(
    covariant UserPostsProvider provider,
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
  String? get name => r'userPostsProvider';
}

/// See also [userPosts].
class UserPostsProvider extends AutoDisposeFutureProvider<List<PostModel>> {
  /// See also [userPosts].
  UserPostsProvider(
    String userId,
  ) : this._internal(
          (ref) => userPosts(
            ref as UserPostsRef,
            userId,
          ),
          from: userPostsProvider,
          name: r'userPostsProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$userPostsHash,
          dependencies: UserPostsFamily._dependencies,
          allTransitiveDependencies: UserPostsFamily._allTransitiveDependencies,
          userId: userId,
        );

  UserPostsProvider._internal(
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
    FutureOr<List<PostModel>> Function(UserPostsRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: UserPostsProvider._internal(
        (ref) => create(ref as UserPostsRef),
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
  AutoDisposeFutureProviderElement<List<PostModel>> createElement() {
    return _UserPostsProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is UserPostsProvider && other.userId == userId;
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
mixin UserPostsRef on AutoDisposeFutureProviderRef<List<PostModel>> {
  /// The parameter `userId` of this provider.
  String get userId;
}

class _UserPostsProviderElement
    extends AutoDisposeFutureProviderElement<List<PostModel>>
    with UserPostsRef {
  _UserPostsProviderElement(super.provider);

  @override
  String get userId => (origin as UserPostsProvider).userId;
}

String _$profileStatsHash() => r'5b8a60233d31e00947fbe8787ff7c84b84941872';

/// See also [profileStats].
@ProviderFor(profileStats)
const profileStatsProvider = ProfileStatsFamily();

/// See also [profileStats].
class ProfileStatsFamily extends Family<AsyncValue<ProfileStats>> {
  /// See also [profileStats].
  const ProfileStatsFamily();

  /// See also [profileStats].
  ProfileStatsProvider call(
    String userId,
  ) {
    return ProfileStatsProvider(
      userId,
    );
  }

  @override
  ProfileStatsProvider getProviderOverride(
    covariant ProfileStatsProvider provider,
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
  String? get name => r'profileStatsProvider';
}

/// See also [profileStats].
class ProfileStatsProvider extends AutoDisposeFutureProvider<ProfileStats> {
  /// See also [profileStats].
  ProfileStatsProvider(
    String userId,
  ) : this._internal(
          (ref) => profileStats(
            ref as ProfileStatsRef,
            userId,
          ),
          from: profileStatsProvider,
          name: r'profileStatsProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$profileStatsHash,
          dependencies: ProfileStatsFamily._dependencies,
          allTransitiveDependencies:
              ProfileStatsFamily._allTransitiveDependencies,
          userId: userId,
        );

  ProfileStatsProvider._internal(
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
    FutureOr<ProfileStats> Function(ProfileStatsRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: ProfileStatsProvider._internal(
        (ref) => create(ref as ProfileStatsRef),
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
  AutoDisposeFutureProviderElement<ProfileStats> createElement() {
    return _ProfileStatsProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is ProfileStatsProvider && other.userId == userId;
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
mixin ProfileStatsRef on AutoDisposeFutureProviderRef<ProfileStats> {
  /// The parameter `userId` of this provider.
  String get userId;
}

class _ProfileStatsProviderElement
    extends AutoDisposeFutureProviderElement<ProfileStats>
    with ProfileStatsRef {
  _ProfileStatsProviderElement(super.provider);

  @override
  String get userId => (origin as ProfileStatsProvider).userId;
}
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
