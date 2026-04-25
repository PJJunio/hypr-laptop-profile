# Troubleshooting

## `powerprofilesctl nao encontrado`

O script continua funcionando, mas nao altera o perfil do `power-profiles-daemon`.

Verifique:

```bash
command -v powerprofilesctl
systemctl status power-profiles-daemon
```

## `hyprctl nao encontrado`

Sem `hyprctl`, o instalador nao consegue:

- detectar a tela interna automaticamente
- validar resolucao e frequencia contra os modos do monitor

Instale o Hyprland ou rode a instalacao em um ambiente onde `hyprctl` exista.

## `hyprctl` existe, mas nao consegue listar monitores

Isso normalmente significa que voce nao esta dentro de uma sessao Hyprland ativa.

Teste:

```bash
hyprctl monitors
hyprctl monitors -j
```

Se falhar, o instalador vai continuar em modo manual, mas sem validacao automatica de modos.

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
- `~/.config/notebook-profile`

Verifique:

```bash
mkdir -p ~/.local/bin ~/.config/notebook-profile
test -w ~/.local/bin && echo ok
test -w ~/.config/notebook-profile && echo ok
```

## Reinstalacao sobrescreveu minha configuracao

O instalador agora cria backup com timestamp antes de substituir:

- `~/.config/notebook-profile/config.env`
- `~/.config/hypr/conf.d/notebook-profile.conf`

Procure arquivos com sufixo `.bak`, por exemplo:

```bash
ls -1 ~/.config/notebook-profile/config.env.*.bak
ls -1 ~/.config/hypr/conf.d/notebook-profile.conf.*.bak
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
export NOTEBOOK_PROFILE_INTERNAL_DISPLAY="nome-correto"
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
notebook-profile status
notebook-profile show-status
notebook-profile auto
```

Para forcar perfis:

```bash
notebook-profile battery
notebook-profile ac
notebook-profile ac-external
```
