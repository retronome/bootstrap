#!/usr/bin/env bash

: "${FORCE:=false}"

# Define the border color for easy customization
BORDER_COLOR="94" # Muted bronze color

# Print styled intro with the defined border color
echo -e "\n\033[1;38;5;${BORDER_COLOR}m┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓\033[0m"
echo -e "\033[1;38;5;${BORDER_COLOR}m┃\033[0m            \033[1;38;5;51mB\033[1;38;5;87me\033[1;38;5;123mg\033[1;38;5;159mi\033[1;38;5;195mn\033[1;38;5;159mn\033[1;38;5;123mi\033[1;38;5;87mn\033[1;38;5;51mg\033[0m \033[1;38;5;87ms\033[1;38;5;123me\033[1;38;5;159mt\033[1;38;5;195mu\033[1;38;5;159mp\033[0m \033[1;38;5;123mp\033[1;38;5;87mr\033[1;38;5;51mo\033[1;38;5;87mc\033[1;38;5;123me\033[1;38;5;159ms\033[1;38;5;195ms\033[1;38;5;159m.\033[1;38;5;123m.\033[1;38;5;87m.\033[0m            \033[1;38;5;${BORDER_COLOR}m┃\033[0m"
echo -e "\033[1;38;5;${BORDER_COLOR}m┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛\033[0m\n"

# Function for section headers and completion
section_start() {
    echo -ne "\033[1;38;5;75m→ $1...\033[0m"
}

section_done() {
    echo -e "\r\033[1;38;5;75m→ $CURRENT_SECTION...\033[1;38;5;118m Done ✓\033[0m"
}

section_skip() {
    echo -e "\r\033[1;38;5;75m→ $CURRENT_SECTION...\033[1;38;5;226m Skipped ⦿\033[0m"
}

# Function to install oh-my-zsh
install_oh_my_zsh() {
    CURRENT_SECTION="Installing Oh My Zsh"
    section_start "$CURRENT_SECTION"

    if [ -d "$HOME/.oh-my-zsh" ]; then
        section_skip
    else
        # Run oh-my-zsh installer silently in the background
        sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended > /dev/null 2>&1 &
        local install_pid=$!

        # Show animated progress with blue dots while installing
        while kill -0 $install_pid 2>/dev/null; do
            echo -ne "\033[1;38;5;75m.\033[0m"
            sleep 1
        done

        # Check if installation was successful
        wait $install_pid
        if [ $? -eq 0 ]; then
            echo -e " \033[1;38;5;118mDone ✓\033[0m"
        else
            echo -e " \033[1;38;5;196mFailed ✗\033[0m"
            return 1
        fi
    fi

    # Create custom theme
    CURRENT_SECTION="Creating custom zsh theme"
    section_start "$CURRENT_SECTION"

    cat <<"EOS" | sed 's/^    //' > ~/.oh-my-zsh/custom/themes/retronome.zsh-theme
    PROMPT='%F{75}%* %F{white}%m:%F{36}%~%{$reset_color%}'
    PROMPT+=' $(git_prompt_info)'
    PROMPT+=$'\n'"%(?:%{$fg[green]%}➜ :%{$fg[red]%}➜ )%{$reset_color%}"

    ZSH_THEME_GIT_PROMPT_PREFIX="("
    ZSH_THEME_GIT_PROMPT_SUFFIX="%{$reset_color%})"
    ZSH_THEME_GIT_PROMPT_DIRTY=" %F{yellow}✗"
    ZSH_THEME_GIT_PROMPT_CLEAN=""
EOS

    if [ $? -eq 0 ]; then
        section_done
    else
        echo -e "\r\033[1;38;5;75m→ $CURRENT_SECTION...\033[1;38;5;196m Failed ✗\033[0m"
        return 1
    fi

    # Configure .zshrc
    CURRENT_SECTION="Configuring .zshrc"
    section_start "$CURRENT_SECTION"

    # Backup existing .zshrc if it exists
    if [ -f "$HOME/.zshrc" ]; then
        mv "$HOME/.zshrc" "$HOME/.zshrc.backup.$(date +%Y%m%d%H%M%S)"
    fi

    cat <<"EOS" > ~/.zshrc
unset MAILCHECK

# Path to your oh-my-zsh installation
export ZSH="$HOME/.oh-my-zsh"

# Set theme
ZSH_THEME="retronome"

# Set plugins
plugins=(git)

# Source oh-my-zsh
source $ZSH/oh-my-zsh.sh

# User configuration
unset zle_bracketed_paste
export SDKMAN_ARCH=arm64
export BROWSER="Firefox"
export JAVA_OPTS="-Djava.net.preferIPv4Stack=true"

# Aliases
alias src="cd $HOME/src"
alias cat="bat"

# Git Editor configuration
export EDITOR="vim"

# Docker configuration
export DOCKER_SCAN_SUGGEST=false

# PATH Configuration
# Add homebrew paths if they exist
if [ -d "/opt/homebrew/bin" ]; then
  export PATH="/opt/homebrew/bin:/opt/homebrew/sbin:$PATH"
fi

# Add Infrastructure bin path if it exists
if [ -d "$HOME/src/infrastructure/bin" ]; then
  export PATH="$HOME/src/infrastructure/bin:$PATH"
fi

# Configure fzf
eval "$(fzf --zsh)"

# Ensure ~/bin is in PATH
export PATH="$HOME/bin:$PATH"
EOS

    if [ $? -eq 0 ]; then
        section_done
    else
        echo -e "\r\033[1;38;5;75m→ $CURRENT_SECTION...\033[1;38;5;196m Failed ✗\033[0m"
        return 1
    fi
}

