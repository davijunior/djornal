# Guia para agentes (Djornal)

Este site é um CMS. Cada endereço tem duas faces: pessoas recebem HTML e você recebe JSON, **pedindo com `Accept: application/json`**. Substitua `$SITE` pelo endereço do site e `$TOKEN` pelo token criado em **Painel → Tokens**.

O esquema completo do que você pode **escrever** (JSON Schema de cada ação) está em `GET $SITE/.well-known/ai-manifest.json`. O cabeçalho `Link: rel="ai-manifest"` de toda resposta aponta para ele.

## Ler (sem token só o publicado; com token, também rascunhos)
```
GET /                      resumo do site (título, endereço, contagens)
GET /blog                  lista de conteúdos
GET /blog/{slug}           um post, com o texto em Markdown
GET /{slug}                uma página, com o texto em Markdown
GET /tag/{slug}  GET /busca?q=
GET /api/midia             arquivos enviados (exige token)
```
Filtros da lista (`/blog`): `tipo=post|page` (padrão post), `status=draft|published` (só com token), `tag`, `q`, `pagina`, `por` (até 100), `texto=1` (traz o corpo; por padrão a lista vem sem ele). Totais em `X-Total-Count` e `X-Pages`.
Rascunhos: com token, use o slug ou o `id` no lugar do slug (`/blog/7`).

Para poupar tokens: `?campos=id,titulo,slug` recorta os campos, `?tabela` devolve a lista em CSV, e repetir o pedido com `If-None-Match: <ETag>` devolve `304` sem corpo quando nada mudou.

## Escrever (exige `Authorization: Bearer $TOKEN` com permissão de escrita)
Todas são `POST` com `Content-Type: application/json`. O corpo é conferido contra o manifesto: erro vira `422` dizendo o campo.

| Ação | Caminho | Corpo |
|---|---|---|
| criar | `/api/conteudo` | `{"conteudo": {"titulo": "...", "texto": "Markdown", "tags": ["a"], "tipo": "post", "status": "draft"}}` |
| alterar só alguns campos | `/api/conteudo/{id}/alterar` | `{"campos": {"texto": "novo corpo"}}` |
| substituir por inteiro | `/api/conteudo/{id}/editar` | igual ao de criar |
| publicar / despublicar | `/api/conteudo/{id}/publicar` · `/despublicar` | (vazio) |
| apagar | `/api/conteudo/{id}/apagar` | (vazio) |
| configurar o site | `/api/site` | `{"ajustes": {"titulo": "...", "slogan": "..."}}` |
| enviar imagem/arquivo | `POST /api/midia` | `multipart`: `-F arquivo=@foto.png -F alt="descrição"` → devolve `url` e `markdown` |

Campos de conteúdo: `titulo` (obrigatório), `texto` (Markdown), `slug`, `resumo`, `tipo` (`post`\|`page`), `status` (`draft`\|`published`), `tags[]`, `publicar_em` (UTC, `AAAA-MM-DD HH:mm`; futuro + `published` = agendado), `em_menu` (páginas).

```bash
curl -X POST $SITE/api/conteudo -H "Authorization: Bearer $TOKEN" -H "Content-Type: application/json" \
  -d '{"conteudo":{"titulo":"Meu post","texto":"# Oi\n\nTexto em **Markdown**.","tags":["novidade"]}}'
curl -X POST $SITE/api/conteudo/5/publicar -H "Authorization: Bearer $TOKEN"
curl -H "Accept: application/json" -H "Authorization: Bearer $TOKEN" "$SITE/blog?status=draft"
```

## Regras de ouro
1. **Crie como rascunho** (é o padrão) e só publique se o humano pediu.
2. `texto` é Markdown. HTML cru é **escapado** (não vira tag): use a sintaxe Markdown.
3. A resposta traz a `url` do conteúdo: confira o resultado lendo de volta.
4. `alterar` mexe só no que você enviou; `editar` substitui tudo (o que faltar volta ao padrão).
5. Horários em UTC. `401` token ausente/inválido, `403` token só de leitura, `404` não existe, `406` rota só de tela, `409` slug em uso, `422` campo inválido, `429` devagar (limite por agente).
6. Slugs reservados (não use): admin, api, blog, tag, busca, uploads, assets, instalar, entrar, sair, feed, sitemap, robots.
