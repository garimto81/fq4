import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class TitleScreen extends StatelessWidget {
  const TitleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'FIRST QUEEN IV',
              style: TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 8,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'HD RENEWAL',
              style: TextStyle(
                fontSize: 20,
                color: Colors.grey[400],
                letterSpacing: 12,
              ),
            ),
            const SizedBox(height: 80),
            _TitleButton(
              label: 'NEW GAME',
              onPressed: () => context.go('/game'),
            ),
            const SizedBox(height: 16),
            _TitleButton(
              label: 'CONTINUE',
              onPressed: () {}, // TODO: load save
            ),
            const SizedBox(height: 16),
            _TitleButton(
              label: 'SETTINGS',
              onPressed: () => context.go('/settings'),
            ),
          ],
        ),
      ),
    );
  }
}

class _TitleButton extends StatelessWidget {
  const _TitleButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 240,
      height: 48,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.white,
          side: const BorderSide(color: Colors.white54),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        child: Text(
          label,
          style: const TextStyle(fontSize: 18, letterSpacing: 4),
        ),
      ),
    );
  }
}
