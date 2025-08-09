# InviScan 🔍

**InviScan** é uma aplicação Flutter para reconhecimento de subdomínios que integra múltiplas ferramentas de pentesting em uma interface intuitiva e moderna. Desenvolvido para profissionais de segurança cibernética e pesquisadores em bug bounty.

## 📋 Funcionalidades

- **Descoberta de Subdomínios**: Integração com múltiplas ferramentas

  - `subfinder` - Descoberta passiva de subdomínios
  - `assetfinder` - Busca em fontes públicas
  - `crt.sh` - Consulta em certificados SSL
  - `ffuf` - Fuzzing de subdomínios com wordlists customizáveis

- **Verificação de Status**: Validação de subdomínios ativos com `httprobe`
- **Screenshots**: Captura automática de telas com `gowitness`
- **Juicy Targets**: Identificação automática de alvos interessantes
- **Interface Intuitiva**: UI moderna com logs em tempo real
- **Configurações Personalizáveis**: Comandos customizáveis para ffuf
- **Salvamento Automático**: Resultados organizados por diretórios com timestamp

## 🛠️ Pré-requisitos

### Ferramentas de Sistema

Certifique-se de ter as seguintes ferramentas instaladas no seu sistema:

```bash
# Instalação das ferramentas via Go
go install github.com/projectdiscovery/subfinder/v2/cmd/subfinder@latest
go install github.com/tomnomnom/assetfinder@latest
go install github.com/tomnomnom/httprobe@latest
go install github.com/ffuf/ffuf@latest
go install github.com/sensepost/gowitness@latest
```

**Nota**: Certifique-se de que o diretório `$GOPATH/bin` (geralmente `~/go/bin`) esteja no seu `PATH`.

### Ambiente de Desenvolvimento

- **Flutter SDK** (3.7.2 ou superior)
- **Dart SDK** (incluído com Flutter)
- **Android Studio** / **VS Code** (recomendado)

## 📦 Instalação

### 1. Clone o Repositório

```bash
git clone https://github.com/romulofer/inviscan.git
cd inviscan
```

### 2. Instale as Dependências

```bash
flutter pub get
```

### 3. Verifique a Instalação

```bash
flutter doctor
```

## 🚀 Executando a Aplicação

### Desktop (Linux/macOS/Windows)

```bash
flutter run -d linux    # Para Linux
flutter run -d macos    # Para macOS
flutter run -d windows  # Para Windows
```

### Mobile

```bash
flutter run -d android  # Para Android
flutter run -d ios      # Para iOS
```

### Web

```bash
flutter run -d chrome   # Para navegador
```

## 📱 Como Usar

1. **Iniciar Scan**:

   - Abra a aplicação
   - Digite o domínio alvo no campo de entrada
   - Clique em "Escanear"

2. **Acompanhar Progresso**:

   - Visualize logs em tempo real
   - Acompanhe o progresso do httprobe
   - Veja o resumo final com estatísticas

3. **Configurações**:

   - Acesse o menu de configurações (ícone ⚙️)
   - Customize comandos do ffuf
   - Ajuste parâmetros conforme necessário

4. **Resultados**:
   - Arquivos salvos automaticamente em `~/Downloads/inviscan_results/`
   - Screenshots organizadas por domínio
   - Listas de subdomínios em formato texto

## 📁 Estrutura de Resultados

```
~/Downloads/inviscan_results/
└── scan_[dominio]_[timestamp]/
    ├── all_subdomains.txt      # Todos os subdomínios encontrados
    ├── active_subdomains.txt   # Subdomínios ativos (status 200)
    ├── unique_subdomains.txt   # Lista única de subdomínios
    └── screenshots/            # Capturas de tela (se houver)
        ├── subdomain1.png
        └── subdomain2.png
```

## ⚙️ Configuração Avançada

### Customização do FFUF

No menu de configurações, você pode personalizar o comando do ffuf:

```bash
# Exemplo de comando customizado
ffuf -w /custom/path/wordlist.txt -u http://FUZZ.DOMAIN -mc 200,301,302 -of json -o /tmp/ffuf_output.json
```

**Variáveis disponíveis**:

- `DOMAIN`: Será substituído pelo domínio alvo
- `FUZZ`: Posição onde as palavras da wordlist serão inseridas

### Wordlists

A aplicação inclui uma wordlist padrão em `lib/wordlists/ffuf/wordlist.txt`. Você pode:

- Substituir por suas próprias wordlists
- Usar wordlists externas via configuração do ffuf
- Combinar múltiplas wordlists

## 🔧 Compilação

### Para Desktop

```bash
flutter build linux --release   # Linux
flutter build macos --release   # macOS
flutter build windows --release # Windows
```

### Para Mobile

```bash
flutter build apk --release     # Android APK
flutter build ios --release     # iOS
```

### Para Web

```bash
flutter build web --release
```

## 🐛 Troubleshooting

### Ferramentas não encontradas

```bash
# Verifique se as ferramentas estão no PATH
which subfinder
which assetfinder
which httprobe
which ffuf
which gowitness

# Se não estiverem, adicione ao PATH:
export PATH=$PATH:~/go/bin
```

### Problemas de Permissão

```bash
# Linux/macOS - certifique-se de que as ferramentas são executáveis
chmod +x ~/go/bin/*
```

### Erro de Dependências

```bash
# Limpe e reinstale dependências
flutter clean
flutter pub get
```

## 📄 Licença

Este projeto está licenciado sob a MIT License - veja o arquivo [LICENSE](LICENSE) para detalhes.

## 🤝 Contribuindo

1. Faça um fork do projeto
2. Crie uma branch para sua feature (`git checkout -b feature/AmazingFeature`)
3. Commit suas mudanças (`git commit -m 'Add some AmazingFeature'`)
4. Push para a branch (`git push origin feature/AmazingFeature`)
5. Abra um Pull Request

## ⚠️ Aviso Legal

Esta ferramenta foi desenvolvida apenas para fins educacionais e testes de segurança autorizados. Os usuários são responsáveis por garantir que tenham permissão adequada antes de realizar testes em qualquer sistema ou rede. O uso inadequado desta ferramenta pode violar leis locais ou internacionais.

## 📞 Suporte

- 🐛 **Issues**: [GitHub Issues](https://github.com/romulofer/inviscan/issues)
- 📧 **Email**: Abra uma issue para suporte
- 📚 **Documentação**: Este README e comentários no código

---

**Desenvolvido com ❤️ usando Flutter**
