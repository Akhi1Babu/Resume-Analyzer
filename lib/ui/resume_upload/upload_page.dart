import 'dart:ui';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'dart:typed_data';
import '../../services/resume_service.dart';
import '../widgets/kinetic_background.dart';

class UploadPage extends StatefulWidget {
  const UploadPage({super.key});

  @override
  State<UploadPage> createState() => _UploadPageState();
}

class _UploadPageState extends State<UploadPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  Uint8List? _fileBytes;
  String? _fileName;
  String _uploadStatus = '';
  final _jobDescriptionController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _scaleAnimation = Tween<double>(
      begin: 0.98,
      end: 1.02,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    _jobDescriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
      withData: true,
    );

    if (result != null && result.files.single.bytes != null) {
      setState(() {
        _fileBytes = result.files.single.bytes;
        _fileName = result.files.single.name;
      });
    }
  }

  Future<void> _uploadAndAnalyze() async {
    if (_fileBytes == null || _fileName == null) return;

    setState(() {
      _uploadStatus = 'Uploading securely to Cloud...';
    });

    try {
      final resumeService = context.read<ResumeService>();

      // Simulate UI micro-steps for better user experience
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted && _uploadStatus.isNotEmpty) {
          setState(() {
            _uploadStatus = 'Extracting PDF Data...';
          });
        }
      });
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted && _uploadStatus.isNotEmpty) {
          setState(() {
            _uploadStatus = 'AI Analysis in progress...';
          });
        }
      });

      final analysisResult = await resumeService.processAndAnalyzeResume(
        _fileBytes!,
        _fileName!,
        jobDescription: _jobDescriptionController.text,
      );

      if (mounted) {
        setState(() {
          _uploadStatus = '';
        });
        context.push('/analysis', extra: analysisResult);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _uploadStatus = '';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error analyzing resume: $e'),
            backgroundColor: Colors.redAccent,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          'Analyze Resume',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () => context.pop(),
        ),
      ),
      body: KineticBackground(
        child: Center(
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(32),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                child: Container(
                  width: 500,
                  margin: const EdgeInsets.symmetric(horizontal: 24),
                  padding: const EdgeInsets.all(48.0),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(32),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.1),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF00FFC2).withOpacity(0.1),
                        blurRadius: 40,
                        spreadRadius: 10,
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(28),
                        decoration: BoxDecoration(
                          color: const Color(0xFF00FFC2).withOpacity(0.15),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: const Color(0xFF00FFC2).withOpacity(0.6),
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF00FFC2).withOpacity(0.3),
                              blurRadius: 20,
                              spreadRadius: 5,
                            ),
                          ],
                        ),
                        child: Icon(
                          _fileBytes == null
                              ? Icons.document_scanner
                              : Icons.picture_as_pdf,
                          size: 80,
                          color: const Color(0xFF00FFC2),
                        ),
                      ),
                      const SizedBox(height: 32),
                      Text(
                        _fileName ?? 'Upload Your PDF Resume',
                        style: Theme.of(context).textTheme.headlineMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Our AI will analyze your skills, experience, and projects to generate smart improvement suggestions.',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 16,
                          height: 1.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 32),
                      TextField(
                        controller: _jobDescriptionController,
                        maxLines: 3,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: 'Paste Job Description here (Optional)',
                          hintStyle: TextStyle(
                            color: Colors.white.withOpacity(0.5),
                          ),
                          filled: true,
                          fillColor: Colors.white.withOpacity(0.05),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(
                              color: Colors.white.withOpacity(0.1),
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(
                              color: Colors.white.withOpacity(0.1),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: const BorderSide(
                              color: Color(0xFF00FFC2),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      if (_uploadStatus.isNotEmpty) ...[
                        const CircularProgressIndicator(
                          color: Color(0xFF00FFC2),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          _uploadStatus,
                          style: const TextStyle(
                            color: Color(0xFF00FFC2),
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ] else if (_fileBytes == null)
                        ElevatedButton.icon(
                          onPressed: _pickFile,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 40,
                              vertical: 20,
                            ),
                            backgroundColor: Colors.white.withOpacity(0.1),
                          ),
                          icon: const Icon(Icons.folder_open),
                          label: const Text('Browse Files'),
                        )
                      else ...[
                        ElevatedButton.icon(
                          onPressed: _uploadAndAnalyze,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 40,
                              vertical: 20,
                            ),
                            backgroundColor: const Color(0xFF00FFC2),
                            foregroundColor: Colors.black,
                            shadowColor: const Color(
                              0xFF00FFC2,
                            ).withOpacity(0.5),
                          ),
                          icon: const Icon(Icons.auto_awesome),
                          label: const Text('Start Analysis'),
                        ),
                        const SizedBox(height: 16),
                        TextButton(
                          onPressed: _pickFile,
                          child: const Text(
                            'Select another file',
                            style: TextStyle(color: Colors.white54),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
