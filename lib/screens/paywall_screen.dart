import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import '../core/providers.dart';
import '../l10n/app_localizations.dart';

class PaywallScreen extends ConsumerStatefulWidget {
  const PaywallScreen({super.key});
  @override
  ConsumerState<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends ConsumerState<PaywallScreen> {
  ProductDetails? _product;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final ProductDetails? p = await ref.read(iapServiceProvider).loadProduct();
    if (mounted) setState(() { _product = p; _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations t = AppLocalizations.of(context);
    final String price = _product?.price ?? '\$3.99';
    return Scaffold(
      appBar: AppBar(leading: const CloseButton()),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              const Spacer(),
              Icon(Icons.phone_in_talk, size: 80, color: Theme.of(context).colorScheme.primary),
              const SizedBox(height: 24),
              Text(t.callIsolation,
                  style: Theme.of(context).textTheme.headlineMedium,
                  textAlign: TextAlign.center),
              const SizedBox(height: 12),
              Text(t.callIsolationDesc,
                  style: Theme.of(context).textTheme.bodyLarge,
                  textAlign: TextAlign.center),
              const Spacer(),
              FilledButton(
                onPressed: _loading ? null : () => ref.read(iapServiceProvider).buy().then((_) {
                  if (mounted) context.pop();
                }),
                child: Text(t.unlock(price)),
              ),
              TextButton(
                onPressed: () => ref.read(iapServiceProvider).restore(),
                child: Text(t.restore),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
