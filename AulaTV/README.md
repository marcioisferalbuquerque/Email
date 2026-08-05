# AulaTV 📺

App para iPhone que carrega **aulas criadas pelo Claude** e as apresenta na sua
**Apple TV** como slides, via AirPlay (espelhamento de tela).

É um *web app instalável* (PWA): não precisa de App Store, Mac nem conta de
desenvolvedor. Você abre a página no Safari, adiciona à Tela de Início, e ele
vira um app com ícone, tela cheia e funcionamento offline.

## Como instalar no iPhone

1. Abra o endereço do app no **Safari** do iPhone.
2. Toque no botão **Compartilhar** (quadrado com seta para cima).
3. Toque em **"Adicionar à Tela de Início"** e confirme.

As aulas ficam salvas no próprio aparelho (localStorage) — não vão para nenhum
servidor.

## Como carregar uma aula

Peça ao Claude, em qualquer conversa ou projeto:

> "Crie uma aula sobre **[seu tema]** no formato AulaTV: markdown, com slides
> separados por `---`"

Depois copie o texto gerado e, no app, toque em **+ Nova aula**, cole e salve.
Também é possível importar arquivos `.md` ou `.txt`.

### Formato das aulas

```markdown
# Título do primeiro slide
Conteúdo em markdown: **negrito**, *itálico*, listas, `código`...

---

## Segundo slide
- Ponto um
- Ponto dois

---

# Último slide
> Uma citação de fechamento
```

Suporta títulos (`#`, `##`, `###`), negrito, itálico, listas numeradas e com
marcadores, citações (`>`), código em linha e blocos de código (```` ``` ````).

## Como transmitir para a Apple TV

A transmissão usa **AirPlay pela rede Wi-Fi** (Bluetooth não transporta vídeo).
iPhone e Apple TV precisam estar na mesma rede.

1. Abra a **Central de Controle** do iPhone (deslize de cima para baixo, a
   partir do canto superior direito).
2. Toque em **Espelhamento de Tela** e escolha a sua Apple TV.
3. No AulaTV, toque em **▶ Apresentar** na aula desejada.
4. **Gire o iPhone na horizontal** para a imagem preencher a TV.

Durante a apresentação: toque no lado direito da tela (ou deslize) para
avançar, lado esquerdo para voltar. O app mantém a tela do iPhone acesa
automaticamente enquanto apresenta.

## Como hospedar

O app é 100% estático — qualquer hospedagem HTTPS serve. As opções mais
simples:

- **GitHub Pages**: em *Settings → Pages* deste repositório, publique a pasta
  do projeto. (Em repositórios privados, o GitHub Pages exige plano pago.)
- **Netlify / Vercel / Cloudflare Pages**: arraste a pasta `AulaTV/` no painel
  deles (têm plano gratuito).
- **Artifact do Claude**: o Claude pode publicar a página diretamente e te dar
  um link privado.

## Arquivos

| Arquivo               | Função                                            |
| --------------------- | ------------------------------------------------- |
| `index.html`          | O app inteiro (interface, editor e apresentação)  |
| `manifest.webmanifest`| Metadados do PWA (nome, ícones, tela cheia)       |
| `sw.js`               | Service worker — faz o app funcionar offline      |
| `icon-180.png`        | Ícone da Tela de Início do iPhone                 |
| `icon-512.png`        | Ícone grande (splash/instalação)                  |
