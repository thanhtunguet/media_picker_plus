import 'package:flutter/material.dart';
import 'package:media_picker_plus/media_picker_plus.dart';

class FilePickerFeature extends StatefulWidget {
  const FilePickerFeature({super.key});

  @override
  State<FilePickerFeature> createState() => _FilePickerFeatureState();
}

class _FilePickerFeatureState extends State<FilePickerFeature> {
  String? _filePath;
  List<String> _multipleFilePaths = [];
  bool _isLoading = false;

  final List<String> _allowedExtensions = [
    '.pdf',
    '.doc',
    '.docx',
    '.txt',
    '.csv',
    '.xls',
    '.xlsx',
    '.pptx',
    '.zip',
    '.json'
  ];

  Future<void> _pickFile() async {
    setState(() => _isLoading = true);
    try {
      final path = await MediaPickerPlus.pickFile(
        allowedExtensions: _allowedExtensions,
      );
      setState(() => _filePath = path);
    } catch (e) {
      _showError('Error picking file: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _pickMultipleFiles() async {
    setState(() => _isLoading = true);
    try {
      final paths = await MediaPickerPlus.pickMultipleFiles(
        allowedExtensions: _allowedExtensions,
      );
      setState(() => _multipleFilePaths = List<String>.from(paths ?? []));
    } catch (e) {
      _showError('Error picking multiple files: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _clearSingleFile() => setState(() => _filePath = null);
  void _clearMultipleFiles() => setState(() => _multipleFilePaths.clear());

  String _getFileName(String path) => path.split('/').last;

  String _getShortPath(String path) {
    if (path.length > 40) {
      return '...${path.substring(path.length - 37)}';
    }
    return path;
  }

  Widget _buildFileTypeInfo() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Supported File Types',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            const Text('📄 Documents: .pdf, .doc, .docx, .txt'),
            const Text('📊 Spreadsheets: .csv, .xls, .xlsx'),
            const Text('📈 Presentations: .pptx'),
            const Text('🗜️ Archives: .zip'),
            const Text('📋 Data: .json'),
            const SizedBox(height: 12),
            const Text(
              'Tip: File types can be customized by modifying the allowedExtensions parameter.',
              style: TextStyle(
                  fontStyle: FontStyle.italic,
                  fontSize: 12,
                  color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSingleFilePreview() {
    if (_filePath == null) return const SizedBox.shrink();

    return Card(
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.description),
            title: const Text('Selected File'),
            trailing: IconButton(
              icon: const Icon(Icons.clear),
              onPressed: _clearSingleFile,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.description, size: 64, color: Colors.blue),
                const SizedBox(height: 12),
                Text(
                  'File: ${_getFileName(_filePath!)}',
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  'Path: ${_getShortPath(_filePath!)}',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMultipleFilesPreview() {
    if (_multipleFilePaths.isEmpty) return const SizedBox.shrink();

    return Card(
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.folder_open),
            title: Text('Multiple Files (${_multipleFilePaths.length})'),
            trailing: IconButton(
              icon: const Icon(Icons.clear),
              onPressed: _clearMultipleFiles,
            ),
          ),
          SizedBox(
            height: 200,
            child: ListView.builder(
              itemCount: _multipleFilePaths.length,
              itemBuilder: (context, index) {
                final path = _multipleFilePaths[index];
                final fileName = _getFileName(path);
                return ListTile(
                  leading: const Icon(Icons.description),
                  title: Text(fileName),
                  subtitle: Text(
                    _getShortPath(path),
                    style: const TextStyle(fontSize: 11),
                  ),
                  onTap: () {
                    // Could add file preview or actions here
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('File Picker'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // File Type Information
                Expanded(
                  flex: 1,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(8),
                    child: _buildFileTypeInfo(),
                  ),
                ),

                // Action Buttons
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _pickFile,
                          icon: const Icon(Icons.folder, size: 18),
                          label: const Text('Pick Single File',
                              style: TextStyle(fontSize: 12)),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _pickMultipleFiles,
                          icon: const Icon(Icons.folder_open, size: 18),
                          label: const Text('Pick Multiple Files',
                              style: TextStyle(fontSize: 12)),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Preview Section
                Expanded(
                  flex: 2,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        _buildSingleFilePreview(),
                        const SizedBox(height: 16),
                        _buildMultipleFilesPreview(),
                        if (_filePath == null && _multipleFilePaths.isEmpty)
                          const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.folder,
                                    size: 64, color: Colors.grey),
                                SizedBox(height: 16),
                                Text(
                                  'No files selected',
                                  style: TextStyle(
                                      fontSize: 18, color: Colors.grey),
                                ),
                                SizedBox(height: 8),
                                Text(
                                  'Tap pick to select files',
                                  style: TextStyle(color: Colors.grey),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
