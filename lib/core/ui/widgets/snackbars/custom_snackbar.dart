import 'package:flutter/material.dart';

class CustomSnackbar {
  static void showSuccess(BuildContext context, String message) {
    _show(
      context,
      message: message,
      color: const Color(0xFF2E7D32),
      icon: Icons.check_circle_rounded,
    );
  }

  static void showFailure(BuildContext context, String message) {
    _show(
      context,
      message: message,
      color: const Color(0xFFD32F2F),
      icon: Icons.error_rounded,
    );
  }

  static void _show(
    BuildContext context, {
    required String message,
    required Color color,
    required IconData icon,
  }) {
    const duration = Duration(milliseconds: 1500);

    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();

    messenger.showSnackBar(
      SnackBar(
        duration: duration,
        behavior: SnackBarBehavior.floating,
        dismissDirection: DismissDirection.horizontal,
        elevation: 6,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        backgroundColor: Colors.transparent,
        padding: EdgeInsets.zero,
        content: _SnackbarContent(
          message: message,
          duration: duration,
          color: color,
          icon: icon,
        ),
      ),
    );
  }
}

class _SnackbarContent extends StatefulWidget {
  final String message;
  final Duration duration;
  final Color color;
  final IconData icon;

  const _SnackbarContent({
    required this.message,
    required this.duration,
    required this.color,
    required this.icon,
  });

  @override
  State<_SnackbarContent> createState() => _SnackbarContentState();
}

class _SnackbarContentState extends State<_SnackbarContent>
    with SingleTickerProviderStateMixin {
  late AnimationController controller;

  @override
  void initState() {
    super.initState();

    controller = AnimationController(vsync: this, duration: widget.duration)
      ..forward();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: widget.color,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(
            blurRadius: 12,
            offset: Offset(0, 6),
            color: Colors.black26,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Icon(widget.icon, color: Colors.white, size: 22),

                const SizedBox(width: 12),

                Expanded(
                  child: Text(
                    widget.message,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),

                GestureDetector(
                  onTap: () {
                    ScaffoldMessenger.of(context).hideCurrentSnackBar();
                  },
                  child: const Icon(
                    Icons.close_rounded,
                    color: Colors.white70,
                    size: 20,
                  ),
                ),
              ],
            ),
          ),

          ClipRRect(
            borderRadius: const BorderRadius.vertical(
              bottom: Radius.circular(14),
            ),
            child: AnimatedBuilder(
              animation: controller,
              builder: (context, child) {
                return LinearProgressIndicator(
                  value: controller.value,
                  backgroundColor: Colors.white24,
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    Colors.white70,
                  ),
                  minHeight: 3,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
