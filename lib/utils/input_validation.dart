/// Utilitários de validação e sanitização de entrada do usuário.
library;

import 'dart:io';

/// Regex que aceita apenas domínios válidos (RFC 1123 + IDN básico).
/// Rejeita IPs, wildcards, e qualquer caractere que possa ser usado
/// para injeção de argumento (espaços, aspas, ponto-e-vírgula, etc.).
final _domainRegex = RegExp(
  r'^(?:[a-zA-Z0-9](?:[a-zA-Z0-9\-]{0,61}[a-zA-Z0-9])?\.)+[a-zA-Z]{2,}$',
);

/// Valida e normaliza um domínio digitado pelo usuário.
/// Remove esquema (http/https) e caminho, depois valida o formato.
/// Lança [ArgumentError] se o domínio for inválido.
String validateAndNormalizeDomain(String input) {
  var d = input.trim();

  // Remove esquema
  d = d.replaceAll(RegExp(r'^https?://', caseSensitive: false), '');

  // Remove caminho, query e fragmento
  d = d.split('/').first;
  d = d.split('?').first;
  d = d.split('#').first;

  // Remove porta
  final portIndex = d.lastIndexOf(':');
  if (portIndex != -1) {
    d = d.substring(0, portIndex);
  }

  d = d.toLowerCase().trim();

  if (d.isEmpty) {
    throw ArgumentError('Domínio não pode ser vazio.');
  }

  if (d.length > 253) {
    throw ArgumentError('Domínio muito longo (máx. 253 caracteres).');
  }

  if (!_domainRegex.hasMatch(d)) {
    throw ArgumentError(
      'Domínio inválido: "$d". Use apenas letras, números e hífens.',
    );
  }

  return d;
}

/// Gera um caminho seguro para arquivo temporário dentro do diretório
/// temporário do sistema, evitando path traversal e nomes previsíveis.
/// [prefix] deve conter apenas caracteres alfanuméricos e underscores.
Future<String> safeTempFilePath(String prefix) async {
  final tmpDir = Directory.systemTemp;
  // Usa pid + timestamp para reduzir previsibilidade
  final name =
      '${prefix}_${pid}_${DateTime.now().microsecondsSinceEpoch}.json';
  return '${tmpDir.path}/$name';
}

/// Valida que um [path] está contido dentro de [allowedBase],
/// prevenindo path traversal.
/// Retorna o path normalizado ou lança [ArgumentError].
String validatePathWithinBase(String path, String allowedBase) {
  final resolved = File(path).absolute.path;
  final base = Directory(allowedBase).absolute.path;

  if (!resolved.startsWith('$base/') && resolved != base) {
    throw ArgumentError(
      'Acesso negado: o caminho "$path" está fora do diretório permitido.',
    );
  }
  return resolved;
}
