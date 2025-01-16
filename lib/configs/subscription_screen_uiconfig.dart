import 'package:revenuecat_integration/configs/packages_text_config.dart';
import 'package:revenuecat_integration/util/defines.dart';
import 'package:revenuecat_integration/widgets/feature_item.dart';

class SubscriptionScreenUiconfig {
  String title;
  String description;
  String purchaseButtonTitle;
  String popularBadgeText;
  String includesTitle;
  List<FeatureItem> features;
  PackagesTextConfig packagesTextConfig;
  SubscriptionScreenBackgroundBuilder? backgroundBuilder;
  EditableText editingSavePercentageText;
  EditableText editingTrialDaysText;
  SubscriptionScreenUiconfig({
    this.title = 'Choose a plan',
    this.description = 'Unlock all the features by subscribing to our service',
    this.purchaseButtonTitle = 'Subscribe',
    this.popularBadgeText = 'Popular',
    this.includesTitle = 'Includes',
    this.backgroundBuilder,
    this.editingSavePercentageText = defaultEditingSavePercentageText,
    this.editingTrialDaysText = defaultTrialDaysText,
    this.features = const[],
    PackagesTextConfig? packagesTextConfig,
  }) : packagesTextConfig = packagesTextConfig ?? PackagesTextConfig.defaultConfig();
  
}

String defaultEditingSavePercentageText(int percentage) {
  return 'Save $percentage%';
}
String defaultTrialDaysText(int trialDays) {
  return 'Free $trialDays days trial';
}
