import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

/// شريط البحث - Search Bar Widget
class SearchBarWidget extends StatefulWidget {
  final String hintText;
  final ValueChanged<String> onChanged;
  final TextEditingController? controller;
  final VoidCallback? onClear;
  final Widget? trailing;
  final double? maxWidth;

  const SearchBarWidget({
    super.key,
    required this.hintText,
    required this.onChanged,
    this.controller,
    this.onClear,
    this.trailing,
    this.maxWidth = 400,
  });

  @override
  State<SearchBarWidget> createState() => _SearchBarWidgetState();
}

class _SearchBarWidgetState extends State<SearchBarWidget> {
  bool _isHovered = false;
  late FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _focusNode.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isFocusedOrHovered = _focusNode.hasFocus || _isHovered;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 50,
        constraints: BoxConstraints(maxWidth: widget.maxWidth ?? 400),
        decoration: BoxDecoration(
          color: isFocusedOrHovered
              ? AppColors.surfaceVariant
              : AppColors.surface,
          borderRadius: BorderRadius.circular(500),
          border: Border.all(
            color: isFocusedOrHovered ? AppColors.primary : AppColors.border,
            width: isFocusedOrHovered ? 1.5 : 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: isFocusedOrHovered
                  ? AppColors.primary.withValues(alpha: 0.08)
                  : Colors.black.withValues(alpha: 0.02),
              blurRadius: isFocusedOrHovered ? 12 : 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: widget.controller,
                focusNode: _focusNode,
                onChanged: widget.onChanged,
                textDirection: TextDirection.rtl,
                style: const TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 14,
                  color: AppColors.textPrimary,
                ),
                decoration: InputDecoration(
                  hintText: widget.hintText,
                  hintStyle: const TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 13,
                    color: AppColors.textHint,
                  ),
                  prefixIcon: AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 200),
                    style: TextStyle(
                      color: isFocusedOrHovered
                          ? AppColors.primary
                          : AppColors.textHint,
                    ),
                    child: Icon(
                      Icons.search_rounded,
                      color: isFocusedOrHovered
                          ? AppColors.primary
                          : AppColors.textHint,
                      size: 20,
                    ),
                  ),
                  suffixIcon:
                      widget.controller != null &&
                          widget.controller!.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(
                            Icons.close_rounded,
                            size: 18,
                            color: AppColors.textHint,
                          ),
                          onPressed: () {
                            widget.controller?.clear();
                            widget.onChanged('');
                            widget.onClear?.call();
                            _focusNode.requestFocus();
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                ),
              ),
            ),
            if (widget.trailing != null) ...[
              Container(height: 30, width: 1, color: AppColors.border),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: widget.trailing!,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
