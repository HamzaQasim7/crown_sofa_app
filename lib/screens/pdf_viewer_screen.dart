import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:form_order_app/data/models/order_model.dart';

import '../services/pdf_service.dart';

class PdfPreviewScreen extends StatefulWidget {
  final OrderModel order;

  const PdfPreviewScreen({super.key, required this.order});

  @override
  State<StatefulWidget> createState() => _PdfPreviewScreenState();
}

class _PdfPreviewScreenState extends State<PdfPreviewScreen> {
  final PdfService _pdfService = PdfService();
  File? _pdfFile;
  bool _isLoading = true;
  bool _isSaving = false;
  String? _errorMessage;
  int _totalPages = 0;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _generatePdf();
  }

  Future<void> _generatePdf() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final pdfFile = await _pdfService.generateOrderPdf(widget.order);

      setState(() {
        _pdfFile = pdfFile;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to generate PDF: $e';
      });
    }
  }

  Future<void> _savePdfToGallery() async {
    if (_pdfFile == null) return;

    setState(() {
      _isSaving = true;
    });

    try {
      final success = await _pdfService.savePdfToGallery(_pdfFile!, context);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? 'Receipt saved to gallery successfully!'
                : 'Failed to save receipt to gallery',
          ),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }

  Future<void> _sharePdf() async {
    if (_pdfFile == null) return;
    await _pdfService.sharePdf(_pdfFile!);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () {
            Navigator.pop(context);
          },
          icon: Icon(Icons.navigate_before, color: Colors.white),
        ),
        title: const Text('Receipt Preview'),
        actions: [
          if (_pdfFile != null)
            IconButton(
              icon: const Icon(Icons.share, color: Colors.white),
              onPressed: _sharePdf,
              tooltip: 'Share Receipt',
            ),
        ],
      ),
      body: _buildBody(),
      floatingActionButton:
          _pdfFile != null
              ? FloatingActionButton.extended(
                onPressed: _isSaving ? null : _savePdfToGallery,
                label: Text(_isSaving ? 'Saving...' : 'Save to Gallery'),
                icon: Icon(_isSaving ? Icons.hourglass_empty : Icons.save),
                backgroundColor:
                    _isSaving ? Colors.grey : Theme.of(context).primaryColor,
              )
              : null,
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Generating receipt...'),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 48),
            const SizedBox(height: 16),
            Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _generatePdf,
              child: const Text('Try Again'),
            ),
          ],
        ),
      );
    }

    if (_pdfFile == null) {
      return const Center(child: Text('No PDF available'));
    }

    return Column(
      children: [
        Expanded(
          child: PDFView(
            filePath: _pdfFile!.path,
            enableSwipe: true,
            swipeHorizontal: true,
            autoSpacing: false,
            pageFling: false,
            pageSnap: true,
            defaultPage: _currentPage,
            onRender: (pages) {
              setState(() {
                _totalPages = pages!;
              });
            },
            onViewCreated: (PDFViewController pdfViewController) {
              // PDF view created
            },
            onPageChanged: (int? page, int? total) {
              if (page != null) {
                setState(() {
                  _currentPage = page;
                });
              }
            },
            onError: (error) {
              setState(() {
                _errorMessage = error.toString();
              });
            },
          ),
        ),
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.grey[200],
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Page ${_currentPage + 1} of $_totalPages',
                style: const TextStyle(fontSize: 16),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
