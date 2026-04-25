# Troubleshooting

## `powerprofilesctl nao encontrado`

O script continua funcionando, mas nao altera o perfil do `power-profiles-daemon`.

Verifique:

```bash
command -v powerprofilesctl
systemctl status power-profiles-daemon
```

## `hyprctl nao encontrado`

Sem `hyprctl`, a instalacao e bloqueada.

Instale o Hyprland ou rode a instalacao em um ambiente Hyprland/HyDE suportado.

Suporte a outros ambientes pode ser implementado futuramente.

## `hyprctl` existe, mas nao consegue listar monitores

Isso normalmente significa que voce nao esta dentro de uma sessao Hyprland ativa.

Teste:

```bash
hyprctl monitors
hyprctl monitors -j
```

Se falhar, a instalacao sera bloqueada.

Suporte a outros ambientes pode ser implementado futuramente.

## Erro de valor invalido para brilho, resolucao ou frequencia

Os formatos esperados sao:

```bash
brilho: 1 a 100
resolucao: 1920x1080
frequencia: 60
```

Exemplo valido:

```bash
./install.sh \
  --internal-display eDP-1 \
  --ac-resolution 1920x1080 \
  --ac-refresh 144 \
  --battery-resolution 1920x1080 \
  --battery-refresh 60 \
  --ac-brightness 100 \
  --battery-brightness 70
```

## Erro de permissao ao instalar

O instalador precisa conseguir escrever em:

- `~/.local/bin`
- `~/.config/hypr-laptop-profile`

Verifique:

```bash
mkdir -p ~/.local/bin ~/.config/hypr-laptop-profile
test -w ~/.local/bin && echo ok
test -w ~/.config/hypr-laptop-profile && echo ok
```

## Reinstalacao sobrescreveu minha configuracao

O instalador agora cria backup com timestamp antes de substituir:

- `~/.config/hypr-laptop-profile/config.env`
- `~/.config/hypr/conf.d/laptop-profile.conf`

Procure arquivos com sufixo `.bak`, por exemplo:

```bash
ls -1 ~/.config/hypr-laptop-profile/config.env.*.bak
ls -1 ~/.config/hypr/conf.d/laptop-profile.conf.*.bak
```

Se quiser sobrescrever sem perguntas em automacao:

```bash
./install.sh --yes --force
```

## O monitor interno nao muda de modo

Confira o nome correto do display:

```bash
hyprctl monitors
hyprctl monitors -j | jq .
```

Se necessario, ajuste:

```bash
export LAPTOP_PROFILE_INTERNAL_DISPLAY="nome-correto"
```

## O script nao detecta monitor externo

O projeto considera externo qualquer monitor que nao comece com `eDP`, `LVDS` ou `DSI`.

Valide a saida:

```bash
hyprctl monitors -j | jq -r '.[].name'
```

## O brilho nao muda

Verifique se `brightnessctl` funciona no seu usuario:

```bash
brightnessctl get
brightnessctl max
brightnessctl set 70%
```

Se isso falhar, o problema nao esta no script e sim em permissao ou integracao com o backlight.

## Quais comandos sao seguros para teste

```bash
laptop-profile status
laptop-profile show-status
laptop-profile auto
```

Para forcar perfis:

```bash
laptop-profile battery
laptop-profile ac
laptop-profile ac-external
```
