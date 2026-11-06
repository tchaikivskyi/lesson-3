set -euo pipefail

readonly MIN_PY_MAJOR=3
readonly MIN_PY_MINOR=9

info()  { printf '\033[1;34m[INFO]\033[0m  %s\n' "$*"; }
ok()    { printf '\033[1;32m[OK]\033[0m    %s\n' "$*"; }
warn()  { printf '\033[1;33m[WARN]\033[0m  %s\n' "$*"; }
error() { printf '\033[1;31m[ERROR]\033[0m %s\n' "$*" >&2; }

command_exists() { command -v "$1" >/dev/null 2>&1; }

if [[ $EUID -eq 0 ]]; then
    SUDO=""
elif command_exists sudo; then
    SUDO="sudo"
else
    error "Потрібні права root або встановлений sudo."
    exit 1
fi

check_os() {
    if [[ ! -f /etc/os-release ]]; then
        error "Не вдалося визначити ОС (/etc/os-release відсутній)."
        exit 1
    fi
    . /etc/os-release
    OS_ID="${ID}"
    OS_CODENAME="${VERSION_CODENAME:-}"

    case "${OS_ID}" in
        ubuntu|debian) ok "ОС: ${PRETTY_NAME}" ;;
        *)
            error "Підтримуються лише Ubuntu та Debian (виявлено: ${OS_ID})."
            exit 1
            ;;
    esac
}

APT_UPDATED=0
apt_update_once() {
    if [[ $APT_UPDATED -eq 0 ]]; then
        info "Оновлення списку пакетів..."
        $SUDO apt-get update -y
        APT_UPDATED=1
    fi
}

apt_install() {
    apt_update_once
    $SUDO env DEBIAN_FRONTEND=noninteractive apt-get install -y "$@"
}

install_docker() {
    if command_exists docker; then
        ok "Docker вже встановлено: $(docker --version)"
        return
    fi

    info "Встановлення Docker з офіційного репозиторію Docker..."
    apt_install ca-certificates curl gnupg

    $SUDO install -m 0755 -d /etc/apt/keyrings
    $SUDO curl -fsSL "https://download.docker.com/linux/${OS_ID}/gpg" \
        -o /etc/apt/keyrings/docker.asc
    $SUDO chmod a+r /etc/apt/keyrings/docker.asc

    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] \
https://download.docker.com/linux/${OS_ID} ${OS_CODENAME} stable" \
        | $SUDO tee /etc/apt/sources.list.d/docker.list >/dev/null

    APT_UPDATED=0
    apt_install docker-ce docker-ce-cli containerd.io docker-buildx-plugin

    $SUDO systemctl enable --now docker 2>/dev/null || warn "Не вдалося запустити службу docker через systemctl."

    if [[ -n "${SUDO}" ]] && ! id -nG "$USER" | grep -qw docker; then
        $SUDO usermod -aG docker "$USER"
        warn "Користувача ${USER} додано до групи docker. Перелогіньтесь, щоб працювати з Docker без sudo."
    fi

    ok "Docker встановлено: $(docker --version)"
}

install_docker_compose() {
    if docker compose version >/dev/null 2>&1; then
        ok "Docker Compose вже встановлено: $(docker compose version)"
        return
    fi
    if command_exists docker-compose; then
        ok "Docker Compose (standalone) вже встановлено: $(docker-compose --version)"
        return
    fi

    info "Встановлення Docker Compose (plugin)..."
    if ! apt_install docker-compose-plugin; then
        warn "docker-compose-plugin недоступний, встановлюю пакет docker-compose."
        apt_install docker-compose
    fi

    if docker compose version >/dev/null 2>&1; then
        ok "Docker Compose встановлено: $(docker compose version)"
    else
        ok "Docker Compose встановлено: $(docker-compose --version)"
    fi
}

python_version_ok() {
    "$1" -c "import sys; sys.exit(0 if sys.version_info >= (${MIN_PY_MAJOR}, ${MIN_PY_MINOR}) else 1)" \
        2>/dev/null
}

install_python() {
    if command_exists python3 && python_version_ok python3; then
        ok "Python вже встановлено: $(python3 --version)"
    else
        info "Встановлення Python ${MIN_PY_MAJOR}.${MIN_PY_MINOR}+..."
        apt_install python3
        if ! python_version_ok python3; then
            warn "Системний python3 старший за ${MIN_PY_MAJOR}.${MIN_PY_MINOR}, встановлюю python3.9."
            apt_install python3.9 python3.9-venv
            $SUDO update-alternatives --install /usr/bin/python3 python3 /usr/bin/python3.9 2
        fi
        ok "Python встановлено: $(python3 --version)"
    fi

    if python3 -m pip --version >/dev/null 2>&1; then
        ok "pip вже встановлено: $(python3 -m pip --version | cut -d' ' -f1-2)"
    else
        info "Встановлення pip..."
        apt_install python3-pip
        ok "pip встановлено: $(python3 -m pip --version | cut -d' ' -f1-2)"
    fi
}

# ---------- Django ----------
install_django() {
    if python3 -c "import django" >/dev/null 2>&1; then
        ok "Django вже встановлено: $(python3 -m django --version)"
        return
    fi

    info "Встановлення Django через pip..."
    local pip_args=(install --user django)
    if python3 -m pip install --help 2>/dev/null | grep -q -- '--break-system-packages'; then
        local stdlib
        stdlib="$(python3 -c 'import sysconfig; print(sysconfig.get_path("stdlib"))')"
        if [[ -f "${stdlib}/EXTERNALLY-MANAGED" ]]; then
            pip_args+=(--break-system-packages)
        fi
    fi
    python3 -m pip "${pip_args[@]}"

    if [[ ":$PATH:" != *":$HOME/.local/bin:"* ]]; then
        warn "Додайте ~/.local/bin у PATH, щоб django-admin був доступний: export PATH=\"\$HOME/.local/bin:\$PATH\""
    fi

    ok "Django встановлено: $(python3 -m django --version)"
}

main() {
    info "=== Встановлення інструментів DevOps ==="
    check_os
    install_docker
    install_docker_compose
    install_python
    install_django
    info "=== Готово ==="
}

main "$@"