#!/usr/bin/env bash
# Teste ponta a ponta: sobe uma CÓPIA do site numa pasta temporária, instala, e exercita
# painel, API (actions), MCP, feeds e permissões. Uso:  testes/e2e.sh [caminho-do-djo]
set -u
DJO="${1:-${DJO:-djo}}"
RAIZ="$(cd "$(dirname "$0")/.." && pwd)"
TMP="$(mktemp -d)"; PORT=$((18000 + RANDOM % 1000)); B="localhost:$PORT"
cp -r "$RAIZ"/{core,paginas,agentes,admin,publico,uploads,rotas.djo,404.djo.html,ask.djo} "$TMP"/
cd "$TMP"; "$DJO" serve -dev -addr "127.0.0.1:$PORT" . >log.txt 2>&1 & PID=$!
trap 'kill $PID 2>/dev/null; rm -rf "$TMP"' EXIT
for i in $(seq 40); do curl -s -o /dev/null "$B/robots.txt" && break; sleep 0.1; done
ok=0; ruim=0
t() { # t "nome" esperado obtido
  if [[ "$3" == *"$2"* ]]; then ok=$((ok+1)); echo "ok    $1"; else ruim=$((ruim+1)); echo "FALHA $1"; echo "      esperava: $2"; echo "      obtido:   ${3:0:300}"; fi; }
code() { curl -s -o /dev/null -w '%{http_code}' "$@"; }
csrf() { grep -o 'name="_token" value="[^"]*"' | head -1 | sed 's/.*value="//;s/"//'; }
J="$TMP/c.txt"; CT='Content-Type: application/json'

t "antes de instalar, / manda para /instalar" "302" "$(code $B/)"
CSRF=$(curl -s -c $J $B/instalar | csrf)
t "instalar rejeita senha curta" "8 caracteres" "$(curl -s -b $J -c $J $B/instalar --data-urlencode "_token=$CSRF" -d 'titulo=Blog&url=http://'$B'&nome=leo&senha=123&senha2=123')"
curl -s -b $J -XPOST $B/instalar -d 'titulo=x&nome=a&senha=12345678&senha2=12345678' -o /dev/null
t "instalar sem CSRF não instala" "200" "$(code $B/instalar)"
CSRF=$(curl -s -b $J -c $J $B/instalar | csrf)
t "instalar conclui" "302" "$(code -b $J -c $J $B/instalar --data-urlencode "_token=$CSRF" -d 'titulo=Meu Blog&url=http://'$B'&nome=leo&senha=segredo123&senha2=segredo123')"
TOK=$(curl -s -b $J $B/admin/tokens | grep -o 'cms_[A-Za-z0-9]*' | head -1); H="Authorization: Bearer $TOK"
t "token inicial gerado" "cms_" "$TOK"
t "instalar de novo não é permitido" "302" "$(code $B/instalar)"

for u in / /blog /blog/bem-vindo /sobre /tag/novidade "/busca?q=site" /feed.xml /sitemap.xml /robots.txt; do t "GET $u" "200" "$(code "$B$u")"; done
t "404 em página que não existe" "404" "$(code $B/nao-existe)"
t "/admin sem login manda entrar" "302" "$(code $B/admin)"
t "agente: / devolve resumo do site" '"publicados"' "$(curl -s $B -H 'Accept: application/json')"
t "agente: página com texto em Markdown" "Esta é uma página" "$(curl -s $B/sobre -H 'Accept: application/json')"
t "agente não recebe HTML de rota só-tela" "406" "$(code $B/admin -H 'Accept: application/json')"
t "RSS válido" "<rss" "$(curl -s $B/feed.xml)"
t "manifesto lista as actions" "criar_conteudo" "$(curl -s $B/.well-known/ai-manifest.json)"

