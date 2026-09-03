/// Utilitários para comandos de ferramentas configuráveis pelo usuário.
///
/// Os comandos são salvos em `SharedPreferences` pela tela de Configurações e
/// lidos pelos módulos de scan. Cada módulo substitui os placeholders (ex.:
/// `DOMAIN`) e depois tokeniza a string em argumentos, executando sem shell
/// (`runInShell: false`) — os placeholders só recebem valores já validados.
library;

import 'binaries.dart';

/// Quebra uma linha de comando em tokens, respeitando aspas simples e duplas.
///
/// Não interpreta shell (sem globs, variáveis ou `\` de escape): apenas separa
/// por espaços fora de aspas. Usado para montar a lista de argumentos passada a
/// `Process.run`/`Process.start` com `runInShell: false`.
List<String> tokenizeCommand(String cmd) {
  final List<String> out = [];
  final StringBuffer current = StringBuffer();
  bool inSingle = false, inDouble = false;

  for (int i = 0; i < cmd.length; i++) {
    final ch = cmd[i];
    if (ch == "'" && !inDouble) {
      inSingle = !inSingle;
      continue;
    }
    if (ch == '"' && !inSingle) {
      inDouble = !inDouble;
      continue;
    }
    if (ch == ' ' && !inSingle && !inDouble) {
      if (current.isNotEmpty) {
        out.add(current.toString());
        current.clear();
      }
    } else {
      current.write(ch);
    }
  }
  if (current.isNotEmpty) out.add(current.toString());
  return out;
}

/// Resolve o executável do primeiro token de um comando.
///
/// Se o token contém [toolName] (ex.: `ffuf`, `ffuf.exe`), resolve via
/// [binPath] para preferir o binário baixado/empacotado; caso o usuário tenha
/// trocado o executável, usa o token como veio.
String resolveExec(String firstToken, String toolName) {
  return firstToken.toLowerCase().contains(toolName)
      ? binPath(toolName)
      : firstToken;
}
