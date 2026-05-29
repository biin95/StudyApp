import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

import 'package:charset/charset.dart' show gbk;
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../models/file_record.dart';
import '../services/database_service.dart';
import '../services/file_service.dart';

class FileViewerScreen extends StatefulWidget {
  final FileRecord file;

  const FileViewerScreen({super.key, required this.file});

  @override
  State<FileViewerScreen> createState() => _FileViewerScreenState();
}

class _FileViewerScreenState extends State<FileViewerScreen> {
  final DatabaseService _db = DatabaseService();
  final FileService _fileService = FileService();
  late bool _isFavorited;
  late bool _isStudied;
  bool _showToolbar = true;
  String? _fullPath;
  String? _htmlContent;
  String? _mdContent;
  bool _loading = true;
  WebViewController? _webViewController;

  @override
  void initState() {
    super.initState();
    _isFavorited = widget.file.isFavorited;
    _isStudied = widget.file.isStudied;
    _initFile();
    _markAsOpened();
  }

  Future<void> _initFile() async {
    try {
      final path = await _fileService.getFullFilePath(widget.file.path);
      setState(() {
        _fullPath = path;
      });

      if (widget.file.format == 'html') {
        final bytes = await File(path).readAsBytes();
        final content = _decodeHtmlBytes(bytes);
        setState(() {
          _htmlContent = content;
          _loading = false;
        });
      } else if (widget.file.format == 'md') {
        final content = await File(path).readAsString();
        setState(() {
          _mdContent = content;
          _loading = false;
        });
      } else {
        setState(() => _loading = false);
      }
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('\u6253\u5f00\u6587\u4ef6\u5931\u8d25: $e')),
        );
      }
    }
  }

  Future<void> _markAsOpened() async {
    try {
      await _db.markAsRead(widget.file.id!);
      await _db.addRecentRecord(widget.file.id!);
    } catch (_) {}
  }

  Future<void> _toggleFavorite() async {
    final newState = !_isFavorited;
    setState(() => _isFavorited = newState);
    try {
      await _db.toggleFavorite(widget.file.id!, newState);
    } catch (e) {
      setState(() => _isFavorited = !newState);
    }
  }

  Future<void> _toggleStudied() async {
    final newState = !_isStudied;
    setState(() => _isStudied = newState);
    try {
      await _db.markAsStudied(widget.file.id!, newState);
    } catch (e) {
      setState(() => _isStudied = !newState);
    }
  }

  String _decodeHtmlBytes(List<int> bytes) {
    final headerLength = bytes.length < 1024 ? bytes.length : 1024;
    final header = String.fromCharCodes(bytes.sublist(0, headerLength));
    final charsetRegex = RegExp(
      "charset\\s*=\\s*[\"']?([a-zA-Z0-9_-]+)",
      caseSensitive: false,
    );
    final match = charsetRegex.firstMatch(header);

    String? targetEncoding;
    if (match != null) {
      targetEncoding = match.group(1)!.toLowerCase();
    }

    if (targetEncoding == 'gbk' || targetEncoding == 'gb2312' || targetEncoding == 'gb18030') {
      return gbk.decode(bytes);
    }
    
    // Try UTF-8 first
    try {
      return utf8.decode(bytes);
    } catch (_) {
      // Fallback to GBK
      return gbk.decode(bytes);
    }
  }

  Widget _buildPdfViewer() {
    if (_fullPath == null) return const Center(child: Text('\u6587\u4ef6\u8def\u5f84\u9519\u8bef'));
    return PDFView(
      filePath: _fullPath!,
      enableSwipe: true,
      swipeHorizontal: false,
      autoSpacing: false,
      pageSnap: true,
      onError: (error) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('PDF\u52a0\u8f7d\u9519\u8bef: $error')),
          );
        }
      },
    );
  }

  Widget _buildHtmlViewer() {
    if (_htmlContent == null) return const Center(child: Text('\u6587\u4ef6\u5185\u5bb9\u4e3a\u7a7a'));

    // \u53ea\u5728\u7b2c\u4e00\u6b21\u6216\u5185\u5bb9\u53d8\u5316\u65f6\u521b\u5efa\u63a7\u5236\u5668
    if (_webViewController == null) {
      // Inject MathJax config and script into the HTML head
      const mathjaxConfig = r"""
<script>
MathJax = {
  tex: { inlineMath: [['$', '$'], ['\\(', '\\)']], displayMath: [['$$', '$$'], ['\\[', '\\]']] },
  svg: { fontCache: 'global' }
};
</script>
<script src="https://cdn.jsdelivr.net/npm/mathjax@3/es5/tex-svg.min.js"></script>
""";

      String html = _htmlContent!;
      // Inject MathJax before </head> if it exists, otherwise before </body> or at start
      if (html.contains('</head>')) {
        html = html.replaceFirst('</head>', '$mathjaxConfig</head>');
      } else if (html.contains('</body>')) {
        html = html.replaceFirst('</body>', '$mathjaxConfig</body>');
      } else {
        html = '$mathjaxConfig$html';
      }

      final controller = WebViewController();
      controller
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setNavigationDelegate(NavigationDelegate(
          onPageFinished: (_) {
            // Trigger MathJax rendering after page loads
            controller.runJavaScript('MathJax.typeset && MathJax.typeset();');
          },
        ))
        ..loadRequest(Uri.dataFromString(
          html,
          mimeType: 'text/html',
          encoding: Encoding.getByName('utf-8'),
        ));

      _webViewController = controller;
    }

    return WebViewWidget(controller: _webViewController!);
  }

  Widget _buildMarkdownViewer() {
    if (_mdContent == null) return const Center(child: Text('\u6587\u4ef6\u5185\u5bb9\u4e3a\u7a7a'));
    return Markdown(
      data: _mdContent!,
      padding: const EdgeInsets.all(16),
      onTapLink: (text, href, title) async {
        if (href != null) {
          final uri = Uri.parse(href);
          if (await canLaunchUrl(uri)) {
            await launchUrl(uri);
          }
        }
      },
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    switch (widget.file.format) {
      case 'pdf':
        return _buildPdfViewer();
      case 'html':
        return _buildHtmlViewer();
      case 'md':
        return _buildMarkdownViewer();
      default:
        return const Center(child: Text('\u4e0d\u652f\u6301\u7684\u6587\u4ef6\u683c\u5f0f'));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _showToolbar
          ? AppBar(
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.pop(context),
              ),
              title: Text(
                widget.file.name,
                style: const TextStyle(fontSize: 16),
                overflow: TextOverflow.ellipsis,
              ),
              actions: [
                IconButton(
                  icon: Icon(
                    _isStudied ? Icons.check_circle : Icons.check_circle_outline,
                    color: _isStudied ? Colors.green : null,
                  ),
                  tooltip: _isStudied ? '取消学完' : '已学完',
                  onPressed: _toggleStudied,
                ),
                IconButton(
                  icon: Icon(
                    _isFavorited ? Icons.star : Icons.star_border,
                    color: _isFavorited ? const Color(0xFFFFD700) : null,
                  ),
                  onPressed: _toggleFavorite,
                ),
              ],
            )
          : null,
      body: GestureDetector(
        onTap: () => setState(() => _showToolbar = !_showToolbar),
        child: _buildBody(),
      ),
    );
  }
}