echo "-- login"
CSRF=$(curl -s -c $J $B/entrar | csrf)
t "login com senha errada" "inválidos" "$(curl -s -b $J -c $J $B/entrar --data-urlencode "_token=$CSRF" -d 'nome=leo&senha=errada')"
CSRF=$(curl -s -b $J -c $J $B/entrar | csrf)
t "login correto" "302" "$(code -b $J -c $J $B/entrar --data-urlencode "_token=$CSRF" -d 'nome=leo&senha=segredo123')"
for u in /admin /admin/conteudos /admin/conteudos/novo /admin/conteudos/1 /admin/midia /admin/tokens /admin/config; do t "painel $u" "200" "$(code -b $J $B$u)"; done
CSRF=$(curl -s -b $J -c $J $B/admin/conteudos/novo | csrf)
t "criar pelo painel" "302" "$(code -b $J $B/admin/conteudos/novo --data-urlencode "_token=$CSRF" -d 'titulo=Pelo painel&texto=ol%C3%A1&tipo=post&status=published&tags=a,b&acao=salvar')"
t "post do painel está no ar" "Pelo painel" "$(curl -s $B/blog/pelo-painel)"
t "prévia renderiza Markdown" "<strong>x</strong>" "$(curl -s -b $J $B/admin/previa --data-urlencode "_token=$CSRF" --data-urlencode 'texto=**x**')"
t "prévia escapa HTML" "&lt;script&gt;" "$(curl -s -b $J $B/admin/previa --data-urlencode "_token=$CSRF" --data-urlencode 'texto=<script>alert(1)</script>')"
curl -s -b $J -XPOST $B/admin/conteudos/3/apagar -o /dev/null
MD() { curl -s -b $J $B/admin/previa --data-urlencode "_token=$CSRF" --data-urlencode "texto=$1"; }
t "markdown: título" '<h2 id="ola-mundo">Olá <em>mundo</em></h2>' "$(MD '## Olá *mundo*')"
t "markdown: lista" '<ul>' "$(MD $'- a\n- b')"
t "markdown: lista numerada" '<ol>' "$(MD $'1. a\n2. b')"
t "markdown: código" '<pre><code class="language-go">x &lt; y' "$(MD $'```go\nx < y\n```')"
t "markdown: tabela" '<th>a</th>' "$(MD $'| a | b |\n|---|---|\n| 1 | 2 |')"
t "markdown: link" '<a href="https://x.y/?a=1&amp;b=2">t</a>' "$(MD '[t](https://x.y/?a=1&b=2)')"
t "markdown: imagem" '<img src="/uploads/a.png" alt="foto"' "$(MD '![foto](/uploads/a.png)')"
t "apagar sem CSRF não apaga" "200" "$(code $B/blog/pelo-painel)"
t "apagar com CSRF" "302" "$(code -b $J -XPOST $B/admin/conteudos/3/apagar --data-urlencode "_token=$CSRF")"
t "post apagado sumiu" "404" "$(code $B/blog/pelo-painel)"

