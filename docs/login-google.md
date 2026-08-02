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
   (HostGator). No nosso caso:
   `https://financeirogrupocajupar.com`
3. **Redirect URLs** → **Add URL**: adicione os endereços exatos onde o
   login pode voltar. Adicione todos abaixo:
   - `https://financeirogrupocajupar.com`
   - `https://financeirogrupocajupar.com/`
   - `https://financeirogrupocajupar.com/dashboard/`
   - `https://financeirogrupocajupar.com/dashboard/index.html`

   Dica: o dashboard usa a própria URL da página como retorno, então
   qualquer endereço que apareça na barra do navegador ao abrir o
   dashboard precisa estar nesta lista.
4. Clique em **Save**.

> Observação: o domínio `financeirogrupocajupar.com` precisa estar apontado
> para o HostGator e com o SSL (HTTPS) ativo antes de testar o login — o
> Google exige HTTPS.

---

## Passo 3 — Testar

1. Abra o dashboard **pela URL publicada** (`https://financeirogrupocajupar.com`),
   não pelo arquivo local — o login Google não funciona em `file://`.
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
- Nunca versione nem faça upload do Client Secret. Ele fica **somente** no
  painel do Supabase.

---

## Erros comuns

- **"redirect_uri_mismatch"** (tela do Google): o URI de redirecionamento no
  Google Cloud está diferente do callback do Supabase. Confira o Passo 1.7.
- **"requested path is invalid" / volta para o login sem entrar**: falta
  adicionar a URL da página em **Redirect URLs** (Passo 2). Confira que a
  URL bate exatamente (com/sem barra no final, `/dashboard/`, etc.).
- **Entra mas cai em "aguardando aprovação"**: comportamento esperado — um
  admin precisa aprovar na aba Usuários.
- **"Apenas contas @cajupar.com..."**: a conta Google usada não é do domínio
  corporativo.
