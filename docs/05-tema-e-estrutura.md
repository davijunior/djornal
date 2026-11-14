# Aparência e estrutura

## Mudar o visual
| Arquivo | O quê |
|---|---|
| `paginas/_topo.djo.html`, `paginas/_rodape.djo.html` | cabeçalho, menu e rodapé do site |
| `paginas/lista.djo.html`, `paginas/conteudo.djo.html` | listas e página de um conteúdo |
| `publico/estilo.css` | estilo do site (tema claro/escuro automático) |
| `publico/admin.css` | estilo do painel |
| `404.djo.html` | página de erro |

Os modelos são `.djo.html`: HTML com `{{ valor }}` e blocos `{% … %}`.

## Mapa do código
```
rotas.djo     a lista fechada de rotas: só existe o que está declarado aqui
core/         regra de negócio, compartilhada pela tela e pelos agentes
  banco.djo     SQLite e migração automática      conteudo.djo  criar/editar/listar, validações
  acoes.djo     as actions (escrita por agentes)  auth.djo      sessão, CSRF, tokens, login
  markdown.djo  renderizador                      midia.djo     uploads
  modelos.djo   structs (Entrada, Conteudo…)      publico.djo   listagem pública
paginas/      HTML do site, feed, sitemap, robots
agentes/      a face JSON de cada rota pública
admin/        o painel
testes/e2e.sh testes de ponta a ponta
```

A tela e o agente chamam as mesmas funções de `core/`, então uma regra muda num lugar só. Para acrescentar uma rota: declare em `rotas.djo` e crie o arquivo de tela e/ou de agente.

## Testes
```bash
testes/e2e.sh /caminho/do/djo
```
Copia o site para uma pasta temporária, sobe um servidor numa porta aleatória e roda cerca de 80 verificações: instalação, painel, API, permissões, agendamento, upload, Markdown, XSS, CSRF e limite de requisições.
