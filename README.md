# Remover E-mails Duplicados no Outlook (Windows)

Macro VBA para o Outlook de computador (Windows) que encontra e remove
e-mails duplicados de qualquer pasta (ex.: Caixa de Entrada), mantendo
sempre **1 cópia** de cada e-mail.

## Arquivo

- `RemoverEmailsDuplicados.bas` — o código da macro, pronto para importar no Outlook.

## Como um e-mail é considerado duplicado?

Quando tem o **mesmo remetente + assunto + data/hora de envio + tamanho**
de outro e-mail já existente na pasta. A cópia mais antiga é mantida e as
repetidas são movidas para a lixeira.

## Instalação (só precisa fazer 1 vez)

1. Abra o Outlook no computador do escritório.
2. Pressione **ALT + F11** para abrir o editor VBA.
3. No menu, vá em **Arquivo → Importar Arquivo...** e escolha o arquivo
   `RemoverEmailsDuplicados.bas`.
   - Alternativa: clique com o botão direito em **Projeto1 → Inserir → Módulo**
     e cole o conteúdo do arquivo.
4. Feche o editor VBA (pode salvar quando perguntar).

## Como usar

1. No Outlook, pressione **ALT + F8**.
2. Selecione **LimparDuplicados** e clique em **Executar**.
3. Escolha a pasta que deseja limpar (ex.: Caixa de Entrada) e clique em OK.
4. A macro mostra quantos duplicados encontrou e pede confirmação antes
   de mover qualquer coisa.

## Segurança

- **Nada é apagado em definitivo**: os duplicados vão para a pasta
  **Itens Excluídos**. Se precisar recuperar algum, é só procurar lá.
- A macro sempre pede confirmação antes de mover os e-mails.

## Se o Outlook bloquear a macro

Vá em **Arquivo → Opções → Central de Confiabilidade →
Configurações da Central de Confiabilidade → Configurações de Macro**
e marque **"Notificações para todas as macros"**. Depois reinicie o Outlook.

## Maré · Guaratuba (`mare/`)

Web app (para salvar na tela de início do iPhone) que estima a maré em Guaratuba como média ponderada dos pontos de Paranaguá e São Francisco do Sul, usando a Open-Meteo Marine API. Mostra agora/30 min/1 h, extremos do dia, semana e 30 dias com fases da Lua. Motor: previsão harmônica padrão (correções nodais, convenção Schureman/NOAA; validada contra previsões oficiais da NOAA, ~1 cm RMS) + efeito do tempo (anomalia filtrada da previsão Open-Meteo). Funciona offline (service worker + constantes embutidas). Alturas no zero da tábua (NR aproximado: nível médio − 0,79 m, valor de Galheta). Base padrão: marégrafo SiMCosta da barra de Guaratuba (2018). Não serve para navegação — confira a tábua oficial da Marinha.
