// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'gifts_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$giftsRepositoryHash() => r'19548b50d8e75f88def7e6e293805535cd530b0f';

/// See also [giftsRepository].
@ProviderFor(giftsRepository)
final giftsRepositoryProvider = AutoDisposeProvider<GiftsRepository>.internal(
  giftsRepository,
  name: r'giftsRepositoryProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$giftsRepositoryHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef GiftsRepositoryRef = AutoDisposeProviderRef<GiftsRepository>;
String _$walletHash() => r'205af7e0958ab2f3765600507f1ffd50e365c7c0';

/// See also [wallet].
@ProviderFor(wallet)
final walletProvider = AutoDisposeStreamProvider<WalletModel?>.internal(
  wallet,
  name: r'walletProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$walletHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef WalletRef = AutoDisposeStreamProviderRef<WalletModel?>;
String _$giftsHistoryHash() => r'147b1bff4459107a3652c67a62b1e8e5378aee09';

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

/// See also [giftsHistory].
@ProviderFor(giftsHistory)
const giftsHistoryProvider = GiftsHistoryFamily();

/// See also [giftsHistory].
class GiftsHistoryFamily extends Family<AsyncValue<List<GiftModel>>> {
  /// See also [giftsHistory].
  const GiftsHistoryFamily();

  /// See also [giftsHistory].
  GiftsHistoryProvider call(
    String userId,
  ) {
    return GiftsHistoryProvider(
      userId,
    );
  }

  @override
  GiftsHistoryProvider getProviderOverride(
    covariant GiftsHistoryProvider provider,
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
  String? get name => r'giftsHistoryProvider';
}

/// See also [giftsHistory].
class GiftsHistoryProvider extends AutoDisposeFutureProvider<List<GiftModel>> {
  /// See also [giftsHistory].
  GiftsHistoryProvider(
    String userId,
  ) : this._internal(
          (ref) => giftsHistory(
            ref as GiftsHistoryRef,
            userId,
          ),
          from: giftsHistoryProvider,
          name: r'giftsHistoryProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$giftsHistoryHash,
          dependencies: GiftsHistoryFamily._dependencies,
          allTransitiveDependencies:
              GiftsHistoryFamily._allTransitiveDependencies,
          userId: userId,
        );

  GiftsHistoryProvider._internal(
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
    FutureOr<List<GiftModel>> Function(GiftsHistoryRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: GiftsHistoryProvider._internal(
        (ref) => create(ref as GiftsHistoryRef),
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
  AutoDisposeFutureProviderElement<List<GiftModel>> createElement() {
    return _GiftsHistoryProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is GiftsHistoryProvider && other.userId == userId;
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
mixin GiftsHistoryRef on AutoDisposeFutureProviderRef<List<GiftModel>> {
  /// The parameter `userId` of this provider.
  String get userId;
}

class _GiftsHistoryProviderElement
    extends AutoDisposeFutureProviderElement<List<GiftModel>>
    with GiftsHistoryRef {
  _GiftsHistoryProviderElement(super.provider);

  @override
  String get userId => (origin as GiftsHistoryProvider).userId;
}

String _$transactionsHash() => r'103d5e0e0feef080dd1791472b57aa2258ffe2eb';

/// See also [transactions].
@ProviderFor(transactions)
const transactionsProvider = TransactionsFamily();

/// See also [transactions].
class TransactionsFamily extends Family<AsyncValue<List<TransactionModel>>> {
  /// See also [transactions].
  const TransactionsFamily();

  /// See also [transactions].
  TransactionsProvider call(
    String userId,
  ) {
    return TransactionsProvider(
      userId,
    );
  }

  @override
  TransactionsProvider getProviderOverride(
    covariant TransactionsProvider provider,
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
  String? get name => r'transactionsProvider';
}

/// See also [transactions].
class TransactionsProvider
    extends AutoDisposeFutureProvider<List<TransactionModel>> {
  /// See also [transactions].
  TransactionsProvider(
    String userId,
  ) : this._internal(
          (ref) => transactions(
            ref as TransactionsRef,
            userId,
          ),
          from: transactionsProvider,
          name: r'transactionsProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$transactionsHash,
          dependencies: TransactionsFamily._dependencies,
          allTransitiveDependencies:
              TransactionsFamily._allTransitiveDependencies,
          userId: userId,
        );

  TransactionsProvider._internal(
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
    FutureOr<List<TransactionModel>> Function(TransactionsRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: TransactionsProvider._internal(
        (ref) => create(ref as TransactionsRef),
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
  AutoDisposeFutureProviderElement<List<TransactionModel>> createElement() {
    return _TransactionsProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is TransactionsProvider && other.userId == userId;
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
mixin TransactionsRef on AutoDisposeFutureProviderRef<List<TransactionModel>> {
  /// The parameter `userId` of this provider.
  String get userId;
}

class _TransactionsProviderElement
    extends AutoDisposeFutureProviderElement<List<TransactionModel>>
    with TransactionsRef {
  _TransactionsProviderElement(super.provider);

  @override
  String get userId => (origin as TransactionsProvider).userId;
}

String _$myWithdrawalsHash() => r'8acb658dc71cb2e324c8a3216693675510bddfb9';

/// See also [myWithdrawals].
@ProviderFor(myWithdrawals)
final myWithdrawalsProvider =
    AutoDisposeFutureProvider<List<WithdrawalRequestModel>>.internal(
  myWithdrawals,
  name: r'myWithdrawalsProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$myWithdrawalsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef MyWithdrawalsRef
    = AutoDisposeFutureProviderRef<List<WithdrawalRequestModel>>;
String _$pendingWithdrawalsHash() =>
    r'285a2b36c3d5634b7459ce850c94945889468179';

/// See also [pendingWithdrawals].
@ProviderFor(pendingWithdrawals)
final pendingWithdrawalsProvider =
    AutoDisposeFutureProvider<List<WithdrawalRequestModel>>.internal(
  pendingWithdrawals,
  name: r'pendingWithdrawalsProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$pendingWithdrawalsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef PendingWithdrawalsRef
    = AutoDisposeFutureProviderRef<List<WithdrawalRequestModel>>;
String _$sendGiftNotifierHash() => r'052e869268c6d5d836f561d037e5061ff7f56657';

/// See also [SendGiftNotifier].
@ProviderFor(SendGiftNotifier)
final sendGiftNotifierProvider =
    AutoDisposeAsyncNotifierProvider<SendGiftNotifier, void>.internal(
  SendGiftNotifier.new,
  name: r'sendGiftNotifierProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$sendGiftNotifierHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$SendGiftNotifier = AutoDisposeAsyncNotifier<void>;
String _$withdrawalNotifierHash() =>
    r'2e0020b1ac09fec7dc8d45f6d527fd5b5f3dc224';

/// See also [WithdrawalNotifier].
@ProviderFor(WithdrawalNotifier)
final withdrawalNotifierProvider =
    AutoDisposeAsyncNotifierProvider<WithdrawalNotifier, void>.internal(
  WithdrawalNotifier.new,
  name: r'withdrawalNotifierProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$withdrawalNotifierHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$WithdrawalNotifier = AutoDisposeAsyncNotifier<void>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
