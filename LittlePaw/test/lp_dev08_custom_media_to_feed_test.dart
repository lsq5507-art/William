import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:little_paw/l10n/strings.dart';
import 'package:little_paw/models/pet.dart';
import 'package:little_paw/services/local_media_store.dart';
import 'package:little_paw/services/pet_subject_media.dart';
import 'package:little_paw/services/space_store.dart';

Uint8List _tinyPng() => Uint8List.fromList(base64Decode(
      'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg=='));

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await LocalMediaStore.instance.clearForTest();
  });

  test('P-08 flags default: custom on, legacy box off; persist', () async {
    final store = SpaceStore();
    await store.load();
    expect(store.customMediaToFeedEnabled, true);
    expect(store.interactiveBoxCardLegacyEnabled, false);

    await store.setCustomMediaToFeedEnabled(false);
    await store.setInteractiveBoxCardLegacyEnabled(true);

    final store2 = SpaceStore();
    await store2.load();
    expect(store2.customMediaToFeedEnabled, false);
    expect(store2.interactiveBoxCardLegacyEnabled, true);
  });

  test('l10n: custom entry + no publish-coming-soon toast', () {
    final zh = S(true);
    final en = S(false);
    expect(zh.get('feed.custom.cta'), '放进圈子');
    expect(zh.get('feed.custom.title'), contains('日常'));
    expect(zh.get('custom.confirm.checkbox'), contains('日常'));
    expect(zh.get('world.top.add_toast').contains('即将开放'), false);
    expect(
      en.get('world.top.add_toast').toLowerCase().contains('coming soon'),
      false,
    );
    expect(zh.get('feed.custom.cta'), isNot('打开纸箱'));
    expect(zh.get('world.publish.a11y'), contains('宠物圈'));
  });

  test('localmedia persists across reload; story uses scheme', () async {
    final store = SpaceStore();
    await store.load();
    await store.createPet(Pet(
      id: 'p1',
      name: '瓜瓜',
      species: 'cat',
      type: PetType.fiction,
      createdAt: DateTime.utc(2026, 11, 3),
    ));

    final png = _tinyPng();
    final url =
        await LocalMediaStore.instance.putBytes(png, preferredId: 'day1');
    expect(url, 'localmedia://day1');
    expect(PetSubjectMedia.isPetSubject(url), true);
    expect(PetSubjectMedia.resolveForFeed(url, petOnly: true), url);

    final story = await store.addCustomMediaStory(
      imageUrl: url,
      caption: '和它晒太阳',
    );
    expect(story, isNotNull);
    expect(store.stories.first.imageUrl, url);
    expect(store.stories.first.bodyZh, '和它晒太阳');

    // Cold-ish reload of media bytes from SharedPreferences.
    await LocalMediaStore.instance.load(force: true);
    final bytes = LocalMediaStore.instance.bytesFor(url);
    expect(bytes, isNotNull);
    expect(bytes!.length, png.length);

    final store2 = SpaceStore();
    await store2.load();
    expect(store2.stories.any((e) => e.imageUrl == url), true);
  });

  test('flag off / oversized: no dirty post', () async {
    final store = SpaceStore();
    await store.load();
    await store.createPet(Pet(
      id: 'p1',
      name: '瓜瓜',
      species: 'dog',
      type: PetType.fiction,
      createdAt: DateTime.utc(2026, 11, 3),
    ));
    final before = store.stories.length;
    await store.setCustomMediaToFeedEnabled(false);
    expect(
      await store.addCustomMediaStory(imageUrl: 'localmedia://x'),
      isNull,
    );
    expect(store.stories.length, before);

    await store.setCustomMediaToFeedEnabled(true);
    expect(
      () => LocalMediaStore.instance
          .putBytes(Uint8List(LocalMediaStore.maxBytes + 1)),
      throwsA(isA<StateError>()),
    );
    expect(store.stories.length, before);
  });

  test('system seed still rejects picsum; localmedia accepted', () {
    expect(
      PetSubjectMedia.isPetSubject('https://picsum.photos/seed/x/800/600'),
      false,
    );
    expect(PetSubjectMedia.isPetSubject('localmedia://abc'), true);
  });
}
