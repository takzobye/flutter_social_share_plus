import 'package:flutter/material.dart';
import 'package:flutter_social_share_plus/flutter_social_share_plus.dart';
import 'package:image_picker/image_picker.dart';

void main() => runApp(const ExampleApp());

class ExampleApp extends StatelessWidget {
  const ExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Social Share Plus',
      theme: ThemeData(colorSchemeSeed: Colors.deepPurple, useMaterial3: true),
      home: const ShareDemoPage(),
    );
  }
}

class ShareDemoPage extends StatefulWidget {
  const ShareDemoPage({super.key});

  @override
  State<ShareDemoPage> createState() => _ShareDemoPageState();
}

class _ShareDemoPageState extends State<ShareDemoPage> {
  final _pathController = TextEditingController();
  final _appIdController = TextEditingController(text: 'YOUR_FACEBOOK_APP_ID');
  final _picker = ImagePicker();
  String _status = 'Choose a local image or video to begin.';
  Map<ShareTarget, bool> _availability = {};

  @override
  void initState() {
    super.initState();
    _checkAvailability();
  }

  @override
  void dispose() {
    _pathController.dispose();
    _appIdController.dispose();
    super.dispose();
  }

  Future<void> _pickMedia() async {
    final file = await _picker.pickMedia();
    if (file != null) _pathController.text = file.path;
  }

  Future<void> _checkAvailability() async {
    final values = <ShareTarget, bool>{};
    for (final target in ShareTarget.values) {
      values[target] = await SocialSharePlus.isAvailable(target);
    }
    if (mounted) setState(() => _availability = values);
  }

  void _showResult(ShareResult result) {
    final message = switch (result) {
      ShareCompleted() => 'Facebook reported completion.',
      ShareLaunched() => 'The target composer opened.',
      ShareCancelled() => 'Cancelled.',
      ShareUnavailable() => 'Target unavailable.',
      ShareFailed(:final code, :final message) => '$code: $message',
    };
    if (!mounted) return;
    setState(() => _status = message);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  StoryConfig _storyConfig() => StoryConfig(
    appId: _appIdController.text,
    backgroundImagePath: _pathController.text,
    backgroundTopColor: Colors.deepOrange,
    backgroundBottomColor: Colors.blue,
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Social Share Plus')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(_status),
          const SizedBox(height: 16),
          TextField(
            controller: _pathController,
            decoration: const InputDecoration(
              labelText: 'Local media path',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: _pickMedia,
            icon: const Icon(Icons.photo_library),
            label: const Text('Pick image or video'),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _appIdController,
            decoration: const InputDecoration(
              labelText: 'Facebook App ID',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          _availabilitySummary(),
          const SizedBox(height: 16),
          const Text(
            'Instagram',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          _button(
            'Instagram Feed',
            ShareTarget.instagramFeed,
            () async => _showResult(
              await SocialSharePlus.instagramFeed(
                filePath: _pathController.text,
              ),
            ),
          ),
          _button(
            'Instagram Story',
            ShareTarget.instagramStory,
            () async => _showResult(
              await SocialSharePlus.instagramStory(config: _storyConfig()),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Facebook',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          _button(
            'Facebook Feed',
            ShareTarget.facebookFeed,
            () async => _showResult(
              await SocialSharePlus.facebookFeed(
                imagePaths: [_pathController.text],
                hashtag: '#flutter',
              ),
            ),
          ),
          _button(
            'Facebook Story',
            ShareTarget.facebookStory,
            () async => _showResult(
              await SocialSharePlus.facebookStory(config: _storyConfig()),
            ),
          ),
        ],
      ),
    );
  }

  Widget _availabilitySummary() {
    if (_availability.isEmpty) return const SizedBox.shrink();
    final available = _availability.entries
        .where((entry) => entry.value)
        .map((entry) => entry.key.name)
        .join(', ');
    return Text('Available: ${available.isEmpty ? 'none' : available}');
  }

  Widget _button(String label, ShareTarget target, VoidCallback onPressed) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: FilledButton.icon(
        onPressed: _availability[target] == false ? null : onPressed,
        icon: const Icon(Icons.ios_share),
        label: Text(label),
      ),
    );
  }
}
