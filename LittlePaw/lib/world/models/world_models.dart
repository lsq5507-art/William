// World Tab · pet feed + character market · v0.5
enum MarketAcquireStatus { locked, trial, owned }

class WorldPet {
  final String id;
  final String nameZh;
  final String nameEn;
  final String breedZh;
  final String breedEn;
  final String personalityZh;
  final String personalityEn;
  final String avatarAsset;

  const WorldPet({
    required this.id,
    required this.nameZh,
    required this.nameEn,
    required this.breedZh,
    required this.breedEn,
    required this.personalityZh,
    required this.personalityEn,
    required this.avatarAsset,
  });

  String name(bool zh) => zh ? nameZh : nameEn;
  String breed(bool zh) => zh ? breedZh : breedEn;
  String personality(bool zh) => zh ? personalityZh : personalityEn;
}

class WorldComment {
  final String id;
  final String authorZh;
  final String authorEn;
  final String textZh;
  final String textEn;
  final DateTime at;

  const WorldComment({
    required this.id,
    required this.authorZh,
    required this.authorEn,
    required this.textZh,
    required this.textEn,
    required this.at,
  });

  String author(bool zh) => zh ? authorZh : authorEn;
  String text(bool zh) => zh ? textZh : textEn;

  WorldComment copyWith({
    String? id,
    String? authorZh,
    String? authorEn,
    String? textZh,
    String? textEn,
    DateTime? at,
  }) =>
      WorldComment(
        id: id ?? this.id,
        authorZh: authorZh ?? this.authorZh,
        authorEn: authorEn ?? this.authorEn,
        textZh: textZh ?? this.textZh,
        textEn: textEn ?? this.textEn,
        at: at ?? this.at,
      );
}

class WorldPost {
  final String id;
  final String petId;
  final String bodyZh;
  final String bodyEn;
  final String imageAsset;
  final DateTime postedAt;
  final int likeCount;
  final bool liked;
  final List<WorldComment> comments;
  final String moodZh;
  final String moodEn;

  const WorldPost({
    required this.id,
    required this.petId,
    required this.bodyZh,
    required this.bodyEn,
    required this.imageAsset,
    required this.postedAt,
    required this.likeCount,
    this.liked = false,
    required this.comments,
    required this.moodZh,
    required this.moodEn,
  });

  String body(bool zh) => zh ? bodyZh : bodyEn;
  String mood(bool zh) => zh ? moodZh : moodEn;

  WorldPost copyWith({
    int? likeCount,
    bool? liked,
    List<WorldComment>? comments,
  }) =>
      WorldPost(
        id: id,
        petId: petId,
        bodyZh: bodyZh,
        bodyEn: bodyEn,
        imageAsset: imageAsset,
        postedAt: postedAt,
        likeCount: likeCount ?? this.likeCount,
        liked: liked ?? this.liked,
        comments: comments ?? this.comments,
        moodZh: moodZh,
        moodEn: moodEn,
      );
}

class WorldMarketItem {
  final String id;
  final String petId;
  final String titleZh;
  final String titleEn;
  final String taglineZh;
  final String taglineEn;
  final String imageAsset;
  final MarketAcquireStatus status;
  final bool demoPaid;

  const WorldMarketItem({
    required this.id,
    required this.petId,
    required this.titleZh,
    required this.titleEn,
    required this.taglineZh,
    required this.taglineEn,
    required this.imageAsset,
    required this.status,
    this.demoPaid = false,
  });

  String title(bool zh) => zh ? titleZh : titleEn;
  String tagline(bool zh) => zh ? taglineZh : taglineEn;

  WorldMarketItem copyWith({MarketAcquireStatus? status}) => WorldMarketItem(
        id: id,
        petId: petId,
        titleZh: titleZh,
        titleEn: titleEn,
        taglineZh: taglineZh,
        taglineEn: taglineEn,
        imageAsset: imageAsset,
        status: status ?? this.status,
        demoPaid: demoPaid,
      );
}
