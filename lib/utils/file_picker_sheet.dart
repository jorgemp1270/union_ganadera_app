import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

/// A reusable bottom-sheet that lets the user pick a file from camera,
/// gallery, or file picker. Returns the chosen [File] or null if cancelled.
///
/// Usage:
/// ```dart
/// final file = await FilePickerSheet.show(context);
/// ```
class FilePickerSheet {
  FilePickerSheet._();

  static Future<File?> show(
    BuildContext context, {

    /// Whether to include the file-picker (PDF/docs) option.
    bool includeFilePicker = true,

    /// Custom title shown at the top of the sheet.
    String title = 'Seleccionar archivo',
  }) {
    return showModalBottomSheet<File?>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder:
          (ctx) => _FilePickerSheetContent(
            title: title,
            includeFilePicker: includeFilePicker,
          ),
    );
  }
}

class _FilePickerSheetContent extends StatelessWidget {
  final String title;
  final bool includeFilePicker;

  const _FilePickerSheetContent({
    required this.title,
    required this.includeFilePicker,
  });

  @override
  Widget build(BuildContext context) {
    final picker = ImagePicker();
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: Text(
                title,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: const Text('Tomar foto'),
              onTap: () async {
                final img = await picker.pickImage(
                  source: ImageSource.camera,
                  imageQuality: 85,
                );
                if (context.mounted) {
                  Navigator.pop(context, img != null ? File(img.path) : null);
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Galería de fotos'),
              onTap: () async {
                final img = await picker.pickImage(
                  source: ImageSource.gallery,
                  imageQuality: 85,
                );
                if (context.mounted) {
                  Navigator.pop(context, img != null ? File(img.path) : null);
                }
              },
            ),
            if (includeFilePicker)
              ListTile(
                leading: const Icon(Icons.attach_file_rounded),
                title: const Text('Seleccionar archivo (PDF, imagen…)'),
                onTap: () async {
                  final result = await FilePicker.platform.pickFiles();
                  if (context.mounted) {
                    Navigator.pop(
                      context,
                      result?.files.single.path != null
                          ? File(result!.files.single.path!)
                          : null,
                    );
                  }
                },
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
