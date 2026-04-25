# hypr-laptop-profile

Automacao em shell para notebooks com Hyprland/HyDE que ajusta energia, brilho, workflow e modo da tela interna de acordo com o estado atual do equipamento.

Pensado para quem quer um notebook que se comporte de forma previsivel:

- na tomada: mais desempenho e tela no modo de uso principal
- na bateria: menos consumo e configuracao mais conservadora
- com monitor externo: comportamento adequado sem precisar reconfigurar tudo manualmente

O comando principal instalado pelo projeto e:

```bash
laptop-profile
```

## Compatibilidade

Suporte oficial atual:

- Hyprland
- HyDE

Incompativel neste momento com ambientes sem Hyprland/HyDE, como GNOME, KDE, XFCE ou Ubuntu padrao sem sessao Hyprland.

O instalador bloqueia esses cenarios explicitamente. Suporte a outros ambientes pode ser implementado futuramente.

## Perfis cobertos

- `ac`: notebook na tomada, sem monitor externo
- `ac-external`: notebook na tomada, com monitor externo
- `battery`: notebook fora da tomada

## O que o script faz

- detecta energia AC lendo `/sys/class/power_supply/*/online`
- detecta monitor externo com `hyprctl monitors -j`
- aplica perfil de energia via `powerprofilesctl`
- ajusta brilho com `brightnessctl`
- alterna o workflow do HyDE em `~/.config/hypr/workflows.conf`
- ajusta o modo da tela interna via `hyprctl keyword monitor`
- evita notificacoes redundantes salvando o ultimo estado em `~/.local/state/hypr-laptop-profile/last-state`

## Por que usar

- reduzir consumo e refresh rate automaticamente ao sair da tomada
- voltar para `performance` ao conectar o carregador
- manter um workflow mais conservador quando estiver em bateria
- reagir a dock/monitor externo sem precisar mudar tudo manualmente

## Beneficios na pratica

- ganho de tempo no uso diario, porque voce nao precisa lembrar de ajustar brilho, modo da tela e perfil de energia toda vez que muda de contexto
- menos desgaste mental ao alternar entre tomada, bateria e monitor externo
- comportamento mais consistente do notebook ao longo do dia
- melhor aproveitamento da bateria com uma configuracao mais conservadora quando o carregador nao esta conectado
- retorno automatico a um modo mais forte de trabalho quando volta para a tomada
- menos chance de esquecer a tela em refresh alto ou brilho exagerado fora da tomada

Em outras palavras: a automacao reduz atrito. Em vez de repetir microajustes manuais, o ambiente responde sozinho ao estado do notebook.

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

Tambem e obrigatorio rodar a instalacao dentro de uma sessao Hyprland/HyDE ativa.

## Instalacao

Fluxo recomendado:

```bash
git clone <repo-url> hypr-laptop-profile
cd hypr-laptop-profile
./install.sh
```

O instalador foi pensado para ser amigavel. Ele pode, por exemplo:

- detectar automaticamente a tela interna e pedir confirmacao
- perguntar resolucao, frequencia e brilho para tomada e bateria
- validar os modos informados contra o que o `hyprctl` reporta
- verificar dependencias e tentar instalar o que estiver faltando
- criar ou atualizar `~/.config/hypr-laptop-profile/config.env`
- criar um snippet opcional para o Hyprland

Exemplo de perguntas:

```bash
detectei a tela interna automaticamente: eDP-1
usar eDP-1 como tela interna?
qual a resolucao desejada na tomada?
qual a frequencia desejada na tomada?
qual a resolucao desejada na bateria?
qual a frequencia desejada na bateria?
qual brilho na tomada?
qual brilho na bateria?
```

Modo nao interativo:

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

Sobrescrita automatica de arquivos gerados:

```bash
./install.sh --yes --force ...
```

Instalacao manual, sem bootstrap:

```bash
make install
```

Detalhes de instalacao, dependencias e flags:

- [docs/INSTALLATION.md](/home/paulo-dias/hypr-laptop-profile/docs/INSTALLATION.md)

## Uso

Comandos mais comuns:

```bash
laptop-profile auto
laptop-profile daemon
laptop-profile status
laptop-profile show-status
laptop-profile battery
laptop-profile ac
laptop-profile ac-external
laptop-profile help
```

O mais comum no dia a dia e:

- `laptop-profile daemon`: fica reaplicando o perfil adequado
- `laptop-profile status`: mostra o estado detectado
- `laptop-profile auto`: aplica uma vez o perfil correspondente ao contexto atual

## Integracao com Hyprland

Adicione ao seu setup:

```ini
exec-once = $HOME/.local/bin/laptop-profile daemon
```

Atalhos opcionais:

```ini
bindd = $mainMod Alt, F7, $d laptop profile battery, exec, laptop-profile battery
bindd = $mainMod Alt, F8, $d laptop profile ac, exec, laptop-profile ac
bindd = $mainMod Alt, F9, $d laptop profile ac external, exec, laptop-profile ac-external
bindd = $mainMod Alt, F10, $d laptop profile status, exec, laptop-profile show-status
```

## Configuracao

O instalador grava a configuracao em:

```bash
~/.config/hypr-laptop-profile/config.env
```

Se quiser ajustar manualmente, voce pode sobrescrever os padroes por variavel de ambiente:

```bash
export LAPTOP_PROFILE_INTERNAL_DISPLAY="eDP-1"
export LAPTOP_PROFILE_BATTERY_BRIGHTNESS="70"
export LAPTOP_PROFILE_AC_BRIGHTNESS="100"
export LAPTOP_PROFILE_BATTERY_DISPLAY_MODE="1920x1080@60"
export LAPTOP_PROFILE_AC_DISPLAY_MODE="1920x1080@144"
```

Mais detalhes:

- [docs/CONFIGURATION.md](/home/paulo-dias/hypr-laptop-profile/docs/CONFIGURATION.md)

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

## Reinstalacao e seguranca

Se voce rodar o instalador novamente:

- ele detecta instalacoes existentes
- pede confirmacao antes de sobrescrever arquivos gerados
- cria backup com timestamp antes da substituicao
- com `--yes`, preserva arquivos existentes quando a resposta padrao for `nao`
- com `--force`, sobrescreve sem perguntar, mas ainda faz backup

## Observacoes importantes

- O projeto foi pensado para Hyprland/HyDE.
- O workflow `powersaver` precisa existir em `~/.config/hypr/workflows/powersaver.conf`.
- O nome da tela interna muda entre fabricantes e modelos.
- O script roda bem como automacao local de usuario; nao foi desenhado como servico systemd.

## Estrutura do repositório

- `bin/laptop-profile`: script principal
- `install.sh`: instalador interativo e configuravel
- `examples/hypr-userprefs.conf.snippet`: exemplo de `exec-once`
- `examples/hypr-keybindings.conf.snippet`: atalhos manuais
- `docs/INSTALLATION.md`: instalacao e integracao
- `docs/CONFIGURATION.md`: variaveis, perfis e personalizacao
- `docs/TROUBLESHOOTING.md`: diagnostico rapido
- `Makefile`: instalacao simplificada

## Licenca

Este projeto esta licenciado sob a licenca MIT. Veja [LICENSE](/home/paulo-dias/hypr-laptop-profile/LICENSE).