# Install Oh My Zsh and configure it
install_oh_my_zsh

# Function to install a single package with Homebrew with nice output
brew_install() {
    local pkg_type="install"
    local pkg_name="$1"

    # Check for cask argument
    if [ "$1" = "--cask" ]; then
        pkg_type="install --cask"
        pkg_name="$2"
    fi

    CURRENT_SECTION="Installing $pkg_name with Homebrew"
    section_start "$CURRENT_SECTION"

    # Run brew in background and update progress with dots
    brew $pkg_type --quiet $pkg_name > /dev/null 2>&1 &
    local brew_pid=$!

    # Show animated progress with blue dots while brewing
    while kill -0 $brew_pid 2>/dev/null; do
        echo -ne "\033[1;38;5;75m.\033[0m"
        sleep 1
    done

    # Check if the installation was successful and place status after dots
    wait $brew_pid
    if [ $? -eq 0 ]; then
        # Add the success message after the dots
        echo -e " \033[1;38;5;118mDone ✓\033[0m"
    else
        # Add the failure message after the dots
        echo -e " \033[1;38;5;196mFailed ✗\033[0m"
    fi
}

# Homebrew installation section
CURRENT_SECTION="Checking for Homebrew"
section_start "$CURRENT_SECTION"
if ! command -v brew &> /dev/null; then
    section_done

    CURRENT_SECTION="Installing Homebrew"
    section_start "$CURRENT_SECTION"
    # Redirect both stdout and stderr to hide all Homebrew install output
    if /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" > /dev/null 2>&1; then
        section_done
    else
        echo -e "\r\033[1;38;5;75m→ $CURRENT_SECTION...\033[1;38;5;196m Failed ✗\033[0m"
        echo -e "\033[1;38;5;196mHomebrew installation failed. Please install manually from https://brew.sh\033[0m"
    fi
else
    section_skip
fi

# Install standard utilities - each with its own line for easy editing
if command -v brew &> /dev/null; then

    # Version control and Git tools
    brew_install git
    brew_install git-lfs                # Git Large File Storage
    brew_install git-filter-repo        # Rewrite git history

    # Flag to track if git-credential-manager needs manual installation
    GCM_NEEDS_INSTALL=false

    # Skip the interactive git-credential-manager installation during main flow
    CURRENT_SECTION="Checking git credential manager"
    section_start "$CURRENT_SECTION"
    if command -v git-credential-manager &>/dev/null; then
        echo -e " \033[1;38;5;118mAlready installed ✓\033[0m"
    else
        echo -e " \033[1;38;5;226mSkipped ⦿\033[0m (will prompt for manual installation at end)"
        GCM_NEEDS_INSTALL=true
    fi

    # Core utilities and command line tools
    brew_install bat      # Better alternative to cat
    brew_install htop     # Interactive process viewer
    brew_install fzf      # Command-line fuzzy finder
    brew_install less     # Terminal pager
    brew_install make     # Build tool
    brew_install yq       # YAML processor
    brew_install jq       # JSON processor

    # Media and image processing
    brew_install ffmpeg   # Audio/video framework
    brew_install vips     # Image processing library
    brew_install exiftool # Read/write image metadata

    # Programming languages and runtime environments
    brew_install deno     # JavaScript/TypeScript runtime
    brew_install gleam    # Functional programming language
    brew_install go       # Go programming language

    # Libraries and dependencies
    brew_install argon2   # Password hashing library
    brew_install icu4c    # Unicode support library

    # Example of installing a cask
    # brew_install --cask iterm2
else
    CURRENT_SECTION="Installing utilities with Homebrew"
    section_start "$CURRENT_SECTION"
    echo -e "\r\033[1;38;5;75m→ $CURRENT_SECTION...\033[1;38;5;196m Skipped (Homebrew not available) ✗\033[0m"
fi

# Start creating bin directory
CURRENT_SECTION="Creating ~/bin for convenience scripts"
section_start "$CURRENT_SECTION"
[ -d "$HOME/bin" ] || mkdir -p "$HOME/bin"
section_done

# Create serve script
CURRENT_SECTION="Creating ~/bin/serve script"
section_start "$CURRENT_SECTION"
if [ "$FORCE" = true ] || [ ! -f "$HOME/bin/serve" ]; then
    cat <<"EOS" | sed 's/^    //' > ~/bin/serve
    #!/usr/bin/env bash

    python3 -m http.server --cgi ${1:-777}
