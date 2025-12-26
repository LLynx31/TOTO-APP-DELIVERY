import 'package:flutter_test/flutter_test.dart';
import 'package:toto_deliverer/core/adapters/base_adapter.dart';

void main() {
  group('BaseAdapter - snake_case to camelCase', () {
    test('convertit snake_case simple en camelCase', () {
      final json = {
        'user_name': 'John',
        'created_at': '2024-01-01',
        'is_active': true,
      };

      final result = BaseAdapter.snakeToCamel(json);

      expect(result['userName'], 'John');
      expect(result['createdAt'], '2024-01-01');
      expect(result['isActive'], true);
    });

    test('gère les clés sans underscore', () {
      final json = {
        'id': '123',
        'name': 'Test',
      };

      final result = BaseAdapter.snakeToCamel(json);

      expect(result['id'], '123');
      expect(result['name'], 'Test');
    });

    test('convertit récursivement les objets imbriqués', () {
      final json = {
        'user_data': {
          'first_name': 'John',
          'last_name': 'Doe',
        },
        'created_at': '2024-01-01',
      };

      final result = BaseAdapter.snakeToCamel(json);

      expect(result['userData'], isA<Map>());
      expect(result['userData']['firstName'], 'John');
      expect(result['userData']['lastName'], 'Doe');
      expect(result['createdAt'], '2024-01-01');
    });

    test('convertit les listes d\'objets', () {
      final json = {
        'user_list': [
          {'user_name': 'John', 'user_age': 30},
          {'user_name': 'Jane', 'user_age': 25},
        ],
      };

      final result = BaseAdapter.snakeToCamel(json);

      expect(result['userList'], isA<List>());
      expect(result['userList'][0]['userName'], 'John');
      expect(result['userList'][0]['userAge'], 30);
      expect(result['userList'][1]['userName'], 'Jane');
    });

    test('gère les valeurs null', () {
      final json = {
        'user_name': null,
        'created_at': '2024-01-01',
      };

      final result = BaseAdapter.snakeToCamel(json);

      expect(result['userName'], null);
      expect(result['createdAt'], '2024-01-01');
    });
  });

  group('BaseAdapter - camelCase to snake_case', () {
    test('convertit camelCase simple en snake_case', () {
      final json = {
        'userName': 'John',
        'createdAt': '2024-01-01',
        'isActive': true,
      };

      final result = BaseAdapter.camelToSnake(json);

      expect(result['user_name'], 'John');
      expect(result['created_at'], '2024-01-01');
      expect(result['is_active'], true);
    });

    test('gère les clés déjà en minuscules', () {
      final json = {
        'id': '123',
        'name': 'Test',
      };

      final result = BaseAdapter.camelToSnake(json);

      expect(result['id'], '123');
      expect(result['name'], 'Test');
    });

    test('convertit récursivement les objets imbriqués', () {
      final json = {
        'userData': {
          'firstName': 'John',
          'lastName': 'Doe',
        },
        'createdAt': '2024-01-01',
      };

      final result = BaseAdapter.camelToSnake(json);

      expect(result['user_data'], isA<Map>());
      expect(result['user_data']['first_name'], 'John');
      expect(result['user_data']['last_name'], 'Doe');
      expect(result['created_at'], '2024-01-01');
    });
  });

  group('BaseAdapter - parseDate', () {
    test('parse une date ISO 8601', () {
      final date = BaseAdapter.parseDate('2024-01-01T10:00:00Z');

      expect(date, isNotNull);
      expect(date!.year, 2024);
      expect(date.month, 1);
      expect(date.day, 1);
      expect(date.hour, 10);
    });

    test('retourne null pour une chaîne invalide', () {
      final date = BaseAdapter.parseDate('invalid-date');

      expect(date, isNull);
    });

    test('retourne null pour null', () {
      final date = BaseAdapter.parseDate(null);

      expect(date, isNull);
    });

    test('retourne DateTime directement', () {
      final input = DateTime(2024, 1, 1);
      final date = BaseAdapter.parseDate(input);

      expect(date, input);
    });

    test('parse un timestamp en millisecondes', () {
      final timestamp = 1704096000000; // 2024-01-01 00:00:00 UTC
      final date = BaseAdapter.parseDate(timestamp);

      expect(date, isNotNull);
      expect(date!.year, 2024);
      expect(date.month, 1);
      expect(date.day, 1);
    });
  });

  group('BaseAdapter - toDouble', () {
    test('convertit int en double', () {
      expect(BaseAdapter.toDouble(5), 5.0);
    });

    test('retourne double directement', () {
      expect(BaseAdapter.toDouble(5.5), 5.5);
    });

    test('parse une chaîne valide', () {
      expect(BaseAdapter.toDouble('5.5'), 5.5);
      expect(BaseAdapter.toDouble('10'), 10.0);
    });

    test('retourne null pour chaîne invalide', () {
      expect(BaseAdapter.toDouble('invalid'), isNull);
    });

    test('retourne null pour null', () {
      expect(BaseAdapter.toDouble(null), isNull);
    });
  });

  group('BaseAdapter - toInt', () {
    test('retourne int directement', () {
      expect(BaseAdapter.toInt(5), 5);
    });

    test('convertit double en int (arrondi)', () {
      expect(BaseAdapter.toInt(5.7), 5);
      expect(BaseAdapter.toInt(5.2), 5);
    });

    test('parse une chaîne valide', () {
      expect(BaseAdapter.toInt('5'), 5);
      expect(BaseAdapter.toInt('10'), 10);
    });

    test('parse une chaîne décimale', () {
      expect(BaseAdapter.toInt('5.7'), 5);
    });

    test('retourne null pour chaîne invalide', () {
      expect(BaseAdapter.toInt('invalid'), isNull);
    });

    test('retourne null pour null', () {
      expect(BaseAdapter.toInt(null), isNull);
    });
  });

  group('BaseAdapter - toBool', () {
    test('retourne bool directement', () {
      expect(BaseAdapter.toBool(true), true);
      expect(BaseAdapter.toBool(false), false);
    });

    test('convertit int en bool', () {
      expect(BaseAdapter.toBool(1), true);
      expect(BaseAdapter.toBool(5), true);
      expect(BaseAdapter.toBool(0), false);
    });

    test('parse chaînes true/false', () {
      expect(BaseAdapter.toBool('true'), true);
      expect(BaseAdapter.toBool('TRUE'), true);
      expect(BaseAdapter.toBool('false'), false);
      expect(BaseAdapter.toBool('FALSE'), false);
    });

    test('parse chaînes yes/no', () {
      expect(BaseAdapter.toBool('yes'), true);
      expect(BaseAdapter.toBool('YES'), true);
      expect(BaseAdapter.toBool('no'), false);
      expect(BaseAdapter.toBool('NO'), false);
    });

    test('parse chaînes 1/0', () {
      expect(BaseAdapter.toBool('1'), true);
      expect(BaseAdapter.toBool('0'), false);
    });

    test('retourne null pour chaîne invalide', () {
      expect(BaseAdapter.toBool('invalid'), isNull);
    });

    test('retourne null pour null', () {
      expect(BaseAdapter.toBool(null), isNull);
    });
  });

  group('BaseAdapter - asString', () {
    test('retourne String directement', () {
      expect(BaseAdapter.asString('hello'), 'hello');
    });

    test('convertit int en String', () {
      expect(BaseAdapter.asString(123), '123');
    });

    test('convertit bool en String', () {
      expect(BaseAdapter.asString(true), 'true');
      expect(BaseAdapter.asString(false), 'false');
    });

    test('retourne null pour null', () {
      expect(BaseAdapter.asString(null), isNull);
    });
  });

  group('BaseAdapter - getValue', () {
    test('extrait une valeur String', () {
      final json = {'name': 'John'};
      expect(BaseAdapter.getValue<String>(json, 'name'), 'John');
    });

    test('extrait une valeur int', () {
      final json = {'age': 30};
      expect(BaseAdapter.getValue<int>(json, 'age'), 30);
    });

    test('convertit String en int', () {
      final json = {'age': '30'};
      expect(BaseAdapter.getValue<int>(json, 'age'), 30);
    });

    test('extrait une valeur double', () {
      final json = {'price': 5.5};
      expect(BaseAdapter.getValue<double>(json, 'price'), 5.5);
    });

    test('convertit int en double', () {
      final json = {'price': 5};
      expect(BaseAdapter.getValue<double>(json, 'price'), 5.0);
    });

    test('extrait une valeur bool', () {
      final json = {'isActive': true};
      expect(BaseAdapter.getValue<bool>(json, 'isActive'), true);
    });

    test('retourne null pour clé manquante', () {
      final json = {'name': 'John'};
      expect(BaseAdapter.getValue<String>(json, 'missing'), isNull);
    });

    test('retourne null pour valeur null', () {
      final json = {'name': null};
      expect(BaseAdapter.getValue<String>(json, 'name'), isNull);
    });

    test('extrait une date', () {
      final json = {'createdAt': '2024-01-01T10:00:00Z'};
      final date = BaseAdapter.getValue<DateTime>(json, 'createdAt');

      expect(date, isNotNull);
      expect(date!.year, 2024);
    });
  });

  group('BaseAdapter - hasKey', () {
    test('trouve une clé exacte', () {
      final json = {'user_name': 'John'};
      expect(BaseAdapter.hasKey(json, 'user_name'), true);
    });

    test('trouve une clé en snake_case depuis camelCase', () {
      final json = {'user_name': 'John'};
      expect(BaseAdapter.hasKey(json, 'userName'), true);
    });

    test('trouve une clé en camelCase depuis snake_case', () {
      final json = {'userName': 'John'};
      expect(BaseAdapter.hasKey(json, 'user_name'), true);
    });

    test('retourne false pour clé manquante', () {
      final json = {'user_name': 'John'};
      expect(BaseAdapter.hasKey(json, 'missing'), false);
    });
  });

  group('BaseAdapter - getFlexible', () {
    test('récupère valeur avec clé exacte', () {
      final json = {'user_name': 'John'};
      expect(BaseAdapter.getFlexible(json, 'user_name'), 'John');
    });

    test('récupère valeur en snake_case depuis camelCase', () {
      final json = {'user_name': 'John'};
      expect(BaseAdapter.getFlexible(json, 'userName'), 'John');
    });

    test('récupère valeur en camelCase depuis snake_case', () {
      final json = {'userName': 'John'};
      expect(BaseAdapter.getFlexible(json, 'user_name'), 'John');
    });

    test('retourne null pour clé manquante', () {
      final json = {'user_name': 'John'};
      expect(BaseAdapter.getFlexible(json, 'missing'), isNull);
    });
  });

  group('BaseAdapter - Cas réels backend', () {
    test('convertit une réponse delivery backend complète', () {
      final backendResponse = {
        'id': '123',
        'client_id': '456',
        'deliverer_id': '789',
        'pickup_address': 'Cocody Angré',
        'pickup_latitude': 5.3599517,
        'pickup_longitude': -3.9810350,
        'delivery_address': 'Plateau',
        'delivery_latitude': 5.3250984,
        'delivery_longitude': -4.0267813,
        'package_description': 'Documents',
        'package_weight': 1.5,
        'price': 2500,
        'status': 'pending',
        'created_at': '2024-01-01T10:00:00Z',
        'accepted_at': null,
      };

      final result = BaseAdapter.snakeToCamel(backendResponse);

      expect(result['id'], '123');
      expect(result['clientId'], '456');
      expect(result['delivererId'], '789');
      expect(result['pickupAddress'], 'Cocody Angré');
      expect(result['pickupLatitude'], 5.3599517);
      expect(result['pickupLongitude'], -3.9810350);
      expect(result['deliveryAddress'], 'Plateau');
      expect(result['packageDescription'], 'Documents');
      expect(result['packageWeight'], 1.5);
      expect(result['price'], 2500);
      expect(result['status'], 'pending');
      expect(result['createdAt'], '2024-01-01T10:00:00Z');
      expect(result['acceptedAt'], null);
    });

    test('convertit une réponse quota backend', () {
      final backendResponse = {
        'id': 'q123',
        'user_id': 'u456',
        'quota_type': 'standard',
        'total_deliveries': 50,
        'remaining_deliveries': 35,
        'price_paid': 35000,
        'purchased_at': '2024-01-01T10:00:00Z',
        'expires_at': '2024-03-01T10:00:00Z',
        'is_active': true,
      };

      final result = BaseAdapter.snakeToCamel(backendResponse);

      expect(result['id'], 'q123');
      expect(result['userId'], 'u456');
      expect(result['quotaType'], 'standard');
      expect(result['totalDeliveries'], 50);
      expect(result['remainingDeliveries'], 35);
      expect(result['pricePaid'], 35000);
      expect(result['purchasedAt'], '2024-01-01T10:00:00Z');
      expect(result['expiresAt'], '2024-03-01T10:00:00Z');
      expect(result['isActive'], true);
    });
  });
}
