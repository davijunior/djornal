# Markdown

O texto é escrito em Markdown e renderizado pelo próprio Djornal (`core/markdown.djo`).

## Suportado
Títulos (`#` a `######`), parágrafos, **negrito**, *itálico*, `código`, blocos de código com ```` ``` ````, citações (`>`), listas com `-` ou `*` e numeradas, linha horizontal (`---`), tabelas, links `[texto](url)` e imagens `![alt](url)`.

## Regras de segurança
- **HTML cru é escapado**, nunca vira tag. Isso impede que um agente (ou texto colado) injete script.
- Links e imagens com esquemas perigosos (`javascript:`, `data:`, `vbscript:`) viram `#`.

## Limites
- Sem listas aninhadas.
- Até 100 mil caracteres por conteúdo (o renderizador é escrito em djo e custa tempo proporcional ao tamanho).
- O **resumo** é gerado do texto, sem a sintaxe, quando você não informa um.
