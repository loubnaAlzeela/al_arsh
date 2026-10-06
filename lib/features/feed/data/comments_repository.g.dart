// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'comments_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$commentsRepositoryHash() =>
    r'f38e53a2ebf653fab28963a38c62443c6a1c6831';

/// See also [commentsRepository].
@ProviderFor(commentsRepository)
final commentsRepositoryProvider =
    AutoDisposeProvider<CommentsRepository>.internal(
  commentsRepository,
  name: r'commentsRepositoryProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$commentsRepositoryHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef CommentsRepositoryRef = AutoDisposeProviderRef<CommentsRepository>;
String _$commentsNotifierHash() => r'049cdc45706aca7f2a00e83ca0365ae597f02484';

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

abstract class _$CommentsNotifier
    extends BuildlessAutoDisposeAsyncNotifier<List<CommentModel>> {
  late final String postId;

  FutureOr<List<CommentModel>> build(
    String postId,
  );
}

/// See also [CommentsNotifier].
@ProviderFor(CommentsNotifier)
const commentsNotifierProvider = CommentsNotifierFamily();

/// See also [CommentsNotifier].
class CommentsNotifierFamily extends Family<AsyncValue<List<CommentModel>>> {
  /// See also [CommentsNotifier].
  const CommentsNotifierFamily();

  /// See also [CommentsNotifier].
  CommentsNotifierProvider call(
    String postId,
  ) {
    return CommentsNotifierProvider(
      postId,
    );
  }

  @override
  CommentsNotifierProvider getProviderOverride(
    covariant CommentsNotifierProvider provider,
  ) {
    return call(
      provider.postId,
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
  String? get name => r'commentsNotifierProvider';
}

/// See also [CommentsNotifier].
class CommentsNotifierProvider extends AutoDisposeAsyncNotifierProviderImpl<
    CommentsNotifier, List<CommentModel>> {
  /// See also [CommentsNotifier].
  CommentsNotifierProvider(
    String postId,
  ) : this._internal(
          () => CommentsNotifier()..postId = postId,
          from: commentsNotifierProvider,
          name: r'commentsNotifierProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$commentsNotifierHash,
          dependencies: CommentsNotifierFamily._dependencies,
          allTransitiveDependencies:
              CommentsNotifierFamily._allTransitiveDependencies,
          postId: postId,
        );

  CommentsNotifierProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.postId,
  }) : super.internal();

  final String postId;

  @override
  FutureOr<List<CommentModel>> runNotifierBuild(
    covariant CommentsNotifier notifier,
  ) {
    return notifier.build(
      postId,
    );
  }

  @override
  Override overrideWith(CommentsNotifier Function() create) {
    return ProviderOverride(
      origin: this,
      override: CommentsNotifierProvider._internal(
        () => create()..postId = postId,
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        postId: postId,
      ),
    );
  }

  @override
  AutoDisposeAsyncNotifierProviderElement<CommentsNotifier, List<CommentModel>>
      createElement() {
    return _CommentsNotifierProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is CommentsNotifierProvider && other.postId == postId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, postId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin CommentsNotifierRef
    on AutoDisposeAsyncNotifierProviderRef<List<CommentModel>> {
  /// The parameter `postId` of this provider.
  String get postId;
}

class _CommentsNotifierProviderElement
    extends AutoDisposeAsyncNotifierProviderElement<CommentsNotifier,
        List<CommentModel>> with CommentsNotifierRef {
  _CommentsNotifierProviderElement(super.provider);

  @override
  String get postId => (origin as CommentsNotifierProvider).postId;
}
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
