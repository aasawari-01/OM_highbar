import 'package:flutter/material.dart';
import '../../constants/colors.dart';

class HorizontalPaginatedView extends StatefulWidget {
  final List<Widget> items;

  const HorizontalPaginatedView({Key? key, required this.items}) : super(key: key);

  @override
  _HorizontalPaginatedViewState createState() => _HorizontalPaginatedViewState();
}

class _HorizontalPaginatedViewState extends State<HorizontalPaginatedView> {
  int _currentIndex = 0;

  void _nextPage() {
    if (_currentIndex < widget.items.length - 1) {
      setState(() {
        _currentIndex++;
      });
    }
  }

  void _prevPage() {
    if (_currentIndex > 0) {
      setState(() {
        _currentIndex--;
      });
    }
  }

  void _onSwipe(DragEndDetails details) {
    if (details.primaryVelocity != null) {
      if (details.primaryVelocity! < -300) {
        // Swipe left
        _nextPage();
      } else if (details.primaryVelocity! > 300) {
        // Swipe right
        _prevPage();
      }
    }
  }

  @override
  void didUpdateWidget(HorizontalPaginatedView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.items.isEmpty) {
      _currentIndex = 0;
    } else if (_currentIndex >= widget.items.length) {
      _currentIndex = widget.items.length - 1;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.items.isEmpty) return const SizedBox.shrink();

    return Column(
      children: [
        GestureDetector(
          onHorizontalDragEnd: _onSwipe,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            transitionBuilder: (Widget child, Animation<double> animation) {
              return FadeTransition(opacity: animation, child: child);
            },
            child: SizedBox(
              key: ValueKey<int>(_currentIndex),
              width: double.infinity,
              child: widget.items[_currentIndex],
            ),
          ),
        ),
        if (widget.items.length > 1) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: Icon(Icons.arrow_back_ios, size: 16, color: _currentIndex > 0 ? AppColors.orangeColor : Colors.grey),
                onPressed: _currentIndex > 0 ? _prevPage : null,
                padding: const EdgeInsets.all(8),
                constraints: const BoxConstraints(),
              ),
              const SizedBox(width: 12),
              Text(
                "${_currentIndex + 1} / ${widget.items.length}",
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textMutedLight),
              ),
              const SizedBox(width: 12),
              IconButton(
                icon: Icon(Icons.arrow_forward_ios, size: 16, color: _currentIndex < widget.items.length - 1 ? AppColors.orangeColor : Colors.grey),
                onPressed: _currentIndex < widget.items.length - 1 ? _nextPage : null,
                padding: const EdgeInsets.all(8),
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: 8),
        ]
      ],
    );
  }
}
