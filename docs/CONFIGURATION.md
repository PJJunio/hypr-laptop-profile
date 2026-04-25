# Configuracao

## Variaveis suportadas

### `NOTEBOOK_PROFILE_INTERNAL_DISPLAY`

Nome do display interno no Hyprland.

Padrao:

```bash
eDP-1
```

### `NOTEBOOK_PROFILE_BATTERY_BRIGHTNESS`

Brilho em percentual quando estiver na bateria.

Padrao:

```bash
70
```

### `NOTEBOOK_PROFILE_AC_BRIGHTNESS`

Brilho em percentual quando estiver na tomada.

Padrao:

```bash
100
```

### `NOTEBOOK_PROFILE_BATTERY_DISPLAY_MODE`

Modo da tela interna quando estiver na bateria.

Padrao:

```bash
1920x1080@60
```

### `NOTEBOOK_PROFILE_AC_DISPLAY_MODE`

Modo da tela interna quando estiver na tomada.

Padrao:

```bash
1920x1080@144
```

## Exemplo de override

```bash
export NOTEBOOK_PROFILE_INTERNAL_DISPLAY="eDP-1"
export NOTEBOOK_PROFILE_BATTERY_BRIGHTNESS="55"
export NOTEBOOK_PROFILE_AC_BRIGHTNESS="90"
export NOTEBOOK_PROFILE_BATTERY_DISPLAY_MODE="1920x1080@60"
export NOTEBOOK_PROFILE_AC_DISPLAY_MODE="2560x1600@120"
```

Voce pode colocar esses exports em `~/.zshrc`, `~/.bashrc` ou no mesmo arquivo que sobe sua sessao do Hyprland.

## Como os perfis funcionam

### `battery`

- perfil de energia: `power-saver`
- workflow Hyprland: `powersaver`
- brilho: `NOTEBOOK_PROFILE_BATTERY_BRIGHTNESS`
- modo da tela: `NOTEBOOK_PROFILE_BATTERY_DISPLAY_MODE`

### `ac`

- perfil de energia: `performance`
- workflow Hyprland: `default`
- brilho: `NOTEBOOK_PROFILE_AC_BRIGHTNESS`
- modo da tela: `NOTEBOOK_PROFILE_AC_DISPLAY_MODE`

### `ac-external`

- perfil de energia: `performance`
- workflow Hyprland: `default`
- brilho: `NOTEBOOK_PROFILE_AC_BRIGHTNESS`
- modo da tela: `NOTEBOOK_PROFILE_AC_DISPLAY_MODE`

## Arquivos de estado

O projeto escreve em:

- `~/.local/state/notebook-profile/last-state`
- `~/.local/state/notebook-profile/missing-powerprofilesctl.warned`

Esses arquivos evitam reexecucoes desnecessarias e notificacoes repetidas.
