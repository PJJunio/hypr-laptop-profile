#!/usr/bin/env bash
set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/notebook-profile"
CONFIG_FILE="$CONFIG_DIR/config.env"
INSTALL_DIR="${HOME}/.local/bin"
TARGET_BIN="${INSTALL_DIR}/notebook-profile"

INTERNAL_DISPLAY=""
BATTERY_BRIGHTNESS=""
AC_BRIGHTNESS=""
BATTERY_RESOLUTION=""
BATTERY_REFRESH=""
AC_RESOLUTION=""
AC_REFRESH=""
INSTALL_DEPS="1"
INSTALL_HYPR_SNIPPET="1"
INSTALL_KEYBINDS="0"
AUTO_YES="0"
FORCE_OVERWRITE="0"
MODE_VALIDATION_WARNING_SHOWN="0"
RESOLVED_MODE_RESOLUTION=""
RESOLVED_MODE_REFRESH=""
CONFIG_BACKUP_CREATED="0"
HYPR_BACKUP_CREATED="0"

usage() {
  cat <<'EOF'
uso: ./install.sh [opcoes]

opcoes:
  --internal-display NOME       nome do display interno, ex: eDP-1
  --battery-brightness N        brilho na bateria, ex: 70
  --ac-brightness N             brilho na tomada, ex: 100
  --battery-resolution RES      resolucao na bateria, ex: 1920x1080
  --battery-refresh HZ          frequencia na bateria, ex: 60
  --ac-resolution RES           resolucao na tomada, ex: 1920x1080
  --ac-refresh HZ               frequencia na tomada, ex: 144
  --skip-deps                   nao tenta instalar dependencias
  --skip-hypr-snippet           nao instala snippet de exec-once
  --install-keybindings         instala snippet com atalhos
  --yes                         aceita os valores padrao sem perguntar
  --force                       sobrescreve arquivos gerados sem perguntar, mantendo backup
  -h, --help                    mostra esta ajuda

sem flags, o script roda em modo interativo.
EOF
}

have_cmd() {
  command -v "$1" >/dev/null 2>&1
}

log() {
  printf '[install] %s\n' "$1"
}

warn() {
  printf '[install] aviso: %s\n' "$1" >&2
}

die() {
  printf '[install] erro: %s\n' "$1" >&2
  exit 1
}

timestamp() {
  date +"%Y%m%d-%H%M%S"
}

backup_file() {
  local source_file="$1"
  local backup_file_path="$2"
  cp "$source_file" "$backup_file_path" || die "nao foi possivel criar backup de ${source_file}"
  log "backup criado: ${backup_file_path}"
}

prompt() {
  local label="$1"
  local default="$2"
  local answer=""

  if [[ "$AUTO_YES" == "1" ]]; then
    printf '%s\n' "$default"
    return 0
  fi

  read -r -p "${label} [${default}]: " answer
  printf '%s\n' "${answer:-$default}"
}

prompt_required() {
  local label="$1"
  local answer=""

  while true; do
    if [[ "$AUTO_YES" == "1" ]]; then
      printf '[install] erro: valor obrigatorio ausente para %s no modo --yes\n' "$label" >&2
      exit 1
    fi

    read -r -p "${label}: " answer
    if [[ -n "$answer" ]]; then
      printf '%s\n' "$answer"
      return 0
    fi
    warn "esse campo e obrigatorio"
  done
}

confirm() {
  local label="$1"
  local default="${2:-y}"
  local answer=""

  if [[ "$AUTO_YES" == "1" ]]; then
    [[ "$default" =~ ^[Yy]$ ]]
    return $?
  fi

  read -r -p "${label} [${default}/n]: " answer
  answer="${answer:-$default}"
  [[ "$answer" =~ ^[Yy]$ ]]
}

