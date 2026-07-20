import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../l10n/app_localizations.dart';
import '../providers/locale_provider.dart';
import '../services/tool_installer.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

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

  // NOTE: The ffuf default omits -o so the scan service injects a
  // cross-platform temp path automatically.  Users may add -o if they want
  // to keep the raw JSON output.
  static const _defaultFfufCommand =
      'ffuf -w wordlists/ffuf/wordlist.txt -u http://FUZZ.DOMAIN -mc 200 -of json';

  static const _defaultSubfinderCommand =
      'subfinder -d DOMAIN -silent -all';

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
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppLocalizations.of(context).commandsSaved)),
    );
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
              tooltip: AppLocalizations.of(context).restoreDefault,
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

  Widget _buildLanguageSelector(AppLocalizations l10n) {
    final current = context.watch<LocaleProvider>().locale.languageCode;
    return Row(
      children: [
        Expanded(
          child: Text(
            l10n.languageLabel,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
        DropdownButton<String>(
          value: current,
          onChanged: (code) {
            if (code != null) {
              context.read<LocaleProvider>().setLocale(Locale(code));
            }
          },
          items: [
            DropdownMenuItem(value: 'pt', child: Text(l10n.languagePortuguese)),
            DropdownMenuItem(value: 'en', child: Text(l10n.languageEnglish)),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsTitle)),
      body:
          _loading
              ? const Center(child: CircularProgressIndicator())
              : Padding(
                padding: const EdgeInsets.all(16),
                child: ListView(
                  children: [
                    _buildLanguageSelector(l10n),
                    const Divider(height: 32),
                    _buildCommandField(
                      label: l10n.ffufCommandLabel,
                      controller: _ffufCommandController,
                      onReset: _resetFfuf,
                      helper: l10n.ffufCommandHelper,
                    ),
                    _buildCommandField(
                      label: l10n.subfinderCommandLabel,
                      controller: _subfinderCommandController,
                      onReset: _resetSubfinder,
                      helper: l10n.domainPlaceholderHelper,
                    ),
                    _buildCommandField(
                      label: l10n.assetfinderCommandLabel,
                      controller: _assetfinderCommandController,
                      onReset: _resetAssetfinder,
                      helper: l10n.assetfinderCommandHelper,
                    ),
                    _buildCommandField(
                      label: l10n.gowitnessCommandLabel,
                      controller: _gowitnessCommandController,
                      onReset: _resetGowitness,
                    ),
                    _buildCommandField(
                      label: l10n.crtshCommandLabel,
                      controller: _crtshCommandController,
                      onReset: _resetCrtsh,
                      helper: l10n.crtshCommandHelper,
                    ),
                    const Divider(height: 32),
                    const _ToolDownloadTile(),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _saveCommands,
                      child: Text(l10n.saveAllButton),
                    ),
                  ],
                ),
              ),
    );
  }
}

class _ToolDownloadTile extends StatefulWidget {
  const _ToolDownloadTile();

  @override
  State<_ToolDownloadTile> createState() => _ToolDownloadTileState();
}

class _ToolDownloadTileState extends State<_ToolDownloadTile> {
  bool _running = false;
  String _status = '';

  Future<void> _download() async {
    final l10n = AppLocalizations.of(context);
    setState(() {
      _running = true;
      _status = l10n.downloadToolsStarting;
    });
    final installer = ToolInstaller();
    final errors = await installer.installAll(
      onProgress: (tool, received, total) {
        if (!mounted) return;
        final pct =
            total > 0 ? ((received / total) * 100).toStringAsFixed(0) : '?';
        setState(() => _status = l10n.downloadToolProgress(tool, pct));
      },
    );
    if (!mounted) return;
    setState(() {
      _running = false;
      _status = errors.isEmpty
          ? l10n.downloadToolsDone
          : l10n.downloadToolsFailures(errors.keys.join(', '));
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(l10n.toolsSectionTitle),
      subtitle: Text(
        _status.isEmpty ? l10n.downloadToolsSubtitle : _status,
      ),
      trailing: _running
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : IconButton(
              icon: const Icon(Icons.download),
              onPressed: _download,
            ),
    );
  }
}
