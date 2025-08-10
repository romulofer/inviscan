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
   - Digite o domínio alvo no campo de entrada (ex: `example.com`)
   - Clique em "Escanear"

2. **Acompanhar Progresso**:

   - Visualize logs em tempo real durante a execução
   - Acompanhe o progresso do httprobe com barra de progresso
   - Veja o resumo final com estatísticas detalhadas

3. **Configurações**:

   - Acesse o menu de configurações (ícone ⚙️)
   - Personalize comandos de todas as ferramentas:
     - FFUF (fuzzing de subdomínios)
     - Subfinder (descoberta passiva)
     - Assetfinder (busca em fontes públicas)
     - Gowitness (captura de screenshots)
     - CRT.sh (consulta de certificados)
   - Restaure configurações padrão quando necessário

4. **Visualizar Resultados**:
   - Tela de resultados com listas organizadas
   - Exportação em formato JSON
   - Arquivos salvos automaticamente em `~/inviscan_dart/`

## 📁 Estrutura de Resultados

```
~/inviscan_dart/
└── [timestamp]/
    ├── subdominios_totais.txt      # Todos os subdomínios encontrados
    ├── subdominios_unicos.txt      # Lista única de subdomínios
    ├── subdominios_unicos_ativos.txt # Subdomínios ativos (verificados)
    └── screenshots/                # Capturas de tela do gowitness
        ├── subdomain1.png
        └── subdomain2.png
```

**Nota**: Os resultados também podem ser exportados como JSON através da tela de resultados.

## ⚙️ Configuração Avançada

### Customização de Comandos

O InviScan permite personalizar completamente os comandos de todas as ferramentas através da tela de configurações:

#### FFUF (Fuzzing de Subdomínios)

```bash
# Comando padrão
ffuf -w lib/wordlists/ffuf/wordlist.txt -u http://FUZZ.DOMAIN -mc 200 -of json -o /tmp/ffuf_output.json

# Exemplo customizado
ffuf -w /custom/path/wordlist.txt -u https://FUZZ.DOMAIN -mc 200,301,302 -of json -o /tmp/ffuf_output.json
```

#### Subfinder (Descoberta Passiva)

```bash
# Comando padrão
subfinder -d DOMAIN -silent -all -o /tmp/subfinder_subs.txt
```

#### Assetfinder (Fontes Públicas)

```bash
# Comando padrão
assetfinder --subs-only DOMAIN
```

#### Gowitness (Screenshots)

```bash
# Comando padrão
gowitness file -s urls.txt -d screenshots --db screenshots.db
```

#### CRT.sh (Certificados SSL)

```bash
# URL padrão
https://crt.sh/?q=%25.DOMAIN&exclude=expired
```

**Variáveis disponíveis**:

- `DOMAIN`: Será substituído pelo domínio alvo
- `FUZZ`: Posição onde as palavras da wordlist serão inseridas (apenas FFUF)

### Wordlists

A aplicação inclui uma wordlist com **114.443 entradas** em `lib/wordlists/ffuf/wordlist.txt`. Inclui:

- Subdomínios comuns (www, mail, ftp, etc.)
- Ambientes de desenvolvimento (dev, test, staging, etc.)
- Serviços e aplicações típicas
- Variações numéricas e regionais

Você pode:

- Substituir por suas próprias wordlists
- Usar wordlists externas via configuração do ffuf
- Combinar múltiplas wordlists

### Juicy Targets

O sistema identifica automaticamente alvos interessantes baseado em palavras-chave como:

- **Desenvolvimento**: dev, test, staging, qa, uat, beta, alpha
- **Autenticação**: login, auth, sso, oauth, admin
- **Infraestrutura**: vpn, jenkins, git, docker, api
- **Bancos de dados**: db, mysql, postgres, mongo
- **Monitoramento**: grafana, kibana, logs, metrics
- **Backups/Temporários**: backup, temp, old, archive

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
- 📚 **Documentação**: Este README e comentários no código

---

**Desenvolvido com ❤️ usando Flutter**

---

# InviScan 🔍 (English)

**InviScan** is a Flutter application for subdomain reconnaissance that integrates multiple pentesting tools into an intuitive and modern interface. Developed for cybersecurity professionals and bug bounty researchers.

## 📋 Features

- **Subdomain Discovery**: Integration with multiple tools

  - `subfinder` - Passive subdomain discovery
  - `assetfinder` - Public sources search
  - `crt.sh` - SSL certificate queries
  - `ffuf` - Subdomain fuzzing with customizable wordlists

- **Status Verification**: Active subdomain validation with `httprobe`
- **Screenshots**: Automatic screen capture with `gowitness`
- **Juicy Targets**: Automatic identification of interesting targets
- **Intuitive Interface**: Modern UI with real-time logs
- **Customizable Settings**: Customizable commands for all tools
- **Automatic Saving**: Results organized by timestamp directories

## 🛠️ Prerequisites

### System Tools

Make sure you have the following tools installed on your system:

