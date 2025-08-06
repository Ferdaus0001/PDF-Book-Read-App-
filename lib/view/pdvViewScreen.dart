import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';

class PdvViewScreen extends StatefulWidget {
  final String pdfName;
  final String pdfPath;

  const PdvViewScreen({super.key, required this.pdfName, required this.pdfPath});

  @override
  State<PdvViewScreen> createState() => _PdvViewScreenState();
}

class _PdvViewScreenState extends State<PdvViewScreen> with SingleTickerProviderStateMixin {
  int totalPage = 0;
  int currentPage = 0;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _onPageChanged(int? page, int? total) {
    if (page != null && total != null) {
      setState(() {
        currentPage = page;
        totalPage = total;
      });
      _animationController.forward(from: 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        centerTitle: true,
        title: Text(
          widget.pdfName,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.black87,
            fontSize: 18,
          ),
          overflow: TextOverflow.ellipsis,
        ),
        iconTheme: const IconThemeData(color: Colors.deepPurple),
      ),
      body: Stack(
        children: [
          PDFView(

            filePath: widget.pdfPath,
            enableSwipe: true,
            swipeHorizontal: true,
            autoSpacing: false,
            pageFling: true,
            onPageChanged: (page, total) {
              _onPageChanged(page, total);
            },
            onRender: (pages) {
              setState(() {
                totalPage = pages ?? 0;
              });
            },
            onError: (error) {
              debugPrint('PDFView Error: $error');
            },
            onPageError: (page, error) {
              debugPrint('Page $page error: $error');
            },
          ),
          if (totalPage > 0)
            Positioned(
              bottom: 20,
              left: 0,
              right: 0,
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Center(
                  child: Container(
                    padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.deepPurple.withOpacity(0.85),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.deepPurple.withOpacity(0.4),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Text(
                      'Page ${currentPage + 1} of $totalPage',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
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
