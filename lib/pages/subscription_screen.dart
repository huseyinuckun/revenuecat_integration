// ignore_for_file: use_build_context_synchronously
import 'package:flutter/material.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:purchases_ui_flutter/purchases_ui_flutter.dart';
import 'package:revenue_cat_integration/configs/subscription_screen_ui_config.dart';
import 'package:revenue_cat_integration/models/lottie_widget_config.dart';
import 'package:revenue_cat_integration/models/revenue_cat_integration_theme.dart';
import 'package:revenue_cat_integration/util/extensions.dart';
import 'package:revenue_cat_integration/widgets/feature_item.dart';

import '../service/revenue_cat_integration_service.dart';
import '../widgets/lottie_widget.dart';

const Color _kColor = Color(0xA0B71C1C);

class SubscriptionScreen extends StatefulWidget {
  final SubscriptionScreenUiConfig? uiConfig;
  final RevenueCatIntegrationTheme? theme;
  const SubscriptionScreen({super.key, this.uiConfig, this.theme});

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  Package? selectedPackage;
  List<Package> packages = [];
  bool isLoading = true;
  bool isError = false;
  ValueNotifier<bool> isBeingPurchased = ValueNotifier(false);
  ValueNotifier<bool> isRestoring = ValueNotifier(false);

  RevenueCatIntegrationTheme? get theme => widget.theme;
  RevenueCatIntegrationService get service => RevenueCatIntegrationService.instance;
  SubscriptionScreenUiConfig get uiConfig =>
      widget.uiConfig ??
      SubscriptionScreenUiConfig(
        features: [
          const FeatureItem(title: "Unlimited access to all features", icon: Icon(Icons.check_circle)),
          const FeatureItem(title: "Ad-free use", icon: Icon(Icons.block)),
          const FeatureItem(title: "New features", icon: Icon(Icons.update)),
        ],
      );

