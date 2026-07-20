import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

/// 選択した写真を、ピンチズーム・ドラッグで好きな位置に調整してから
/// 円形に切り抜くための画面。
///
/// 「決定」を押すと、その時点で円の中に見えている部分を切り抜いた
/// PNG画像のバイト列を持って前の画面に戻る(Navigator.pop)。
///
/// 補足: 最初は少しだけズームされた状態(scale: 1.3)から始める。
/// 写真が枠とぴったり同じ大きさのまま(拡大なし)だと、
/// ドラッグしても動かせる余地が無く「操作しても何も変わらない」
/// ように見えてしまうため。
class PhotoCropPage extends StatefulWidget {
  final Uint8List imageBytes;

  const PhotoCropPage({super.key, required this.imageBytes});

  @override
  State<PhotoCropPage> createState() => _PhotoCropPageState();
}

class _PhotoCropPageState extends State<PhotoCropPage> {
  final GlobalKey _repaintKey = GlobalKey();
  late final TransformationController _controller = TransformationController(
    // 最初から少しズームしておき、ドラッグで動かせる余地を作っておく
    Matrix4.identity()..scale(1.3),
  );
  bool _isSaving = false;

  // 切り抜き枠のサイズ(画面上の表示ピクセル数)
  static const double _cropSize = 280;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _confirm() async {
    setState(() => _isSaving = true);
    try {
      final boundary =
          _repaintKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final pngBytes = byteData!.buffer.asUint8List();

      if (mounted) {
        Navigator.of(context).pop(pngBytes);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('切り抜きに失敗しました: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text('写真の位置を調整'),
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _confirm,
            child: _isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                  )
                : const Text(
                    '決定',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                  ),
          ),
        ],
      ),
      body: Column(
        children: [
          const SizedBox(height: 24),
          const Text(
            'ピンチで拡大縮小、ドラッグで位置を調整できます',
            style: TextStyle(color: Colors.white70, fontSize: 13),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: Center(
              child: ClipOval(
                child: RepaintBoundary(
                  key: _repaintKey,
                  child: SizedBox(
                    width: _cropSize,
                    height: _cropSize,
                    child: InteractiveViewer(
                      transformationController: _controller,
                      minScale: 1,
                      maxScale: 5,
                      panEnabled: true,
                      scaleEnabled: true,
                      boundaryMargin: const EdgeInsets.all(1000),
                      child: Image.memory(
                        widget.imageBytes,
                        fit: BoxFit.cover,
                        width: _cropSize,
                        height: _cropSize,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}