EOS
    chmod +x ~/bin/serve
    section_done
else
    section_skip
fi

# Install Docker Desktop app (includes the modern Docker Compose plugin)
brew_install --cask docker

# No need to install docker-compose separately as Docker Desktop includes the plugin
CURRENT_SECTION="Verifying Docker Compose plugin"
section_start "$CURRENT_SECTION"
echo -e " \033[1;38;5;226mNote: Use 'docker compose' instead of 'docker-compose'\033[0m"

# Function to install with curl scripts - similar to brew_install but for curl-based installers
curl_script_install() {
    local name="$1"
    local script_url="$2"
    local redirect_arg="$3"  # -s for silent, -o- to output to stdout

    CURRENT_SECTION="Installing $name"
    section_start "$CURRENT_SECTION"

    # Run the curl script in background
    bash -c "curl $redirect_arg '$script_url' | bash" > /dev/null 2>&1 &
    local install_pid=$!

    # Show animated progress while installing
    while kill -0 $install_pid 2>/dev/null; do
        echo -ne "\033[1;38;5;75m.\033[0m"
        sleep 1
    done

    # Check if installation was successful
    wait $install_pid
    if [ $? -eq 0 ]; then
        echo -e " \033[1;38;5;118mDone ✓\033[0m"
    else
        echo -e " \033[1;38;5;196mFailed ✗\033[0m"
    fi
}

# Function for SDK manager installations
sdk_install() {
    local tool_type="$1"
    local version="$2"

    CURRENT_SECTION="Installing $tool_type $version"
    section_start "$CURRENT_SECTION"

    # Need to source sdkman first
    source "$HOME/.sdkman/bin/sdkman-init.sh" > /dev/null 2>&1

    # Run the sdk install in background
    bash -c "source $HOME/.sdkman/bin/sdkman-init.sh && sdk install $tool_type $version -d -y" > /dev/null 2>&1 &
    local install_pid=$!

    # Show animated progress while installing
    while kill -0 $install_pid 2>/dev/null; do
        echo -ne "\033[1;38;5;75m.\033[0m"
        sleep 1
    done

    # Check if installation was successful
    wait $install_pid
    if [ $? -eq 0 ]; then
        echo -e " \033[1;38;5;118mDone ✓\033[0m"
    else
        echo -e " \033[1;38;5;196mFailed ✗\033[0m"
    fi
}

# Install NVM (Node Version Manager)
curl_script_install "NVM" "https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.3/install.sh" "-o-"

# Install Node.js with NVM
CURRENT_SECTION="Installing Node.js LTS"
section_start "$CURRENT_SECTION"

# Source NVM first and install Node
bash -c "export NVM_DIR=\"$HOME/.nvm\" && [ -s \"$NVM_DIR/nvm.sh\" ] && \. \"$NVM_DIR/nvm.sh\" && nvm install lts/iron --default" > /dev/null 2>&1 &
install_pid=$!

# Show animated progress while installing
while kill -0 $install_pid 2>/dev/null; do
    echo -ne "\033[1;38;5;75m.\033[0m"
    sleep 1
done

# Check if installation was successful
wait $install_pid
if [ $? -eq 0 ]; then
    echo -e " \033[1;38;5;118mDone ✓\033[0m"
else
    echo -e " \033[1;38;5;196mFailed ✗\033[0m"
fi

# Install SDKMAN
curl_script_install "SDKMAN" "https://get.sdkman.io" "-s"

# Install Scala and Java with SDKMAN
sdk_install "scala" "3.7.0"
sdk_install "java" "21-tem"

# Install Mill build tool
CURRENT_SECTION="Installing Mill build tool"
section_start "$CURRENT_SECTION"

# Download Mill launcher script and make it executable
(
    # Create a temporary directory
    tmp_dir=$(mktemp -d)
    cd "$tmp_dir"

    # Download Mill 0.12.5
    curl -L -s -o mill https://github.com/com-lihaoyi/mill/releases/download/0.12.5/0.12.5-assembly

    # Move to ~/bin and make executable
    mv mill "$HOME/bin/"
    chmod +x "$HOME/bin/mill"

    # Clean up
    cd - > /dev/null
    rm -rf "$tmp_dir"
) > /dev/null 2>&1 &

install_pid=$!

# Show animated progress while installing
while kill -0 $install_pid 2>/dev/null; do
    echo -ne "\033[1;38;5;75m.\033[0m"
    sleep 1
done

# Check if installation was successful
wait $install_pid
if [ $? -eq 0 ] && [ -x "$HOME/bin/mill" ]; then
    echo -e " \033[1;38;5;118mDone ✓\033[0m"
else
    echo -e " \033[1;38;5;196mFailed ✗\033[0m"
fi

# Install Xcode Command Line Tools
CURRENT_SECTION="Installing Xcode Command Line Tools"
section_start "$CURRENT_SECTION"

