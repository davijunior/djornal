# Usando o painel

Entre em `/entrar` e vá para `/admin`.

## Conteúdos
Dois tipos:
- **Post**: aparece em `/blog`, no feed e nas tags. Endereço `/blog/{slug}`.
- **Página**: endereço `/{slug}`. Marque **em menu** para ela aparecer no topo do site.

Cada conteúdo tem título, endereço (slug), resumo, texto em Markdown, tags e estado.

| Estado | Efeito |
|---|---|
| Rascunho | só aparece no painel e para tokens de agente |
| Publicado | visível a todos |
| Publicado com data futura | **agendado**: fica invisível até a data (horário em **UTC**, `AAAA-MM-DD HH:mm`) |

O editor tem pré-visualização do Markdown ao lado. O slug sai do título se você deixar em branco; se já existir, ganha um sufixo. Alguns slugs são reservados: `admin, api, blog, tag, busca, uploads, assets, instalar, entrar, sair, feed, sitemap, robots`.

## Mídia
Envie imagens e arquivos em **Mídia**. Cada envio devolve a URL e o trecho de Markdown pronto para colar (`![alt](/uploads/…)`). Limite de 10 MB. Extensões aceitas: jpg, jpeg, png, gif, webp, avif, ico, pdf, txt, csv, json, md, zip, gz, mp3, wav, ogg, mp4, webm. HTML, SVG e scripts são recusados de propósito.

No editor, o botão **Inserir imagem** envia uma imagem nova ou escolhe uma já enviada; também dá para colar (Ctrl+V) ou arrastar uma imagem para o texto.

## Exportar e importar
Em **Exportar**, baixe um `.json` com os posts e páginas: texto em Markdown, tags, status, datas e a lista de mídia (com ou sem rascunhos). Usuários, senhas, tokens e configurações não vão. Serve de backup e para levar conteúdo de um Djornal para outro (do site local para o do servidor, por exemplo).

Para importar, envie esse arquivo no outro site. Cada conteúdo é reconhecido pelo endereço (slug): se já existir, você escolhe **manter o daqui** (pular) ou **substituir**. Comece com **Só simular** (vem marcado): mostra quantos seriam criados, substituídos e pulados, sem gravar. O relatório lista os erros por item.

Os arquivos de mídia não vão dentro do JSON: copie a pasta `uploads/` junto. O relatório lista os arquivos citados nos textos que faltam no site de destino; depois de copiá-los, importe de novo para registrá-los na Mídia. Limite de 10 MB por arquivo de importação.

## Tokens
Em **Tokens** você cria chaves para agentes:
- **leitura**: vê também os rascunhos;
- **escrita**: além disso, cria, edita, publica e apaga.

O token (`cms_…`) é mostrado uma vez e guardado só como hash. Revogue a qualquer momento.

## Configurações
Título, slogan, descrição, rodapé e endereço público do site. Também a troca da senha.

## Segurança embutida
Formulários com proteção CSRF; login bloqueado após 5 falhas em 15 minutos por IP; HTML cru no texto é escapado.
