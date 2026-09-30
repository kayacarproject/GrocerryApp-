import 'package:flutter/material.dart';

import '../../core/config/app_config.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/router/app_routes.dart';
import '../../core/utils/launcher.dart';
import '../../models/payment.dart';
import '../../widgets/common/app_card.dart';
import '../../widgets/order/payment_method_style.dart';

/// Static informational pages: help, payments, privacy, terms, about.
class InfoScreen extends StatelessWidget {
  const InfoScreen({super.key, required this.page});

  final InfoPage page;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(page.title)),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: switch (page) {
          InfoPage.help => _help(context),
          InfoPage.payments => _payments(),
          InfoPage.privacy => _document(_privacySections),
          InfoPage.terms => _document(_termsSections),
          InfoPage.about => _document(_aboutSections),
        },
      ),
    );
  }

  List<Widget> _help(BuildContext context) => [
    AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('We\'re here to help', style: AppTextStyles.h3),
          AppSpacing.gapXs,
          Text('Our support team is available 7 AM – 11 PM, every day.', style: AppTextStyles.bodySmall),
          AppSpacing.gapLg,
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => Launcher.call(context, AppConfig.supportPhone),
                  icon: const Icon(Icons.call_outlined),
                  label: const Text('Call us'),
                ),
              ),
              AppSpacing.gapMd,
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => Launcher.email(
                    context,
                    AppConfig.supportEmail,
                    subject: '${AppConfig.appName} support',
                  ),
                  icon: const Icon(Icons.mail_outline_rounded),
                  label: const Text('Email'),
                ),
              ),
            ],
          ),
        ],
      ),
    ),
    AppSpacing.gapXl,
    Text('Frequently asked questions', style: AppTextStyles.title),
    AppSpacing.gapSm,
    for (final (question, answer) in _faqs)
      Card(
        margin: const EdgeInsets.only(bottom: AppSpacing.sm),
        clipBehavior: Clip.antiAlias,
        child: ExpansionTile(
          title: Text(question, style: AppTextStyles.label),
          childrenPadding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.lg),
          expandedCrossAxisAlignment: CrossAxisAlignment.start,
          shape: const Border(),
          children: [
            Text(answer, style: AppTextStyles.body.copyWith(color: AppColors.textSecondary)),
          ],
        ),
      ),
  ];

  List<Widget> _payments() => [
    Text('Supported payment methods', style: AppTextStyles.title),
    AppSpacing.gapMd,
    for (final method in PaymentMethod.available) ...[
      AppCard(
        child: Row(
          children: [
            Icon(method.icon, color: AppColors.primary),
            AppSpacing.gapMd,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(method.label, style: AppTextStyles.label),
                  Text(method.hint, style: AppTextStyles.bodySmall),
                ],
              ),
            ),
          ],
        ),
      ),
      AppSpacing.gapSm,
    ],
    AppSpacing.gapLg,
    AppCard(
      color: AppColors.infoLight,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.lock_outline_rounded, color: AppColors.info),
          AppSpacing.gapMd,
          Expanded(
            child: Text(
              'For your security we never store card numbers, CVVs or UPI PINs. '
              'All online payments are processed by a PCI-DSS compliant payment partner.',
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.textPrimary),
            ),
          ),
        ],
      ),
    ),
  ];

  List<Widget> _document(List<(String, String)> sections) => [
    Text('Last updated: 1 September 2026', style: AppTextStyles.caption),
    AppSpacing.gapLg,
    for (final (heading, body) in sections) ...[
      Text(heading, style: AppTextStyles.title),
      AppSpacing.gapSm,
      Text(body, style: AppTextStyles.body.copyWith(color: AppColors.textSecondary)),
      AppSpacing.gapXl,
    ],
  ];

  static const _faqs = [
    (
      'How fast is delivery?',
      'Express orders typically arrive in 10–15 minutes. You can also choose a scheduled slot at checkout.',
    ),
    (
      'Is there a minimum order value?',
      'No. Orders above ₹199 get free delivery; a small delivery fee applies below that.',
    ),
    (
      'How do I cancel an order?',
      'Open the order from My Orders and tap Cancel. Orders can be cancelled until they are being prepared.',
    ),
    (
      'When will I get my refund?',
      'Refunds for cancelled prepaid orders reach the original payment method within 5–7 business days.',
    ),
    (
      'What if an item is damaged or missing?',
      'Contact support from this page within 48 hours of delivery and we\'ll make it right.',
    ),
  ];

  static const _privacySections = [
    (
      'What we collect',
      'We collect the information you provide — your name, email, phone number and delivery addresses — '
          'plus order history needed to deliver and support your orders.',
    ),
    (
      'How we use it',
      'Your data is used to process orders, deliver groceries, provide support and, with your consent, '
          'send offers. We never sell your personal information.',
    ),
    (
      'Payments',
      'Payment details are handled by our certified payment partner. We do not store card numbers or PINs.',
    ),
    (
      'Your choices',
      AppConfig.notificationsEnabled
          ? 'You can update your profile, manage notification preferences in Settings, or contact us to delete your account.'
          : 'You can update your profile in Settings, or contact us to delete your account.',
    ),
  ];

  static const _termsSections = [
    (
      'Using Basketly',
      'By creating an account you agree to provide accurate information and to use the service for personal, non-commercial purposes.',
    ),
    (
      'Pricing & availability',
      'Prices and stock are confirmed at the time your order is placed. If an item becomes unavailable we will refund it.',
    ),
    (
      'Cancellations & refunds',
      'Orders may be cancelled before they are prepared. Refunds are issued to the original payment method.',
    ),
    (
      'Liability',
      'We take care to deliver quality products. Report any issue within 48 hours of delivery.',
    ),
  ];

  static const _aboutSections = [
    (
      'Our story',
      'Basketly brings fresh groceries and daily essentials from trusted local stores to your door in minutes.',
    ),
  ];
}
