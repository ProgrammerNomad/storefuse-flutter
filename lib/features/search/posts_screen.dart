import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/models/json_helpers.dart';
import '../../core/providers/providers.dart';
import '../../core/widgets/error_view.dart';

class PostsScreen extends ConsumerStatefulWidget {
  const PostsScreen({super.key});

  @override
  ConsumerState<PostsScreen> createState() => _PostsScreenState();
}

class _PostsScreenState extends ConsumerState<PostsScreen> {
  List<JsonMap> _posts = const [];
  Object? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final client = await ref.read(apiClientProvider.future);
      final data = (await client.getPosts()).data;
      setState(() {
        _posts = asJsonList(data['items']);
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
    return Scaffold(
      appBar: AppBar(title: const Text('Blog')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? ErrorView(message: _error.toString(), onRetry: _load)
              : ListView.separated(
                  itemCount: _posts.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (_, i) {
                    final post = _posts[i];
                    final slug = post['slug'] as String? ?? '';
                    final title = post['title'] as String? ?? slug;
                    return ListTile(
                      title: Text(title),
                      onTap: slug.isEmpty ? null : () => context.push('/posts/$slug'),
                    );
                  },
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
    if (_loading) {
      return Scaffold(appBar: AppBar(), body: const Center(child: CircularProgressIndicator()));
    }
    if (_error != null || _post == null) {
      return Scaffold(
        appBar: AppBar(),
        body: ErrorView(message: _error.toString(), onRetry: _load),
      );
    }
    final title = _post!['title'] as String? ?? '';
    final content = _post!['content'] as String? ?? '';
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [Text(content)],
      ),
    );
  }
}
