import 'package:money2/money2.dart';

/// Utility class for working with Money and Currency in the app
///
/// Provides helper methods to get Currency instances from Organisation
/// and create Money objects with the correct currency.
class MoneyHelper {
  /// Get a Currency instance from an ISO code (e.g., 'USD', 'EUR')
  ///
  /// Uses CommonCurrencies if available, otherwise creates a basic currency.
  /// Defaults to USD if the currency code is invalid or not found.
  static Currency getCurrency(String isoCode) {
    try {
      // Try to parse a test amount to get the currency
      final currencies = Currencies();
      final testMoney = currencies.parse('\$${isoCode}1.00');
      return testMoney.currency;
    } catch (e) {
      // If parsing fails, try to find in registered currencies
      try {
        final currencies = Currencies();
        final currency = currencies.find(isoCode);
        if (currency != null) {
          return currency;
        }
        // Fallback to USD if currency not found
        print('Warning: Currency $isoCode not found, defaulting to USD');
        return CommonCurrencies().usd;
      } catch (e) {
        // Fallback to USD if currency not found
        print('Warning: Currency $isoCode not found, defaulting to USD');
        return CommonCurrencies().usd;
      }
    }
  }

  /// Create a Money instance from minor units (e.g., cents)
  ///
  /// Example: createFromMinorUnits(1050, 'USD') = $10.50
  static Money createFromMinorUnits(int minorUnits, String currencyCode) {
    return Money.fromInt(minorUnits, isoCode: currencyCode);
  }

  /// Create a Money instance from a decimal amount (major units)
  ///
  /// Example: createFromAmount(10.50, 'USD') = $10.50
  static Money createFromAmount(num amount, String currencyCode) {
    return Money.fromNum(amount, isoCode: currencyCode);
  }

  /// Parse a money string with a currency code
  ///
  /// Example: parse('$10.50', 'USD') = $10.50
  static Money parse(String moneyString, String currencyCode) {
    final currency = getCurrency(currencyCode);
    return Money.parseWithCurrency(moneyString, currency);
  }

  /// Format a Money instance with a custom pattern
  ///
  /// Common patterns:
  /// - 'S#,##0.00' -> $1,234.56
  /// - 'SCCC #,##0.00' -> $USD 1,234.56
  /// - '#,##0.00 S' -> 1,234.56 $
  static String format(Money money, {String pattern = 'S#,##0.00'}) {
    return money.format(pattern);
  }

  /// Get the symbol for a currency code
  ///
  /// Example: getSymbol('USD') = '$'
  static String getSymbol(String currencyCode) {
    final currency = getCurrency(currencyCode);
    return currency.symbol;
  }

  /// Get the decimal digits (precision) for a currency
  ///
  /// Example: getDecimalDigits('USD') = 2 (cents)
  static int getDecimalDigits(String currencyCode) {
    final currency = getCurrency(currencyCode);
    return currency.decimalDigits;
  }

  /// Convert Money to JSON for storage
  ///
  /// Returns a map with minorUnits, decimals, and isoCode
  static Map<String, dynamic> toJson(Money money) {
    return money.toJson();
  }

  /// Create Money from JSON
  ///
  /// Expects a map with minorUnits, decimals, and isoCode
  static Money fromJson(Map<String, dynamic> json) {
    return Money.fromJson(json);
  }

  /// List of commonly used currencies
  static List<String> get commonCurrencyCodes => [
        'USD', // US Dollar
        'EUR', // Euro
        'GBP', // British Pound
        'JPY', // Japanese Yen
        'AUD', // Australian Dollar
        'CAD', // Canadian Dollar
        'CHF', // Swiss Franc
        'CNY', // Chinese Yuan
        'INR', // Indian Rupee
        'MXN', // Mexican Peso
        'BRL', // Brazilian Real
        'ZAR', // South African Rand
        'AED', // UAE Dirham
        'SAR', // Saudi Riyal
        'SEK', // Swedish Krona
        'NOK', // Norwegian Krone
        'DKK', // Danish Krone
        'SGD', // Singapore Dollar
        'HKD', // Hong Kong Dollar
        'KRW', // South Korean Won
      ];

  /// Get currency information for display
  ///
  /// Returns a map with code, symbol, name, and decimalDigits
  static Map<String, dynamic> getCurrencyInfo(String currencyCode) {
    final currency = getCurrency(currencyCode);
    return {
      'code': currency.isoCode,
      'symbol': currency.symbol,
      'name': currency.name,
      'decimalDigits': currency.decimalDigits,
    };
  }
}
