import 'package:flutter/material.dart';

/// Helper class for converting icon code points to const IconData instances
/// This allows Flutter to tree-shake unused icons
class IconHelper {
  IconHelper._();

  /// Default icon to use when code point is not found or invalid
  static const IconData defaultIcon = Icons.account_balance_wallet;

  /// Map of common icon code points to their const IconData
  static const Map<int, IconData> _iconMap = {
    // Finance & Money
    0xe047: Icons.account_balance_wallet,
    0xe0af: Icons.account_balance,
    0xe84f: Icons.credit_card,
    0xe8a6: Icons.money,
    0xf05d7: Icons.wallet,
    0xe227: Icons.savings,
    0xe850: Icons.credit_score,
    0xe263: Icons.attach_money,
    0xe8d1: Icons.payment,
    0xf04e9: Icons.currency_exchange,
    0xf04ea: Icons.price_check,
    0xf04eb: Icons.receipt_long,
    0xf04ec: Icons.point_of_sale,
    0xe0c8: Icons.local_atm,

    // Shopping
    0xe536: Icons.shopping_cart,
    0xe54e: Icons.shopping_bag,
    0xe59c: Icons.store,
    0xe0c6: Icons.local_offer,
    0xf0507: Icons.sell,
    0xe161: Icons.redeem,
    0xe0b7: Icons.card_giftcard,
    0xe533: Icons.local_mall,

    // Food & Dining
    0xe1bc: Icons.restaurant,
    0xe56c: Icons.fastfood,
    0xe531: Icons.local_cafe,
    0xe530: Icons.local_bar,
    0xe532: Icons.local_dining,
    0xef6f: Icons.coffee,
    0xf0533: Icons.ramen_dining,
    0xf0534: Icons.lunch_dining,
    0xf0535: Icons.brunch_dining,
    0xf0536: Icons.breakfast_dining,
    0xf0537: Icons.dinner_dining,

    // Transport
    0xe557: Icons.directions_car,
    0xe1c4: Icons.directions_bus,
    0xe1c3: Icons.directions_subway,
    0xe63d: Icons.flight,
    0xe53b: Icons.local_taxi,
    0xef4d: Icons.two_wheeler,
    0xef11: Icons.pedal_bike,
    0xe558: Icons.local_shipping,
    0xef3b: Icons.electric_car,

    // Health & Medical
    0xe87c: Icons.medical_services,
    0xe195: Icons.local_hospital,
    0xe1c1: Icons.local_pharmacy,
    0xe3be: Icons.fitness_center,
    0xe1e0: Icons.spa,
    0xf0622: Icons.self_improvement,
    0xf05c3: Icons.psychology,
    0xf059e: Icons.vaccines,
    0xf0453: Icons.health_and_safety,

    // Home & Living
    0xe88a: Icons.home,
    0xe068: Icons.apartment,
    0xf04c5: Icons.cottage,
    0xe43c: Icons.weekend,
    0xe1fa: Icons.bed,
    0xe1f2: Icons.bathtub,
    0xe56d: Icons.kitchen,
    0xef12: Icons.chair,
    0xe3f0: Icons.light,
    0xe86e: Icons.construction,

    // Technology
    0xe8b8: Icons.phone_android,
    0xe30a: Icons.laptop,
    0xe1b1: Icons.devices,
    0xe1db: Icons.headphones,
    0xe3af: Icons.camera_alt,
    0xe30d: Icons.computer,
    0xe334: Icons.watch,
    0xe32f: Icons.tablet_android,
    0xf06a4: Icons.smart_toy,

    // Entertainment
    0xe40b: Icons.theaters,
    0xe404: Icons.movie,
    0xe405: Icons.music_note,
    0xe039: Icons.sports_esports,
    0xe114: Icons.casino,
    0xe1d7: Icons.local_activity,
    0xef5b: Icons.celebration,
    0xe40a: Icons.palette,
    0xef43: Icons.sports,

    // Education
    0xe8a1: Icons.school,
    0xe865: Icons.book,
    0xe3f4: Icons.menu_book,
    0xef52: Icons.auto_stories,
    0xe8b0: Icons.science,
    0xea16: Icons.calculate,
    0xea3b: Icons.architecture,
    0xea3d: Icons.engineering,

    // Travel
    0xe577: Icons.hotel,
    0xf04fc: Icons.luggage,
    0xf04b7: Icons.travel_explore,
    0xe1c0: Icons.beach_access,
    0xe3f7: Icons.landscape,
    0xef75: Icons.hiking,
    0xe3ff: Icons.terrain,
    0xef62: Icons.festival,

    // Work & Business
    0xe7f4: Icons.work,
    0xe0d4: Icons.business,
    0xe0d8: Icons.business_center,
    0xea36: Icons.factory,
    0xe7fd: Icons.manage_accounts,

    // Symbols & Goals
    0xe153: Icons.flag,
    0xe80e: Icons.emoji_events,
    0xe83e: Icons.grade,
    0xe838: Icons.stars,
    0xe8e4: Icons.military_tech,
    0xe87e: Icons.workspace_premium,
    0xe1af: Icons.trending_up,
    0xe1b0: Icons.trending_down,
    0xe8f5: Icons.show_chart,
    0xe8f4: Icons.pie_chart,
    0xe26b: Icons.bar_chart,
  };