echo "-- API REST (actions)"
t "criar sem token: 401" "autenticação necessária" "$(curl -s -XPOST $B/api/conteudo -H "$CT" -d '{"conteudo":{"titulo":"x"}}')"
t "token inválido: 401" "inválido" "$(curl -s -H 'Accept: application/json' -H 'Authorization: Bearer cms_x' $B/blog)"
R=$(curl -s -XPOST $B/api/conteudo -H "$H" -H "$CT" -d '{"conteudo":{"titulo":"Post do agente","texto":"# Oi\n\nCriado via **API**.","tags":["ia","api"]}}')
t "criar rascunho" '"status":"draft"' "$R"
t "slug gerado do título" '"slug":"post-do-agente"' "$R"
ID=$(echo "$R" | grep -o '"id":[0-9]*' | head -1 | cut -d: -f2)
t "rascunho invisível ao público" "404" "$(code $B/blog/post-do-agente)"
t "rascunho invisível na API anônima" "404" "$(code $B/blog/$ID -H 'Accept: application/json')"
t "rascunho visível com token" "Post do agente" "$(curl -s -H "$H" -H 'Accept: application/json' $B/blog/$ID)"
t "filtro status=draft" "Post do agente" "$(curl -s -H "$H" -H 'Accept: application/json' "$B/blog?status=draft")"
t "alterar parcial" "Texto revisado" "$(curl -s -XPOST $B/api/conteudo/$ID/alterar -H "$H" -H "$CT" -d '{"campos":{"texto":"Texto revisado."}}')"
t "alterar preserva o resto" '"tags":["api","ia"]' "$(curl -s -H "$H" -H 'Accept: application/json' $B/blog/$ID)"
t "campo desconhecido: 422" "campo desconhecido" "$(curl -s -XPOST $B/api/conteudo/$ID/alterar -H "$H" -H "$CT" -d '{"campos":{"foo":1}}')"
t "slug reservado: 422" "reservado" "$(curl -s -XPOST $B/api/conteudo -H "$H" -H "$CT" -d '{"conteudo":{"titulo":"x","slug":"admin"}}')"
t "slug repetido: 409" "já está em uso" "$(curl -s -XPOST $B/api/conteudo -H "$H" -H "$CT" -d '{"conteudo":{"titulo":"x","slug":"sobre"}}')"
t "tipo errado: 422 do manifesto" "deve ser String" "$(curl -s -XPOST $B/api/conteudo -H "$H" -H "$CT" -d '{"conteudo":{"titulo":5}}')"
t "data ruim: 422" "publicar_em" "$(curl -s -XPOST $B/api/conteudo -H "$H" -H "$CT" -d '{"conteudo":{"titulo":"d","publicar_em":"ontem"}}')"
t "publicar" '"ao_vivo":true' "$(curl -s -XPOST $B/api/conteudo/$ID/publicar -H "$H")"
t "publicado fica no ar" "Texto revisado" "$(curl -s $B/blog/post-do-agente)"
t "agente anônimo lê o publicado" "Texto revisado" "$(curl -s -H 'Accept: application/json' $B/blog/post-do-agente)"
t "agente lista páginas (?tipo=page)" '"slug":"sobre"' "$(curl -s -H 'Accept: application/json' "$B/blog?tipo=page")"
t "anônimo não vê rascunho nem com ?status=" '"slug":"sobre"' "$(curl -s -H 'Accept: application/json' "$B/blog?status=draft&tipo=page")"
t "agendado não aparece" "404" "$(curl -s -XPOST $B/api/conteudo -H "$H" -H "$CT" -d '{"conteudo":{"titulo":"Futuro","status":"published","publicar_em":"2999-01-01"}}' >/dev/null; code $B/blog/futuro)"
t "despublicar" '"status":"draft"' "$(curl -s -XPOST $B/api/conteudo/$ID/despublicar -H "$H")"
t "lista pública com ?campos=" '"titulo":"Bem-vindo"' "$(curl -s "$B/blog?campos=titulo" -H 'Accept: application/json')"
t "lista em CSV (?tabela)" "id,titulo" "$(curl -s "$B/blog?tabela&campos=id,titulo" -H 'Accept: application/json')"
t "ETag e 304" "304" "$(E=$(curl -si $B/blog -H 'Accept: application/json' | grep -i '^etag' | cut -d' ' -f2 | tr -d '\r'); code $B/blog -H 'Accept: application/json' -H "If-None-Match: $E")"
t "configurar_site" "Novo nome" "$(curl -s -XPOST $B/api/site -H "$H" -H "$CT" -d '{"ajustes":{"titulo":"Novo nome"}}')"
t "apagar" "apagado" "$(curl -s -XPOST $B/api/conteudo/$ID/apagar -H "$H")"
curl -s -b $J $B/admin/tokens --data-urlencode "_token=$CSRF" -d 'acao=criar&nome=leitor&escopo=leitura' -o /dev/null
RO=$(curl -s -b $J $B/admin/tokens | grep -o 'cms_[A-Za-z0-9]*' | head -1)
t "token somente leitura lê" "200" "$(code -H "Authorization: Bearer $RO" -H 'Accept: application/json' $B/blog)"
t "token somente leitura não escreve" "somente leitura" "$(curl -s -XPOST $B/api/conteudo -H "Authorization: Bearer $RO" -H "$CT" -d '{"conteudo":{"titulo":"x"}}')"
printf '\x89PNG\r\n\x1a\nfake' > "$TMP/f.png"
t "upload via API" "/uploads/" "$(curl -s -XPOST $B/api/midia -H "$H" -F arquivo=@"$TMP/f.png" -F alt=teste)"
echo '<script>' > "$TMP/x.html"
t "upload .html é recusado" "não aceito" "$(curl -s -XPOST $B/api/midia -H "$H" -F arquivo=@"$TMP/x.html")"
t "listar mídia" "teste" "$(curl -s -H "$H" $B/api/midia)"
t "editor tem o botão de imagem" "Inserir imagem" "$(curl -s -b $J $B/admin/conteudos/novo)"
t "editor envia imagem (sessão + CSRF)" '"markdown"' "$(curl -s -b $J $B/admin/midia/enviar -F "_token=$CSRF" -F arquivo=@"$TMP/f.png" -F alt=capa)"
t "editor: upload sem CSRF = 403" "403" "$(code -b $J $B/admin/midia/enviar -F arquivo=@"$TMP/f.png")"
t "editor: upload sem login = 401" "401" "$(code $B/admin/midia/enviar -F "_token=$CSRF" -F arquivo=@"$TMP/f.png")"
t "editor: .html é recusado" "não aceito" "$(curl -s -b $J $B/admin/midia/enviar -F "_token=$CSRF" -F arquivo=@"$TMP/x.html")"
t "editor lista só imagens" '"capa"' "$(curl -s -b $J $B/admin/midia/imagens)"
t "editor: lista sem login = 401" "401" "$(code $B/admin/midia/imagens)"