  @override
  void initState() {
    _animationController = AnimationController(vsync: this);
    super.initState();
    fetchPackages();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> fetchPackages() async {
    try {
      final List<Package>? packages = await service.getPackages();
      if (packages != null) {
        this.packages = [...packages]..sort((a, b) => b.packageType.index.compareTo(a.packageType.index));
        var unsubscribedPackages = this.packages.where((package) => !service.activeSubscriptions.contains(package.storeProduct.identifier)).toList();
        selectedPackage = unsubscribedPackages.firstWhereOrNull((package) => package.packageType == PackageType.annual) ?? unsubscribedPackages.firstOrNull;
      }
      isError = packages.isNull || packages!.isEmpty;
    } catch (e) {
      isError = true;
      debugPrint(e.toString());
    } finally {
      isLoading = false;
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    var size = MediaQuery.sizeOf(context);
    var lottieAsset = context.isDarkTheme ? "subscription_bg_dark_animation.json" : "subscription_bg_light_animation.json";

    return Scaffold(
      backgroundColor: theme?.backgroundColor,
      body: SafeArea(
        child: Container(
          color: Colors.transparent,
          constraints: const BoxConstraints.expand(),
          child: Stack(
            children: [
              if (uiConfig.backgroundBuilder != null) uiConfig.backgroundBuilder!(context, size.height, size.width),
              if (uiConfig.backgroundBuilder == null) ...[
                Positioned(
                  top: 20,
                  left: 0,
                  child: Opacity(
                    opacity: 0.3,
                    child: LottieWidget(
                      config: LottieWidgetConfig(asset: 'assets/animations/$lottieAsset', package: "revenue_cat_integration", repeat: true, size: const Size(300, 300)),
                    ),
                  ),
                ),
                Positioned(
                  bottom: -20,
                  right: 0,
                  child: Transform.rotate(
                    angle: 3.14,
                    child: Opacity(
                      opacity: 0.3,
                      child: LottieWidget(
                        config: LottieWidgetConfig(asset: 'assets/animations/$lottieAsset', package: "revenue_cat_integration", repeat: true, size: const Size(300, 300)),
                      ),
                    ),
                  ),
                ),
              ],
              if (uiConfig.foregroundBuilder.isNull) ...[
                SingleChildScrollView(
                  physics: const BouncingScrollPhysics(
                    parent: AlwaysScrollableScrollPhysics(),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Center(
                          child: LottieWidget(
                            config: LottieWidgetConfig(asset: 'assets/animations/premium.json', package: "revenue_cat_integration", repeat: true, size: const Size(250, 250)),
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          uiConfig.title,
                          style: context.textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme?.titleColor,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          uiConfig.description,
                          style: context.textTheme.bodyLarge?.copyWith(color: theme?.subTitleColor),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 32),
                        _buildFeaturesList(),
                        const SizedBox(height: 32),
                        _buildPackageCards(),
                        const SizedBox(height: 24),
                        _buildSubscribeButton(context),
                        const SizedBox(height: 16),
                        _buildFooter(),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  top: 16,
                  left: 16,
                  child: Container(
                    decoration: BoxDecoration(
                      color: theme?.closeButtonBg,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(40),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                    child: IconButton(
                      icon: Icon(Icons.close, color: theme?.closeButton),
                      onPressed: () => context.pop(PaywallResult.cancelled),
                    ),
                  ),
                ),
              ] else
                uiConfig.foregroundBuilder!(context, packages, isError, isLoading)
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPackageCards() {
    if (isError) {
      return Card(
        elevation: 0,
        color: theme?.errorColor?.withAlpha(25),
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Center(
            child: Column(
              children: [
                Icon(Icons.warning_amber_rounded, color: theme?.errorColor, size: 50),
                Text(
                  uiConfig.packagesLoadingErrorText,
                  style: TextStyle(color: theme?.errorColor),
                ),
              ],
            ),
          ),
        ),
      );
    }
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }
    return Column(
      children: packages.map((package) {
        var isDisabled = service.activeSubscriptions.contains(package.storeProduct.identifier);
        final isSelected = selectedPackage == package;
        final bool isPopular = service.isPopular(package);
        final (int?, PeriodUnit)? trialDays = service.getTrialDays(package);
        final int? savePercentage = service.getSavePercentage(package, packages);
        final Widget child = Banner(
          color: isPopular ? theme?.popularBadgeBg ?? _kColor : Colors.transparent,
          textStyle: TextStyle(color: theme?.popularBadgeText, fontSize: 12),
          message: isPopular ? uiConfig.popularBadgeText : "",
          location: BannerLocation.topEnd,
          shadow: BoxShadow(
            color: isPopular ? Colors.black.withAlpha(100) : Colors.black.withAlpha(0),
            blurRadius: 2,
            offset: const Offset(0, 2),
          ),
          child: Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.only(bottom: 16, left: 16, right: 32, top: 16),
            decoration: BoxDecoration(
              color: isSelected ? theme?.packageSelectedBg : theme?.packageUnselectedBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected ? theme?.packageBorderColor ?? Colors.white : Colors.transparent,
                width: 2,
              ),
            ),
            child: Row(
              children: [
                if (!isDisabled)
                  Radio(
                    activeColor: theme?.packageRadioColor,
                    value: package,
                    groupValue: selectedPackage,
                    onChanged: (Package? value) {
                      setState(() => selectedPackage = value);
                    },
                  ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _getPackageTitle(package),
                        style: context.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme?.packageTextColor,
                        ),
                      ),
                      if (trialDays?.$1 != null)
                        Text(
                          uiConfig.editingTrialDaysText(trialDays!.$1!, trialDays.$2),
                          style: TextStyle(
                            color: theme?.trialText,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                    ],
                  ),
                ),
                if (isDisabled)
                  Card(
                    elevation: 0,
                    color: theme?.popularBadgeBg,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      child: Text(
                        uiConfig.activePackageText,
                        style: TextStyle(color: theme?.popularBadgeText),
                      ),
                    ),
                  )
                else
                  Text(
                    package.storeProduct.priceString,
                    style: TextStyle(
                      fontSize: 24,
                      color: theme?.packageTextColor,
                    ),
                  ),
              ],
            ),
          ),
        );
        return GestureDetector(
          onTap: isDisabled ? null : () => setState(() => selectedPackage = package),
          child: Badge(
              label: savePercentage != null ? Text(uiConfig.editingSavePercentageText(savePercentage)) : null,
              backgroundColor: savePercentage != null ? theme?.popularBadgeBg : null,
              textColor: theme?.popularBadgeText,
              isLabelVisible: savePercentage != null,
              alignment: Alignment.topLeft,
              offset: const Offset(18, -8),
              child: ClipRRect(clipBehavior: Clip.hardEdge, child: child)),
        );
      }).toList(),
    );
  }

  Widget _buildFeaturesList() {
    if (uiConfig.features.isEmpty) return const SizedBox();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          uiConfig.includesTitle,
          style: context.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: theme?.titleColor),
        ),
        const SizedBox(height: 16),
        ...uiConfig.features,
      ],
    );
  }

