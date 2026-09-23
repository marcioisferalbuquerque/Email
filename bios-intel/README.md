# Agente de BIOS Intel

Agente do Claude Code que **lê** o BIOS/UEFI de computadores Intel,
**compara** com boas práticas e com o firmware mais recente do fabricante e
**entrega um relatório** de melhorias com um roteiro passo a passo.

> **O agente não grava nada no BIOS.** Ele não atualiza nem modifica o
> firmware sozinho. Quem aplica as mudanças é você, na tela de Setup do BIOS
> ou pelo utilitário oficial do fabricante. Um BIOS gravado errado pode
> inutilizar a placa-mãe.

## Arquivos

| Arquivo | Função |
|---|---|
| `../.claude/agents/bios-intel.md` | Definição do agente (regras, checklist, formato do relatório) |
| `Coletar-BIOS-Windows.ps1` | Coleta os dados no Windows (somente leitura) |
| `coletar-bios-linux.sh` | Coleta os dados no Linux (somente leitura) |

## Como usar

### 1. Coletar os dados no computador a analisar

**Windows** — abra o PowerShell **como Administrador** na pasta do arquivo:

```powershell
powershell -ExecutionPolicy Bypass -File .\Coletar-BIOS-Windows.ps1
```

O relatório `bios-relatorio-<computador>-<data>.txt` vai para a Área de Trabalho.

**Linux**:

```bash
sudo bash coletar-bios-linux.sh
```

### 2. Pedir a análise ao agente

No Claude Code, com este repositório aberto:

```
Use o agente bios-intel para analisar o arquivo bios-relatorio-XXXX.txt
```

O agente identifica modelo e versão do BIOS, procura a versão mais recente
no site oficial do fabricante e devolve:

1. identificação da máquina;
2. versão do BIOS instalada x mais recente (com o link oficial);
3. achados e recomendações por prioridade (Secure Boot, TPM/PTT, VT-x,
   VT-d, modo UEFI, senha de BIOS, Intel AMT, Thunderbolt, XMP…);
4. perguntas sobre o que não dá para detectar por software;
5. roteiro passo a passo, riscos e o que não foi verificado.

Cada item vem marcado como **[FATO]**, **[ESTIMATIVA]** ou **[HIPÓTESE]**.

## Cuidados antes de atualizar o BIOS

- Se o Windows usa **BitLocker**, suspenda a proteção antes e tenha a chave
  de recuperação em mãos (https://aka.ms/myrecoverykey). Sem isso, a
  atualização pode fazer o computador pedir a chave na próxima inicialização.
- Notebook: bateria carregada e carregador ligado. Não desligue durante a
  atualização.
- Use apenas o arquivo do modelo exato, baixado do site oficial.
- Não mude de Legacy para UEFI sem antes converter o disco para GPT, ou o
  Windows deixa de iniciar.
