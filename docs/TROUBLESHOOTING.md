# Troubleshooting

## `powerprofilesctl nao encontrado`

O script continua funcionando, mas nao altera o perfil do `power-profiles-daemon`.

Verifique:

```bash
command -v powerprofilesctl
systemctl status power-profiles-daemon
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
