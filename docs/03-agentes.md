# Djornal para agentes

Cada endereço do site tem duas faces: pessoas recebem HTML; agentes recebem JSON ao pedir com `Accept: application/json`. Não existe uma API separada para leitura.

O guia curto para entregar a um agente é o [AGENTS.md](../AGENTS.md). Aqui está o detalhe.

## Descoberta
`GET /.well-known/ai-manifest.json` descreve, em JSON Schema, todas as rotas de leitura e todas as ações de escrita. Toda resposta traz `Link: </.well-known/ai-manifest.json>; rel="ai-manifest"`. Pela linha de comando: `djo agent http://localhost:8080/.well-known/ai-manifest.json`.

## Quem precisa de token
| | Sem token | Com token |
|---|---|---|
| Ler o publicado | sim | sim |
| Ler rascunhos | não (404) | sim |
| Escrever, listar mídia | não (401) | sim, com escopo `escrita` (leitura dá 403) |

Envie `Authorization: Bearer cms_…`. Um token inválido dá 401, mesmo em rotas públicas.

## Ler
```
GET /                  resumo do site: título, endereço, contagens
GET /blog              lista (sem o texto por padrão)
GET /blog/{slug}       um post, com o texto em Markdown
GET /{slug}            uma página
GET /tag/{slug}        posts de uma tag
GET /busca?q=…         busca
GET /api/midia         arquivos enviados (exige token)
```
Filtros da lista: `tipo=post|page`, `status=draft|published` (só com token), `tag`, `q`, `pagina`, `por` (até 100), `texto=1` (traz o corpo).
Totais em `X-Total-Count`, `X-Page`, `X-Pages`. Com token, o `{slug}` pode ser o `id` (`/blog/7`) para alcançar rascunhos.

Para gastar menos tokens: `?campos=id,titulo,slug` recorta os campos; `?tabela` devolve a lista em CSV; `If-None-Match: <ETag>` devolve `304` sem corpo se nada mudou. Respostas públicas têm cache de 10 s.

## Escrever
Todas são `POST` com `Content-Type: application/json` e token de escrita. O corpo é conferido contra o manifesto; erro vira `422` dizendo o campo.

| Ação | Caminho | Corpo |
|---|---|---|
| `criar_conteudo` | `/api/conteudo` | `{"conteudo": {"titulo": "…", "texto": "…"}}` |
| `alterar_conteudo` | `/api/conteudo/{id}/alterar` | `{"campos": {"texto": "…"}}`: só o que foi enviado muda |
| `editar_conteudo` | `/api/conteudo/{id}/editar` | igual ao de criar: substitui tudo, o que faltar volta ao padrão |
| `publicar_conteudo` | `/api/conteudo/{id}/publicar` | vazio |
| `despublicar_conteudo` | `/api/conteudo/{id}/despublicar` | vazio |
| `apagar_conteudo` | `/api/conteudo/{id}/apagar` | vazio (irreversível) |
| `configurar_site` | `/api/site` | `{"ajustes": {"titulo": "…", "url": "…"}}` |
| enviar arquivo | `POST /api/midia` | `multipart`: `-F arquivo=@foto.png -F alt="…"` |

Campos de conteúdo: `titulo` (obrigatório), `texto`, `slug`, `resumo`, `tipo` (`post`|`page`), `status` (`draft`|`published`), `tags[]`, `publicar_em`, `em_menu`.

## Códigos de resposta
`401` token ausente/inválido · `403` token só de leitura · `404` não existe · `406` rota só de tela · `409` slug em uso · `415` arquivo não aceito · `422` campo inválido · `429` devagar (limite por agente).

## Exemplo completo
```bash
S=http://localhost:8080; T=cms_…
curl -X POST $S/api/conteudo -H "Authorization: Bearer $T" -H "Content-Type: application/json" \
  -d '{"conteudo":{"titulo":"Meu post","texto":"# Oi\n\nTexto **Markdown**.","tags":["novidade"]}}'
curl -H "Accept: application/json" -H "Authorization: Bearer $T" "$S/blog/meu-post"   # conferir
curl -X POST $S/api/conteudo/5/publicar -H "Authorization: Bearer $T"
```

## Boas práticas para quem integra
1. Crie como rascunho (padrão) e só publique quando um humano pedir.
2. Leia de volta depois de escrever.
3. Use `alterar` para revisões; `editar` apaga o que você não reenviar.
4. Dê um token por agente, para revogar um sem afetar os outros.
