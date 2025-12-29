import 'package:flutter/material.dart';

/// Helper class for converting icon code points to const IconData instances
/// This allows Flutter to tree-shake unused icons
class IconHelper {
  IconHelper._();

  /// Default icon to use when code point is not found or invalid
  static const IconData defaultIcon = Icons.account_balance_wallet;

  /// Map of common icon code points to their const IconData
  /// Add more icons as needed for your application
  static const Map<int, IconData> _iconMap = {
    // Account/Finance related icons
    0xe047: Icons.account_balance_wallet, // account_balance_wallet
    0xe0af: Icons.account_balance, // account_balance
    0xe84f: Icons.credit_card, // credit_card
    0xe8a6: Icons.money, // money
    0xf05d7: Icons.wallet, // wallet
    0xe227: Icons.savings, // savings
    0xe850: Icons.credit_score, // credit_score
    0xe263: Icons.attach_money, // attach_money
    0xe25d: Icons.account_balance_wallet_outlined, // account_balance_wallet_outlined
    0xe8d1: Icons.payment, // payment

    // Goal related icons
    0xe153: Icons.flag, // flag
    0xe80e: Icons.emoji_events, // emoji_events
    0xe83e: Icons.grade, // grade
    0xe8e4: Icons.military_tech, // military_tech
    0xe838: Icons.stars, // stars
    0xe87e: Icons.workspace_premium, // workspace_premium

    // Other common icons
    0xe88a: Icons.home, // home
    0xe7f4: Icons.work, // work
    0xe536: Icons.shopping_cart, // shopping_cart
    0xe532: Icons.local_dining, // local_dining
    0xe531: Icons.local_cafe, // local_cafe
    0xe530: Icons.local_bar, // local_bar
    0xe557: Icons.directions_car, // directions_car
    0xe63d: Icons.flight, // flight
    0xe577: Icons.hotel, // hotel
    0xe8a1: Icons.school, // school
    0xe87c: Icons.medical_services, // medical_services
    0xe3be: Icons.fitness_center, // fitness_center
    0xe039: Icons.sports_esports, // sports_esports
    0xe0b7: Icons.card_giftcard, // card_giftcard
    0xe54e: Icons.shopping_bag, // shopping_bag
    0xe8b8: Icons.phone_android, // phone_android
    0xe30a: Icons.laptop, // laptop
    0xe1b1: Icons.devices, // devices
    0xe1db: Icons.headphones, // headphones
    0xe40b: Icons.theaters, // theaters
    0xe1bc: Icons.restaurant, // restaurant
    0xe56c: Icons.fastfood, // fastfood
    0xe0da: Icons.local_grocery_store, // local_grocery_store
    0xe55f: Icons.local_gas_station, // local_gas_station
    0xe1c4: Icons.directions_bus, // directions_bus
    0xe1c3: Icons.directions_subway, // directions_subway
    0xe195: Icons.local_hospital, // local_hospital
    0xe1c1: Icons.local_pharmacy, // local_pharmacy
    0xe0c8: Icons.local_atm, // local_atm
    0xe0c6: Icons.local_offer, // local_offer
    0xe8f4: Icons.pie_chart, // pie_chart
    0xe1af: Icons.trending_up, // trending_up
    0xe1b0: Icons.trending_down, // trending_down
    0xe8f5: Icons.show_chart, // show_chart
  };

  /// Get IconData from string code point
  /// Returns const IconData if found in map, otherwise returns default icon
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
  /// Returns const IconData if found in map, otherwise returns default icon
  static IconData fromCodePoint(int codePoint) {
    return _iconMap[codePoint] ?? defaultIcon;
  }

  /// Convert IconData to string code point for storage
  static String toCodePointString(IconData iconData) {
    return iconData.codePoint.toString();
  }

  /// Get list of available icons for selection
  /// Returns list of (iconData, name) tuples
  static List<(IconData, String)> getAvailableIcons() {
    return [
      (Icons.account_balance_wallet, 'Wallet'),
      (Icons.account_balance, 'Bank'),
      (Icons.credit_card, 'Credit Card'),
      (Icons.money, 'Cash'),
      (Icons.savings, 'Savings'),
      (Icons.credit_score, 'Credit'),
      (Icons.payment, 'Payment'),
      (Icons.flag, 'Flag'),
      (Icons.emoji_events, 'Trophy'),
      (Icons.grade, 'Star'),
      (Icons.military_tech, 'Medal'),
      (Icons.stars, 'Stars'),
      (Icons.workspace_premium, 'Premium'),
      (Icons.home, 'Home'),
      (Icons.work, 'Work'),
      (Icons.shopping_cart, 'Shopping'),
      (Icons.local_dining, 'Dining'),
      (Icons.local_cafe, 'Cafe'),
      (Icons.local_bar, 'Bar'),
      (Icons.directions_car, 'Car'),
      (Icons.flight, 'Flight'),
      (Icons.hotel, 'Hotel'),
      (Icons.school, 'School'),
      (Icons.medical_services, 'Medical'),
      (Icons.fitness_center, 'Fitness'),
      (Icons.sports_esports, 'Gaming'),
      (Icons.card_giftcard, 'Gift'),
      (Icons.shopping_bag, 'Shopping Bag'),
      (Icons.phone_android, 'Phone'),
      (Icons.laptop, 'Laptop'),
      (Icons.devices, 'Devices'),
      (Icons.headphones, 'Headphones'),
      (Icons.theaters, 'Entertainment'),
      (Icons.restaurant, 'Restaurant'),
      (Icons.fastfood, 'Fast Food'),
      (Icons.local_grocery_store, 'Grocery'),
      (Icons.local_gas_station, 'Gas Station'),
      (Icons.directions_bus, 'Bus'),
      (Icons.directions_subway, 'Subway'),
      (Icons.local_hospital, 'Hospital'),
      (Icons.local_pharmacy, 'Pharmacy'),
      (Icons.local_atm, 'ATM'),
      (Icons.local_offer, 'Offers'),
      (Icons.pie_chart, 'Budget'),
      (Icons.trending_up, 'Growth'),
      (Icons.trending_down, 'Decline'),
      (Icons.show_chart, 'Chart'),
    ];
  }
}