printf %s '{"conteudo":{"titulo":"g","texto":"' > "$TMP/g.json"; head -c 100001 /dev/zero | tr '\0' x >> "$TMP/g.json"; printf %s '"}}' >> "$TMP/g.json"
t "texto grande é recusado" "muito grande" "$(curl -s -XPOST $B/api/conteudo -H "$H" -H "$CT" -d @"$TMP/g.json")"

echo "-- /ask (perguntas em linguagem natural, só leitura)"
ASK() { curl -s -XPOST $B/ask -H "$CT" "$@"; }
curl -s -XPOST $B/api/conteudo -H "$H" -H "$CT" -d '{"conteudo":{"titulo":"Rascunho do ask","texto":"x","tags":["ask-interno"]}}' >/dev/null
curl -s -XPOST $B/api/conteudo -H "$H" -H "$CT" -d '{"conteudo":{"titulo":"Agendado do ask","texto":"x","status":"published","publicar_em":"2099-01-01 10:00","tags":["ask-futuro"]}}' >/dev/null
t "GET /ask é a página com a caixa" "<form" "$(curl -s $B/ask)"
t "/ask lista posts publicados" '"Bem-vindo"' "$(ASK -d '{"question":"liste posts"}')"
t "/ask lista não traz o texto" "0" "$(ASK -d '{"question":"liste posts"}' | grep -c '"text"')"
t "/ask um item traz o texto inteiro" "Para agentes" "$(ASK -d '{"question":"mostre o post bem-vindo"}')"
t "/ask item de rascunho = não encontrei (público)" "Não encontrei" "$(ASK -d '{"question":"mostre o post \"rascunho-do-ask\""}')"
t "/ask item de rascunho com token de leitura" '"Rascunho do ask"' "$(ASK -H "Authorization: Bearer $RO" -d '{"question":"mostre o post \"rascunho-do-ask\""}')"
t "/ask público não vê rascunho" '"count":0' "$(ASK -d '{"question":"quantos posts tem a tag ask-interno?"}')"
t "/ask público não vê agendado" '"count":0' "$(ASK -d '{"question":"quantos posts tem a tag ask-futuro?"}')"
t "/ask público não filtra por status" "Não entendi" "$(ASK -d '{"question":"liste posts com status draft"}')"
t "/ask com token de leitura vê rascunho" '"Rascunho do ask"' "$(ASK -H "Authorization: Bearer $RO" -d '{"question":"liste posts com status draft"}')"
t "/ask logado no painel vê rascunho" '"Rascunho do ask"' "$(ASK -b $J -d '{"question":"liste posts com status draft"}')"
t "/ask com token inválido = 401" "401" "$(code -XPOST $B/ask -H "$CT" -H 'Authorization: Bearer cms_invalido' -d '{"question":"liste posts"}')"
t "/ask recusa escrita mesmo com token de escrita" "403" "$(code -XPOST $B/ask -H "$CT" -H "$H" -d '{"question":"apague os posts"}')"
t "/ask não responde a GET ?q=" "0" "$(curl -s "$B/ask?q=liste+posts" | grep -c 'Bem-vindo')"
t "ask.djo não é servido" "404" "$(code $B/ask.djo)"
t "/ask fora do manifesto" "0" "$(curl -s $B/.well-known/ai-manifest.json | grep -c '"/ask')"
t "slug 'ask' é reservado" "reservado" "$(curl -s -XPOST $B/api/conteudo -H "$H" -H "$CT" -d '{"conteudo":{"titulo":"x","slug":"ask"}}')"