# Check if already installed
if xcode-select -p &>/dev/null; then
    section_skip
else
    # Touch a temporary file to trigger the CLT installation
    touch /tmp/.com.apple.dt.CommandLineTools.installondemand.in-progress

    # Find the latest Command Line Tools package
    CLT_PACKAGE=$(softwareupdate -l | grep -B 1 "Command Line Tools" | awk -F"*" '/^ *\*/ {print $2}' | sed 's/^ *//' | tail -n1)

    # Install it non-interactively if found
    if [[ -n "$CLT_PACKAGE" ]]; then
        (softwareupdate -i "$CLT_PACKAGE" --verbose; rm /tmp/.com.apple.dt.CommandLineTools.installondemand.in-progress) > /dev/null 2>&1 &
        install_pid=$!

        # Show animated progress while installing
        while kill -0 $install_pid 2>/dev/null; do
            echo -ne "\033[1;38;5;75m.\033[0m"
            sleep 1
        done

        # Check if installation was successful
        wait $install_pid
        if xcode-select -p &>/dev/null; then
            echo -e " \033[1;38;5;118mDone ✓\033[0m"
        else
            echo -e " \033[1;38;5;196mFailed ✗\033[0m"
            echo -e "\033[1;38;5;196mPlease run 'xcode-select --install' manually.\033[0m"
        fi
    else
        echo -e " \033[1;38;5;196mFailed ✗\033[0m"
        echo -e "\033[1;38;5;196mCould not find Command Line Tools package. Please run 'xcode-select --install' manually.\033[0m"
    fi
fi

# Install pup HTML parser
CURRENT_SECTION="Installing pup HTML parser"
section_start "$CURRENT_SECTION"

# First make sure Go is installed and available
if ! command -v go &>/dev/null; then
    echo -e " \033[1;38;5;226mSkipped ⦿\033[0m (Go not installed)"
else
    # Install pup using go install
    (go install github.com/ericchiang/pup@latest) > /dev/null 2>&1 &
    install_pid=$!

    # Show animated progress while installing
    while kill -0 $install_pid 2>/dev/null; do
        echo -ne "\033[1;38;5;75m.\033[0m"
        sleep 1
    done

    # Check if installation was successful by looking for pup in GOPATH/bin
    wait $install_pid
    if [ $? -eq 0 ] && [ -x "$HOME/go/bin/pup" ]; then
        echo -e " \033[1;38;5;118mDone ✓\033[0m"

        # Add Go bin to PATH if not already there
        if ! grep -q 'export PATH="$HOME/go/bin:$PATH"' "$HOME/.zshrc"; then
            CURRENT_SECTION="Adding Go bin directory to PATH"
            section_start "$CURRENT_SECTION"
            echo 'export PATH="$HOME/go/bin:$PATH"' >> "$HOME/.zshrc"
            section_done
        fi
    else
        echo -e " \033[1;38;5;196mFailed ✗\033[0m"
    fi
fi

# Install Miniconda and set up Python ML environment
CURRENT_SECTION="Installing Miniconda"
section_start "$CURRENT_SECTION"

# Check if Miniconda is already installed
if [ -d "$HOME/miniconda3" ]; then
    section_skip
else
    # Download Miniconda installer for Apple Silicon
    (
        # Create a temporary directory
        tmp_dir=$(mktemp -d)
        cd "$tmp_dir"

        # Download the installer
        curl -fsSL https://repo.anaconda.com/miniconda/Miniconda3-latest-MacOSX-arm64.sh -o miniconda.sh

        # Install Miniconda non-interactively
        bash miniconda.sh -b -p "$HOME/miniconda3"

        # Add conda to path for this script session
        export PATH="$HOME/miniconda3/bin:$PATH"

        # Initialize conda for shell (without user confirmation)
        "$HOME/miniconda3/bin/conda" init zsh
        "$HOME/miniconda3/bin/conda" init bash

        # Configure conda to activate base environment by default
        "$HOME/miniconda3/bin/conda" config --set auto_activate_base true

        # Clean up
        cd - > /dev/null
        rm -rf "$tmp_dir"
    ) > /dev/null 2>&1 &

    install_pid=$!

    # Show animated progress while installing
    while kill -0 $install_pid 2>/dev/null; do
        echo -ne "\033[1;38;5;75m.\033[0m"
        sleep 1
    done

    # Check if installation was successful
    wait $install_pid
    if [ -d "$HOME/miniconda3" ]; then
        echo -e " \033[1;38;5;118mDone ✓\033[0m"
    else
        echo -e " \033[1;38;5;196mFailed ✗\033[0m"
    fi
fi

# Install PyTorch and ML packages
CURRENT_SECTION="Installing PyTorch and ML packages"
section_start "$CURRENT_SECTION"

# Create a flag file to track whether PyTorch is installed
pytorch_flag="$HOME/.pytorch_installed"

if [ -f "$pytorch_flag" ]; then
    section_skip
