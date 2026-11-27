import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show AuthException;

import '../../../core/sync/sync_import_consent.dart';
import '../domain/auth_repository.dart';
import '../domain/auth_user.dart';
import 'auth_providers.dart';

class AccountScreen extends ConsumerStatefulWidget {
  const AccountScreen({super.key});

  @override
  ConsumerState<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends ConsumerState<AccountScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isSignUp = false;
  bool _isSubmitting = false;
  String? _statusMessage;
  String? _editingConsentForUserId;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final repository = ref.watch(authRepositoryProvider);
    if (repository == null) return _buildLocalOnlyNotice();

    final userAsync = ref.watch(authUserProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Hesap')),
      body: userAsync.when(
        data: (user) => user == null
            ? _buildAuthForm(repository)
            : _buildSignedInView(repository, user),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _buildMessage('Oturum bilgisi alınamadı: $error'),
      ),
    );
  }

  Widget _buildLocalOnlyNotice() {
    return Scaffold(
      appBar: AppBar(title: const Text('Hesap')),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Supabase henüz yapılandırılmadı. Hesap açmadan yerel '
            'harcamalarını kullanmaya devam edebilirsin.',
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }

  Widget _buildAuthForm(AuthRepository repository) {
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(
            _isSignUp ? 'Hesap oluştur' : 'Giriş yap',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          const Text(
            'Hesap isteğe bağlıdır. Giriş yapmadan da yerel '
            'harcamalarını kullanabilirsin.',
          ),
          const SizedBox(height: 24),
          TextFormField(
            key: const Key('auth-email-field'),
            controller: _emailController,
            decoration: const InputDecoration(labelText: 'E-posta'),
            keyboardType: TextInputType.emailAddress,
            autofillHints: const [AutofillHints.email],
            validator: (value) {
              final email = value?.trim() ?? '';
              if (!email.contains('@')) return 'Geçerli bir e-posta gir.';
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            key: const Key('auth-password-field'),
            controller: _passwordController,
            decoration: const InputDecoration(labelText: 'Şifre'),
            obscureText: true,
            autofillHints: [
              _isSignUp ? AutofillHints.newPassword : AutofillHints.password,
            ],
            validator: (value) => value == null || value.isEmpty
                ? 'Şifre alanı zorunludur.'
                : null,
          ),
          if (_statusMessage != null) ...[
            const SizedBox(height: 16),
            Text(
              _statusMessage!,
              key: const Key('auth-status-message'),
              textAlign: TextAlign.center,
            ),
          ],
          const SizedBox(height: 20),
          FilledButton(
            key: const Key('auth-submit-button'),
            onPressed: _isSubmitting ? null : () => _submit(repository),
            child: Text(
              _isSubmitting
                  ? 'İşleniyor...'
                  : _isSignUp
                  ? 'Hesap oluştur'
                  : 'Giriş yap',
            ),
          ),
          TextButton(
            key: const Key('auth-mode-toggle-button'),
            onPressed: _isSubmitting
                ? null
                : () => setState(() {
                    _isSignUp = !_isSignUp;
                    _statusMessage = null;
                  }),
            child: Text(_isSignUp ? 'Zaten hesabım var' : 'Yeni hesap oluştur'),
          ),
        ],
      ),
    );
  }

  Widget _buildSignedInView(AuthRepository repository, AuthUser user) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const Icon(Icons.account_circle_outlined, size: 56),
        const SizedBox(height: 12),
        Center(
          child: Text(
            user.email ?? user.id,
            key: const Key('signed-in-user-email'),
          ),
        ),
        if (_statusMessage != null) ...[
          const SizedBox(height: 12),
          Text(_statusMessage!, textAlign: TextAlign.center),
        ],
        const SizedBox(height: 20),
        _buildSyncImportConsent(
          user.id,
          ref.watch(syncImportConsentProvider(user.id)),
        ),
        const SizedBox(height: 20),
        OutlinedButton(
          key: const Key('auth-sign-out-button'),
          onPressed: _isSubmitting ? null : () => _signOut(repository),
          child: const Text('Çıkış yap'),
        ),
      ],
    );
  }

  Widget _buildSyncImportConsent(
    String userId,
    AsyncValue<SyncImportConsentDecision?> consentAsync,
  ) {
    return consentAsync.when(
      data: (decision) {
        final isEditing =
            decision == null || _editingConsentForUserId == userId;
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Yerel kayıtların için aktarım tercihi',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                if (isEditing) ...[
                  const Text(
                    'İzin verirsen kategorilerin, harcamaların, düzenli '
                    'ödemelerin ve aylık bütçen sonraki aşamada hesabına '
                    'aktarılabilir. Fiş görselleri cihazında kalır. Bu '
                    'tercih ekranında hiçbir veri gönderilmez.',
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    alignment: WrapAlignment.end,
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      TextButton(
                        key: const Key('sync-import-decline-button'),
                        onPressed: _isSubmitting
                            ? null
                            : () => _saveSyncImportDecision(
                                userId,
                                SyncImportConsentDecision.declined,
                              ),
                        child: const Text('İzin verme'),
                      ),
                      FilledButton(
                        key: const Key('sync-import-allow-button'),
                        onPressed: _isSubmitting
                            ? null
                            : () => _saveSyncImportDecision(
                                userId,
                                SyncImportConsentDecision.allowed,
                              ),
                        child: const Text('İzin ver'),
                      ),
                    ],
                  ),
                ] else ...[
                  Text(
                    decision == SyncImportConsentDecision.allowed
                        ? 'Aktarım izni verildi.'
                        : 'Aktarıma izin verilmedi.',
                  ),
                  const SizedBox(height: 4),
                  const Text('Şu anda hiçbir veri gönderilmiyor.'),
                  if (decision == SyncImportConsentDecision.allowed &&
                      ref.watch(categorySyncServiceProvider) != null) ...[
                    const SizedBox(height: 12),
                    FilledButton.icon(
                      key: const Key('sync-categories-button'),
                      onPressed: _isSubmitting
                          ? null
                          : () => _syncCategories(userId),
                      icon: const Icon(Icons.sync),
                      label: const Text('Kategorileri senkronize et'),
                    ),
                  ],
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      key: const Key('sync-import-change-button'),
                      onPressed: _isSubmitting
                          ? null
                          : () => setState(
                              () => _editingConsentForUserId = userId,
                            ),
                      child: const Text('Tercihi değiştir'),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
      loading: () => const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Center(child: CircularProgressIndicator()),
        ),
      ),
      error: (error, _) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Aktarım tercihi okunamadı: $error'),
              TextButton(
                onPressed: () =>
                    ref.invalidate(syncImportConsentProvider(userId)),
                child: const Text('Yeniden dene'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _syncCategories(String userId) async {
    setState(() {
      _isSubmitting = true;
      _statusMessage = null;
    });
    try {
      final service = ref.read(categorySyncServiceProvider);
      if (service == null) {
        throw StateError('Supabase is not configured.');
      }

      final result = await service.syncCategories(userId: userId);
      if (!mounted) return;
      setState(
        () => _statusMessage =
            'Kategoriler eşitlendi: ${result.created} yeni, '
            '${result.merged} eşleşen, ${result.updated} güncellenen, '
            '${result.deleted} silinen.',
      );
    } catch (error) {
      if (mounted) {
        setState(() => _statusMessage = 'Senkronizasyon başarısız: $error');
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _saveSyncImportDecision(
    String userId,
    SyncImportConsentDecision decision,
  ) async {
    setState(() {
      _isSubmitting = true;
      _statusMessage = null;
    });
    try {
      await ref
          .read(syncImportConsentRepositoryProvider)
          .saveDecision(userId, decision);
      if (!mounted) return;
      setState(() => _editingConsentForUserId = null);
      ref.invalidate(syncImportConsentProvider(userId));
    } catch (error) {
      if (mounted) {
        setState(() => _statusMessage = 'Tercih kaydedilemedi: $error');
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Widget _buildMessage(String message) {
    return Scaffold(
      appBar: AppBar(title: const Text('Hesap')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(message, textAlign: TextAlign.center),
        ),
      ),
    );
  }

  Future<void> _submit(AuthRepository repository) async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
      _statusMessage = null;
    });
    try {
      final email = _emailController.text.trim();
      final password = _passwordController.text;
      if (_isSignUp) {
        await repository.signUp(email: email, password: password);
        if (!mounted) return;
        setState(
          () => _statusMessage =
              'Kayıt isteği gönderildi. E-posta doğrulaması istenirse '
              'gelen kutunu kontrol et.',
        );
      } else {
        await repository.signInWithPassword(email: email, password: password);
      }
    } on AuthException catch (error) {
      if (mounted) setState(() => _statusMessage = error.message);
    } catch (error) {
      if (mounted) setState(() => _statusMessage = 'İşlem başarısız: $error');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _signOut(AuthRepository repository) async {
    setState(() {
      _isSubmitting = true;
      _statusMessage = null;
    });
    try {
      await repository.signOut();
    } on AuthException catch (error) {
      if (mounted) setState(() => _statusMessage = error.message);
    } catch (error) {
      if (mounted) setState(() => _statusMessage = 'Çıkış yapılamadı: $error');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }
}
