import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'dart:typed_data';

/// Service for extracting text content from PDF files.
class PdfService {
  /// Extract all text from a PDF file's bytes.
  Future<String> extractText(Uint8List pdfBytes) async {
    try {
      final PdfDocument document = PdfDocument(inputBytes: pdfBytes);
      final StringBuffer buffer = StringBuffer();

      for (int i = 0; i < document.pages.count; i++) {
        final text = PdfTextExtractor(document).extractText(startPageIndex: i);
        buffer.writeln(text);
      }

      document.dispose();
      final extracted = buffer.toString().trim();

      if (extracted.isEmpty) {
        throw PdfServiceException(
          'Could not extract text from this PDF. '
          'The file might be scanned or image-based.',
        );
      }

      return extracted;
    } catch (e) {
      if (e is PdfServiceException) rethrow;
      throw PdfServiceException('Failed to read PDF: $e');
    }
  }
}

/// Custom exception for PDF service errors.
class PdfServiceException implements Exception {
  final String message;
  const PdfServiceException(this.message);

  @override
  String toString() => 'PdfServiceException: $message';
}