check_basic_requirements() {
  [[ -f "${PROJECT_DIR}/bin/notebook-profile" ]] || die "script principal nao encontrado em ${PROJECT_DIR}/bin/notebook-profile"
  have_cmd install || die "comando 'install' nao encontrado; instale coreutils"
  mkdir -p "$INSTALL_DIR" || die "nao foi possivel criar ${INSTALL_DIR}"
  mkdir -p "$CONFIG_DIR" || die "nao foi possivel criar ${CONFIG_DIR}"
  [[ -w "$INSTALL_DIR" ]] || die "sem permissao de escrita em ${INSTALL_DIR}"
  [[ -w "$CONFIG_DIR" ]] || die "sem permissao de escrita em ${CONFIG_DIR}"
}

report_existing_installation() {
  local hypr_snippet="${XDG_CONFIG_HOME:-$HOME/.config}/hypr/conf.d/notebook-profile.conf"
  local found=0

  if [[ -f "$TARGET_BIN" ]]; then
    log "instalacao existente detectada: binario em ${TARGET_BIN}"
    found=1
  fi

  if [[ -f "$CONFIG_FILE" ]]; then
    log "instalacao existente detectada: configuracao em ${CONFIG_FILE}"
    found=1
  fi

  if [[ -f "$hypr_snippet" ]]; then
    log "instalacao existente detectada: snippet do Hyprland em ${hypr_snippet}"
    found=1
  fi

  [[ "$found" -eq 1 ]] || return 0
  warn "a instalacao sera tratada como atualizacao segura"
  [[ "$FORCE_OVERWRITE" == "1" ]] && warn "modo --force ativo: arquivos gerados serao sobrescritos automaticamente com backup"
}

has_hyprctl_access() {
  have_cmd hyprctl || return 1
  hyprctl monitors -j >/dev/null 2>&1
}

warn_if_hyprctl_unavailable() {
  if ! have_cmd hyprctl; then
    warn "hyprctl nao encontrado"
    warn "sem hyprctl o instalador nao consegue detectar a tela interna nem validar modos automaticamente"
    return 0
  fi

  if ! has_hyprctl_access; then
    warn "hyprctl encontrado, mas nao foi possivel consultar os monitores"
    warn "isso normalmente acontece fora de uma sessao Hyprland ativa"
    warn "o instalador seguira em modo manual para nome da tela e validacao de modos"
  fi
}

validate_brightness_value() {
  local value="$1"
  local label="$2"
  [[ "$value" =~ ^[0-9]+$ ]] || die "${label} deve ser um numero inteiro entre 1 e 100"
  (( value >= 1 && value <= 100 )) || die "${label} deve estar entre 1 e 100"
}

validate_refresh_value() {
  local value="$1"
  local label="$2"
  [[ "$value" =~ ^[0-9]+$ ]] || die "${label} deve ser um numero inteiro em Hz"
  (( value >= 1 )) || die "${label} deve ser maior que zero"
}

validate_resolution_value() {
  local value="$1"
  local label="$2"
  [[ "$value" =~ ^[0-9]+x[0-9]+$ ]] || die "${label} deve estar no formato LARGURAxALTURA, por exemplo 1920x1080"
}

detect_current_display() {
  if has_hyprctl_access && have_cmd jq; then
    hyprctl monitors -j 2>/dev/null \
      | jq -r '.[] | select(.name | test("^(eDP|LVDS|DSI)"; "i")) | .name' \
      | head -n1
  fi
}

resolve_internal_display() {
  local detected_display="${1:-}"
  local confirmed="n"

  if [[ -n "$INTERNAL_DISPLAY" ]]; then
    return 0
  fi

  if [[ -n "$detected_display" ]]; then
    log "tela interna detectada automaticamente: ${detected_display}"
    if confirm "usar ${detected_display} como tela interna?" "y"; then
      INTERNAL_DISPLAY="$detected_display"
      return 0
    fi
  else
    warn "nao foi possivel detectar automaticamente a tela interna"
  fi

  warn "para descobrir manualmente, rode:"
  warn "  hyprctl monitors"
  warn "ou:"
  warn "  hyprctl monitors -j | jq -r '.[].name'"

  INTERNAL_DISPLAY="$(prompt_required "digite o nome da sua tela interna")"
}