```bash
# Install tools via Go
go install github.com/projectdiscovery/subfinder/v2/cmd/subfinder@latest
go install github.com/tomnomnom/assetfinder@latest
go install github.com/tomnomnom/httprobe@latest
go install github.com/ffuf/ffuf@latest
go install github.com/sensepost/gowitness@latest
```

**Note**: Make sure the `$GOPATH/bin` directory (usually `~/go/bin`) is in your `PATH`.

### Development Environment

- **Flutter SDK** (3.7.2 or higher)
- **Dart SDK** (included with Flutter)
- **Android Studio** / **VS Code** (recommended)

## 📦 Installation

### 1. Clone the Repository

```bash
git clone https://github.com/romulofer/inviscan.git
cd inviscan
```

### 2. Install Dependencies

```bash
flutter pub get
```

### 3. Verify Installation

```bash
flutter doctor
```

## 🚀 Running the Application

### Desktop (Linux/macOS/Windows)

```bash
flutter run -d linux    # For Linux
flutter run -d macos    # For macOS
flutter run -d windows  # For Windows
```

### Mobile

```bash
flutter run -d android  # For Android
flutter run -d ios      # For iOS
```

### Web

```bash
flutter run -d chrome   # For browser
```

## 📱 How to Use

1. **Start Scan**:

   - Open the application
   - Enter the target domain in the input field (e.g., `example.com`)
   - Click "Escanear" (Scan)

2. **Monitor Progress**:

   - View real-time logs during execution
   - Track httprobe progress with progress bar
   - See detailed final summary with statistics

3. **Settings**:

   - Access the settings menu (⚙️ icon)
   - Customize commands for all tools:
     - FFUF (subdomain fuzzing)
     - Subfinder (passive discovery)
     - Assetfinder (public sources search)
     - Gowitness (screenshot capture)
     - CRT.sh (certificate queries)
   - Restore default settings when needed

4. **View Results**:
   - Results screen with organized lists
   - JSON format export
   - Files automatically saved to `~/inviscan_dart/`

## 📁 Results Structure

```
~/inviscan_dart/
└── [timestamp]/
    ├── subdominios_totais.txt      # All found subdomains
    ├── subdominios_unicos.txt      # Unique subdomain list
    ├── subdominios_unicos_ativos.txt # Active subdomains (verified)
    └── screenshots/                # Gowitness screenshots
        ├── subdomain1.png
        └── subdomain2.png
```

**Note**: Results can also be exported as JSON through the results screen.

## ⚙️ Advanced Configuration

### Command Customization

InviScan allows complete customization of all tool commands through the settings screen:

#### FFUF (Subdomain Fuzzing)

```bash
# Default command
ffuf -w lib/wordlists/ffuf/wordlist.txt -u http://FUZZ.DOMAIN -mc 200 -of json -o /tmp/ffuf_output.json

# Custom example
ffuf -w /custom/path/wordlist.txt -u https://FUZZ.DOMAIN -mc 200,301,302 -of json -o /tmp/ffuf_output.json
```

**Available variables**:

- `DOMAIN`: Will be replaced with the target domain
- `FUZZ`: Position where wordlist words will be inserted (FFUF only)

### Wordlists

The application includes a wordlist with **114,443 entries** at `lib/wordlists/ffuf/wordlist.txt`. Includes:

- Common subdomains (www, mail, ftp, etc.)
- Development environments (dev, test, staging, etc.)
- Typical services and applications
- Numeric and regional variations

You can:

- Replace with your own wordlists
- Use external wordlists via ffuf configuration
- Combine multiple wordlists

### Juicy Targets

The system automatically identifies interesting targets based on keywords like:

- **Development**: dev, test, staging, qa, uat, beta, alpha
- **Authentication**: login, auth, sso, oauth, admin
- **Infrastructure**: vpn, jenkins, git, docker, api
- **Databases**: db, mysql, postgres, mongo
- **Monitoring**: grafana, kibana, logs, metrics
- **Backups/Temporary**: backup, temp, old, archive

## 🔧 Building

### For Desktop

```bash
flutter build linux --release   # Linux
flutter build macos --release   # macOS
flutter build windows --release # Windows
```

### For Mobile

```bash
flutter build apk --release     # Android APK
flutter build ios --release     # iOS
```

### For Web

```bash
flutter build web --release
```

## 🐛 Troubleshooting

### Tools not found

```bash
# Check if tools are in PATH
which subfinder
which assetfinder
which httprobe
which ffuf
which gowitness

# If not, add to PATH:
export PATH=$PATH:~/go/bin
```

### Permission Issues

```bash
# Linux/macOS - ensure tools are executable
chmod +x ~/go/bin/*
```

### Dependency Errors

```bash
# Clean and reinstall dependencies
flutter clean
flutter pub get
```

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🤝 Contributing

1. Fork the project
2. Create a feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## ⚠️ Legal Notice

This tool was developed for educational purposes and authorized security testing only. Users are responsible for ensuring they have proper permission before performing tests on any system or network. Improper use of this tool may violate local or international laws.

## 📞 Support

- 🐛 **Issues**: [GitHub Issues](https://github.com/romulofer/inviscan/issues)
- 📚 **Documentation**: This README and code comments

---

**Developed with ❤️ using Flutter**