  /// Get IconData from string code point
  static IconData fromString(String? codePointString) {
    if (codePointString == null || codePointString.isEmpty) {
      return defaultIcon;
    }
    try {
      final codePoint = int.parse(codePointString);
      return fromCodePoint(codePoint);
    } catch (e) {
      return defaultIcon;
    }
  }

  /// Get IconData from int code point
  static IconData fromCodePoint(int codePoint) {
    return _iconMap[codePoint] ?? Icons.category_outlined;
  }

  /// Convert IconData to string code point for storage
  static String toCodePointString(IconData iconData) {
    return iconData.codePoint.toString();
  }

  /// Get list of available icons for selection.
  /// Returns list of (iconData, name, category) tuples.
  static List<(IconData, String, String)> getAvailableIcons() {
    return [
      // Finance & Money
      (Icons.account_balance_wallet, 'Wallet', 'Finance'),
      (Icons.account_balance, 'Bank', 'Finance'),
      (Icons.credit_card, 'Credit Card', 'Finance'),
      (Icons.money, 'Money', 'Finance'),
      (Icons.savings, 'Savings', 'Finance'),
      (Icons.payment, 'Payment', 'Finance'),
      (Icons.attach_money, 'Attach Money', 'Finance'),
      (Icons.credit_score, 'Credit Score', 'Finance'),
      (Icons.currency_exchange, 'Currency Exchange', 'Finance'),
      (Icons.price_check, 'Price Check', 'Finance'),
      (Icons.receipt_long, 'Receipt', 'Finance'),
      (Icons.point_of_sale, 'Point of Sale', 'Finance'),
      (Icons.local_atm, 'ATM', 'Finance'),

      // Shopping
      (Icons.shopping_cart, 'Shopping Cart', 'Shopping'),
      (Icons.shopping_bag, 'Shopping Bag', 'Shopping'),
      (Icons.store, 'Store', 'Shopping'),
      (Icons.local_offer, 'Offer', 'Shopping'),
      (Icons.sell, 'Sell', 'Shopping'),
      (Icons.redeem, 'Redeem', 'Shopping'),
      (Icons.card_giftcard, 'Gift Card', 'Shopping'),
      (Icons.local_mall, 'Mall', 'Shopping'),

      // Food & Dining
      (Icons.restaurant, 'Restaurant', 'Food'),
      (Icons.fastfood, 'Fast Food', 'Food'),
      (Icons.local_cafe, 'Cafe', 'Food'),
      (Icons.local_bar, 'Bar', 'Food'),
      (Icons.local_dining, 'Dining', 'Food'),
      (Icons.coffee, 'Coffee', 'Food'),
      (Icons.ramen_dining, 'Ramen', 'Food'),
      (Icons.lunch_dining, 'Lunch', 'Food'),
      (Icons.brunch_dining, 'Brunch', 'Food'),
      (Icons.breakfast_dining, 'Breakfast', 'Food'),
      (Icons.dinner_dining, 'Dinner', 'Food'),

      // Transport
      (Icons.directions_car, 'Car', 'Transport'),
      (Icons.directions_bus, 'Bus', 'Transport'),
      (Icons.directions_subway, 'Subway', 'Transport'),
      (Icons.flight, 'Flight', 'Transport'),
      (Icons.local_taxi, 'Taxi', 'Transport'),
      (Icons.two_wheeler, 'Motorcycle', 'Transport'),
      (Icons.pedal_bike, 'Bicycle', 'Transport'),
      (Icons.local_shipping, 'Shipping', 'Transport'),
      (Icons.electric_car, 'Electric Car', 'Transport'),

      // Health & Medical
      (Icons.medical_services, 'Medical', 'Health'),
      (Icons.local_hospital, 'Hospital', 'Health'),
      (Icons.local_pharmacy, 'Pharmacy', 'Health'),
      (Icons.fitness_center, 'Fitness', 'Health'),
      (Icons.spa, 'Spa', 'Health'),
      (Icons.self_improvement, 'Wellness', 'Health'),
      (Icons.psychology, 'Psychology', 'Health'),
      (Icons.vaccines, 'Vaccines', 'Health'),
      (Icons.health_and_safety, 'Health & Safety', 'Health'),

      // Home & Living
      (Icons.home, 'Home', 'Home'),
      (Icons.apartment, 'Apartment', 'Home'),
      (Icons.cottage, 'Cottage', 'Home'),
      (Icons.weekend, 'Weekend', 'Home'),
      (Icons.bed, 'Bed', 'Home'),
      (Icons.bathtub, 'Bathroom', 'Home'),
      (Icons.kitchen, 'Kitchen', 'Home'),
      (Icons.chair, 'Furniture', 'Home'),
      (Icons.light, 'Lighting', 'Home'),
      (Icons.construction, 'Construction', 'Home'),

      // Technology
      (Icons.phone_android, 'Phone', 'Technology'),
      (Icons.laptop, 'Laptop', 'Technology'),
      (Icons.devices, 'Devices', 'Technology'),
      (Icons.headphones, 'Headphones', 'Technology'),
      (Icons.camera_alt, 'Camera', 'Technology'),
      (Icons.computer, 'Computer', 'Technology'),
      (Icons.watch, 'Watch', 'Technology'),
      (Icons.tablet_android, 'Tablet', 'Technology'),
      (Icons.smart_toy, 'Smart Toy', 'Technology'),

      // Entertainment
      (Icons.theaters, 'Theaters', 'Entertainment'),
      (Icons.movie, 'Movie', 'Entertainment'),
      (Icons.music_note, 'Music', 'Entertainment'),
      (Icons.sports_esports, 'Gaming', 'Entertainment'),
      (Icons.casino, 'Casino', 'Entertainment'),
      (Icons.local_activity, 'Activity', 'Entertainment'),
      (Icons.celebration, 'Celebration', 'Entertainment'),
      (Icons.palette, 'Arts', 'Entertainment'),
      (Icons.sports, 'Sports', 'Entertainment'),

      // Education
      (Icons.school, 'School', 'Education'),
      (Icons.book, 'Book', 'Education'),
      (Icons.menu_book, 'Menu Book', 'Education'),
      (Icons.auto_stories, 'Stories', 'Education'),
      (Icons.science, 'Science', 'Education'),
      (Icons.calculate, 'Calculate', 'Education'),
      (Icons.architecture, 'Architecture', 'Education'),
      (Icons.engineering, 'Engineering', 'Education'),

      // Travel
      (Icons.hotel, 'Hotel', 'Travel'),
      (Icons.luggage, 'Luggage', 'Travel'),
      (Icons.travel_explore, 'Travel', 'Travel'),
      (Icons.beach_access, 'Beach', 'Travel'),
      (Icons.landscape, 'Landscape', 'Travel'),
      (Icons.hiking, 'Hiking', 'Travel'),
      (Icons.terrain, 'Terrain', 'Travel'),
      (Icons.festival, 'Festival', 'Travel'),

      // Work & Business
      (Icons.work, 'Work', 'Work'),
      (Icons.business, 'Business', 'Work'),
      (Icons.business_center, 'Business Center', 'Work'),
      (Icons.factory, 'Factory', 'Work'),
      (Icons.engineering, 'Engineering', 'Work'),
      (Icons.manage_accounts, 'Manage Accounts', 'Work'),

      // Symbols & Goals
      (Icons.flag, 'Flag', 'Goals'),
      (Icons.emoji_events, 'Trophy', 'Goals'),
      (Icons.grade, 'Grade', 'Goals'),
      (Icons.stars, 'Stars', 'Goals'),
      (Icons.military_tech, 'Medal', 'Goals'),
      (Icons.workspace_premium, 'Premium', 'Goals'),
      (Icons.trending_up, 'Trending Up', 'Goals'),
      (Icons.trending_down, 'Trending Down', 'Goals'),
      (Icons.show_chart, 'Show Chart', 'Goals'),
      (Icons.pie_chart, 'Pie Chart', 'Goals'),
      (Icons.bar_chart, 'Bar Chart', 'Goals'),
    ];
  }
}