  Widget _buildSubscribeButton(BuildContext context) {
    String getButtonTitle() {
      if (selectedPackage == null) return uiConfig.purchaseButtonTitle;
      if (service.isPremium.value) return uiConfig.upgradeButtonTitle;
      if (selectedPackage!.storeProduct.defaultOption.isNotNull && !selectedPackage!.storeProduct.defaultOption!.isBasePlan) return uiConfig.specialOfferTitle;
      return uiConfig.purchaseButtonTitle;
    }

    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ValueListenableBuilder(
          valueListenable: isBeingPurchased,
          builder: (context, value, _) {
            return AnimatedOpacity(
              duration: const Duration(milliseconds: 300),
              opacity: value ? .4 : 1,
              child: ElevatedButton(
                onPressed: selectedPackage == null
                    ? null
                    : () async {
                        if (value) return;
                        try {
                          isBeingPurchased.value = true;
                          PaywallResult result = service.isPremium.value ? await service.upgradePackage(selectedPackage!) : await service.purchase(selectedPackage!);
                          if (!context.mounted || result == PaywallResult.cancelled) return;
                          context.pop(result);
                        } catch (e) {
                          context.pop(PaywallResult.error);
                        } finally {
                          isBeingPurchased.value = false;
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme?.purchaseButtonColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: value
                    ? SizedBox.square(dimension: 25, child: CircularProgressIndicator(strokeCap: StrokeCap.round, color: theme?.purchaseButtonColor))
                    : Text(getButtonTitle(), style: context.textTheme.titleSmall!.copyWith(color: theme?.purchaseButtonTextColor)),
              ),
            );
          }),
    );
  }

  Widget _buildFooter() {
    return ValueListenableBuilder(
      valueListenable: isRestoring,
      builder: (context, value, _) {
        return TextButton(
          onPressed: () async {
            if (value) return;
            try {
              isRestoring.value = true;
              var result = await service.restore();
              isRestoring.value = false;
              if (result) {
                context.pop(PaywallResult.restored);
              }
            } catch (e) {
              context.pop(PaywallResult.error);
            } finally {
              isRestoring.value = false;
            }
          },
          child: value
              ? SizedBox.square(dimension: 25, child: CircularProgressIndicator(strokeCap: StrokeCap.round, color: theme?.purchaseButtonColor))
              : Text(
                  uiConfig.restorePurchases,
                  style: context.textTheme.bodyMedium?.copyWith(color: theme?.subTitleColor),
                ),
        );
      },
    );
  }

  String _getPackageTitle(Package package) {
    switch (package.packageType) {
      case PackageType.unknown:
        return uiConfig.packagesTextConfig.unknowPackageText;
      case PackageType.custom:
        return uiConfig.packagesTextConfig.customPackageText;
      case PackageType.lifetime:
        return uiConfig.packagesTextConfig.lifetimePackageText;
      case PackageType.annual:
        return uiConfig.packagesTextConfig.annualPackageText;
      case PackageType.sixMonth:
        return uiConfig.packagesTextConfig.sixMonthPackageText;
      case PackageType.threeMonth:
        return uiConfig.packagesTextConfig.threeMonthPackageText;
      case PackageType.twoMonth:
        return uiConfig.packagesTextConfig.twoMonthPackageText;
      case PackageType.monthly:
        return uiConfig.packagesTextConfig.monthlyPackageText;
      case PackageType.weekly:
        return uiConfig.packagesTextConfig.weeklyPackageText;
    }
  }
}
