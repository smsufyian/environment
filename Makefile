
# Global configuration and helpers
.PHONY: help check-deps install-deps check-docker devstart devstop devrebuild devlogs devshell devclean

# Colors for output
BLUE := \033[0;34m
GREEN := \033[0;32m
YELLOW := \033[0;33m
RED := \033[0;31m
CYAN := \033[0;36m
MAGENTA := \033[0;35m
WHITE := \033[1;37m
BOLD := \033[1m
UNDERLINE := \033[4m
NC := \033[0m # No Color

# Progress bar characters
PROGRESS_EMPTY := ░
PROGRESS_FULL := █
PROGRESS_WIDTH := 30

# Detect OS
# Also detect Windows-like environments (Git Bash/MSYS/Cygwin/WSL) via uname -s and
# treat them as "windows". Assumes a Bash-compatible shell is used on Windows.
UNAME_S := $(shell uname -s)
ifeq ($(UNAME_S),Linux)
	OS := linux
endif
ifeq ($(UNAME_S),Darwin)
	OS := macos
endif
ifneq (,$(filter MINGW% MSYS% CYGWIN%,$(UNAME_S)))
	OS := windows
endif

# Helper macros for colored output
# IMPORTANT: Do NOT prefix commands in macro bodies with '@'. These macros may be
# expanded inside shell blocks (if/then/else). If the body started with '@', the shell
# would see a literal '@echo' which fails. Suppress echoing at call sites instead,
# e.g., use '@$(call print_section,...)' inside recipes.

# Helper function to print colored header
define print_header
	echo ""
	echo "$(CYAN)╔════════════════════════════════════════════════════════════╗$(NC)"
	echo "$(CYAN)║$(NC) $(BOLD)$(WHITE)$(1)$(NC) $(CYAN)║$(NC)"
	echo "$(CYAN)╚════════════════════════════════════════════════════════════╝$(NC)"
	echo ""
endef

# Helper function to print progress bar (POSIX sh compatible)
define print_progress
	echo -n "$(MAGENTA)[$(NC)"
	i=1; \
	while [ $$i -le $(PROGRESS_WIDTH) ]; do \
		echo -n "$(PROGRESS_FULL)"; \
		i=$$((i+1)); \
	done
	echo "$(MAGENTA)] $(GREEN)100%$(NC) $(1)$(NC)"
endef

# Helper function to print colored section
define print_section
	echo "$(BOLD)$(CYAN)▶ $(1)$(NC)"
endef

# Helper function to print success message
define print_success
	echo "$(GREEN)✓ $(1)$(NC)"
endef

# Helper function to print error message
define print_error
	echo "$(RED)✗ $(1)$(NC)"
endef

# Helper function to print warning message
define print_warning
	echo "$(YELLOW)⚠ $(1)$(NC)"
endef

# Helper function to print info message
define print_info
	echo "$(BLUE)ℹ $(1)$(NC)"
endef

# Default command when just running 'make'
.DEFAULT_GOAL := help

help:
	@$(call print_header,Dev Container Toolkit - Available Commands)
	@echo "$(BOLD)$(BLUE)Installation & Setup:$(NC)"
	@echo "  $(GREEN)make check-deps$(NC)       - Check if all dependencies are installed"
	@echo "  $(GREEN)make install-deps$(NC)     - Install missing dependencies"
	@echo "  $(GREEN)make check-docker$(NC)     - Check if Docker daemon is running"
	@echo ""
	@echo "$(BOLD)$(BLUE)Container Operations:$(NC)"
	@echo "  $(GREEN)make devstart$(NC)         - Start the dev container"
	@echo "  $(GREEN)make devstop$(NC)          - Stop the dev container"
	@echo "  $(GREEN)make devrebuild$(NC)       - Rebuild the dev container"
	@echo "  $(GREEN)make devlogs$(NC)          - View dev container logs"
	@echo "  $(GREEN)make devshell$(NC)         - Open shell in running container"
	@echo "  $(GREEN)make devclean$(NC)         - Remove dev container and images"
	@echo ""

check-deps:
	@$(call print_header,Dependency Check)
	@$(call print_section,Verifying installed tools)
	@echo ""
	@if command -v docker >/dev/null 2>&1; then \
		$(call print_success,Docker is installed); \
		docker --version | sed 's/^/  /'; \
	else \
		$(call print_error,Docker is NOT installed); \
	fi
	@echo ""
	@if command -v docker-compose >/dev/null 2>&1; then \
		$(call print_success,Docker Compose is installed); \
		docker-compose --version | sed 's/^/  /'; \
	else \
		$(call print_error,Docker Compose is NOT installed); \
	fi
	@echo ""
	@if command -v devcontainer >/dev/null 2>&1; then \
		$(call print_success,Dev Containers CLI is installed); \
		devcontainer --version | sed 's/^/  /'; \
	else \
		$(call print_error,Dev Containers CLI is NOT installed); \
	fi
	@echo ""

check-docker:
	@$(call print_header,Docker Daemon Status Check)
	@$(call print_section,Verifying Docker daemon)
	@echo ""
	@if docker info >/dev/null 2>&1; then \
		$(call print_success,Docker daemon is running); \
		echo ""; \
		docker --version | sed 's/^/  /'; \
	else \
		$(call print_error,Docker daemon is NOT running); \
		echo ""; \
		$(call print_warning,Please start Docker Desktop or Docker daemon and try again); \
		echo ""; \
		echo "$(YELLOW)macOS:$(NC) Open Docker Desktop from Applications"; \
		echo "$(YELLOW)Linux:$(NC) Run: $(BOLD)sudo systemctl start docker$(NC)"; \
		echo ""; \
		exit 1; \
	fi
	@echo ""

install-deps:
	@$(call print_header,Dependency Installation)
	@$(call print_section,Detecting operating system)
	@echo ""
ifeq ($(OS),macos)
	@echo "$(MAGENTA)→ macOS detected$(NC)"
	@echo ""
	@$(call print_section,Checking Homebrew)
	@if command -v brew >/dev/null 2>&1; then \
		$(call print_success,Homebrew is already installed); \
	else \
		$(call print_warning,Homebrew not found. Installing...); \
		/bin/bash -c "$$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"; \
		$(call print_success,Homebrew installed); \
	fi
	@echo ""
	@$(call print_section,Installing Docker Desktop)
	@if command -v docker >/dev/null 2>&1; then \
		$(call print_success,Docker is already installed); \
	else \
		echo "$(YELLOW)Installing Docker Desktop via Homebrew...$(NC)"; \
		brew install --cask docker; \
		$(call print_success,Docker Desktop installed); \
		$(call print_warning,Please launch Docker Desktop from Applications); \
	fi
	@echo ""
	@$(call print_section,Installing Dev Containers CLI)
	@if command -v devcontainer >/dev/null 2>&1; then \
		$(call print_success,Dev Containers CLI is already installed); \
	else \
		echo "$(YELLOW)Installing Dev Containers CLI via npm...$(NC)"; \
		npm install -g @devcontainers/cli; \
		$(call print_success,Dev Containers CLI installed); \
	fi
	@echo ""
	@$(call print_success,All dependencies installed for macOS)
	@$(call print_warning,Please ensure Docker Desktop is running before using 'make devstart')
	@echo ""
else ifeq ($(OS),linux)
	@echo "$(MAGENTA)→ Linux detected$(NC)"
	@echo ""
	@$(call print_section,Updating package lists)
	@sudo apt-get update && sudo apt-get install -y curl gnupg lsb-release ubuntu-keyring || true
	@echo ""
	@$(call print_section,Installing Docker)
	@if command -v docker >/dev/null 2>&1; then \
		$(call print_success,Docker is already installed); \
	else \
		echo "$(YELLOW)Installing Docker...$(NC)"; \
		curl -fsSL https://get.docker.com -o get-docker.sh && sudo sh get-docker.sh && rm get-docker.sh; \
		sudo usermod -aG docker $$USER; \
		$(call print_success,Docker installed); \
		$(call print_warning,Please log out and log back in for group changes to take effect); \
	fi
	@echo ""
	@$(call print_section,Installing Docker Compose)
	@if command -v docker-compose >/dev/null 2>&1; then \
		$(call print_success,Docker Compose is already installed); \
	else \
		echo "$(YELLOW)Installing Docker Compose...$(NC)"; \
		sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$$(uname -s)-$$(uname -m)" -o /usr/local/bin/docker-compose && sudo chmod +x /usr/local/bin/docker-compose; \
		$(call print_success,Docker Compose installed); \
	fi
	@echo ""
	@$(call print_section,Installing Dev Containers CLI)
	@if command -v devcontainer >/dev/null 2>&1; then \
		$(call print_success,Dev Containers CLI is already installed); \
	else \
		echo "$(YELLOW)Installing Dev Containers CLI...$(NC)"; \
		sudo npm install -g @devcontainers/cli; \
		$(call print_success,Dev Containers CLI installed); \
	fi
	@echo ""
	@$(call print_section,Starting Docker daemon)
	@sudo systemctl start docker || true
	@$(call print_success,Docker daemon started)
	@echo ""
	@$(call print_success,All dependencies installed for Linux)
	@echo ""
else ifeq ($(OS),windows)
	@echo "$(MAGENTA)→ Windows detected$(NC)"
	@echo ""
	@$(call print_section,Checking Docker)
	@if command -v docker >/dev/null 2>&1; then \
		$(call print_success,Docker is available on PATH); \
		docker --version | sed 's/^/  /'; \
	else \
		$(call print_warning,Please install Docker Desktop for Windows: https://docs.docker.com/desktop/install/windows/); \
	fi
	@echo ""
	@$(call print_section,Checking Dev Containers CLI)
	@if command -v devcontainer >/dev/null 2>&1; then \
		$(call print_success,Dev Containers CLI is available); \
		devcontainer --version | sed 's/^/  /'; \
	else \
		$(call print_warning,Dev Containers CLI not found); \
		echo "  Install via npm: npm install -g @devcontainers/cli"; \
		echo "  Note: Node.js is required: https://nodejs.org/"; \
	fi
	@echo ""
	@$(call print_info,On Windows, this Makefile provides detection and guidance only. Follow the instructions above.)
	@echo ""
else
	@$(call print_error,Unsupported OS detected)
	@echo "$(YELLOW)Please install the following manually:$(NC)"
	@echo "  • Docker: https://docs.docker.com/get-docker/"
	@echo "  • Docker Compose: https://docs.docker.com/compose/install/"
	@echo "  • Dev Containers CLI: npm install -g @devcontainers/cli"
	@echo ""
endif

devstart: check-deps check-docker
	@$(call print_header,Starting Dev Container)
	@$(call print_section,Initializing container environment)
	@echo ""
	@devcontainer open --workspace-folder $(PWD)
	@echo ""
	@$(call print_progress,Dev container started successfully)
	@echo ""
	@$(call print_success,Your development environment is ready)
	@echo "$(BLUE)ℹ Run 'make help' for more commands$(NC)"
	@echo ""

devstop: check-docker
	@$(call print_header,Stopping Dev Container)
	@$(call print_section,Shutting down container)
	@echo ""
	@devcontainer close --workspace-folder $(PWD)
	@echo ""
	@$(call print_progress,Dev container stopped)
	@echo ""

devrebuild: check-deps check-docker
	@$(call print_header,Rebuilding Dev Container)
	@$(call print_section,Reconstructing container image)
	@echo ""
	@devcontainer rebuild --workspace-folder $(PWD)
	@echo ""
	@$(call print_progress,Dev container rebuilt successfully)
	@echo ""
	@$(call print_success,Container is ready to use)
	@echo ""

devlogs: check-docker
	@$(call print_header,Dev Container Logs)
	@$(call print_section,Streaming container logs)
	@echo ""
	@docker logs -f devcontainer-go-1

devshell: check-docker
	@$(call print_header,Container Shell Access)
	@$(call print_section,Connecting to container)
	@echo ""
	@docker exec -it devcontainer-go-1 /bin/bash

devclean: check-docker
	@$(call print_header,Cleaning Up Dev Container)
	@$(call print_section,Removing container and images)
	@echo ""
	@devcontainer close --workspace-folder $(PWD) || true
	@docker system prune -f
	@echo ""
	@$(call print_progress,Dev container cleaned successfully)
	@echo ""
	@$(call print_success,All containers and unused images removed)
	@echo ""