else
    # Install packages into the base environment
    (
        # Add conda to path for this script session if needed
        export PATH="$HOME/miniconda3/bin:$PATH"

        # Install Python 3.10 first
        "$HOME/miniconda3/bin/conda" install -y python=3.10

        # Install NumPy 1.x (compatible with PyTorch)
        "$HOME/miniconda3/bin/conda" install -y numpy=1.24

        # Install PyTorch with MPS support for Apple Silicon
        "$HOME/miniconda3/bin/conda" install -y pytorch torchvision torchaudio -c pytorch

        # Install common ML packages from conda-forge
        "$HOME/miniconda3/bin/conda" install -y pandas matplotlib scikit-learn jupyter ipykernel onnx -c conda-forge

        # Install additional ML packages from conda-forge
        "$HOME/miniconda3/bin/conda" install -y transformers datasets -c conda-forge

        # Create flag file to indicate successful installation
        touch "$pytorch_flag"
    ) > /dev/null 2>&1 &

    install_pid=$!

    # Show animated progress while installing
    while kill -0 $install_pid 2>/dev/null; do
        echo -ne "\033[1;38;5;75m.\033[0m"
        sleep 1
    done

    # Check if installation was successful
    wait $install_pid
    if [ -f "$pytorch_flag" ]; then
        echo -e " \033[1;38;5;118mDone ✓\033[0m"
    else
        echo -e " \033[1;38;5;196mFailed ✗\033[0m"
    fi
fi

# Add conda initialization to .zshrc
CURRENT_SECTION="Adding conda initialization to .zshrc"
section_start "$CURRENT_SECTION"

if grep -q "miniconda3/bin" "$HOME/.zshrc"; then
    section_skip
else
    # Add conda initialization
    (
        echo '' >> "$HOME/.zshrc"
        echo '# Conda initialization' >> "$HOME/.zshrc"
        echo 'export PATH="$HOME/miniconda3/bin:$PATH"' >> "$HOME/.zshrc"
        echo 'source $HOME/miniconda3/etc/profile.d/conda.sh' >> "$HOME/.zshrc"
    ) > /dev/null 2>&1

    # Check if successful
    if grep -q "miniconda3/bin" "$HOME/.zshrc"; then
        section_done
    else
        echo -e " \033[1;38;5;196mFailed ✗\033[0m"
    fi
fi

# Create a convenience script for ML project setup
CURRENT_SECTION="Creating ML project setup script"
section_start "$CURRENT_SECTION"

if [ -f "$HOME/bin/ml-project" ]; then
    section_skip
