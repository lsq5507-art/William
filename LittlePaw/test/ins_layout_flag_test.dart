import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:little_paw/services/space_store.dart';
import 'package:little_paw/models/pet.dart';

void main() {
  test('insFeedLayoutEnabled persists and gates fill merge', () async {
    SharedPreferences.setMockInitialValues({});
    final store = SpaceStore();
    await store.load();
    expect(store.insFeedLayoutEnabled, true);
    expect(store.feedDemoFillEnabled, false);

    await store.createPet(Pet(
      id: 'p1',
      name: 'Mochi',
      species: 'cat',
      type: PetType.fiction,
      createdAt: DateTime.utc(2026, 11, 3),
    ));
    await store.completeOnboarding();
    // Product default: no demo fill posts in visual feed.
    expect(store.visualFeedStories().every((s) => !s.isDemoFill), true);

    await store.setInsFeedLayoutEnabled(false);
    expect(store.insFeedLayoutEnabled, false);
    expect(
      store.visualFeedStories().every((s) => !s.isDemoFill),
      true,
    );

    await store.setInsFeedLayoutEnabled(true);
    await store.setFeedDemoFillEnabled(true);
    expect(store.visualFeedStories().length, greaterThanOrEqualTo(6));
    expect(store.visualFeedStories().any((s) => s.isDemoFill), true);

    await store.setFeedDemoFillEnabled(false);
    expect(store.visualFeedStories().every((s) => !s.isDemoFill), true);
  });
}
