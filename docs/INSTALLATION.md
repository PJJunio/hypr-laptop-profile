# Instalacao

## Requisitos

- `bash`
- `jq`
- `hyprctl`
- `brightnessctl`
- `notify-send`
- `powerprofilesctl` opcional

No Arch Linux e derivados, um conjunto tipico seria:

```bash
sudo pacman -S jq brightnessctl libnotify power-profiles-daemon
```

`hyprctl` normalmente ja vem com a instalacao do Hyprland.

## Instalacao local

```bash
git clone <repo-url> notebook-profile
cd notebook-profile
make install
```

O `Makefile` instala o script em `~/.local/bin/notebook-profile`.

## Instalacao manual

```bash
mkdir -p ~/.local/bin
install -m 755 bin/notebook-profile ~/.local/bin/notebook-profile
```

Confirme que `~/.local/bin` esta no `PATH`:

```bash
echo "$PATH"
command -v notebook-profile
```

## Integracao com Hyprland

Adicione ao seu arquivo de inicializacao:

```ini
exec-once = $HOME/.local/bin/notebook-profile daemon
```

Se voce usa uma configuracao no estilo HyDE, pode aproveitar os snippets em `examples/`.

## Teste inicial

Rode:

```bash
notebook-profile status
notebook-profile auto
```

Se tudo estiver correto, o script deve detectar energia, monitor externo e imprimir o perfil calculado.
