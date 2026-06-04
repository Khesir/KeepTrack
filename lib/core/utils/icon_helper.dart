import 'package:flutter/material.dart';

class IconHelper {
  IconHelper._();

  static const IconData defaultIcon = Icons.account_balance_wallet;

  static Map<int, IconData>? _reverseMap;

  static Map<int, IconData> get _iconMap {
    if (_reverseMap != null) return _reverseMap!;
    _reverseMap = {};
    for (final entry in getAvailableIcons()) {
      _reverseMap![entry.$1.codePoint] = entry.$1;
    }
    return _reverseMap!;
  }

  static IconData fromString(String? codePointString) {
    if (codePointString == null || codePointString.isEmpty) return defaultIcon;
    try {
      final codePoint = int.parse(codePointString);
      return _iconMap[codePoint] ?? defaultIcon;
    } catch (_) {
      return defaultIcon;
    }
  }

  static String toCodePointString(IconData iconData) {
    return iconData.codePoint.toString();
  }

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
