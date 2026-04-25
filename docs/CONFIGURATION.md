# Configuracao

## Variaveis suportadas

### `LAPTOP_PROFILE_INTERNAL_DISPLAY`

Nome do display interno no Hyprland.

Padrao:

```bash
eDP-1
```

### `LAPTOP_PROFILE_BATTERY_BRIGHTNESS`

Brilho em percentual quando estiver na bateria.

Padrao:

```bash
70
```

### `LAPTOP_PROFILE_AC_BRIGHTNESS`

Brilho em percentual quando estiver na tomada.

Padrao:

```bash
100
```

### `LAPTOP_PROFILE_BATTERY_DISPLAY_MODE`

Modo da tela interna quando estiver na bateria.

Padrao:

```bash
1920x1080@60
```

### `LAPTOP_PROFILE_AC_DISPLAY_MODE`

Modo da tela interna quando estiver na tomada.

Padrao:

```bash
1920x1080@144
```

## Exemplo de override

```bash
export LAPTOP_PROFILE_INTERNAL_DISPLAY="eDP-1"
export LAPTOP_PROFILE_BATTERY_BRIGHTNESS="55"
export LAPTOP_PROFILE_AC_BRIGHTNESS="90"
export LAPTOP_PROFILE_BATTERY_DISPLAY_MODE="1920x1080@60"
export LAPTOP_PROFILE_AC_DISPLAY_MODE="2560x1600@120"
```

Voce pode colocar esses exports em `~/.zshrc`, `~/.bashrc` ou no mesmo arquivo que sobe sua sessao do Hyprland.

## Como os perfis funcionam

### `battery`

- perfil de energia: `power-saver`
- workflow Hyprland: `powersaver`
- brilho: `LAPTOP_PROFILE_BATTERY_BRIGHTNESS`
- modo da tela: `LAPTOP_PROFILE_BATTERY_DISPLAY_MODE`

### `ac`

- perfil de energia: `performance`
- workflow Hyprland: `default`
- brilho: `LAPTOP_PROFILE_AC_BRIGHTNESS`
- modo da tela: `LAPTOP_PROFILE_AC_DISPLAY_MODE`

### `ac-external`

- perfil de energia: `performance`
- workflow Hyprland: `default`
- brilho: `LAPTOP_PROFILE_AC_BRIGHTNESS`
- modo da tela: `LAPTOP_PROFILE_AC_DISPLAY_MODE`

## Arquivos de estado

O projeto escreve em:

- `~/.local/state/hypr-laptop-profile/last-state`
- `~/.local/state/hypr-laptop-profile/missing-powerprofilesctl.warned`

Esses arquivos evitam reexecucoes desnecessarias e notificacoes repetidas.