detect_current_mode() {
  local display_name="${1:-}"
  [[ -n "$display_name" ]] || return 0

  if has_hyprctl_access && have_cmd jq; then
    hyprctl monitors -j 2>/dev/null \
      | jq -r --arg name "$display_name" '
          .[]
          | select(.name == $name)
          | "\(.width)x\(.height)@\(.refreshRate | floor)"
        ' \
      | head -n1
  fi
}

list_display_modes() {
  local display_name="${1:-}"
  local monitors_json=""
  [[ -n "$display_name" ]] || return 0
  has_hyprctl_access || return 0
  have_cmd jq || return 0

  monitors_json="$(hyprctl monitors all -j 2>/dev/null || hyprctl monitors -j 2>/dev/null || true)"
  [[ -n "$monitors_json" ]] || return 0
  jq -e . >/dev/null 2>&1 <<<"$monitors_json" || return 0

  jq -r --arg name "$display_name" '
    .[]
    | select(.name == $name)
    | (
        (.availableModes[]?),
        (.modes[]? | if type == "string" then . else "\(.width)x\(.height)@\(.refreshRate // .refresh // 0 | floor)" end)
      )
  ' <<<"$monitors_json" 2>/dev/null | awk 'NF' | sort -u
}

mode_resolution() {
  local mode="${1:-}"
  printf '%s\n' "${mode%@*}"
}

mode_refresh() {
  local mode="${1:-}"
  printf '%s\n' "${mode#*@}"
}

compose_mode() {
  local resolution="$1"
  local refresh="$2"
  printf '%s@%s\n' "$resolution" "$refresh"
}

show_supported_modes() {
  local display_name="$1"
  local modes=""

  modes="$(list_display_modes "$display_name")"
  [[ -n "$modes" ]] || return 0

  warn "modos detectados para ${display_name}:"
  while IFS= read -r mode; do
    [[ -n "$mode" ]] || continue
    warn "  - ${mode}"
  done <<<"$modes"
}

validate_mode_for_display() {
  local display_name="$1"
  local resolution="$2"
  local refresh="$3"
  local target mode_list

  target="$(compose_mode "$resolution" "$refresh")"
  mode_list="$(list_display_modes "$display_name")"

  [[ -n "$mode_list" ]] || return 2
  grep -Fxq "$target" <<<"$mode_list"
}

resolve_mode_with_validation() {
  local profile_label="$1"
  local default_resolution="$2"
  local default_refresh="$3"
  local resolution="$4"
  local refresh="$5"
  local target="" validate_status=0

  while true; do
    if [[ -z "$resolution" ]]; then
      resolution="$(prompt "qual a resolucao desejada ${profile_label}?" "$default_resolution")"
    fi

    if [[ -z "$refresh" ]]; then
      refresh="$(prompt "qual a frequencia desejada ${profile_label}?" "$default_refresh")"
    fi

    target="$(compose_mode "$resolution" "$refresh")"

    validate_status=0
    if validate_mode_for_display "$INTERNAL_DISPLAY" "$resolution" "$refresh"; then
      validate_status=0
    else
      validate_status=$?
    fi

    if [[ "$validate_status" -eq 0 ]]; then
      RESOLVED_MODE_RESOLUTION="$resolution"
      RESOLVED_MODE_REFRESH="$refresh"
      return 0
    fi

    case "$validate_status" in
      1)
        warn "o modo ${target} nao foi encontrado para a tela ${INTERNAL_DISPLAY}"
        show_supported_modes "$INTERNAL_DISPLAY"
        if [[ "$AUTO_YES" == "1" ]]; then
          exit 1
        fi
        resolution=""
        refresh=""
        ;;
      2)
        if [[ "$MODE_VALIDATION_WARNING_SHOWN" != "1" ]]; then
          warn "nao foi possivel validar automaticamente os modos suportados da tela ${INTERNAL_DISPLAY}"
          MODE_VALIDATION_WARNING_SHOWN="1"
        fi
        if confirm "usar ${target} mesmo sem validacao automatica?" "y"; then
          RESOLVED_MODE_RESOLUTION="$resolution"
          RESOLVED_MODE_REFRESH="$refresh"
          return 0
        fi
        resolution=""
        refresh=""
        ;;
    esac
  done
}

