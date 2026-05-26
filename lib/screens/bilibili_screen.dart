import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

class BilibiliScreen extends StatefulWidget {
  const BilibiliScreen({super.key});

  @override
  State<BilibiliScreen> createState() => _BilibiliScreenState();
}

class _BilibiliScreenState extends State<BilibiliScreen> {
  static const _channel = MethodChannel('com.studyapp/bilibili');

  @override
  void initState() {
    super.initState();
    _launchBilibili();
  }

  Future<void> _launchBilibili() async {
    // Try native Android intent first (most reliable on Android 11+)
    try {
      final result = await _channel.invokeMethod('launchBilibili');
      if (result == true && mounted) {
        Navigator.pop(context);
        return;
      }
    } catch (_) {}

    // Fallback: url_launcher
    try {
      await launchUrl(Uri.parse('bilibili://'), mode: LaunchMode.externalApplication);
      if (mounted) Navigator.pop(context);
      return;
    } catch (_) {}

    // All failed
    if (mounted) _showInstallDialog();
  }

  void _showInstallDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('未安装B站'),
        content: const Text('检测到您的设备未安装B站应用。\n\n是否前往应用商店下载？'),
        actions: [
          TextButton(
            onPressed: () { Navigator.pop(context); Navigator.pop(context); },
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              Navigator.pop(context);
              try {
                await launchUrl(Uri.parse('market://details?id=tv.danmaku.bili'), mode: LaunchMode.externalApplication);
              } catch (_) {
                await launchUrl(Uri.parse('https://www.bilibili.com'), mode: LaunchMode.externalApplication);
              }
            },
            child: const Text('去下载'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('B站'), elevation: 0),
      body: const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.smart_display, size: 80, color: Colors.pink),
            SizedBox(height: 16),
            Text('正在打开B站...', style: TextStyle(fontSize: 16, color: Colors.grey)),
            SizedBox(height: 8),
            CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}
