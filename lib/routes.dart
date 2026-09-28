import 'package:flutter/material.dart';

import 'features/alerts/rate_alert_page.dart';
import 'features/calculators/age_calculator_page.dart';
import 'features/calculators/bmi_calculator_page.dart';
import 'features/calculators/calculator_hub_page.dart';
import 'features/calculators/date_difference_page.dart';
import 'features/calculators/discount_calculator_page.dart';
import 'features/calculators/loan_calculator_page.dart';
import 'features/calculators/percentage_calculator_page.dart';
import 'features/calculators/scientific_calculator_page.dart';
import 'features/converters/converter_hub_page.dart';
import 'features/converters/height_converter_page.dart';
import 'features/converters/number_base_page.dart';
import 'features/currency/converter_page.dart';
import 'features/currency/currency_profile_page.dart';
import 'features/currency/metals_page.dart';
import 'features/currency/multi_currency_page.dart';
import 'features/currency/rate_adjustment_page.dart';
import 'features/currency/rate_list_page.dart';
import 'features/currency/simulation_page.dart';
import 'features/currency/trend_chart_page.dart';
import 'features/settings/about_page.dart';
import 'features/settings/settings_page.dart';
import 'features/settings/theme_page.dart';
import 'features/tools/tip_calculator_page.dart';
import 'features/tools/world_clock_page.dart';
import 'features/travel/travel_budget_page.dart';

/// Every named route in the app.
class Routes {
  const Routes._();

  static const String home = '/';
  static const String multi = '/multi';
  static const String charts = '/charts';
  static const String assets = '/assets';
  static const String rateList = '/rate-list';
  static const String simulation = '/simulation';
  static const String adjustment = '/adjustment';
  static const String alerts = '/alerts';
  static const String travel = '/travel';
  static const String clock = '/clock';
  static const String tip = '/tip';
  static const String profile = '/profile';
  static const String calculators = '/calculators';
  static const String scientific = '/scientific';
  static const String age = '/age';
  static const String dateDiff = '/date-diff';
  static const String discount = '/discount';
  static const String bmi = '/bmi';
  static const String loan = '/loan';
  static const String percentage = '/percentage';
  static const String converters = '/converters';
  static const String height = '/height';
  static const String numberBase = '/number-base';
  static const String settings = '/settings';
  static const String theme = '/theme';
  static const String about = '/about';

  static Map<String, WidgetBuilder> table() => <String, WidgetBuilder>{
        home: (_) => const ConverterPage(),
        multi: (_) => const MultiCurrencyPage(),
        charts: (_) => const TrendChartPage(),
        assets: (_) => const MetalsPage(),
        rateList: (_) => const RateListPage(),
        simulation: (_) => const SimulationPage(),
        adjustment: (_) => const RateAdjustmentPage(),
        alerts: (_) => const RateAlertPage(),
        travel: (_) => const TravelBudgetPage(),
        clock: (_) => const WorldClockPage(),
        tip: (_) => const TipCalculatorPage(),
        profile: (_) => const CurrencyProfilePage(),
        calculators: (_) => const CalculatorHubPage(),
        scientific: (_) => const ScientificCalculatorPage(),
        age: (_) => const AgeCalculatorPage(),
        dateDiff: (_) => const DateDifferencePage(),
        discount: (_) => const DiscountCalculatorPage(),
        bmi: (_) => const BmiCalculatorPage(),
        loan: (_) => const LoanCalculatorPage(),
        percentage: (_) => const PercentageCalculatorPage(),
        converters: (_) => const ConverterHubPage(),
        height: (_) => const HeightConverterPage(),
        numberBase: (_) => const NumberBasePage(),
        settings: (_) => const SettingsPage(),
        theme: (_) => const ThemePage(),
        about: (_) => const AboutPage(),
      };
}