echo "-- exportar e importar"
t "página exportar no painel" "Exportar e importar" "$(curl -s -b $J $B/admin/exportar)"
t "exportar exige login" "302" "$(code $B/admin/exportar/baixar)"
curl -s -b $J -D "$TMP/exp.h" "$B/admin/exportar/baixar?rascunhos=1" -o "$TMP/exp.json"
t "exportar baixa um arquivo" "attachment" "$(cat "$TMP/exp.h")"
t "exportação traz texto e tags" 'Para agentes de IA' "$(cat "$TMP/exp.json")"
t "exportação com rascunhos" '"rascunho-do-ask"' "$(cat "$TMP/exp.json")"
t "exportação sem rascunhos" "0" "$(curl -s -b $J "$B/admin/exportar/baixar" | grep -c 'rascunho-do-ask')"
t "exportação não leva tokens nem senhas" "0" "$(grep -c 'cms_\|senha\|hash' "$TMP/exp.json")"
IMP() { curl -s -b $J $B/admin/exportar -F "_token=$CSRF" "$@"; }
t "reimportar no mesmo site pula tudo" "0</strong> criados" "$(IMP -F arquivo=@"$TMP/exp.json" -F modo=pular)"
t "simular substituir não grava" "seriam substituídos" "$(IMP -F arquivo=@"$TMP/exp.json" -F modo=substituir -F simular=on)"
cat > "$TMP/novo.json" <<'JSON'
{"djornal": 1, "conteudos": [
 {"tipo": "post", "titulo": "Veio de outro site", "slug": "veio-de-outro-site", "texto": "Oi ![foto](/uploads/2020-01/nao-existe.png)", "status": "published", "publicar_em": "2024-05-01 10:00:00", "tags": ["importado"], "criado": "2024-04-30 09:00:00"},
 {"tipo": "post", "titulo": "", "slug": "sem-titulo-imp"},
 "lixo"],
 "midias": [{"arquivo": "../_dados/cms.db"}, {"arquivo": "uploads/2020-01/nao-existe.png"}]}
JSON
R=$(IMP -F arquivo=@"$TMP/novo.json")
t "importar cria o post novo" "1</strong> criados" "$R"
t "importar relata erros por item" "2</strong> com erro" "$R"
t "importar lista mídia que falta" "uploads/2020-01/nao-existe.png" "$R"
t "importar ignora caminho fora de uploads" "0" "$(echo "$R" | grep -c 'cms.db')"
t "post importado está no ar com data original" "2024" "$(curl -s -H 'Accept: application/json' $B/blog/veio-de-outro-site)"
t "post importado mantém a tag" "importado" "$(curl -s -H 'Accept: application/json' $B/blog/veio-de-outro-site)"
sed -i 's/Oi !/Mudado !/' "$TMP/novo.json"
t "importar substituir regrava" "1</strong> substituídos" "$(IMP -F arquivo=@"$TMP/novo.json" -F modo=substituir)"
t "substituído tem o texto novo" "Mudado" "$(curl -s -H "$H" -H 'Accept: application/json' $B/blog/veio-de-outro-site)"
echo '{"x": 1}' > "$TMP/ruim.json"; echo 'nao é json' > "$TMP/ruim2.json"
t "importar recusa JSON de outra coisa" "não é uma exportação" "$(IMP -F arquivo=@"$TMP/ruim.json")"
t "importar recusa arquivo inválido" "não é um JSON válido" "$(IMP -F arquivo=@"$TMP/ruim2.json")"
t "importar sem CSRF é recusado" "0" "$(curl -s -b $J $B/admin/exportar -F arquivo=@"$TMP/novo.json" | grep -c 'criados')"
t "importar não deixa o arquivo para trás" "0" "$(ls _dados/importar 2>/dev/null | wc -l)"

echo "-- segurança"
curl -s -XPOST $B/api/conteudo -H "$H" -H "$CT" -d '{"conteudo":{"titulo":"xss","texto":"[a](javascript:alert(1)) <img src=x onerror=alert(1)>","status":"published"}}' >/dev/null
t "javascript: vira #" 'href="#"' "$(curl -s $B/blog/xss)"
t "HTML cru escapado" "&lt;img" "$(curl -s $B/blog/xss)"
t "banco não é servido" "404" "$(code $B/_dados/cms.db)"
t "core não é servido" "404" "$(code $B/core/auth.djo)"
for i in 1 2 3 4 5 6; do C=$(curl -s -c $TMP/c2.txt $B/entrar | csrf); R2=$(curl -s -b $TMP/c2.txt $B/entrar --data-urlencode "_token=$C" -d 'nome=leo&senha=nao'); done
t "5 falhas de login bloqueiam" "Muitas tentativas" "$R2"

echo; echo "passou: $ok  falhou: $ruim"
[[ $ruim -eq 0 ]] || { echo "--- erros do servidor:"; grep -E ' (5[0-9][0-9]) ' log.txt | tail -10; exit 1; }
