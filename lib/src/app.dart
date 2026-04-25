import 'package:flutter/material.dart';

import 'services/export_service.dart';
import 'services/gallery_storage_service.dart';
import 'services/image_pick_service.dart';
import 'services/local_coloring_pipeline_service.dart';
import 'state/magic_book_controller.dart';
import 'state/magic_book_scope.dart';
import 'theme/magic_book_theme.dart';
import 'screens/home_shell.dart';

class MagicBookApp extends StatefulWidget {
  const MagicBookApp({super.key});

  @override
  State<MagicBookApp> createState() => _MagicBookAppState();
}

class _MagicBookAppState extends State<MagicBookApp> {
  late final MagicBookController _controller;

  @override
  void initState() {
    super.initState();
    _controller = MagicBookController(
      imagePickService: MobileImagePickService(),
      pipelineService: const LocalColoringPipelineService(),
      galleryStorageService: InMemoryGalleryStorageService(),
      exportService: MobileExportService(),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return MagicBookScope(
          controller: _controller,
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'MagicBook',
            theme: MagicBookTheme.light(),
            home: const HomeShell(),
          ),
        );
      },
    );
  }
}