detect_package_manager() {
  if have_cmd pacman; then
    printf 'pacman\n'
  elif have_cmd apt-get; then
    printf 'apt\n'
  elif have_cmd dnf; then
    printf 'dnf\n'
  elif have_cmd zypper; then
    printf 'zypper\n'
  else
    printf 'unknown\n'
  fi
}

package_name() {
  local manager="$1"
  local command_name="$2"

  case "$manager:$command_name" in
    pacman:jq) printf 'jq\n' ;;
    pacman:brightnessctl) printf 'brightnessctl\n' ;;
    pacman:notify-send) printf 'libnotify\n' ;;
    pacman:powerprofilesctl) printf 'power-profiles-daemon\n' ;;
    pacman:hyprctl) printf 'hyprland\n' ;;
    apt:jq) printf 'jq\n' ;;
    apt:brightnessctl) printf 'brightnessctl\n' ;;
    apt:notify-send) printf 'libnotify-bin\n' ;;
    apt:powerprofilesctl) printf 'power-profiles-daemon\n' ;;
    apt:hyprctl) printf 'hyprland\n' ;;
    dnf:jq) printf 'jq\n' ;;
    dnf:brightnessctl) printf 'brightnessctl\n' ;;
    dnf:notify-send) printf 'libnotify\n' ;;
    dnf:powerprofilesctl) printf 'power-profiles-daemon\n' ;;
    dnf:hyprctl) printf 'hyprland\n' ;;
    zypper:jq) printf 'jq\n' ;;
    zypper:brightnessctl) printf 'brightnessctl\n' ;;
    zypper:notify-send) printf 'libnotify-tools\n' ;;
    zypper:powerprofilesctl) printf 'power-profiles-daemon\n' ;;
    zypper:hyprctl) printf 'hyprland\n' ;;
    *) printf '%s\n' "$command_name" ;;
  esac
}

install_missing_dependencies() {
  local manager="$1"
  local required=(jq brightnessctl notify-send powerprofilesctl hyprctl)
  local missing_packages=()
  local cmd package

  for cmd in "${required[@]}"; do
    if ! have_cmd "$cmd"; then
      package="$(package_name "$manager" "$cmd")"
      missing_packages+=("$package")
    fi
  done

  if [[ "${#missing_packages[@]}" -eq 0 ]]; then
    log "todas as dependencias principais ja estao disponiveis"
    return 0
  fi

  warn "dependencias ausentes: ${missing_packages[*]}"

  if [[ "$manager" == "unknown" ]]; then
    warn "gerenciador de pacotes nao suportado; instale manualmente e rode novamente"
    return 0
  fi

  if ! confirm "deseja instalar as dependencias ausentes com ${manager}?" "y"; then
    warn "instalacao de dependencias ignorada"
    return 0
  fi

  if ! have_cmd sudo; then
    warn "sudo nao encontrado; instale as dependencias manualmente"
    return 0
  fi

  case "$manager" in
    pacman)
      sudo pacman -Sy --needed "${missing_packages[@]}"
      ;;
    apt)
      sudo apt-get update
      sudo apt-get install -y "${missing_packages[@]}"
      ;;
    dnf)
      sudo dnf install -y "${missing_packages[@]}"
      ;;
    zypper)
      sudo zypper install -y "${missing_packages[@]}"
      ;;
  esac

  for cmd in "${required[@]}"; do
    if ! have_cmd "$cmd"; then
      warn "dependencia ainda ausente apos tentativa de instalacao: ${cmd}"
    fi
  done
}

