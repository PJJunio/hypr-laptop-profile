# Instalacao

## Requisitos

- sessao Hyprland ou HyDE ativa
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

Sem Hyprland/HyDE ativo, a instalacao e bloqueada. Suporte a outros ambientes pode ser implementado futuramente.

## Instalacao local

```bash
git clone <repo-url> hypr-laptop-profile
cd hypr-laptop-profile
./install.sh
```

O `install.sh`:

- tenta detectar automaticamente a tela interna e pede confirmacao
- se nao detectar, instrui como descobrir manualmente com `hyprctl`
- pergunta a resolucao e a frequencia desejadas na tomada e na bateria
- valida a combinacao escolhida contra os modos reportados pelo `hyprctl`, quando disponivel
- valida entradas invalidas, falta de permissoes e ferramentas basicas de instalacao
- pergunta os niveis de brilho
- verifica dependencias e tenta instalar as ausentes
- instala o script em `~/.local/bin/laptop-profile`
- grava a configuracao em `~/.config/hypr-laptop-profile/config.env`
- detecta instalacao existente e pede confirmacao antes de sobrescrever arquivos gerados
- cria backup com timestamp de `config.env` e do snippet do Hyprland antes da substituicao
- com `--yes`, preserva arquivos existentes quando a resposta padrao for nao
- com `--force`, sobrescreve arquivos gerados sem perguntar e ainda cria backup
- opcionalmente cria um snippet do Hyprland em `~/.config/hypr/conf.d/laptop-profile.conf`

## Flags uteis

```bash
./install.sh --help
```

Exemplo nao interativo:

```bash
./install.sh \
  --internal-display eDP-1 \
  --ac-resolution 1920x1080 \
  --ac-refresh 144 \
  --battery-resolution 1920x1080 \
  --battery-refresh 60 \
  --ac-brightness 100 \
  --battery-brightness 70 \
  --yes
```

Exemplo nao interativo com sobrescrita forcada:

```bash
./install.sh \
  --internal-display eDP-1 \
  --ac-resolution 1920x1080 \
  --ac-refresh 144 \
  --battery-resolution 1920x1080 \
  --battery-refresh 60 \
  --ac-brightness 100 \
  --battery-brightness 70 \
  --yes \
  --force
```

## Instalacao manual

```bash
make install
```

ou:

```bash
mkdir -p ~/.local/bin
install -m 755 bin/laptop-profile ~/.local/bin/laptop-profile
```

Confirme que `~/.local/bin` esta no `PATH`:

```bash
echo "$PATH"
command -v laptop-profile
```

## Integracao com Hyprland

Adicione ao seu arquivo de inicializacao:

```ini
exec-once = $HOME/.local/bin/laptop-profile daemon
```

Se voce usa uma configuracao no estilo HyDE, pode aproveitar os snippets em `examples/`.

## Teste inicial

Rode:

```bash
laptop-profile status
laptop-profile auto
```

Se tudo estiver correto, o script deve detectar energia, monitor externo e imprimir o perfil calculado.
