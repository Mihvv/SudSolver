import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../backend/services/sudoku_notifier.dart';
import '../../backend/services/sudoku_state.dart';
import 'board_confirmation_screen.dart';
import 'edit_photo_screen.dart';

class CameraScreen extends ConsumerStatefulWidget {
  final bool fromGallery;
  const CameraScreen({super.key, required this.fromGallery});

  @override
  ConsumerState<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends ConsumerState<CameraScreen> {
  bool _isLoading = false;
  File? _pickedImage;
  final ImagePicker _picker = ImagePicker();

  // --- KAMERA ---
  CameraController? _cameraController;
  bool _cameraReady = false;

  @override
  void initState() {
    super.initState();
    if (widget.fromGallery) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _pickFromGallery());
    } else {
      _initCamera();
    }
  }

  Future<void> _initCamera() async {
    final cameras = await availableCameras();
    if (cameras.isEmpty) return;

    _cameraController = CameraController(
      cameras.first,
      ResolutionPreset.high,
      enableAudio: false,
    );

    await _cameraController!.initialize();
    if (mounted) setState(() => _cameraReady = true);
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }

  Future<void> _pickFromGallery() async {
    final XFile? file = await _picker.pickImage(source: ImageSource.gallery);
    if (file == null) {
      if (mounted) Navigator.pop(context);
      return;
    }
    setState(() => _pickedImage = File(file.path));
  }

  Future<void> _scan() async {
    if (widget.fromGallery) {
      // Galeria — pokaż edytor przed skanowaniem
      if (_pickedImage == null) return;
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => EditPhotoScreen(
            imageFile: _pickedImage!,
            onConfirm: (path) => _doScan(path),
          ),
        ),
      );
    } else {
      // Aparat — zrób zdjęcie
      if (_cameraController == null || !_cameraReady) return;
      final XFile photo = await _cameraController!.takePicture();
      await _doScan(photo.path);
    }
  }

  Future<void> _doScan(String path) async {
    setState(() => _isLoading = true);
    await ref.read(sudokuProvider.notifier).scanBoard(path);
    if (!mounted) return;
    final status = ref.read(sudokuProvider).status;
    if (status == GameStatus.correctingOCR) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const BoardConfirmationScreen()),
      );
    } else {
      setState(() => _isLoading = false);
    }
  }

  Widget _buildCameraPreview() {
    if (!_cameraReady || _cameraController == null) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white54),
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: CameraPreview(_cameraController!),
    );
  }

  Widget _buildGalleryPreview() {
    if (_pickedImage == null) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(Icons.photo_library_outlined, size: 80, color: Colors.white24),
          SizedBox(height: 16),
          Text('Wybierz zdjęcie z galerii',
              style: TextStyle(color: Colors.white38, fontSize: 16)),
        ],
      );
    }
    return Image.file(
      _pickedImage!,
      fit: BoxFit.contain,
      width: double.infinity,
      height: double.infinity,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        title: Text(widget.fromGallery ? 'Galeria' : 'Aparat'),
        actions: [
          if (widget.fromGallery && _pickedImage != null)
            TextButton(
              onPressed: _pickFromGallery,
              child: const Text('Zmień', style: TextStyle(color: Colors.white)),
            ),
        ],
      ),
      body: Stack(
        children: [
          // Podgląd
          Center(
            child: Container(
              margin: const EdgeInsets.fromLTRB(16, 16, 16, 160),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white24),
                borderRadius: BorderRadius.circular(12),
              ),
              clipBehavior: Clip.antiAlias,
              child: widget.fromGallery
                  ? _buildGalleryPreview()
                  : _buildCameraPreview(),
            ),
          ),

          // Loading overlay
          if (_isLoading)
            Container(
              color: Colors.black54,
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: Colors.white),
                    SizedBox(height: 16),
                    Text('Skanowanie...',
                        style: TextStyle(color: Colors.white, fontSize: 16)),
                  ],
                ),
              ),
            ),

          // Przycisk migawki
          if (!_isLoading)
            Positioned(
              bottom: 48,
              left: 0,
              right: 0,
              child: Center(
                child: GestureDetector(
                  onTap: _scan,
                  child: Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                      border: Border.all(color: Colors.white54, width: 4),
                    ),
                    child: Icon(
                      widget.fromGallery ? Icons.check : Icons.camera,
                      size: 32,
                      color: Colors.black87,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}