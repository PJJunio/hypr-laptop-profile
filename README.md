# notebook-profile

Automacao em shell para notebooks com Hyprland/HyDE que ajusta energia, brilho, workflow e modo da tela interna conforme o contexto atual do equipamento.

Perfis cobertos:

- `ac`: notebook na tomada, sem monitor externo
- `ac-external`: notebook na tomada, com monitor externo
- `battery`: notebook fora da tomada

O projeto foi extraido de uma instalacao local e reorganizado como um repositório reaproveitavel.

## O que o script faz

- detecta energia AC lendo `/sys/class/power_supply/*/online`
- detecta monitor externo com `hyprctl monitors -j`
- aplica perfil de energia via `powerprofilesctl`
- ajusta brilho com `brightnessctl`
- alterna o workflow do HyDE em `~/.config/hypr/workflows.conf`
- ajusta o modo da tela interna via `hyprctl keyword monitor`
- evita notificacoes redundantes salvando o ultimo estado em `~/.local/state/notebook-profile/last-state`

## Casos de uso

- reduzir consumo e refresh rate automaticamente ao sair da tomada
- voltar para `performance` ao conectar o carregador
- manter um workflow mais conservador quando estiver em bateria
- reagir a dock/monitor externo sem precisar mudar tudo manualmente

## Estrutura

- `bin/notebook-profile`: script principal
- `examples/hypr-userprefs.conf.snippet`: exemplo de `exec-once`
- `examples/hypr-keybindings.conf.snippet`: atalhos manuais
- `docs/INSTALLATION.md`: instalacao e integracao
- `docs/CONFIGURATION.md`: variaveis, perfis e personalizacao
- `docs/TROUBLESHOOTING.md`: diagnostico rapido
- `Makefile`: instalacao local simplificada

## Dependencias

Obrigatorias para a automacao completa:

- `bash`
- `jq`
- `hyprctl`
- `brightnessctl`
- `notify-send`

Opcional:

- `powerprofilesctl`

Sem `powerprofilesctl`, o script continua funcionando e apenas deixa de aplicar o perfil do `power-profiles-daemon`.

## Instalacao rapida

```bash
git clone <repo-url> notebook-profile
cd notebook-profile
make install
```

Sem `make`:

```bash
mkdir -p ~/.local/bin
install -m 755 bin/notebook-profile ~/.local/bin/notebook-profile
```

Depois garanta que `~/.local/bin` esteja no `PATH`.

## Uso

```bash
notebook-profile auto
notebook-profile daemon
notebook-profile status
notebook-profile show-status
notebook-profile battery
notebook-profile ac
notebook-profile ac-external
notebook-profile help
```

## Integracao com Hyprland

Adicione ao seu setup:

```ini
exec-once = $HOME/.local/bin/notebook-profile daemon
```

Atalhos opcionais:

```ini
bindd = $mainMod Alt, F7, $d notebook profile battery, exec, notebook-profile battery
bindd = $mainMod Alt, F8, $d notebook profile ac, exec, notebook-profile ac
bindd = $mainMod Alt, F9, $d notebook profile ac external, exec, notebook-profile ac-external
bindd = $mainMod Alt, F10, $d notebook profile status, exec, notebook-profile show-status
```

## Configuracao

Voce pode sobrescrever os padroes por variavel de ambiente:

```bash
export NOTEBOOK_PROFILE_INTERNAL_DISPLAY="eDP-1"
export NOTEBOOK_PROFILE_BATTERY_BRIGHTNESS="70"
export NOTEBOOK_PROFILE_AC_BRIGHTNESS="100"
export NOTEBOOK_PROFILE_BATTERY_DISPLAY_MODE="1920x1080@60"
export NOTEBOOK_PROFILE_AC_DISPLAY_MODE="1920x1080@144"
```

Para mais detalhes, veja `docs/CONFIGURATION.md`.

## Exemplo de status

```text
detected_profile=ac
ac=on
external_monitor=none
power_profile=performance
hypr_workflow=default
brightness_target=100%
internal_display=eDP-1
internal_display_mode=1920x1080@144
```

## Observacoes

- O projeto foi pensado para Hyprland/HyDE.
- O workflow `powersaver` precisa existir em `~/.config/hypr/workflows/powersaver.conf`.
- O nome da tela interna muda entre fabricantes e modelos.
- O script roda bem como automacao local de usuario; nao foi desenhado como servico systemd.

## Licenca

Este projeto esta licenciado sob a licenca MIT. Veja [LICENSE](/home/paulo-dias/notebook-profile/LICENSE).
