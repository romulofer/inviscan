import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _ffufCommandController = TextEditingController();
  final _subfinderCommandController = TextEditingController();
  final _gowitnessCommandController = TextEditingController();
  final _crtshCommandController = TextEditingController();
  final _assetfinderCommandController = TextEditingController();

  static const _ffufCommandKey = 'ffuf_command';
  static const _subfinderCommandKey = 'subfinder_command';
  static const _gowitnessCommandKey = 'gowitness_command';
  static const _crtshCommandKey = 'crtsh_command';
  static const _assetfinderCommandKey = 'assetfinder_command';

  static const _defaultFfufCommand =
      'ffuf -w lib/wordlists/ffuf/wordlist.txt -u http://FUZZ.DOMAIN -mc 200 -of json -o /tmp/ffuf_output.json';

  static const _defaultSubfinderCommand =
      'subfinder -d DOMAIN -silent -all -o /tmp/subfinder_subs.txt';

  static const _defaultGowitnessCommand =
      'gowitness file -s urls.txt -d screenshots --db screenshots.db';

  static const _defaultCrtshCommand =
      'https://crt.sh/?q=%25.DOMAIN&exclude=expired';

  static const _defaultAssetfinderCommand = 'assetfinder --subs-only DOMAIN';

  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadSaved();
  }

  Future<void> _loadSaved() async {
    final prefs = await SharedPreferences.getInstance();
    _ffufCommandController.text =
        prefs.getString(_ffufCommandKey) ?? _defaultFfufCommand;
    _subfinderCommandController.text =
        prefs.getString(_subfinderCommandKey) ?? _defaultSubfinderCommand;
    _gowitnessCommandController.text =
        prefs.getString(_gowitnessCommandKey) ?? _defaultGowitnessCommand;
    _crtshCommandController.text =
        prefs.getString(_crtshCommandKey) ?? _defaultCrtshCommand;
    _assetfinderCommandController.text =
        prefs.getString(_assetfinderCommandKey) ?? _defaultAssetfinderCommand;
    setState(() => _loading = false);
  }

  Future<void> _saveCommands() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_ffufCommandKey, _ffufCommandController.text.trim());
    await prefs.setString(
      _subfinderCommandKey,
      _subfinderCommandController.text.trim(),
    );
    await prefs.setString(
      _gowitnessCommandKey,
      _gowitnessCommandController.text.trim(),
    );
    await prefs.setString(
      _crtshCommandKey,
      _crtshCommandController.text.trim(),
    );
    await prefs.setString(
      _assetfinderCommandKey,
      _assetfinderCommandController.text.trim(),
    );

    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Comandos salvos.')));
    Navigator.pop(context);
  }

  Future<void> _resetFfuf() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_ffufCommandKey, _defaultFfufCommand);
    _ffufCommandController.text = _defaultFfufCommand;
  }

  Future<void> _resetSubfinder() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_subfinderCommandKey, _defaultSubfinderCommand);
    _subfinderCommandController.text = _defaultSubfinderCommand;
  }

  Future<void> _resetGowitness() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_gowitnessCommandKey, _defaultGowitnessCommand);
    _gowitnessCommandController.text = _defaultGowitnessCommand;
  }

  Future<void> _resetCrtsh() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_crtshCommandKey, _defaultCrtshCommand);
    _crtshCommandController.text = _defaultCrtshCommand;
  }

  Future<void> _resetAssetfinder() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_assetfinderCommandKey, _defaultAssetfinderCommand);
    _assetfinderCommandController.text = _defaultAssetfinderCommand;
  }

  @override
  void dispose() {
    _ffufCommandController.dispose();
    _subfinderCommandController.dispose();
    _gowitnessCommandController.dispose();
    _crtshCommandController.dispose();
    _assetfinderCommandController.dispose();
    super.dispose();
  }

  Widget _buildCommandField({
    required String label,
    required TextEditingController controller,
    required VoidCallback onReset,
    String? helper,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            IconButton(
              tooltip: 'Restaurar padrão',
              onPressed: onReset,
              icon: const Icon(Icons.restore),
            ),
          ],
        ),
        TextFormField(
          controller: controller,
          decoration: InputDecoration(
            border: const OutlineInputBorder(),
            helperText: helper,
          ),
          style: const TextStyle(fontFamily: 'monospace'),
          minLines: 2,
          maxLines: 4,
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Configurações')),
      body:
          _loading
              ? const Center(child: CircularProgressIndicator())
              : Padding(
                padding: const EdgeInsets.all(16),
                child: ListView(
                  children: [
                    _buildCommandField(
                      label: 'Comando do FFUF',
                      controller: _ffufCommandController,
                      onReset: _resetFfuf,
                      helper:
                          'Placeholders: FUZZ (posição do subdomínio) e DOMAIN (alvo).',
                    ),
                    _buildCommandField(
                      label: 'Comando do Subfinder',
                      controller: _subfinderCommandController,
                      onReset: _resetSubfinder,
                      helper: 'Placeholder: DOMAIN (alvo).',
                    ),
                    _buildCommandField(
                      label: 'Comando do Assetfinder',
                      controller: _assetfinderCommandController,
                      onReset: _resetAssetfinder,
                      helper:
                          'Placeholder: DOMAIN (alvo). Não possui -o nativo; use redireção (> arquivo) se quiser salvar.',
                    ),
                    _buildCommandField(
                      label: 'Comando do Gowitness',
                      controller: _gowitnessCommandController,
                      onReset: _resetGowitness,
                    ),
                    _buildCommandField(
                      label: 'URL do CRT.sh',
                      controller: _crtshCommandController,
                      onReset: _resetCrtsh,
                      helper:
                          'Placeholder: DOMAIN (alvo). Use %25 para o caractere %.',
                    ),
                    ElevatedButton(
                      onPressed: _saveCommands,
                      child: const Text('Salvar tudo'),
                    ),
                  ],
                ),
              ),
    );
  }
}
