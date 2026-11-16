# Djornal

CMS no estilo WordPress, escrito em [djo](https://djolang.zfxsoftware.cloud), simples de instalar e de usar e pensado para **agentes de IA**. Cada endereço tem duas faces: pessoas recebem HTML e agentes recebem JSON (`Accept: application/json`). A escrita é uma API tipada, com manifesto em `/.well-known/ai-manifest.json`. Tudo usa recursos nativos da djo: sem dependências, sem banco para configurar (é um arquivo SQLite).

## Começar

Precisa só do binário `djo` (sem Go): veja [como instalar a djo](https://djolang.zfxsoftware.cloud/instalar).

```bash
git clone git@github.com:davijunior/djornal.git meusite
cd meusite
djo serve -dev .                  # http://localhost:8080
```

Abra o endereço. Enquanto não houver administrador, o site leva ao **instalador** (`/instalar`), que pede nome do site, endereço público, usuário e senha. Ele cria um post de boas-vindas, a página "Sobre" e **um token para o seu primeiro agente** (mostrado uma vez). O painel fica em `/admin`.

Para colocar no ar, gere um executável único e rode atrás de um proxy HTTPS:

```bash
djo build -o djornal .
./djornal -addr :8080             # dados em djornal.d/, ao lado do executável
```

Cada site é uma cópia deste repositório: o código e os dados convivem na mesma pasta, mas `_dados/` (banco) e os arquivos de `uploads/` não vão para o git. Para atualizar o Djornal num site existente, traga as mudanças do repositório; os dados são mantidos e o banco se migra sozinho.

## O que tem

| Para pessoas | Para agentes (recursos nativos da djo) |
|---|---|
| Painel em `/admin`: conteúdos, mídia, tokens, configurações | Mesmos endereços em JSON com `Accept: application/json` (texto em Markdown) |
| Editor Markdown com pré-visualização | Escrita por `action`s tipadas; manifesto em `/.well-known/ai-manifest.json` |
| Posts, páginas (menu), tags, busca | Tokens por agente, só-leitura ou escrita, revogáveis (guardados como hash); com token, rascunhos aparecem |
| Rascunho, agendamento (UTC), pré-visualização de rascunhos logado | `?campos=`, `?tabela` (CSV), `ETag`/`304`, cache e limite por agente |
| RSS, sitemap, robots, tema claro/escuro, upload de arquivos | Erros 422 que dizem qual campo está errado |

Guia para entregar a um agente: [AGENTS.md](AGENTS.md).

**Perguntas em linguagem natural (`/ask`).** Pessoas podem perguntar ao site em português ou inglês, sem modelo de IA: abra `/ask` no navegador ou use `djo ask https://seu-site "liste posts de 2025 com a tag novidade"` (precisa da djo v0.6.0 ou mais nova). É só leitura. Sem login ou token aparece só o que está no ar; com token (`DJO_ASK_TOKEN`) ou logado no painel, também rascunhos e agendados. O que pode ser perguntado está em [ask.djo](ask.djo), que lê visões do banco sem senhas nem tokens (criadas em `core/banco.djo`). Para desligar, apague o `ask.djo`.

## Documentação
1. [Instalação](docs/01-instalacao.md)
2. [Usando o painel](docs/02-painel.md)
3. [Djornal para agentes](docs/03-agentes.md)
4. [Markdown](docs/04-markdown.md)
5. [Aparência e estrutura](docs/05-tema-e-estrutura.md)
6. [Produção e limites](docs/06-producao.md)

## Como está organizado

```
rotas.djo      só existe o que está declarado aqui (tela + agente + actions)
core/          regra de negócio (a tela e a API de agentes chamam as mesmas funções)
  conteudo.djo   criar/editar/listar, validações   acoes.djo  actions = escrita para agentes
  markdown.djo   renderizador de Markdown          banco.djo  SQLite
  auth.djo       sessão, CSRF, tokens
paginas/ agentes/ admin/    apresentação (HTML, JSON, painel)
publico/       CSS            uploads/   arquivos enviados     _dados/   banco (nunca servido)
```

Para mudar o visual: `paginas/_topo.djo.html`, `paginas/_rodape.djo.html` e `publico/estilo.css`.

## Dia a dia

- **Backup:** copie `_dados/` e `uploads/` (no executável único, a pasta `cms.d/` ao lado dele).
- **Atualizar:** troque os arquivos (ou o executável); os dados são mantidos.
- **Token novo / revogar:** Painel → Tokens.
- **Testes:** `testes/e2e.sh /caminho/do/djo` sobe uma cópia descartável e roda ~80 verificações (instalação, painel, API, permissões, XSS, CSRF).

## Em produção

- Rode atrás de um proxy HTTPS (Caddy/nginx) e preencha o **endereço público** em Configurações (usado em links, feed e sitemap).
- Atrás de proxy todos os agentes parecem ter o mesmo IP: ajuste `-agent-rate` (veja `djo serve -h`) ou use `-agent-rate 0` e limite no proxy.
- Sem `-dev`, erros mostram só uma página genérica (o detalhe vai para o log).

## Limites conhecidos

- **Sessões ficam na memória** (limitação da djo): reiniciar o servidor desloga o painel. Os tokens de API não são afetados.
- Horários só em UTC. Texto de até 100 mil caracteres por conteúdo. Uploads até 10 MB (veja docs/02-painel.md).
- Markdown: sem listas aninhadas; HTML cru é escapado de propósito (um agente induzido não consegue injetar script).
- Um usuário administrador só por padrão (sem papéis/colaboradores), sem comentários.
- O SQLite aceita um escritor por vez: de sobra para um site pequeno.
