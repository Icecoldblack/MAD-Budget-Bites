import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:budget_bites/data/meal_repository.dart';
import 'package:budget_bites/models/meal.dart';

import 'test_helpers.dart';

void main() {
  late Database db;
  late MealRepository repository;

  setUp(() async {
    db = await openTestDatabase();
    repository = MealRepository(db);
  });

  tearDown(() async {
    await db.close();
  });

  const burrito = Meal(
    name: 'Burrito Bowl',
    venueNote: 'Food court',
    cuisine: 'Mexican',
    estimatedPriceMinor: 950,
  );

  test('starts with no meals', () async {
    expect(await repository.getAllMeals(), isEmpty);
  });

  test('insert saves a meal and gives it an id', () async {
    final id = await repository.insertMeal(burrito);

    final meals = await repository.getAllMeals();
    expect(meals.length, 1);
    expect(meals.first.id, id);
    expect(meals.first.name, 'Burrito Bowl');
    expect(meals.first.venueNote, 'Food court');
    expect(meals.first.cuisine, 'Mexican');
    expect(meals.first.estimatedPriceMinor, 950);
  });

  test('getAllMeals returns meals sorted by name', () async {
    await repository.insertMeal(burrito);
    await repository.insertMeal(const Meal(
      name: 'Apple Salad',
      venueNote: '',
      cuisine: 'American',
      estimatedPriceMinor: 500,
    ));

    final meals = await repository.getAllMeals();
    expect(meals.map((meal) => meal.name), ['Apple Salad', 'Burrito Bowl']);
  });

  test('update changes a saved meal', () async {
    final id = await repository.insertMeal(burrito);

    await repository.updateMeal(Meal(
      id: id,
      name: 'Burrito Bowl',
      venueNote: 'Food court',
      cuisine: 'Mexican',
      estimatedPriceMinor: 1000,
    ));

    final meals = await repository.getAllMeals();
    expect(meals.first.estimatedPriceMinor, 1000);
  });

  test('delete removes a meal', () async {
    final id = await repository.insertMeal(burrito);

    await repository.deleteMeal(id);

    expect(await repository.getAllMeals(), isEmpty);
  });

  test('the database rejects a negative price', () async {
    const badMeal = Meal(
      name: 'Bad',
      venueNote: '',
      cuisine: 'None',
      estimatedPriceMinor: -100,
    );

    expect(() => repository.insertMeal(badMeal), throwsA(anything));
    expect(await repository.getAllMeals(), isEmpty);
  });
}
