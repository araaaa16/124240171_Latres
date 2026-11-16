import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:rick_morty_app/models/character_model.dart';
import 'package:rick_morty_app/services/auth_service.dart';
import 'package:rick_morty_app/services/favorite_service.dart';
import 'package:rick_morty_app/services/hive_helper.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('hive_test_');
    Hive.init(tempDir.path);
    await Hive.openBox<Map>(HiveHelper.usersBoxName);
    SharedPreferences.setMockInitialValues({});
  });

  tearDown(() async {
    await Hive.close();
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  group('Hive Local Database User Accounts', () {
    test('Register user stores account in Hive', () async {
      final auth = AuthService();
      final err = await auth.register('Zahra', 'zahra@gmail.com', 'password123');
      expect(err, isNull);

      final exists = await HiveHelper.emailExists('zahra@gmail.com');
      expect(exists, isTrue);

      final user = await HiveHelper.getUserByEmail('zahra@gmail.com');
      expect(user, isNotNull);
      expect(user!['name'], 'Zahra');
      expect(user['email'], 'zahra@gmail.com');
      expect(user['password'], 'password123');
    });

    test('Duplicate registration rejected by Hive check', () async {
      final auth = AuthService();
      await auth.register('Zahra', 'zahra@gmail.com', 'password123');
      final duplicateErr = await auth.register('Zahra 2', 'zahra@gmail.com', 'pass456');
      expect(duplicateErr, 'Email already registered');
    });

    test('Login verifies against Hive and saves session to SharedPreferences', () async {
      final auth = AuthService();
      await auth.register('Zahra', 'zahra@gmail.com', 'password123');

      // Bad password
      final badPass = await auth.login('zahra@gmail.com', 'wrongpassword');
      expect(badPass, 'Incorrect password');

      // Non-existent email
      final nonExistent = await auth.login('notfound@gmail.com', 'password123');
      expect(nonExistent, 'Email not registered');

      // Correct login
      final success = await auth.login('zahra@gmail.com', 'password123');
      expect(success, isNull);

      // Verify SharedPreferences session
      final isLoggedIn = await auth.isLoggedIn();
      final email = await auth.getUserEmail();
      final name = await auth.getUserName();
      expect(isLoggedIn, isTrue);
      expect(email, 'zahra@gmail.com');
      expect(name, 'Zahra');

      // Logout clears session from SharedPreferences
      await auth.logout();
      expect(await auth.isLoggedIn(), isFalse);
      expect(await auth.getUserEmail(), isNull);

      // But Hive account remains intact!
      expect(await HiveHelper.emailExists('zahra@gmail.com'), isTrue);
    });
  });

  group('SharedPreferences Favorites Management', () {
    test('Add, check, retrieve, and remove favorites via SharedPreferences', () async {
      final favService = FavoriteService();
      const character = Character(
        id: 1,
        name: 'Rick Sanchez',
        status: 'Alive',
        species: 'Human',
        gender: 'Male',
        image: 'https://rickandmortyapi.com/api/character/avatar/1.jpeg',
        originName: 'Earth (C-137)',
        locationName: 'Citadel of Ricks',
        episode: ['1', '2'],
      );

      // Initially not favorite
      expect(await favService.isFavorite(1), isFalse);

      // Add to favorites
      await favService.addFavorite(character);
      expect(await favService.isFavorite(1), isTrue);

      final favIds = await favService.getFavoriteIds();
      expect(favIds.contains(1), isTrue);

      final favList = await favService.getFavorites();
      expect(favList.length, 1);
      expect(favList.first.name, 'Rick Sanchez');

      // Remove from favorites
      await favService.removeFavorite(1);
      expect(await favService.isFavorite(1), isFalse);
      expect((await favService.getFavorites()).isEmpty, isTrue);
    });
  });
}

