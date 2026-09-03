/// Utilitários de validação e sanitização de entrada do usuário.
library;

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