write_config_file() {
  local battery_mode ac_mode

  battery_mode="$(compose_mode "$BATTERY_RESOLUTION" "$BATTERY_REFRESH")"
  ac_mode="$(compose_mode "$AC_RESOLUTION" "$AC_REFRESH")"

  mkdir -p "$CONFIG_DIR"

  if [[ -f "$CONFIG_FILE" ]]; then
    if [[ "$FORCE_OVERWRITE" != "1" ]]; then
      if ! confirm "ja existe uma configuracao em ${CONFIG_FILE}. deseja sobrescrever?" "n"; then
        log "configuracao existente mantida"
        return 0
      fi
    fi

    backup_file "$CONFIG_FILE" "${CONFIG_FILE}.$(timestamp).bak"
    CONFIG_BACKUP_CREATED="1"
  fi

  cat > "$CONFIG_FILE" <<EOF
export NOTEBOOK_PROFILE_INTERNAL_DISPLAY="${INTERNAL_DISPLAY}"
export NOTEBOOK_PROFILE_BATTERY_BRIGHTNESS="${BATTERY_BRIGHTNESS}"
export NOTEBOOK_PROFILE_AC_BRIGHTNESS="${AC_BRIGHTNESS}"
export NOTEBOOK_PROFILE_BATTERY_DISPLAY_MODE="${battery_mode}"
export NOTEBOOK_PROFILE_AC_DISPLAY_MODE="${ac_mode}"
EOF
}

install_binary() {
  if [[ -f "$TARGET_BIN" ]]; then
    log "atualizando binario existente em ${TARGET_BIN}"
  fi
  mkdir -p "$INSTALL_DIR"
  install -m 755 "${PROJECT_DIR}/bin/notebook-profile" "$TARGET_BIN"
}

install_hypr_integration() {
  local hypr_dir="${XDG_CONFIG_HOME:-$HOME/.config}/hypr"
  local hypr_snippet_dir="${hypr_dir}/conf.d"
  local hypr_snippet="${hypr_snippet_dir}/notebook-profile.conf"

  mkdir -p "$hypr_snippet_dir"

  if [[ -f "$hypr_snippet" ]]; then
    if [[ "$FORCE_OVERWRITE" != "1" ]]; then
      if ! confirm "ja existe um snippet em ${hypr_snippet}. deseja sobrescrever?" "n"; then
        log "snippet existente mantido"
        return 0
      fi
    fi

    backup_file "$hypr_snippet" "${hypr_snippet}.$(timestamp).bak"
    HYPR_BACKUP_CREATED="1"
  fi

  cat > "$hypr_snippet" <<EOF
# notebook-profile auto-generated snippet
exec-once = \$HOME/.local/bin/notebook-profile daemon
EOF

  log "snippet do Hyprland escrito em ${hypr_snippet}"

  if [[ "$INSTALL_KEYBINDS" == "1" ]]; then
    cat >> "$hypr_snippet" <<'EOF'

$ut=Utilities
$d=[$ut]
bindd = $mainMod Alt, F7, $d notebook profile battery, exec, notebook-profile battery
bindd = $mainMod Alt, F8, $d notebook profile ac, exec, notebook-profile ac
bindd = $mainMod Alt, F9, $d notebook profile ac external, exec, notebook-profile ac-external
bindd = $mainMod Alt, F10, $d notebook profile status, exec, notebook-profile show-status
EOF
    log "atalhos opcionais adicionados ao snippet"
  fi
}

parse_args() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --internal-display)
        INTERNAL_DISPLAY="${2:?valor ausente para --internal-display}"
        shift 2
        ;;
      --battery-brightness)
        BATTERY_BRIGHTNESS="${2:?valor ausente para --battery-brightness}"
        shift 2
        ;;
      --ac-brightness)
        AC_BRIGHTNESS="${2:?valor ausente para --ac-brightness}"
        shift 2
        ;;
      --battery-resolution)
        BATTERY_RESOLUTION="${2:?valor ausente para --battery-resolution}"
        shift 2
        ;;
      --battery-refresh)
        BATTERY_REFRESH="${2:?valor ausente para --battery-refresh}"
        shift 2
        ;;
      --ac-resolution)
        AC_RESOLUTION="${2:?valor ausente para --ac-resolution}"
        shift 2
        ;;
      --ac-refresh)
        AC_REFRESH="${2:?valor ausente para --ac-refresh}"
        shift 2
        ;;
      --skip-deps)
        INSTALL_DEPS="0"
        shift
        ;;
      --skip-hypr-snippet)
        INSTALL_HYPR_SNIPPET="0"
        shift
        ;;
      --install-keybindings)
        INSTALL_KEYBINDS="1"
        shift
        ;;
      --yes)
        AUTO_YES="1"
        shift
        ;;
      --force)
        FORCE_OVERWRITE="1"
        shift
        ;;
      -h|--help)
        usage
        exit 0
        ;;
      *)
        printf 'argumento invalido: %s\n' "$1" >&2
        usage >&2
        exit 1
        ;;
    esac
  done
}

