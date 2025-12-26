/// Base adapter avec utilitaires de transformation de données
///
/// Fournit des méthodes pour:
/// - Conversion snake_case ↔ camelCase
/// - Parsing sécurisé des dates
/// - Conversions de types avec null-safety
class BaseAdapter {
  /// Convertit récursivement les clés snake_case en camelCase
  ///
  /// Exemple:
  /// ```dart
  /// snakeToCamel({'user_name': 'John', 'created_at': '2024-01-01'})
  /// // => {'userName': 'John', 'createdAt': '2024-01-01'}
  /// ```
  static Map<String, dynamic> snakeToCamel(Map<String, dynamic> json) {
    final result = <String, dynamic>{};

    json.forEach((key, value) {
      final camelKey = _snakeToCamelCase(key);

      if (value is Map<String, dynamic>) {
        result[camelKey] = snakeToCamel(value);
      } else if (value is List) {
        result[camelKey] = value.map((item) {
          if (item is Map<String, dynamic>) {
            return snakeToCamel(item);
          }
          return item;
        }).toList();
      } else {
        result[camelKey] = value;
      }
    });

    return result;
  }

  /// Convertit récursivement les clés camelCase en snake_case
  ///
  /// Exemple:
  /// ```dart
  /// camelToSnake({'userName': 'John', 'createdAt': '2024-01-01'})
  /// // => {'user_name': 'John', 'created_at': '2024-01-01'}
  /// ```
  static Map<String, dynamic> camelToSnake(Map<String, dynamic> json) {
    final result = <String, dynamic>{};

    json.forEach((key, value) {
      final snakeKey = _camelToSnakeCase(key);

      if (value is Map<String, dynamic>) {
        result[snakeKey] = camelToSnake(value);
      } else if (value is List) {
        result[snakeKey] = value.map((item) {
          if (item is Map<String, dynamic>) {
            return camelToSnake(item);
          }
          return item;
        }).toList();
      } else {
        result[snakeKey] = value;
      }
    });

    return result;
  }

  /// Convertit une chaîne snake_case en camelCase
  ///
  /// Exemple:
  /// ```dart
  /// _snakeToCamelCase('user_name') // => 'userName'
  /// _snakeToCamelCase('created_at') // => 'createdAt'
  /// _snakeToCamelCase('id') // => 'id'
  /// ```
  static String _snakeToCamelCase(String snake) {
    if (!snake.contains('_')) return snake;

    final parts = snake.split('_');
    final first = parts.first;
    final rest = parts.skip(1).map((part) {
      if (part.isEmpty) return '';
      return part[0].toUpperCase() + part.substring(1).toLowerCase();
    });

    return first + rest.join('');
  }

  /// Convertit une chaîne camelCase en snake_case
  ///
  /// Exemple:
  /// ```dart
  /// _camelToSnakeCase('userName') // => 'user_name'
  /// _camelToSnakeCase('createdAt') // => 'created_at'
  /// _camelToSnakeCase('id') // => 'id'
  /// ```
  static String _camelToSnakeCase(String camel) {
    return camel.replaceAllMapped(
      RegExp(r'[A-Z]'),
      (match) => '_${match.group(0)!.toLowerCase()}',
    );
  }

  /// Parse une date depuis différents formats avec null-safety
  ///
  /// Supporte:
  /// - String ISO 8601 (2024-01-01T10:00:00Z)
  /// - DateTime object
  /// - int (timestamp en millisecondes)
  /// - null
  ///
  /// Exemple:
  /// ```dart
  /// parseDate('2024-01-01T10:00:00Z') // => DateTime(2024, 1, 1, 10, 0)
  /// parseDate(null) // => null
  /// parseDate(1704096000000) // => DateTime from timestamp
  /// ```
  static DateTime? parseDate(dynamic value) {
    if (value == null) return null;

    if (value is DateTime) return value;

    if (value is String) {
      try {
        return DateTime.parse(value);
      } catch (e) {
        return null;
      }
    }

    if (value is int) {
      try {
        return DateTime.fromMillisecondsSinceEpoch(value);
      } catch (e) {
        return null;
      }
    }

    return null;
  }

  /// Convertit de manière sécurisée en double
  ///
  /// Supporte:
  /// - double
  /// - int
  /// - String parsable
  /// - null
  ///
  /// Exemple:
  /// ```dart
  /// toDouble(5.5) // => 5.5
  /// toDouble(5) // => 5.0
  /// toDouble('5.5') // => 5.5
  /// toDouble(null) // => null
  /// toDouble('invalid') // => null
  /// ```
  static double? toDouble(dynamic value) {
    if (value == null) return null;

    if (value is double) return value;

    if (value is int) return value.toDouble();

    if (value is String) {
      try {
        return double.parse(value);
      } catch (e) {
        return null;
      }
    }

    return null;
  }

