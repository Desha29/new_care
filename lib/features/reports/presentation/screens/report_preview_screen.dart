import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:printing/printing.dart';
import '../../../../core/constants/app_colors.dart';

class ReportPreviewScreen extends StatefulWidget {
  final String title;
  final String fileName;
  final Future<Uint8List> Function() buildReport;
  final List<Widget>? extraActions;
  final Future<void> Function()? onExportExcel;

  const ReportPreviewScreen({
    super.key,
    required this.title,
    required this.fileName,
    required this.buildReport,
    this.extraActions,
    this.onExportExcel,
  });

  @override
  State<ReportPreviewScreen> createState() => _ReportPreviewScreenState();
}

class _ReportPreviewScreenState extends State<ReportPreviewScreen> {
  final ScrollController _scrollController = ScrollController();

  int _currentPage = 1;
  int _totalPages = 0;

  // Heights of each page item (page height + separator) — populated once pages are known
  double _pageItemHeight = 0;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_pageItemHeight <= 0 || _totalPages == 0) return;
    // Each page item occupies _pageItemHeight pixels (page + 14 separator).
    // Top padding = 16px.
    final offset = _scrollController.offset;
    final page = ((offset - 16) / _pageItemHeight).floor() + 1;
    final clamped = page.clamp(1, _totalPages);
    if (clamped != _currentPage) {
      setState(() => _currentPage = clamped);
    }
  }

  void _scrollToPage(int page) {
    if (_pageItemHeight <= 0) return;
    final targetOffset = 16.0 + (page - 1) * _pageItemHeight;
    _scrollController.animateTo(
      targetOffset.clamp(0, _scrollController.position.maxScrollExtent),
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
    );
  }

  void _goToPrevPage() {
    if (_currentPage > 1) _scrollToPage(_currentPage - 1);
  }

  void _goToNextPage() {
    if (_currentPage < _totalPages) _scrollToPage(_currentPage + 1);
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFEEF0F5),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          surfaceTintColor: Colors.transparent,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary),
            onPressed: () => Navigator.pop(context),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.description_rounded,
                  color: AppColors.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.title,
                      style: const TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      'معاينة التقرير قبل الطباعة',
                      style: const TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            // Page counter badge in the app bar
            if (_totalPages > 0)
              Container(
                margin: const EdgeInsets.only(left: 16),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.2),
                  ),
                ),
                child: Text(
                  'صفحة $_currentPage من $_totalPages',
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ),
          ],
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(1),
            child: Container(color: AppColors.border, height: 1),
          ),
        ),
        body: Column(
          children: [
            // ── PDF Pages Area ──────────────────────────────────────────────
            Expanded(
              child: PdfPreview.builder(
                build: (format) => widget.buildReport(),
                allowSharing: false,
                allowPrinting: false,
                canChangePageFormat: false,
                canChangeOrientation: false,
                canDebug: false,
                enableScrollToPage: true,
                pagesBuilder: (context, pages) {
                  // Update total page count
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (pages.length != _totalPages) {
                      setState(() => _totalPages = pages.length);
                    }
                  });

                  return LayoutBuilder(
                    builder: (context, constraints) {
                      // Compute the rendered height of a page card so we can
                      // scroll precisely to any page.
                      final pageWidth = constraints.maxWidth - 16 * 2 - 8 * 2;
                      // Use the aspect ratio of the first page (all pages are
                      // the same format), fallback to A4 ~1.414
                      final ratio = pages.isNotEmpty
                          ? pages[0].aspectRatio
                          : (1 / 1.4142);
                      final pageHeight = pageWidth / ratio;
                      final itemHeight = pageHeight + 14; // + separator

                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (_pageItemHeight != itemHeight) {
                          setState(() => _pageItemHeight = itemHeight);
                        }
                      });

                      return ListView.separated(
                        controller: _scrollController,
                        padding: const EdgeInsets.symmetric(
                          vertical: 16,
                          horizontal: 16,
                        ),
                        itemCount: pages.length,
                        separatorBuilder: (_, _) =>
                            const SizedBox(height: 14),
                        itemBuilder: (context, i) {
                          final isCurrentPage = (i + 1) == _currentPage;
                          return _PageCard(
                            image: pages[i].image,
                            aspectRatio: pages[i].aspectRatio,
                            pageNumber: i + 1,
                            totalPages: pages.length,
                            isCurrentPage: isCurrentPage,
                          );
                        },
                      );
                    },
                  );
                },
                loadingWidget: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 48,
                        height: 48,
                        child: CircularProgressIndicator(
                          strokeWidth: 3,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            AppColors.primary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'جاري تجهيز التقرير...',
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 14,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                pdfFileName: widget.fileName,
              ),
            ),

            // ── Bottom Action Bar ───────────────────────────────────────────
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(
                  top: BorderSide(color: AppColors.border, width: 1),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: SafeArea(
                child: Row(
                  children: [
                    // ── Page navigation (prev / next) ──
                    if (_totalPages > 1) ...[
                      _NavButton(
                        icon: Icons.chevron_right_rounded,
                        tooltip: 'الصفحة السابقة',
                        onPressed: _currentPage > 1 ? _goToPrevPage : null,
                      ),
                      const SizedBox(width: 4),
                      // Compact page indicator
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEEF0F5),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '$_currentPage / $_totalPages',
                          style: const TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      _NavButton(
                        icon: Icons.chevron_left_rounded,
                        tooltip: 'الصفحة التالية',
                        onPressed:
                            _currentPage < _totalPages ? _goToNextPage : null,
                      ),
                      const SizedBox(width: 12),
                    ],

                    // ── File name ──
                    Expanded(
                      child: Row(
                        children: [
                          const Icon(
                            Icons.insert_drive_file_rounded,
                            size: 18,
                            color: AppColors.textHint,
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              '${widget.fileName}.pdf',
                              style: const TextStyle(
                                fontFamily: 'Cairo',
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // ── Extra actions ──
                    if (widget.extraActions != null) ...[
                      ...widget.extraActions!,
                      const SizedBox(width: 12),
                    ],

                    // ── Excel export ──
                    if (widget.onExportExcel != null) ...[
                      ElevatedButton.icon(
                        onPressed: () async {
                          try {
                            await widget.onExportExcel!();
                          } catch (_) {}
                        },
                        icon: const Icon(Icons.table_view_rounded, size: 18),
                        label: const Text(
                          'Excel تصدير',
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF107C41),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 18, vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                      const SizedBox(width: 12),
                    ],

                    // ── Share ──
                    OutlinedButton.icon(
                      onPressed: () async {
                        final bytes = await widget.buildReport();
                        await Printing.sharePdf(
                          bytes: bytes,
                          filename: '${widget.fileName}.pdf',
                        );
                      },
                      icon: const Icon(Icons.share_rounded, size: 18),
                      label: const Text(
                        'مشاركة',
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.secondary,
                        side: BorderSide(
                          color: AppColors.secondary.withValues(alpha: 0.3),
                        ),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 18, vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(width: 12),

                    // ── Print ──
                    ElevatedButton.icon(
                      onPressed: () async {
                        final bytes = await widget.buildReport();
                        await Printing.layoutPdf(
                          onLayout: (format) async => bytes,
                          name: widget.fileName,
                        );
                      },
                      icon: const Icon(Icons.print_rounded, size: 18),
                      label: const Text(
                        'طباعة',
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 22, vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Single PDF page card
// ─────────────────────────────────────────────────────────────────────────────
class _PageCard extends StatelessWidget {
  final ImageProvider image;
  final double aspectRatio;
  final int pageNumber;
  final int totalPages;
  final bool isCurrentPage;

  const _PageCard({
    required this.image,
    required this.aspectRatio,
    required this.pageNumber,
    required this.totalPages,
    required this.isCurrentPage,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Page shadow + border
        AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isCurrentPage
                  ? AppColors.primary.withValues(alpha: 0.5)
                  : AppColors.border,
              width: isCurrentPage ? 1.8 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: isCurrentPage
                    ? AppColors.primary.withValues(alpha: 0.12)
                    : Colors.black.withValues(alpha: 0.06),
                blurRadius: isCurrentPage ? 12 : 6,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(7),
            child: AspectRatio(
              aspectRatio: aspectRatio,
              child: Image(image: image, fit: BoxFit.cover),
            ),
          ),
        ),
        // Page number label
        const SizedBox(height: 6),
        Text(
          'صفحة $pageNumber من $totalPages',
          style: TextStyle(
            fontFamily: 'Cairo',
            fontSize: 11,
            color: isCurrentPage ? AppColors.primary : AppColors.textHint,
            fontWeight:
                isCurrentPage ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Simple navigation icon button
// ─────────────────────────────────────────────────────────────────────────────
class _NavButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;

  const _NavButton({
    required this.icon,
    required this.tooltip,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(8),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: enabled
                ? AppColors.primary.withValues(alpha: 0.08)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            size: 22,
            color: enabled ? AppColors.primary : AppColors.textHint,
          ),
        ),
      ),
    );
  }
}
