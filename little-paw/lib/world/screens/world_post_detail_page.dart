// World Tab · post detail + comments · v0.5
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/strings.dart';
import '../../services/space_store.dart';
import '../../theme/lp_theme.dart';
import '../world_store.dart';
import 'world_pet_detail_page.dart';

class WorldPostDetailPage extends StatefulWidget {
  const WorldPostDetailPage({super.key, required this.postId});
  final String postId;

  @override
  State<WorldPostDetailPage> createState() => _WorldPostDetailPageState();
}

class _WorldPostDetailPageState extends State<WorldPostDetailPage> {
  final _ctrl = TextEditingController();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final zh = context.watch<SpaceStore>().localeZh;
    final s = S(zh);
    final store = context.watch<WorldStore>();
    final post = store.postById(widget.postId);
    if (post == null) {
      return Scaffold(
        appBar: AppBar(title: Text(s.get('world.detail.missing'))),
        body: Center(child: Text(s.get('world.detail.missing'))),
      );
    }
    final pet = store.petById(post.petId);
    final tokens = context.lpTokens;
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF262626),
        elevation: 0,
        title: Text(
          pet?.name(zh) ?? s.get('world.tab'),
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(0.5),
          child: Divider(height: 0.5, thickness: 0.5, color: tokens.borderHairline),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              children: [
                AspectRatio(
                  aspectRatio: 1,
                  child: Image.asset(post.imageAsset, fit: BoxFit.cover),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (pet != null)
                        GestureDetector(
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) =>
                                    WorldPetDetailPage(petId: pet.id),
                              ),
                            );
                          },
                          child: CircleAvatar(
                            backgroundImage: AssetImage(pet.avatarAsset),
                          ),
                        ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          post.body(zh),
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF262626),
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => store.toggleLike(post.id),
                        icon: Icon(
                          post.liked ? Icons.favorite : Icons.favorite_border,
                          color: post.liked
                              ? const Color(0xFFED4956)
                              : const Color(0xFF262626),
                        ),
                      ),
                      Text(
                        '${post.likeCount}',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
                Divider(height: 1, color: tokens.borderHairline),
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
                  child: Text(
                    s.get('world.comments.title'),
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ),
                ...post.comments.map(
                  (c) => ListTile(
                    dense: true,
                    title: Text(
                      c.author(zh),
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                    subtitle: Text(c.text(zh)),
                  ),
                ),
              ],
            ),
          ),
          SafeArea(
            top: false,
            child: Container(
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: tokens.borderHairline)),
                color: Colors.white,
              ),
              padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _ctrl,
                      decoration: InputDecoration(
                        hintText: s.get('world.comments.hint'),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(22),
                          borderSide:
                              BorderSide(color: tokens.borderHairline),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        isDense: true,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      store.addComment(post.id, zh: zh, text: _ctrl.text);
                      _ctrl.clear();
                    },
                    child: Text(
                      s.get('world.comments.send'),
                      style: const TextStyle(
                        color: Color(0xFF1A1A1A),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
