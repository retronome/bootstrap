# Retronome Bootstrap

A streamlined setup script for bootstrapping macOS development environments with essential tools and configurations.

## Features

- 🔧 **Core Tools**: Git, Homebrew, Command Line Tools, and essential utilities
- 💻 **Development Environment**: Node.js, Java, Scala, Go, Python and more
- 📝 **Code Editors**: Visual Studio Code and Zed with CLI integration
- 🐚 **Shell Configuration**: Oh My Zsh with a custom theme
- 🐳 **Container Support**: Docker and Docker Compose
- 🔄 **Build Tools**: Mill, Make, and more

## Quick Install

```bash
curl -fsSL https://raw.githubusercontent.com/retronome/bootstrap/main/setup.sh | bash
```

## What's Included

### CLI Tools and Utilities
- Git (with credential manager, LFS, filter-repo)
- Homebrew
- Xcode Command Line Tools
- bat, fzf, htop, make, and more

### Programming Languages & Runtimes
- Node.js via NVM
- Java via SDKMAN
- Scala
- Go
- Deno
- Gleam
- Python

### Applications
- Visual Studio Code
- Zed
- Docker Desktop

### Build Tools
- Mill 0.12.5
- Make

### Configuration
- Custom zsh theme
- Git configuration
- Docker environment
- Environment path settings

## Manual Installation

If you prefer to run the script manually or make modifications:

1. Clone the repository:
   ```bash
   git clone https://github.com/retronome/bootstrap.git
   ```

2. Run the setup script:
   ```bash
   cd bootstrap
   chmod +x setup.sh
   ./setup.sh
   ```

## Security

It's always a good practice to review scripts before executing them. You can inspect this script first:

```bash
curl -fsSL https://raw.githubusercontent.com/retronome/bootstrap/main/setup.sh > setup.sh
less setup.sh  # Review the script
bash setup.sh  # Run if it looks good
```

## License

MIT