  /// Convertit de manière sécurisée en int
  ///
  /// Supporte:
  /// - int
  /// - double (arrondi)
  /// - String parsable
  /// - null
  ///
  /// Exemple:
  /// ```dart
  /// toInt(5) // => 5
  /// toInt(5.7) // => 5
  /// toInt('5') // => 5
  /// toInt(null) // => null
  /// toInt('invalid') // => null
  /// ```
  static int? toInt(dynamic value) {
    if (value == null) return null;

    if (value is int) return value;

    if (value is double) return value.toInt();

    if (value is String) {
      try {
        return int.parse(value);
      } catch (e) {
        // Essayer de parser comme double puis convertir
        try {
          return double.parse(value).toInt();
        } catch (e2) {
          return null;
        }
      }
    }

    return null;
  }

  /// Convertit de manière sécurisée en bool
  ///
  /// Supporte:
  /// - bool
  /// - int (0 = false, autre = true)
  /// - String ('true', '1', 'yes' = true)
  /// - null
  ///
  /// Exemple:
  /// ```dart
  /// toBool(true) // => true
  /// toBool(1) // => true
  /// toBool(0) // => false
  /// toBool('true') // => true
  /// toBool(null) // => null
  /// ```
  static bool? toBool(dynamic value) {
    if (value == null) return null;

    if (value is bool) return value;

    if (value is int) return value != 0;

    if (value is String) {
      final lower = value.toLowerCase();
      if (lower == 'true' || lower == '1' || lower == 'yes') return true;
      if (lower == 'false' || lower == '0' || lower == 'no') return false;
      return null;
    }

    return null;
  }

  /// Convertit de manière sécurisée en String
  ///
  /// Supporte tous les types et retourne null seulement si la valeur est null
  ///
  /// Exemple:
  /// ```dart
  /// asString('hello') // => 'hello'
  /// asString(123) // => '123'
  /// asString(true) // => 'true'
  /// asString(null) // => null
  /// ```
  static String? asString(dynamic value) {
    if (value == null) return null;
    return value.toString();
  }

  /// Extrait une valeur d'un Map de manière sécurisée avec typage
  ///
  /// Exemple:
  /// ```dart
  /// final json = {'name': 'John', 'age': 30};
  /// getValue<String>(json, 'name') // => 'John'
  /// getValue<int>(json, 'age') // => 30
  /// getValue<String>(json, 'missing') // => null
  /// ```
  static T? getValue<T>(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value == null) return null;

    try {
      if (value is T) return value;

      // Tentative de conversion pour les types courants
      if (T == int) return toInt(value) as T?;
      if (T == double) return toDouble(value) as T?;
      if (T == bool) return toBool(value) as T?;
      if (T == String) return asString(value) as T?;
      if (T == DateTime) return parseDate(value) as T?;

      return value as T?;
    } catch (e) {
      return null;
    }
  }

  /// Vérifie si un Map contient une clé (case-insensitive et flexible)
  ///
  /// Cherche la clé en:
  /// 1. Format exact
  /// 2. snake_case
  /// 3. camelCase
  ///
  /// Exemple:
  /// ```dart
  /// final json = {'user_name': 'John'};
  /// hasKey(json, 'user_name') // => true
  /// hasKey(json, 'userName') // => true (trouve user_name)
  /// hasKey(json, 'missing') // => false
  /// ```
  static bool hasKey(Map<String, dynamic> json, String key) {
    if (json.containsKey(key)) return true;

    // Essayer snake_case
    final snakeKey = _camelToSnakeCase(key);
    if (json.containsKey(snakeKey)) return true;

    // Essayer camelCase
    final camelKey = _snakeToCamelCase(key);
    if (json.containsKey(camelKey)) return true;

    return false;
  }

  /// Récupère une valeur avec fallback sur snake_case ou camelCase
  ///
  /// Exemple:
  /// ```dart
  /// final json = {'user_name': 'John'};
  /// getFlexible(json, 'userName') // => 'John' (trouve user_name)
  /// getFlexible(json, 'user_name') // => 'John'
  /// ```
  static dynamic getFlexible(Map<String, dynamic> json, String key) {
    if (json.containsKey(key)) return json[key];

    // Essayer snake_case
    final snakeKey = _camelToSnakeCase(key);
    if (json.containsKey(snakeKey)) return json[snakeKey];

    // Essayer camelCase
    final camelKey = _snakeToCamelCase(key);
    if (json.containsKey(camelKey)) return json[camelKey];

    return null;
  }
}
