import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/models/json_helpers.dart';
import '../../core/providers/providers.dart';
import '../../core/widgets/app_scaffold.dart';
import '../../core/widgets/cached_thumbnail.dart';
import '../../core/widgets/error_view.dart';
import '../../core/widgets/paginated_list_view.dart';
import '../../core/widgets/store_html.dart';
import '../catalog/catalog_repository.dart';

class PostsScreen extends ConsumerStatefulWidget {
  const PostsScreen({super.key});

  @override
  ConsumerState<PostsScreen> createState() => _PostsScreenState();
}

class _PostsScreenState extends ConsumerState<PostsScreen> {
  final _listKey = GlobalKey<PaginatedListViewState>();

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Blog',
      body: RefreshIndicator(
        onRefresh: () async => _listKey.currentState?.refresh(),
        child: PaginatedListView(
          key: _listKey,
          physics: const AlwaysScrollableScrollPhysics(),
          emptyTitle: 'No posts yet',
          loadPage: (page) =>
              ref.read(catalogRepositoryProvider).postsPage(page: page),
          separatorBuilder: (_, _) => const Divider(height: 1),
          itemBuilder: (context, post, index) {
            final slug = post['slug'] as String? ?? '';
            final title = post['title'] as String? ?? slug;
            final date = post['date']?.toString();
            String? formatted;
            if (date != null) {
              final parsed = DateTime.tryParse(date);
              if (parsed != null) formatted = DateFormat.yMMMd().format(parsed);
            }
            final image = imageUrl(
              asJsonMap(post['featured_image'] ?? post['image']),
            );
            return ListTile(
              leading: cachedThumbnail(
                url: image,
                size: 56,
                borderRadius: BorderRadius.circular(4),
              ),
              title: Text(title),
              subtitle: Text(
                [
                  ?formatted,
                  post['author']?.toString(),
                ].whereType<String>().join(' · '),
              ),
              onTap: slug.isEmpty
                  ? null
                  : () => context.push('/home/posts/$slug'),
            );
          },
        ),
      ),
    );
  }
}

class PostDetailScreen extends ConsumerStatefulWidget {
  const PostDetailScreen({super.key, required this.slug});

  final String slug;

  @override
  ConsumerState<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends ConsumerState<PostDetailScreen> {
  JsonMap? _post;
  Object? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final client = await ref.read(apiClientProvider.future);
      final post = (await client.getPost(widget.slug)).data;
      setState(() {
        _post = post;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Post',
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? ErrorView(message: _error.toString(), onRetry: _load)
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  _post?['title']?.toString() ?? widget.slug,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                if (_post?['date'] != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4, bottom: 12),
                    child: Text(_post!['date'].toString()),
                  ),
                StoreHtml(html: _post?['content']?.toString() ?? ''),
              ],
            ),
    );
  }
}
