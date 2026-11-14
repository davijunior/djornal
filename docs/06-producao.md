# Produção

1. **HTTPS**: rode atrás de um proxy (Caddy ou nginx) e deixe o Djornal em `localhost`.
2. **Endereço público**: preencha em Painel → Configurações. É usado em links, feed e sitemap.
3. **Sem `-dev`**: sem essa opção, erros mostram uma página genérica e o detalhe vai para o log.
4. **Limite de agentes**: atrás de um proxy todos parecem ter o mesmo IP. Ajuste `-agent-rate` (padrão 50 req/s por cliente) ou use `-agent-rate 0` e limite no proxy. `-agent-conc` limita requisições simultâneas.
5. **Backup**: `_dados/` e `uploads/` (no executável, a pasta `.d/` ao lado).
6. **Tokens**: um por agente, de escopo mínimo, revogados quando não servirem mais.

## Limites conhecidos
- **Sessões ficam na memória**: reiniciar o servidor desloga o painel (tokens de API não são afetados).
- Horários só em UTC.
- Um administrador só; sem papéis, colaboradores ou comentários.
- SQLite aceita um escritor por vez: de sobra para um site pequeno.
- Markdown sem listas aninhadas.
