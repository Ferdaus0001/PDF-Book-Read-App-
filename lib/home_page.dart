import 'dart:io';
import 'package:external_path/external_path.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:path/path.dart' as path;
import 'package:permission_handler/permission_handler.dart';
import 'package:ffff/view/pdvViewScreen.dart';

class PdfScreen extends StatefulWidget {
  const PdfScreen({super.key});

  @override
  State<PdfScreen> createState() => _PdfScreenState();
}

class _PdfScreenState extends State<PdfScreen> with SingleTickerProviderStateMixin {
  final List<String> _pdfFiles = [];
  List<String> _filteredFiles = [];
  bool _isLoading = true;
  bool isSearching = false;
  TextEditingController searchController = TextEditingController();

  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    requestPermissionAndLoadFiles();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
  }

  @override
  void dispose() {
    searchController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> requestPermissionAndLoadFiles() async {
    bool granted = await _checkAndRequestPermissions();
    if (granted) {
      String downloadPath = await ExternalPath.getExternalStoragePublicDirectory(
          ExternalPath.DIRECTORY_DOWNLOAD);

      if (downloadPath.isNotEmpty) {
        await _getFilesRecursively(downloadPath);
      }

      setState(() {
        _filteredFiles = List.from(_pdfFiles);
        _isLoading = false;
      });
    } else {
      setState(() {
        _isLoading = false;
      });
      debugPrint('Permission denied');
      Get.snackbar(
        'Permission Denied',
        'Storage permission is required to access PDF files.',
        backgroundColor: Colors.red.shade400,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  Future<bool> _checkAndRequestPermissions() async {
    if (Platform.isAndroid) {
      if (await Permission.storage.request().isGranted) {
        return true;
      }
      if (await Permission.manageExternalStorage.request().isGranted) {
        return true;
      }
      return false;
    }
    return true; // iOS or others
  }

  Future<void> _getFilesRecursively(String directoryPath) async {
    try {
      final rootDir = Directory(directoryPath);
      final List<FileSystemEntity> entities = await rootDir.list(recursive: true).toList();

      for (var entity in entities) {
        if (entity is File && entity.path.toLowerCase().endsWith('.pdf')) {
          _pdfFiles.add(entity.path);
        }
      }
    } catch (e) {
      debugPrint('Error while fetching files: $e');
    }
  }

  void _filterFiles(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredFiles = List.from(_pdfFiles);
      } else {
        _filteredFiles = _pdfFiles.where((file) {
          final fileName = path.basename(file).toLowerCase();
          return fileName.contains(query.toLowerCase());
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        backgroundColor: Colors.deepPurple,
        elevation: 6,
        title: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: !isSearching
              ? const Text(
            'PDF Reader',
            key: ValueKey('title'),
            style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white),
          )
              : TextField(
            key: const ValueKey('searchField'),
            controller: searchController,
            autofocus: true,
            decoration: InputDecoration(
              hintText: 'Search PDFs...',
              border: InputBorder.none,
              hintStyle:
              TextStyle(color: Colors.white70.withOpacity(0.8)),
            ),
            style: const TextStyle(color: Colors.white),
            cursorColor: Colors.white,
            onChanged: _filterFiles,
          ),
          transitionBuilder: (Widget child, Animation<double> animation) {
            return FadeTransition(opacity: animation, child: child);
          },
        ),
        actions: [
          IconButton(
            icon: Icon(isSearching ? Icons.close : Icons.search,
                color: Colors.white),
            onPressed: () {
              setState(() {
                if (isSearching) {
                  searchController.clear();
                  _filterFiles('');
                }
                isSearching = !isSearching;
              });
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
        child: CircularProgressIndicator(color: Colors.blueAccent),
      )
          : _filteredFiles.isEmpty
          ? Center(
        child: Text(
          "No PDF files found",
          style: TextStyle(
              fontSize: 18, color: Colors.grey.shade600),
        ),
      )
          : ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 12),
        itemCount: _filteredFiles.length,
        itemBuilder: (context, index) {
          String filePath = _filteredFiles[index];
          String fileName = path.basename(filePath);
          return Padding(
            padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Card(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              elevation: 4,
              shadowColor: Colors.deepPurple.shade100,
              child: ListTile(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                tileColor: Colors.white,
                title: Text(
                  fileName,
                  style: const TextStyle(fontWeight: FontWeight.w600,color: Colors.black),
                ),
                leading: const Icon(Icons.picture_as_pdf,
                    color: Colors.redAccent, size: 28),
                trailing: const Icon(Icons.arrow_forward_ios,
                    size: 20, color: Colors.deepPurple),
                onTap: () {
                  Get.to(() => PdvViewScreen(
                      pdfName: fileName, pdfPath: filePath));
                },
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.deepPurple,
        onPressed: () {
          setState(() {
            _pdfFiles.clear();
            _filteredFiles.clear();
            _isLoading = true;
          });
          requestPermissionAndLoadFiles();
        },
        child: const Icon(Icons.refresh, color: Colors.white),
      ),
    );
  }
}
