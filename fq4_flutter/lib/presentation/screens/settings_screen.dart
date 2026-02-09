import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('SETTINGS'),
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/'),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          _buildSection('Graphics', [
            _buildSwitchTile('CRT Filter', false),
            _buildSwitchTile('Pixel Mode', false),
          ]),
          _buildSection('Audio', [
            _buildSliderTile('BGM Volume', 0.8),
            _buildSliderTile('SFX Volume', 0.8),
          ]),
          _buildSection('Language', [
            _buildDropdownTile('Language', 'ja', ['ja', 'ko', 'en']),
          ]),
        ],
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Text(
            title,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        ...children,
        const Divider(color: Colors.white24),
      ],
    );
  }

  Widget _buildSwitchTile(String label, bool value) {
    return SwitchListTile(
      title: Text(label, style: const TextStyle(color: Colors.white)),
      value: value,
      onChanged: (_) {},
    );
  }

  Widget _buildSliderTile(String label, double value) {
    return ListTile(
      title: Text(label, style: const TextStyle(color: Colors.white)),
      subtitle: Slider(value: value, onChanged: (_) {}),
    );
  }

  Widget _buildDropdownTile(String label, String value, List<String> options) {
    return ListTile(
      title: Text(label, style: const TextStyle(color: Colors.white)),
      trailing: DropdownButton<String>(
        value: value,
        dropdownColor: Colors.grey[900],
        style: const TextStyle(color: Colors.white),
        items: options
            .map((o) => DropdownMenuItem(value: o, child: Text(o)))
            .toList(),
        onChanged: (_) {},
      ),
    );
  }
}