else
    cat <<"EOS" | sed 's/^    //' > ~/bin/ml-project
    #!/usr/bin/env bash

    # ML Project Setup Script
    # Usage: ml-project <project_name>

    if [ -z "$1" ]; then
        echo "Usage: ml-project <project_name>"
        exit 1
    fi

    PROJECT_NAME="$1"

    # Create project directory
    mkdir -p "$PROJECT_NAME"
    cd "$PROJECT_NAME"

    # Create standard project structure
    mkdir -p data/{raw,processed}
    mkdir -p notebooks
    mkdir -p src/{models,utils,data}

    # Create initial files
    touch README.md
    touch requirements.txt

    # Create .gitignore
    cat > .gitignore << 'GITIGNORE'
    # Python
    __pycache__/
    *.py[cod]
    *$py.class
    *.so
    .Python
    env/
    build/
    develop-eggs/
    dist/
    downloads/
    eggs/
    .eggs/
    lib/
    lib64/
    parts/
    sdist/
    var/
    *.egg-info/
    .installed.cfg
    *.egg

    # Jupyter Notebooks
    .ipynb_checkpoints

    # Model files
    *.h5
    *.pkl
    *.pt
    *.pth

    # Data files (consider your specific needs)
    data/raw/*
    data/processed/*
    !data/raw/.gitkeep
    !data/processed/.gitkeep

    # Environment
    .env
    .venv
    venv/
    ENV/
    GITIGNORE

    # Create placeholder files to keep directories
    touch data/raw/.gitkeep
    touch data/processed/.gitkeep

    # Initialize Jupyter notebook with PyTorch imports
    cat > notebooks/01_exploration.ipynb << 'NOTEBOOK'
    {
     "cells": [
      {
       "cell_type": "markdown",
       "metadata": {},
       "source": [
        "# Data Exploration and Analysis\n",
        "\n",
        "This notebook contains initial exploration of the dataset."
       ]
      },
      {
       "cell_type": "code",
       "execution_count": null,
       "metadata": {},
       "source": [
        "import torch\n",
        "import numpy as np\n",
        "import pandas as pd\n",
        "import matplotlib.pyplot as plt\n",
        "\n",
        "# Check PyTorch and access to MPS (Metal Performance Shaders)\n",
        "print(f\"PyTorch version: {torch.__version__}\")\n",
        "print(f\"MPS available: {torch.backends.mps.is_available()}\")\n",
        "\n",
        "# Set the compute device\n",
        "device = torch.device(\"mps\" if torch.backends.mps.is_available() else \"cpu\")\n",
        "print(f\"Using device: {device}\")"
       ],
       "outputs": []
      }
     ],
     "metadata": {
      "kernelspec": {
       "display_name": "Python [conda env:pytorch]",
       "language": "python",
       "name": "conda-env-pytorch-py"
      },
      "language_info": {
       "codemirror_mode": {
        "name": "ipython",
        "version": 3
       },
       "file_extension": ".py",
       "mimetype": "text/x-python",
       "name": "python",
       "nbconvert_exporter": "python",
       "pygments_lexer": "ipython3",
       "version": "3.10.0"
      }
     },
     "nbformat": 4,
     "nbformat_minor": 4
    }
    NOTEBOOK

    # Initialize main script file
    cat > src/main.py << 'MAINPY'
    import torch
    import argparse

    def main():
        parser = argparse.ArgumentParser(description='ML model training script')
        parser.add_argument('--data', type=str, required=True, help='Path to data file')
        parser.add_argument('--epochs', type=int, default=10, help='Number of epochs')
        parser.add_argument('--batch-size', type=int, default=32, help='Batch size')
        args = parser.parse_args()

        # Set device
        device = torch.device("mps" if torch.backends.mps.is_available() else "cpu")
        print(f"Using device: {device}")

        # Your code here
        print(f"Starting training with {args.epochs} epochs and batch size {args.batch_size}")

    if __name__ == "__main__":
        main()
    MAINPY

    # Activate the PyTorch environment
    # shellcheck disable=SC1090
    source "$HOME/miniconda3/etc/profile.d/conda.sh"
    conda activate pytorch

    # Install ipykernel for this project
    python -m ipykernel install --user --name pytorch --display-name "Python [conda env:pytorch]"

    echo "ML project '$PROJECT_NAME' created successfully!"
    echo "To start working:"
    echo "  cd $PROJECT_NAME"
    echo "  conda activate pytorch"
    echo "  jupyter notebook notebooks/01_exploration.ipynb"
EOS

    chmod +x ~/bin/ml-project

    if [ -x "$HOME/bin/ml-project" ]; then
        section_done
    else
        echo -e " \033[1;38;5;196mFailed ✗\033[0m"
    fi
fi

# Install Visual Studio Code and set up the CLI command
CURRENT_SECTION="Installing Visual Studio Code"
section_start "$CURRENT_SECTION"

# Check if VS Code is already installed
if [ -d "/Applications/Visual Studio Code.app" ]; then
    echo -e " \033[1;38;5;226mAlready installed ⦿\033[0m"
else
    # Install VS Code using brew
    brew_install --cask visual-studio-code
fi

# Set up the 'code' CLI command
CURRENT_SECTION="Setting up 'code' command-line tool"
section_start "$CURRENT_SECTION"

# Check if the command already exists and works
if command -v code &>/dev/null; then
    echo -e " \033[1;38;5;226mAlready set up ⦿\033[0m"
else
    # The path to the code binary inside VS Code.app
    CODE_CLI_PATH="/Applications/Visual Studio Code.app/Contents/Resources/app/bin/code"

    if [ -f "$CODE_CLI_PATH" ]; then
        # Create a symbolic link to the code CLI
        (
            # Check if ~/bin exists, create if not
            [ -d "$HOME/bin" ] || mkdir -p "$HOME/bin"

            # Create the symlink
            ln -sf "$CODE_CLI_PATH" "$HOME/bin/code"

            # Ensure the link is executable
            chmod +x "$HOME/bin/code"
        ) > /dev/null 2>&1 &

        install_pid=$!

        # Show animated progress while installing
        while kill -0 $install_pid 2>/dev/null; do
            echo -ne "\033[1;38;5;75m.\033[0m"
            sleep 1
        done

        # Check if the symlink was created successfully
        wait $install_pid
        if [ -x "$HOME/bin/code" ]; then
            echo -e " \033[1;38;5;118mDone ✓\033[0m"

            # Notify the user
            echo -e "\033[1;38;5;75m→ The 'code' command is now available in your terminal\033[0m"
        else
            echo -e " \033[1;38;5;196mFailed ✗\033[0m"
        fi
    else
        echo -e " \033[1;38;5;196mFailed ✗\033[0m"
        echo -e "\033[1;38;5;226mCLI tool not found. You can set it up manually from VS Code by:\033[0m"
        echo -e "\033[1;38;5;226m1. Opening VS Code\033[0m"
        echo -e "\033[1;38;5;226m2. Opening the Command Palette (Cmd+Shift+P)\033[0m"
        echo -e "\033[1;38;5;226m3. Typing 'shell command' and selecting 'Install code command in PATH'\033[0m"
    fi
fi

# Install Zed editor and set up the CLI command
CURRENT_SECTION="Installing Zed editor"
section_start "$CURRENT_SECTION"

# Check if Zed is already installed
if [ -d "/Applications/Zed.app" ]; then
    echo -e " \033[1;38;5;226mAlready installed ⦿\033[0m"
else
    # Install Zed using brew
    brew_install --cask zed
fi

# Set up the 'zed' CLI command
CURRENT_SECTION="Setting up 'zed' command-line tool"
section_start "$CURRENT_SECTION"

# Check if the command already exists and works
if command -v zed &>/dev/null; then
    echo -e " \033[1;38;5;226mAlready set up ⦿\033[0m"
else
    # The path to the zed CLI binary inside Zed.app
    ZED_CLI_PATH="/Applications/Zed.app/Contents/MacOS/cli"

    if [ -f "$ZED_CLI_PATH" ]; then
        # Create a symbolic link to the zed CLI
        (
            # Ensure /usr/local/bin exists
            [ -d "/usr/local/bin" ] || sudo mkdir -p "/usr/local/bin"

            # Create the symlink (might require sudo)
            if [ -w "/usr/local/bin" ]; then
                # If user has write permission, create link without sudo
                ln -sf "$ZED_CLI_PATH" "/usr/local/bin/zed"
            else
                # Otherwise use sudo
                sudo ln -sf "$ZED_CLI_PATH" "/usr/local/bin/zed"
            fi
        ) > /dev/null 2>&1 &

        install_pid=$!

        # Show animated progress while installing
        while kill -0 $install_pid 2>/dev/null; do
            echo -ne "\033[1;38;5;75m.\033[0m"
            sleep 1
        done

        # Check if the symlink was created successfully
        wait $install_pid
        if [ -x "/usr/local/bin/zed" ]; then
            echo -e " \033[1;38;5;118mDone ✓\033[0m"

            # Notify the user
            echo -e "\033[1;38;5;75m→ The 'zed' command is now available in your terminal\033[0m"
        else
            echo -e " \033[1;38;5;196mFailed ✗\033[0m"

            # Alternative: Create link in ~/bin if /usr/local/bin failed
            echo -e "\033[1;38;5;75m→ Trying alternative installation to ~/bin...\033[0m"

            (
                # Ensure ~/bin exists
                [ -d "$HOME/bin" ] || mkdir -p "$HOME/bin"

                # Create the symlink in ~/bin
                ln -sf "$ZED_CLI_PATH" "$HOME/bin/zed"

                # Ensure the link is executable
                chmod +x "$HOME/bin/zed"
            ) > /dev/null 2>&1 &

            install_pid=$!

            # Show animated progress
            while kill -0 $install_pid 2>/dev/null; do
                echo -ne "\033[1;38;5;75m.\033[0m"
                sleep 1
            done

            # Check if the alternative symlink was created successfully
            wait $install_pid
            if [ -x "$HOME/bin/zed" ]; then
                echo -e " \033[1;38;5;118mDone ✓\033[0m"
                echo -e "\033[1;38;5;75m→ The 'zed' command is now available in your terminal (via ~/bin)\033[0m"
            else
                echo -e " \033[1;38;5;196mFailed ✗\033[0m"
            fi
        fi
    else
        echo -e " \033[1;38;5;196mFailed ✗\033[0m"
        echo -e "\033[1;38;5;226mCLI tool not found. Zed might not have been installed correctly.\033[0m"
    fi
fi

# Install JetBrains Mono font
CURRENT_SECTION="Installing JetBrains Mono font"
section_start "$CURRENT_SECTION"

# Check if font is already installed
if [ -f "$HOME/Library/Fonts/JetBrainsMono-Regular.ttf" ]; then
    echo -e " \033[1;38;5;226mAlready installed ⦿\033[0m"
else
    # Download and install JetBrains Mono
    (
        # Create a temporary directory
        tmp_dir=$(mktemp -d)
        cd "$tmp_dir"

        # Download the font zip file
        curl -L -s -o jetbrains-mono.zip "https://github.com/JetBrains/JetBrainsMono/releases/download/v2.304/JetBrainsMono-2.304.zip"

        # Extract the font files
        unzip -q jetbrains-mono.zip

        # Create the user fonts directory if it doesn't exist
        mkdir -p "$HOME/Library/Fonts"

        # Copy the font files to the user fonts directory
        cp -f fonts/ttf/*.ttf "$HOME/Library/Fonts/"

        # Clean up
        cd - > /dev/null
        rm -rf "$tmp_dir"
    ) > /dev/null 2>&1 &

    install_pid=$!

    # Show animated progress while installing
    while kill -0 $install_pid 2>/dev/null; do
        echo -ne "\033[1;38;5;75m.\033[0m"
        sleep 1
    done

    # Check if installation was successful
    wait $install_pid
    if [ $? -eq 0 ] && [ -f "$HOME/Library/Fonts/JetBrainsMono-Regular.ttf" ]; then
        echo -e " \033[1;38;5;118mDone ✓\033[0m"
        echo -e "\033[1;38;5;75m→ JetBrains Mono font has been installed and is ready to use in your applications\033[0m"
    else
        echo -e " \033[1;38;5;196mFailed ✗\033[0m"
    fi
fi

# Import custom Terminal.app profile
CURRENT_SECTION="Installing custom Terminal.app profile"
section_start "$CURRENT_SECTION"

# Download and import Terminal profile
(
    # Download the profile
    curl -fsSL -o "/tmp/Retronome.terminal" "https://raw.githubusercontent.com/retronome/bootstrap/main/Retronome.terminal"

    # Import the profile (this will open Terminal.app)
    open "/tmp/Retronome.terminal"

    # Wait a moment for Terminal to process
    sleep 2

    # Set as default profile
    defaults write com.apple.Terminal "Default Window Settings" -string "Retronome"
    defaults write com.apple.Terminal "Startup Window Settings" -string "Retronome"

    # Clean up
    rm -f "/tmp/Retronome.terminal"
) > /dev/null 2>&1 &

install_pid=$!

# Show animated progress while installing
while kill -0 $install_pid 2>/dev/null; do
    echo -ne "\033[1;38;5;75m.\033[0m"
    sleep 1
done

# Check if installation was successful
wait $install_pid
if [ $? -eq 0 ]; then
    echo -e " \033[1;38;5;118mDone ✓\033[0m"
    TERMINAL_CONFIGURED=true
else
    echo -e " \033[1;38;5;196mFailed ✗\033[0m"
fi

# Keep track that we need to tell user to restart Terminal at the end
NEEDS_TERMINAL_RESTART=true

# Add Terminal restart instructions if needed
if [ "${NEEDS_TERMINAL_RESTART:-false}" = true ]; then
    echo -e "\n\033[1;38;5;51m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"
    echo -e "\033[1;38;5;226m⚠️  Action Required:\033[0m"
    echo -e "\033[1;38;5;75m→ Please restart Terminal.app to apply all changes:\033[0m"
    echo -e "   \033[1;38;5;255m- New JetBrains Mono font\033[0m"
    echo -e "   \033[1;38;5;255m- Custom Terminal theme\033[0m"
    echo -e "   \033[1;38;5;255m- Updated PATH and environment variables\033[0m"
    echo -e "   \033[1;38;5;255m- Oh My Zsh configuration\033[0m"
    echo -e "\033[1;38;5;51m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"
fi

# Print important follow-up instructions if needed
if [ "$GCM_NEEDS_INSTALL" = true ]; then
    echo -e "\n\033[1;38;5;51m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"
    echo -e "\033[1;38;5;226m⚠️  Follow-up Action Required:\033[0m"
    echo -e "\033[1;38;5;75m→ Install Git Credential Manager (requires sudo):\033[0m"
    echo -e "   \033[1;38;5;255mbrew install git-credential-manager && sudo git-credential-manager configure\033[0m"
    echo -e "\033[1;38;5;51m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"
fi

# Print completion message with the same border color
echo -e "\n\n\033[1;38;5;${BORDER_COLOR}m┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓\033[0m"
echo -e "\033[1;38;5;${BORDER_COLOR}m┃\033[0m              \033[1;38;5;51mD\033[1;38;5;87mo\033[1;38;5;123mn\033[1;38;5;159me\033[1;38;5;195m!\033[0m \033[1;38;5;51mS\033[1;38;5;87me\033[1;38;5;123mt\033[1;38;5;159mu\033[1;38;5;195mp\033[0m \033[1;38;5;51mc\033[1;38;5;87mo\033[1;38;5;123mm\033[1;38;5;159mp\033[1;38;5;195ml\033[1;38;5;51me\033[1;38;5;87mt\033[1;38;5;123me\033[1;38;5;159m.\033[0m               \033[1;38;5;${BORDER_COLOR}m┃\033[0m"
echo -e "\033[1;38;5;${BORDER_COLOR}m┃\033[0m                                                  \033[1;38;5;${BORDER_COLOR}m┃\033[0m"
echo -e "\033[1;38;5;${BORDER_COLOR}m┃\033[0m       \033[1;38;5;201mG\033[1;38;5;200mo\033[0m \033[1;38;5;199mf\033[1;38;5;198mo\033[1;38;5;197mr\033[1;38;5;196mt\033[1;38;5;202mh\033[0m \033[1;38;5;208ma\033[1;38;5;214mn\033[1;38;5;220md\033[0m \033[1;38;5;226mc\033[1;38;5;190mo\033[1;38;5;154md\033[1;38;5;118me\033[0m \033[1;38;5;82mw\033[1;38;5;46mi\033[1;38;5;47mt\033[1;38;5;48mh\033[0m \033[1;38;5;49mg\033[1;38;5;50mr\033[1;38;5;51me\033[1;38;5;45ma\033[1;38;5;39mt\033[0m \033[1;38;5;33mv\033[1;38;5;27me\033[1;38;5;21mr\033[1;38;5;57mv\033[1;38;5;93me\033[1;38;5;129m!\033[0m        \033[1;38;5;${BORDER_COLOR}m┃\033[0m"
echo -e "\033[1;38;5;${BORDER_COLOR}m┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛\033[0m\n"
