import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_colors.dart';

class PinInputWidget extends StatefulWidget {
  final Function(String) onCompleted;
  final int pinLength;

  const PinInputWidget({
    super.key,
    required this.onCompleted,
    this.pinLength = 4,
  });

  @override
  State<PinInputWidget> createState() => _PinInputWidgetState();
}

class _PinInputWidgetState extends State<PinInputWidget> {
  late List<String> _pin;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _pin = List.filled(widget.pinLength, '');
  }

  void _onKeyPressed(String value) {
    if (_currentIndex < widget.pinLength) {
      setState(() {
        _pin[_currentIndex] = value;
        _currentIndex++;
      });

      if (_currentIndex == widget.pinLength) {
        widget.onCompleted(_pin.join());
        // Reset after a short delay
        Future.delayed(const Duration(milliseconds: 300), () {
          if (mounted) {
            setState(() {
              _pin = List.filled(widget.pinLength, '');
              _currentIndex = 0;
            });
          }
        });
      }
    }
  }

  void _onBackspace() {
    if (_currentIndex > 0) {
      setState(() {
        _currentIndex--;
        _pin[_currentIndex] = '';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // PIN Dots
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            widget.pinLength,
            (index) => Container(
              margin: const EdgeInsets.symmetric(horizontal: 12),
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: index < _currentIndex
                    ? AppColors.primary
                    : AppColors.surfaceVariant,
                border: Border.all(
                  color: index < _currentIndex
                      ? AppColors.primary
                      : AppColors.textTertiary,
                  width: 2,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 48),

        // Number Pad
        SizedBox(
          width: 280,
          child: Column(
            children: [
              _buildNumberRow(['1', '2', '3']),
              const SizedBox(height: 16),
              _buildNumberRow(['4', '5', '6']),
              const SizedBox(height: 16),
              _buildNumberRow(['7', '8', '9']),
              const SizedBox(height: 16),
              _buildBottomRow(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNumberRow(List<String> numbers) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: numbers.map((number) => _buildNumberButton(number)).toList(),
    );
  }

  Widget _buildBottomRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        const SizedBox(width: 72, height: 72), // Empty space
        _buildNumberButton('0'),
        _buildBackspaceButton(),
      ],
    );
  }

  Widget _buildNumberButton(String number) {
    return InkWell(
      onTap: () {
        HapticFeedback.lightImpact();
        _onKeyPressed(number);
      },
      borderRadius: BorderRadius.circular(36),
      child: Container(
        width: 72,
        height: 72,
        decoration: BoxDecoration(
          color: AppColors.surfaceVariant,
          shape: BoxShape.circle,
        ),
        child: Center(
          child: Text(
            number,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBackspaceButton() {
    return InkWell(
      onTap: () {
        HapticFeedback.lightImpact();
        _onBackspace();
      },
      borderRadius: BorderRadius.circular(36),
      child: Container(
        width: 72,
        height: 72,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
        ),
        child: const Center(
          child: Icon(
            Icons.backspace_outlined,
            size: 28,
            color: AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}
