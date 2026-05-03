import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pink_diary_calendar/config/app_info.dart';
import 'package:pink_diary_calendar/config/legal_links.dart' as legal;
import 'package:pink_diary_calendar/pages/home_shell_page.dart';
import 'package:pink_diary_calendar/services/local_storage_service.dart';
import 'package:pink_diary_calendar/services/notification_service.dart';
import 'package:pink_diary_calendar/theme/app_colors.dart';
import 'package:pink_diary_calendar/widgets/warm_card.dart';
import 'package:pink_diary_calendar/widgets/warm_page_scaffold.dart';

class LegalGatePage extends StatefulWidget {
  const LegalGatePage({super.key});

  @override
  State<LegalGatePage> createState() => _LegalGatePageState();
}

class _LegalGatePageState extends State<LegalGatePage> {
  final LocalStorageService _storageService = const LocalStorageService();

  bool? _hasValidAgreement;

  @override
  void initState() {
    super.initState();
    _checkLegalAgreement();
  }

  Future<void> _checkLegalAgreement() async {
    final hasValidAgreement = await _storageService.hasValidLegalAgreement(
      termsVersion: legal.termsVersion,
      privacyVersion: legal.privacyVersion,
    );

    if (hasValidAgreement) {
      await _initializeAfterAgreement();
    }

    if (!mounted) {
      return;
    }
    setState(() => _hasValidAgreement = hasValidAgreement);
  }

  Future<void> _initializeAfterAgreement() async {
    try {
      await NotificationService.instance.initialize();
      await NotificationService.instance.rescheduleAnniversaryNotifications();
    } catch (error, stackTrace) {
      debugPrint('Post-agreement notification init failed: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  Future<void> _handleAgreed() async {
    await _initializeAfterAgreement();
    if (!mounted) {
      return;
    }
    setState(() => _hasValidAgreement = true);
  }

  @override
  Widget build(BuildContext context) {
    final hasValidAgreement = _hasValidAgreement;
    if (hasValidAgreement == null) {
      return const _LegalLoadingPage();
    }

    if (!hasValidAgreement) {
      return LegalConsentPage(
        storageService: _storageService,
        onAgreed: _handleAgreed,
      );
    }

    return const HomeShellPage();
  }
}

class LegalConsentPage extends StatefulWidget {
  const LegalConsentPage({
    required this.onAgreed,
    this.storageService = const LocalStorageService(),
    super.key,
  });

  final LocalStorageService storageService;
  final Future<void> Function() onAgreed;

  @override
  State<LegalConsentPage> createState() => _LegalConsentPageState();
}

class _LegalConsentPageState extends State<LegalConsentPage> {
  final ScrollController _scrollController = ScrollController();
  late final Future<_LegalDocuments> _documentsFuture;

  bool _hasReachedBottom = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _documentsFuture = _loadDocuments();
    _scrollController.addListener(_updateReachBottom);
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_updateReachBottom)
      ..dispose();
    super.dispose();
  }

  Future<_LegalDocuments> _loadDocuments() async {
    final terms = await rootBundle.loadString(legal.termsAssetPath);
    final privacy = await rootBundle.loadString(legal.privacyAssetPath);
    return _LegalDocuments(terms: terms, privacy: privacy);
  }

  void _updateReachBottom() {
    if (!_scrollController.hasClients ||
        !_scrollController.position.hasContentDimensions) {
      return;
    }

    final position = _scrollController.position;
    final reachedBottom = position.pixels >= position.maxScrollExtent - 20;
    if (reachedBottom != _hasReachedBottom) {
      setState(() => _hasReachedBottom = reachedBottom);
    }
  }

  Future<void> _agreeAndContinue() async {
    if (!_hasReachedBottom || _isSaving) {
      return;
    }

    setState(() => _isSaving = true);
    try {
      await widget.storageService.saveLegalAgreement(
        termsVersion: legal.termsVersion,
        privacyVersion: legal.privacyVersion,
      );
      await widget.onAgreed();
    } catch (error, stackTrace) {
      debugPrint('Save legal agreement failed: $error');
      debugPrintStack(stackTrace: stackTrace);
      if (!mounted) {
        return;
      }
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(content: Text('保存同意状态失败，请稍后再试')));
    }
  }

  void _disagree() {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text('需要同意用户协议与隐私政策后才能继续使用${AppInfo.appName}。')),
      );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: WarmPageScaffold(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '欢迎使用${AppInfo.appName}',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: AppColors.ink,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                '欢迎使用${AppInfo.appName}。为了保护你的个人信息和使用权益，请你完整阅读并同意以下《用户协议》和《隐私政策》后继续使用。',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.ink,
                  height: 1.55,
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: FutureBuilder<_LegalDocuments>(
                  future: _documentsFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState != ConnectionState.done) {
                      return const WarmCard(
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }

                    if (snapshot.hasError || !snapshot.hasData) {
                      return WarmCard(
                        child: Text(
                          '协议正文加载失败，请检查 assets/legal 资源是否已注册。',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      );
                    }

                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (mounted) {
                        _updateReachBottom();
                      }
                    });

                    final documents = snapshot.data!;
                    return WarmCard(
                      padding: EdgeInsets.zero,
                      child: Scrollbar(
                        controller: _scrollController,
                        thumbVisibility: true,
                        child: SingleChildScrollView(
                          controller: _scrollController,
                          padding: const EdgeInsets.fromLTRB(18, 18, 18, 22),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const _LegalSectionTitle('用户协议'),
                              _LegalBodyText(documents.terms),
                              const SizedBox(height: 28),
                              const _LegalSectionTitle('隐私政策'),
                              _LegalBodyText(documents.privacy),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              _LegalActionBar(
                canAgree: _hasReachedBottom && !_isSaving,
                isSaving: _isSaving,
                onDisagree: _disagree,
                onAgree: _agreeAndContinue,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LegalLoadingPage extends StatelessWidget {
  const _LegalLoadingPage();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.transparent,
      body: WarmPageScaffold(child: Center(child: CircularProgressIndicator())),
    );
  }
}

class _LegalActionBar extends StatelessWidget {
  const _LegalActionBar({
    required this.canAgree,
    required this.isSaving,
    required this.onDisagree,
    required this.onAgree,
  });

  final bool canAgree;
  final bool isSaving;
  final VoidCallback onDisagree;
  final VoidCallback onAgree;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.only(top: 14, bottom: 14),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: onDisagree,
                child: const Text('不同意'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: ElevatedButton(
                onPressed: canAgree ? onAgree : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: canAgree
                      ? AppColors.roseDeep
                      : AppColors.line,
                  foregroundColor: canAgree ? Colors.white : AppColors.muted,
                ),
                child: Text(isSaving ? '正在保存' : '同意并继续'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LegalSectionTitle extends StatelessWidget {
  const _LegalSectionTitle(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleLarge?.copyWith(
        color: AppColors.roseDeep,
        fontWeight: FontWeight.w900,
      ),
    );
  }
}

class _LegalBodyText extends StatelessWidget {
  const _LegalBodyText(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return SelectableText(
      text,
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
        color: AppColors.ink,
        height: 1.68,
        fontSize: 15,
      ),
    );
  }
}

class _LegalDocuments {
  const _LegalDocuments({required this.terms, required this.privacy});

  final String terms;
  final String privacy;
}
