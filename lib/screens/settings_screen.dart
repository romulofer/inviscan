import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final TextEditingController _ffufCommandController = TextEditingController();

  static const String _ffufCommandKey = 'ffuf_command';

  @override
  void initState() {
    super.initState();
    _loadCurrentCommand();
  }

  Future<void> _loadCurrentCommand() async {
    final prefs = await SharedPreferences.getInstance();
    final currentCommand = prefs.getString(_ffufCommandKey);
    setState(() {
      _ffufCommandController.text =
          currentCommand ?? 'ffuf -w wordlist.txt -u https://FUZZ.example.com';
    });
  }

  Future<void> _saveCommand() async {
    final prefs = await SharedPreferences.getInstance();
    final newCommand = _ffufCommandController.text.trim();
    await prefs.setString(_ffufCommandKey, newCommand);
    debugPrint('Novo comando ffuf salvo: $newCommand');
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Comando salvo!')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Configurações')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Comando do FFUF atual:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _ffufCommandController,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Digite o comando ffuf...',
              ),
              maxLines: null,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _saveCommand,
              child: const Text('Salvar'),
            ),
          ],
        ),
      ),
    );
  }
}
