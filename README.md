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