validate_inputs() {
  [[ -n "$INTERNAL_DISPLAY" ]] || die "nome da tela interna nao pode ficar vazio"
  validate_resolution_value "$AC_RESOLUTION" "resolucao na tomada"
  validate_refresh_value "$AC_REFRESH" "frequencia na tomada"
  validate_resolution_value "$BATTERY_RESOLUTION" "resolucao na bateria"
  validate_refresh_value "$BATTERY_REFRESH" "frequencia na bateria"
  validate_brightness_value "$AC_BRIGHTNESS" "brilho na tomada"
  validate_brightness_value "$BATTERY_BRIGHTNESS" "brilho na bateria"
}

main() {
  local manager default_display default_mode default_resolution default_refresh

  parse_args "$@"
  check_basic_requirements
  report_existing_installation

  manager="$(detect_package_manager)"
  [[ "$INSTALL_DEPS" == "1" ]] && install_missing_dependencies "$manager"
  warn_if_hyprctl_unavailable

  default_display="$(detect_current_display)"
  if [[ "$AUTO_YES" == "1" && -z "$INTERNAL_DISPLAY" ]]; then
    INTERNAL_DISPLAY="${default_display:-eDP-1}"
  else
    resolve_internal_display "$default_display"
  fi

  default_mode="$(detect_current_mode "$INTERNAL_DISPLAY")"
  default_mode="${default_mode:-1920x1080@144}"
  default_resolution="$(mode_resolution "$default_mode")"
  default_refresh="$(mode_refresh "$default_mode")"
  resolve_mode_with_validation "na tomada" "$default_resolution" "$default_refresh" "$AC_RESOLUTION" "$AC_REFRESH"
  AC_RESOLUTION="$RESOLVED_MODE_RESOLUTION"
  AC_REFRESH="$RESOLVED_MODE_REFRESH"
  resolve_mode_with_validation "na bateria" "$default_resolution" "60" "$BATTERY_RESOLUTION" "$BATTERY_REFRESH"
  BATTERY_RESOLUTION="$RESOLVED_MODE_RESOLUTION"
  BATTERY_REFRESH="$RESOLVED_MODE_REFRESH"
  AC_BRIGHTNESS="${AC_BRIGHTNESS:-$(prompt "qual brilho na tomada?" "100")}"
  BATTERY_BRIGHTNESS="${BATTERY_BRIGHTNESS:-$(prompt "qual brilho na bateria?" "70")}"
  validate_inputs

  install_binary
  write_config_file

  if [[ "$INSTALL_HYPR_SNIPPET" == "1" ]]; then
    if confirm "deseja instalar um snippet de exec-once para o Hyprland?" "y"; then
      if [[ "$INSTALL_KEYBINDS" != "1" ]] && confirm "deseja adicionar atalhos de teclado tambem?" "n"; then
        INSTALL_KEYBINDS="1"
      fi
      install_hypr_integration
    fi
  fi

  log "instalacao concluida"
  log "binario: ${TARGET_BIN}"
  log "configuracao: ${CONFIG_FILE}"
  [[ "$CONFIG_BACKUP_CREATED" == "1" ]] && log "backup da configuracao foi criado antes da substituicao"
  [[ "$HYPR_BACKUP_CREATED" == "1" ]] && log "backup do snippet do Hyprland foi criado antes da substituicao"
  log "teste com: notebook-profile status"
}

main "$@"
