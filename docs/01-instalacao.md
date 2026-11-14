# Instalação

O Djornal precisa só do binário `djo` (veja `../djo/README.md`). Não precisa de Go, de banco de dados nem de configuração.

## Rodar

```bash
djo serve .                        # http://localhost:8080
djo serve -addr :8088 .            # outra porta, aceitando conexões de fora
djo serve -dev .                   # mostra os erros na própria página (só para desenvolver)
```

## Gerar um executável único

```bash
djo build -o djornal .
./djornal -addr :8080
```

O executável guarda o código do site. Os dados (banco e uploads) ficam numa pasta `djornal.d/` ao lado dele.

## Primeiro acesso

Abra o endereço. Enquanto não houver administrador, toda página leva a `/instalar`, que pede:

| Campo | Para quê |
|---|---|
| Nome do site | título no topo, no feed e no painel |
| Endereço público | usado em links, feed e sitemap (ex.: `https://meusite.com`) |
| Usuário e senha | o administrador. A senha precisa de 8 caracteres ou mais |

Ao concluir, o instalador cria um post de boas-vindas, uma página de exemplo e **um token para o seu primeiro agente**. O token aparece **uma única vez**: anote-o. Se perder, crie outro em Painel → Tokens.

## Onde ficam os dados

| Pasta | Conteúdo |
|---|---|
| `_dados/` | banco SQLite (`cms.db`). Nunca é servida pela web |
| `uploads/` | arquivos enviados, em `uploads/AAAA-MM/` com nome aleatório |

**Backup** = copiar essas duas pastas. **Atualizar** = trocar os arquivos do site (ou o executável); os dados são mantidos e o banco se migra sozinho.

**Recomeçar do zero** = parar o servidor e apagar `_dados/`.
