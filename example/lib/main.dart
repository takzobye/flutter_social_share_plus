import 'package:flutter/material.dart';
import 'package:flutter_social_share_plus/flutter_social_share_plus.dart';

void main() {
  runApp(const ExampleApp());
}

class ExampleApp extends StatelessWidget {
  const ExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Social Share Plus',
      theme: ThemeData(
        colorSchemeSeed: Colors.deepPurple,
        useMaterial3: true,
      ),
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
  Map<SocialPlatform, bool> _installedApps = {};
  String _status = 'Ready';

  @override
  void initState() {
    super.initState();
    _checkInstalledApps();
  }

  Future<void> _checkInstalledApps() async {
    final apps = await SocialSharePlus.getInstalledApps();
    if (!mounted) return;
    setState(() => _installedApps = apps);
  }

  void _showResult(ShareResult result) {
    final message = switch (result) {
      ShareSuccess() => 'Shared successfully!',
      ShareError(:final message) => 'Error: $message',
      ShareAppNotInstalled() => 'App not installed',
      ShareCancelled() => 'Cancelled',
    };
    if (!mounted) return;
    setState(() => _status = message);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Social Share Plus')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Status: $_status', style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 8),
          if (_installedApps.isNotEmpty) ...[
            Text(
              'Installed: ${_installedApps.entries.where((e) => e.value).map((e) => e.key.name).join(', ')}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 16),
          ],

          // Instagram
          _SectionHeader('Instagram'),
          _ShareButton(
            label: 'Instagram Direct',
            icon: Icons.send,
            onPressed: () async {
              final result = await SocialSharePlus.instagramDirect(
                message: 'Hello from Flutter Social Share Plus!',
              );
              _showResult(result);
            },
          ),
          _ShareButton(
            label: 'Instagram Story',
            icon: Icons.auto_stories,
            onPressed: () async {
              final result = await SocialSharePlus.instagramStory(
                config: StoryConfig(
                  appId: 'YOUR_FACEBOOK_APP_ID',
                  backgroundTopColor: '#FF5733',
                  backgroundBottomColor: '#3366FF',
                ),
              );
              _showResult(result);
            },
          ),

          const SizedBox(height: 16),

          // Facebook
          _SectionHeader('Facebook'),
          _ShareButton(
            label: 'Facebook Story',
            icon: Icons.auto_stories,
            onPressed: () async {
              final result = await SocialSharePlus.facebookStory(
                config: StoryConfig(
                  appId: 'YOUR_FACEBOOK_APP_ID',
                  backgroundTopColor: '#1877F2',
                  backgroundBottomColor: '#0D47A1',
                ),
              );
              _showResult(result);
            },
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.title);
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 8),
      child: Text(title, style: Theme.of(context).textTheme.titleMedium),
    );
  }
}

class _ShareButton extends StatelessWidget {
  const _ShareButton({
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: FilledButton.icon(
        onPressed: onPressed,
        icon: Icon(icon),
        label: Text(label),
      ),
    );
  }
}
