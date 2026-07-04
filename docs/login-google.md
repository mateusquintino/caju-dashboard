# Login com Google — configuração no Supabase

O código do dashboard já está pronto (botão "Entrar com Google", trava de
domínio @cajupar.com e fluxo de aprovação). Falta só ligar o provedor no
Supabase. Siga os passos abaixo — leva ~3 minutos.

Projeto Supabase: **caju-dashboard**
Callback (já usado no Google Cloud): `https://ubcoplavpmwulnhzigxg.supabase.co/auth/v1/callback`

---

## Passo 1 — Ativar o provedor Google

1. Acesse https://supabase.com/dashboard e abra o projeto **caju-dashboard**.
2. Menu lateral → **Authentication**.
3. Clique em **Sign In / Providers** (em alguns painéis aparece como **Providers**).
4. Na lista, clique em **Google**.
5. Ligue o botão **Enable Sign in with Google**.
6. Preencha:
   - **Client ID (for OAuth)**: cole o ID do cliente do Google
     (termina em `...apps.googleusercontent.com`).
   - **Client Secret (for OAuth)**: cole a chave secreta do cliente
     (começa com `GOCSPX-`).
7. Confira o campo **Callback URL (for OAuth)** mostrado na tela. Ele deve ser
   exatamente:
   `https://ubcoplavpmwulnhzigxg.supabase.co/auth/v1/callback`
   (é o mesmo que você cadastrou no Google Cloud). Se estiver diferente,
   copie o valor mostrado aqui e adicione-o no Google Cloud → Credenciais →
   seu cliente OAuth → "URIs de redirecionamento autorizados".
8. Clique em **Save**.

---

## Passo 2 — Configurar as URLs de redirecionamento

Isso diz ao Supabase para quais endereços ele pode devolver o usuário depois
do login. Sem isso, o login volta com erro "redirect não permitido".

1. Ainda em **Authentication** → clique em **URL Configuration**.
2. **Site URL**: coloque o endereço onde o dashboard fica publicado
   (GitHub Pages). Exemplo:
   `https://SEU-USUARIO.github.io/SEU-REPOSITORIO/`
3. **Redirect URLs** → **Add URL**: adicione o endereço exato da página do
   login (onde o `index.html` abre). Exemplos possíveis:
   - `https://SEU-USUARIO.github.io/SEU-REPOSITORIO/`
   - `https://SEU-USUARIO.github.io/SEU-REPOSITORIO/dashboard/`
   - `https://SEU-USUARIO.github.io/SEU-REPOSITORIO/dashboard/index.html`

   Dica: use a URL que aparece na barra do navegador quando você abre o
   dashboard publicado — é exatamente essa que deve entrar aqui. Pode
   adicionar mais de uma se tiver dúvida.
4. Clique em **Save**.

> Como descobrir sua URL do GitHub Pages: no repositório do GitHub →
> **Settings** → **Pages**. O endereço publicado aparece no topo.

---

## Passo 3 — Testar

1. Abra o dashboard **pela URL publicada** (GitHub Pages), não pelo arquivo
   local — o login Google não funciona em `file://`.
2. Clique em **Entrar com Google** e escolha uma conta **@cajupar.com**.
3. O usuário entra como **pendente** (aguardando aprovação).
4. Um administrador aprova na aba **Usuários**. Pronto.

Contas fora do domínio @cajupar.com são bloqueadas automaticamente (trava no
banco) e recebem a mensagem de acesso negado.

---

## Segurança

- Depois de configurar, **gere uma nova chave secreta** no Google Cloud e
  remova a anterior (a que foi compartilhada em conversa). No Google Cloud →
  Credenciais → seu cliente OAuth → em "Chaves secretas do cliente",
  "Adicionar chave" e depois excluir a antiga. Atualize o secret no Supabase.
- Nunca versione o Client Secret no GitHub.

---

## Erros comuns

- **"redirect_uri_mismatch"** (tela do Google): o URI de redirecionamento no
  Google Cloud está diferente do callback do Supabase. Confira o Passo 1.7.
- **"requested path is invalid" / volta para o login sem entrar**: falta
  adicionar a URL da página em **Redirect URLs** (Passo 2).
- **Entra mas cai em "aguardando aprovação"**: comportamento esperado — um
  admin precisa aprovar na aba Usuários.
- **"Apenas contas @cajupar.com..."**: a conta Google usada não é do domínio
  corporativo.
