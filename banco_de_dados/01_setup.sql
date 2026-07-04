-- ══════════════════════════════════════════════════════════════
--  Caju Dashboard — Setup completo do Supabase
--  Execute este arquivo no SQL Editor do seu projeto Supabase
--  (menu lateral esquerdo → SQL Editor → New query → cole e Run)
-- ══════════════════════════════════════════════════════════════


-- ──────────────────────────────────────────────────────────────
-- 1. TABELA: profiles  (vinculada ao auth.users)
-- ──────────────────────────────────────────────────────────────
create table if not exists public.profiles (
  id       uuid references auth.users on delete cascade primary key,
  email    text not null,
  nome     text not null default '',
  role     text not null default 'user',    -- 'admin' | 'user'
  status   text not null default 'pending', -- 'active' | 'pending' | 'rejected' | 'inactive'
  created_at timestamptz default now()
);

alter table public.profiles enable row level security;

-- Usuário lê/atualiza apenas seu próprio perfil
create policy "perfil_select_proprio" on public.profiles
  for select using (auth.uid() = id);

-- Admin lê todos os perfis
create policy "perfil_select_admin" on public.profiles
  for select using (
    exists (select 1 from public.profiles p where p.id = auth.uid() and p.role = 'admin')
  );

-- Admin atualiza qualquer perfil
create policy "perfil_update_admin" on public.profiles
  for update using (
    exists (select 1 from public.profiles p where p.id = auth.uid() and p.role = 'admin')
  );


-- ──────────────────────────────────────────────────────────────
-- 2. TRIGGER: cria profile automaticamente ao se cadastrar
-- ──────────────────────────────────────────────────────────────
create or replace function public.handle_new_user()
returns trigger language plpgsql security definer as $$
begin
  insert into public.profiles (id, email, nome, role, status)
  values (
    new.id,
    new.email,
    coalesce(new.raw_user_meta_data->>'nome', split_part(new.email, '@', 1)),
    'user',
    'pending'
  )
  on conflict (id) do nothing;
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure public.handle_new_user();


-- ──────────────────────────────────────────────────────────────
-- 3. FUNÇÃO: promove primeiro admin (sem exigir service_role)
-- ──────────────────────────────────────────────────────────────
create or replace function public.setup_first_admin(user_id uuid)
returns void language plpgsql security definer as $$
begin
  -- Só executa se não houver nenhum admin ativo ainda
  if not exists (
    select 1 from public.profiles where role = 'admin' and status = 'active'
  ) then
    update public.profiles
    set role = 'admin', status = 'active'
    where id = user_id;
  end if;
end;
$$;


-- ──────────────────────────────────────────────────────────────
-- 4. FUNÇÃO: verifica se existe admin ativo (usada no init)
--    Evita recursão de RLS ao verificar profiles sem estar logado
-- ──────────────────────────────────────────────────────────────
create or replace function public.has_active_admin()
returns boolean language plpgsql security definer as $$
begin
  return exists (
    select 1 from public.profiles
    where role = 'admin' and status = 'active'
  );
end;
$$;

-- Permite chamada anônima (necessário para o check do primeiro acesso)
grant execute on function public.has_active_admin() to anon, authenticated;


-- ──────────────────────────────────────────────────────────────
-- 5. FUNÇÃO: admin exclui usuário (profiles + auth.users)
-- ──────────────────────────────────────────────────────────────
create or replace function public.admin_delete_user(target_id uuid)
returns void language plpgsql security definer as $$
begin
  -- Somente admin pode chamar
  if not exists (
    select 1 from public.profiles
    where id = auth.uid() and role = 'admin'
  ) then
    raise exception 'Acesso negado: somente administradores podem excluir usuários.';
  end if;

  -- Não permite excluir a si mesmo
  if auth.uid() = target_id then
    raise exception 'Você não pode excluir sua própria conta.';
  end if;

  -- Exclui de auth.users; o cascade apaga profiles automaticamente
  delete from auth.users where id = target_id;
end;
$$;

grant execute on function public.admin_delete_user(uuid) to authenticated;


-- ──────────────────────────────────────────────────────────────
-- 6. FUNÇÃO: admin altera senha de outro usuário
-- ──────────────────────────────────────────────────────────────
create or replace function public.admin_change_password(target_id uuid, new_pass text)
returns void language plpgsql security definer as $$
begin
  -- Somente admin pode chamar
  if not exists (
    select 1 from public.profiles
    where id = auth.uid() and role = 'admin'
  ) then
    raise exception 'Acesso negado: somente administradores podem alterar senhas.';
  end if;

  -- Valida comprimento mínimo
  if length(new_pass) < 6 then
    raise exception 'A senha deve ter pelo menos 6 caracteres.';
  end if;

  -- Atualiza hash da senha em auth.users
  update auth.users
  set encrypted_password = crypt(new_pass, gen_salt('bf'))
  where id = target_id;
end;
$$;

grant execute on function public.admin_change_password(uuid, text) to authenticated;


-- ──────────────────────────────────────────────────────────────
-- 7. TABELA: contas
-- ──────────────────────────────────────────────────────────────
create table if not exists public.contas (
  id            serial primary key,
  loja          text not null default '',  -- código da loja (ex: 'MULT 01', 'NFE 02')
  empresa       text not null,             -- nome completo da empresa/unidade
  marca         text not null,             -- grupo/bandeira (ex: 'Caminito Parrilla')
  cnpj          text not null default '',  -- CNPJ da empresa
  banco         text not null,             -- 'Santander' | 'Itaú'
  agencia       text default '',           -- agência (4 dígitos)
  conta         text default '',           -- ACCTID = agência + conta_sem_hífen
  saldo_inicial numeric(15,2) default 0,
  ativo         boolean default true,
  created_at    timestamptz default now()
);

alter table public.contas enable row level security;

-- Qualquer autenticado pode ler
create policy "contas_select" on public.contas
  for select using (auth.role() = 'authenticated');

-- Só admin pode inserir/atualizar/deletar
create policy "contas_insert_admin" on public.contas
  for insert with check (
    exists (select 1 from public.profiles p where p.id = auth.uid() and p.role = 'admin')
  );
create policy "contas_update_admin" on public.contas
  for update using (
    exists (select 1 from public.profiles p where p.id = auth.uid() and p.role = 'admin')
  );


-- ──────────────────────────────────────────────────────────────
-- 8. TABELA: transacoes
--    tipo: 'receita' | 'despesa' | 'rendimento' | 'transferencia'
--    Nota: 'transferencia' inclui CONTAMAX (aplicação/resgate automático
--    Santander) e transferências entre contas — ambos impactam o saldo.
-- ──────────────────────────────────────────────────────────────
create table if not exists public.transacoes (
  id         serial primary key,
  conta_id   integer references public.contas(id) on delete cascade,
  data       date not null,
  descricao  text default '',
  valor      numeric(15,2) not null,
  tipo       text not null check (tipo in ('receita','despesa','rendimento','transferencia')),
  fitid      text,
  created_at timestamptz default now(),
  unique (conta_id, fitid)
);

alter table public.transacoes enable row level security;

create policy "transacoes_select" on public.transacoes
  for select using (auth.role() = 'authenticated');

create policy "transacoes_insert_admin" on public.transacoes
  for insert with check (
    exists (select 1 from public.profiles p where p.id = auth.uid() and p.role = 'admin')
  );

create policy "transacoes_delete_admin" on public.transacoes
  for delete using (
    exists (select 1 from public.profiles p where p.id = auth.uid() and p.role = 'admin')
  );


-- ──────────────────────────────────────────────────────────────
-- 9. TABELA: importacoes
-- ──────────────────────────────────────────────────────────────
create table if not exists public.importacoes (
  id               serial primary key,
  arquivo          text not null,
  banco            text not null,
  data_importacao  timestamptz default now(),
  qtd_transacoes   integer default 0,
  status           text default 'ok'
);

alter table public.importacoes enable row level security;

create policy "importacoes_select" on public.importacoes
  for select using (auth.role() = 'authenticated');

create policy "importacoes_insert_admin" on public.importacoes
  for insert with check (
    exists (select 1 from public.profiles p where p.id = auth.uid() and p.role = 'admin')
  );

create policy "importacoes_delete_admin" on public.importacoes
  for delete using (
    exists (select 1 from public.profiles p where p.id = auth.uid() and p.role = 'admin')
  );


-- ──────────────────────────────────────────────────────────────
-- 10. FUNÇÃO: limpar dados (transações + importações)
--     NÃO zera saldos iniciais — eles são configuração, não dados.
-- ──────────────────────────────────────────────────────────────
create or replace function public.limpar_dados()
returns void language plpgsql security definer as $$
begin
  delete from public.transacoes;
  delete from public.importacoes;
end;
$$;


-- ──────────────────────────────────────────────────────────────
-- 11. COLUNAS EXTRAS: loja e cnpj (idempotente — seguro rodar mais de uma vez)
-- ──────────────────────────────────────────────────────────────
alter table public.contas add column if not exists loja text not null default '';
alter table public.contas add column if not exists cnpj text not null default '';


-- ──────────────────────────────────────────────────────────────
-- 12. SEED — todas as contas (banco novo/vazio)
--     Execute apenas uma vez, após criar as tabelas.
--     Se já tiver contas cadastradas, use a seção 13 abaixo.
--
--  FÓRMULA DO ACCTID (campo "conta"):
--    Santander: agência (4 dig) + conta sem hífen (9 dig) = 13 dígitos
--               Ex: AG 0815, CONTA 13001904-2  →  0815 + 130019042 = '0815130019042'
--    Itaú:      agência (4 dig) + conta sem hífen (6 dig) = 10 dígitos
--               Ex: AG 8090, CONTA 97276-4     →  8090 + 972764   = '8090972764'
--
--  MARCAS e cores no dashboard (CSS var --c-{slug}):
--    'Caminito Parrilla'  → --c-caminito   (#10B981)
--    'Nazo Japanese Food' → --c-nazo       (#8B5CF6)
--    'Caju'               → --c-caju       (#E8430A)   ← Boteco Caju Limão
--    'Foster Burguer'     → --c-foster     (#3B82F6)
--    'Responsa Bar'       → --c-responsa   (#06B6D4)
--    'CPD'                → --c-cpd        (#EC4899)
--    'Holding - Fermult'  → --c-fermult    (#0EA5E9)
--    'Holding - Cajupar'  → --c-cajupar-h  (#F97316)
-- ──────────────────────────────────────────────────────────────
insert into public.contas (loja, empresa, marca, cnpj, banco, agencia, conta, saldo_inicial) values

  -- ════════════════════════════════════════════════════════════
  --  SANTANDER  (BANKID 033)
  -- ════════════════════════════════════════════════════════════

  -- ── Grupo Fermult  (CNPJ 35.631.524) ─────────────────────────────────────
  ('MULT 01', 'CPD - Caminito Parrilla',          'CPD',                '35.631.524/0001-65', 'Santander', '3739', '3739130046204', 0),
  ('MULT 02', 'Nazo Japanese Food - Goiânia',     'Nazo Japanese Food', '35.631.524/0002-46', 'Santander', '3739', '3739130049410', 0),
  ('MULT 03', 'Caminito Parrilla - Sudoeste',     'Caminito Parrilla',  '35.631.524/0003-27', 'Santander', '3739', '3739130049427', 0),
  ('MULT 05', 'Caminito Parrilla - Asa Norte',    'Caminito Parrilla',  '35.631.524/0005-99', 'Santander', '3739', '3739130058542', 0),
  ('MULT 07', 'Holding - Fermult',                'Holding - Fermult',  '35.631.524/0007-50', 'Santander', '3739', '3739130063333', 0),
  ('MULT 12', 'Caminito Parrilla - Águas Claras', 'Caminito Parrilla',  '35.631.524/0012-18', 'Santander', '3739', '3739130065782', 0),
  ('MULT 14', 'Caminito Parrilla - Asa Sul',      'Caminito Parrilla',  '35.631.524/0014-80', 'Santander', '3739', '3739130066673', 0),

  -- ── Nazo Japanese Food  (CNPJ 21.131.221) ────────────────────────────────
  ('NFE 01', 'Nazo Japanese Food - Asa Sul',      'Nazo Japanese Food', '21.131.221/0001-79', 'Santander', '0815', '0815130009153', 0),
  ('NFE 03', 'Nazo Japanese Food - Águas Claras', 'Nazo Japanese Food', '21.131.221/0003-30', 'Santander', '3739', '3739130067399', 0),
  ('NFE 04', 'Nazo Japanese Food - Sudoeste',     'Nazo Japanese Food', '21.131.221/0004-11', 'Santander', '3739', '3739130067423', 0),
  ('NFE 05', 'CPD - Nazo Japanese Food',          'CPD',                '21.131.221/0005-00', 'Santander', '3739', '3739130067715', 0),

  -- ── Boteco Caju Limão / Cajupar  (CNPJ 37.119.545 / 62.723.936) ─────────
  ('CAJU 01',    'Boteco Caju Limão - Asa Norte', 'Caju',              '37.119.545/0001-21', 'Santander', '0815', '0815130019042', 0),
  ('CAJU 03',    'Boteco Caju Limão - Sudoeste',  'Caju',              '37.119.545/0003-93', 'Santander', '0815', '0815130019035', 0),
  ('CAJU ITAIM', 'Boteco Caju Limão - Itaim SP',  'Caju',              '62.723.936/0001-06', 'Santander', '0815', '0815130019176', 0),
  ('CAJUPAR',    'Holding - Cajupar',              'Holding - Cajupar', '37.119.545/0004-74', 'Santander', '3441', '3441130032520', 0),

  -- ── Foster's Burger / Responsa  (CNPJ 37.492.271 / 34.492.271) ──────────
  ('RESPONSA',   'Bar Responsa',                   'Responsa Bar',  '37.492.271/0001-11', 'Santander', '0815', '0815130019073', 0),
  ('FB01 - ASS', 'Foster''s Burger - Asa Sul',     'Foster Burguer','37.492.271/0003-83', 'Santander', '0815', '0815130019097', 0),
  ('FB02 - BOS', 'Foster''s Burger - Bosque',      'Foster Burguer','37.492.271/0002-00', 'Santander', '0815', '0815130019080', 0),
  ('FB03 - AC',  'Foster''s Burger - Águas Claras','Foster Burguer','37.492.271/0005-45', 'Santander', '0815', '0815130019107', 0),
  ('FB04 - SIG', 'Foster''s Burger - Sudoeste',    'Foster Burguer','34.492.271/0006-26', 'Santander', '0815', '0815130019114', 0),
  ('FB05 - ANS', 'Foster''s Burger - Asa Norte',   'Foster Burguer','34.492.271/0007-07', 'Santander', '0815', '0815130019121', 0),

  -- ════════════════════════════════════════════════════════════
  --  ITAÚ  (BANKID 0341)
  -- ════════════════════════════════════════════════════════════

  -- ── Grupo Fermult  (CNPJ 35.631.524) ─────────────────────────────────────
  ('MULT 02', 'Nazo Japanese Food - Goiânia',     'Nazo Japanese Food', '35.631.524/0002-46', 'Itaú', '8090', '8090972764', 0),
  ('MULT 03', 'Caminito Parrilla - Sudoeste',     'Caminito Parrilla',  '35.631.524/0003-27', 'Itaú', '8090', '8090972756', 0),
  ('MULT 05', 'Caminito Parrilla - Asa Norte',    'Caminito Parrilla',  '35.631.524/0005-99', 'Itaú', '8090', '8090972749', 0),
  ('MULT 12', 'Caminito Parrilla - Águas Claras', 'Caminito Parrilla',  '35.631.524/0012-18', 'Itaú', '8090', '8090972723', 0),
  ('MULT 14', 'Caminito Parrilla - Asa Sul',      'Caminito Parrilla',  '35.631.524/0014-80', 'Itaú', '8090', '8090972715', 0),

  -- ── Nazo Japanese Food  (CNPJ 21.131.221) ────────────────────────────────
  ('NFE 01', 'Nazo Japanese Food - Asa Sul',      'Nazo Japanese Food', '21.131.221/0001-79', 'Itaú', '8090', '8090972699', 0),
  ('NFE 03', 'Nazo Japanese Food - Águas Claras', 'Nazo Japanese Food', '21.131.221/0003-30', 'Itaú', '8090', '8090972673',  0),
  ('NFE 04', 'Nazo Japanese Food - Sudoeste',     'Nazo Japanese Food', '21.131.221/0004-11', 'Itaú', '8090', '8090972657', 0),

  -- ── Boteco Caju Limão  (CNPJ 37.119.545) ────────────────────────────────
  ('CAJU 01', 'Boteco Caju Limão - Asa Norte',    'Caju',              '37.119.545/0001-21', 'Itaú', '4147', '4147984209', 0),
  ('CAJU 03', 'Boteco Caju Limão - Sudoeste',     'Caju',              '37.119.545/0003-93', 'Itaú', '4147', '4147984217', 0),
  -- CAJU ITAIM/SP: sem conta Itaú na planilha fornecida

  -- ── Foster's Burger / Responsa  (CNPJ 37.492.271 / 34.492.271) ──────────
  ('RESPONSA',   'Bar Responsa',                   'Responsa Bar',  '37.492.271/0001-11', 'Itaú', '6557', '6557984587', 0),
  ('FB01 - ASS', 'Foster''s Burger - Asa Sul',     'Foster Burguer','37.492.271/0003-83', 'Itaú', '1670', '1670998028', 0),
  ('FB02 - BOS', 'Foster''s Burger - Bosque',      'Foster Burguer','37.492.271/0002-00', 'Itaú', '1670', '1670998093', 0),
  ('FB03 - AC',  'Foster''s Burger - Águas Claras','Foster Burguer','37.492.271/0005-45', 'Itaú', '6557', '6557979264', 0),
  ('FB04 - SIG', 'Foster''s Burger - Sudoeste',    'Foster Burguer','34.492.271/0006-26', 'Itaú', '4147', '4147983649', 0),
  ('FB05 - ANS', 'Foster''s Burger - Asa Norte',   'Foster Burguer','34.492.271/0007-07', 'Itaú', '4739', '4739989467', 0)

on conflict do nothing;


-- ──────────────────────────────────────────────────────────────
-- 13. MIGRAÇÃO — banco já existente com nomes antigos
--     Renomeia todas as contas para os nomes corretos da planilha
--     e adiciona as que ainda não existem.
--     Identificação pelo ACCTID (campo "conta") — não depende do nome antigo.
-- ──────────────────────────────────────────────────────────────

-- 13a. Garante colunas loja/cnpj (caso seção 11 não tenha rodado)
alter table public.contas add column if not exists loja text not null default '';
alter table public.contas add column if not exists cnpj text not null default '';

-- 13b. Desativa placeholders sem número de conta (dados obsoletos)
update public.contas set ativo = false
  where (conta = '' or conta is null) and ativo = true;

-- 13c. Atualiza nome/marca/loja/cnpj das contas existentes pelo ACCTID ────────
-- SANTANDER
update public.contas set loja='MULT 01', empresa='CPD - Caminito Parrilla',          marca='CPD',                cnpj='35.631.524/0001-65', agencia='3739' where banco='Santander' and conta='3739130046204';
update public.contas set loja='MULT 02', empresa='Nazo Japanese Food - Goiânia',     marca='Nazo Japanese Food', cnpj='35.631.524/0002-46', agencia='3739' where banco='Santander' and conta='3739130049410';
update public.contas set loja='MULT 03', empresa='Caminito Parrilla - Sudoeste',     marca='Caminito Parrilla',  cnpj='35.631.524/0003-27', agencia='3739' where banco='Santander' and conta='3739130049427';
update public.contas set loja='MULT 05', empresa='Caminito Parrilla - Asa Norte',    marca='Caminito Parrilla',  cnpj='35.631.524/0005-99', agencia='3739' where banco='Santander' and conta='3739130058542';
update public.contas set loja='MULT 07', empresa='Holding - Fermult',                marca='Holding - Fermult',  cnpj='35.631.524/0007-50', agencia='3739' where banco='Santander' and conta='3739130063333';
update public.contas set loja='MULT 12', empresa='Caminito Parrilla - Águas Claras', marca='Caminito Parrilla',  cnpj='35.631.524/0012-18', agencia='3739' where banco='Santander' and conta='3739130065782';
update public.contas set loja='MULT 14', empresa='Caminito Parrilla - Asa Sul',      marca='Caminito Parrilla',  cnpj='35.631.524/0014-80', agencia='3739' where banco='Santander' and conta='3739130066673';
update public.contas set loja='NFE 01',  empresa='Nazo Japanese Food - Asa Sul',     marca='Nazo Japanese Food', cnpj='21.131.221/0001-79', agencia='0815' where banco='Santander' and conta='0815130009153';
update public.contas set loja='NFE 03',  empresa='Nazo Japanese Food - Águas Claras',marca='Nazo Japanese Food', cnpj='21.131.221/0003-30', agencia='3739' where banco='Santander' and conta='3739130067399';
update public.contas set loja='NFE 04',  empresa='Nazo Japanese Food - Sudoeste',    marca='Nazo Japanese Food', cnpj='21.131.221/0004-11', agencia='3739' where banco='Santander' and conta='3739130067423';
update public.contas set loja='NFE 05',  empresa='CPD - Nazo Japanese Food',         marca='CPD',                cnpj='21.131.221/0005-00', agencia='3739' where banco='Santander' and conta='3739130067715';
update public.contas set loja='CAJU 01',    empresa='Boteco Caju Limão - Asa Norte', marca='Caju',              cnpj='37.119.545/0001-21', agencia='0815' where banco='Santander' and conta='0815130019042';
update public.contas set loja='CAJU 03',    empresa='Boteco Caju Limão - Sudoeste',  marca='Caju',              cnpj='37.119.545/0003-93', agencia='0815' where banco='Santander' and conta='0815130019035';
update public.contas set loja='CAJU ITAIM', empresa='Boteco Caju Limão - Itaim SP',  marca='Caju',              cnpj='62.723.936/0001-06', agencia='0815' where banco='Santander' and conta='0815130019176';
update public.contas set loja='CAJUPAR',    empresa='Holding - Cajupar',              marca='Holding - Cajupar', cnpj='37.119.545/0004-74', agencia='3441' where banco='Santander' and conta='3441130032520';
update public.contas set loja='RESPONSA',   empresa='Bar Responsa',                   marca='Responsa Bar',      cnpj='37.492.271/0001-11', agencia='0815' where banco='Santander' and conta='0815130019073';
update public.contas set loja='FB01 - ASS', empresa='Foster''s Burger - Asa Sul',    marca='Foster Burguer',    cnpj='37.492.271/0003-83', agencia='0815' where banco='Santander' and conta='0815130019097';
update public.contas set loja='FB02 - BOS', empresa='Foster''s Burger - Bosque',     marca='Foster Burguer',    cnpj='37.492.271/0002-00', agencia='0815' where banco='Santander' and conta='0815130019080';
update public.contas set loja='FB03 - AC',  empresa='Foster''s Burger - Águas Claras',marca='Foster Burguer',   cnpj='37.492.271/0005-45', agencia='0815' where banco='Santander' and conta='0815130019107';
update public.contas set loja='FB04 - SIG', empresa='Foster''s Burger - Sudoeste',   marca='Foster Burguer',    cnpj='34.492.271/0006-26', agencia='0815' where banco='Santander' and conta='0815130019114';
update public.contas set loja='FB05 - ANS', empresa='Foster''s Burger - Asa Norte',  marca='Foster Burguer',    cnpj='34.492.271/0007-07', agencia='0815' where banco='Santander' and conta='0815130019121';
-- ITAÚ
update public.contas set loja='MULT 02', empresa='Nazo Japanese Food - Goiânia',     marca='Nazo Japanese Food', cnpj='35.631.524/0002-46', agencia='8090' where banco='Itaú' and conta='8090972764';
update public.contas set loja='MULT 03', empresa='Caminito Parrilla - Sudoeste',     marca='Caminito Parrilla',  cnpj='35.631.524/0003-27', agencia='8090' where banco='Itaú' and conta='8090972756';
update public.contas set loja='MULT 05', empresa='Caminito Parrilla - Asa Norte',    marca='Caminito Parrilla',  cnpj='35.631.524/0005-99', agencia='8090' where banco='Itaú' and conta='8090972749';
update public.contas set loja='MULT 12', empresa='Caminito Parrilla - Águas Claras', marca='Caminito Parrilla',  cnpj='35.631.524/0012-18', agencia='8090' where banco='Itaú' and conta='8090972723';
update public.contas set loja='MULT 14', empresa='Caminito Parrilla - Asa Sul',      marca='Caminito Parrilla',  cnpj='35.631.524/0014-80', agencia='8090' where banco='Itaú' and conta='8090972715';
update public.contas set loja='NFE 01',  empresa='Nazo Japanese Food - Asa Sul',     marca='Nazo Japanese Food', cnpj='21.131.221/0001-79', agencia='8090' where banco='Itaú' and conta='8090972699';
update public.contas set loja='NFE 03',  empresa='Nazo Japanese Food - Águas Claras',marca='Nazo Japanese Food', cnpj='21.131.221/0003-30', agencia='8090' where banco='Itaú' and conta='8090972673';
update public.contas set loja='NFE 04',  empresa='Nazo Japanese Food - Sudoeste',    marca='Nazo Japanese Food', cnpj='21.131.221/0004-11', agencia='8090' where banco='Itaú' and conta='8090972657';
update public.contas set loja='CAJU 01', empresa='Boteco Caju Limão - Asa Norte',    marca='Caju',              cnpj='37.119.545/0001-21', agencia='4147' where banco='Itaú' and conta='4147984209';
update public.contas set loja='CAJU 03', empresa='Boteco Caju Limão - Sudoeste',     marca='Caju',              cnpj='37.119.545/0003-93', agencia='4147' where banco='Itaú' and conta='4147984217';
update public.contas set loja='RESPONSA',   empresa='Bar Responsa',                   marca='Responsa Bar',      cnpj='37.492.271/0001-11', agencia='6557' where banco='Itaú' and conta='6557984587';
update public.contas set loja='FB01 - ASS', empresa='Foster''s Burger - Asa Sul',    marca='Foster Burguer',    cnpj='37.492.271/0003-83', agencia='1670' where banco='Itaú' and conta='1670998028';
update public.contas set loja='FB02 - BOS', empresa='Foster''s Burger - Bosque',     marca='Foster Burguer',    cnpj='37.492.271/0002-00', agencia='1670' where banco='Itaú' and conta='1670998093';
update public.contas set loja='FB03 - AC',  empresa='Foster''s Burger - Águas Claras',marca='Foster Burguer',   cnpj='37.492.271/0005-45', agencia='6557' where banco='Itaú' and conta='6557979264';
update public.contas set loja='FB04 - SIG', empresa='Foster''s Burger - Sudoeste',   marca='Foster Burguer',    cnpj='34.492.271/0006-26', agencia='4147' where banco='Itaú' and conta='4147983649';
update public.contas set loja='FB05 - ANS', empresa='Foster''s Burger - Asa Norte',  marca='Foster Burguer',    cnpj='34.492.271/0007-07', agencia='4739' where banco='Itaú' and conta='4739989467';

-- 13d. Insere contas que ainda não existem (identificadas pelo ACCTID) ─────────
insert into public.contas (loja, empresa, marca, cnpj, banco, agencia, conta, saldo_inicial)
select v.loja, v.empresa, v.marca, v.cnpj, v.banco, v.agencia, v.conta, 0
from (values
  -- Santander — novas
  ('MULT 03', 'Caminito Parrilla - Sudoeste',     'Caminito Parrilla',  '35.631.524/0003-27', 'Santander', '3739', '3739130049427'),
  ('MULT 12', 'Caminito Parrilla - Águas Claras', 'Caminito Parrilla',  '35.631.524/0012-18', 'Santander', '3739', '3739130065782'),
  ('MULT 14', 'Caminito Parrilla - Asa Sul',      'Caminito Parrilla',  '35.631.524/0014-80', 'Santander', '3739', '3739130066673'),
  ('NFE 03',  'Nazo Japanese Food - Águas Claras','Nazo Japanese Food', '21.131.221/0003-30', 'Santander', '3739', '3739130067399'),
  ('NFE 04',  'Nazo Japanese Food - Sudoeste',    'Nazo Japanese Food', '21.131.221/0004-11', 'Santander', '3739', '3739130067423'),
  ('CAJU 03',    'Boteco Caju Limão - Sudoeste',  'Caju',              '37.119.545/0003-93', 'Santander', '0815', '0815130019035'),
  ('CAJU ITAIM', 'Boteco Caju Limão - Itaim SP',  'Caju',              '62.723.936/0001-06', 'Santander', '0815', '0815130019176'),
  ('FB01 - ASS', 'Foster''s Burger - Asa Sul',    'Foster Burguer',    '37.492.271/0003-83', 'Santander', '0815', '0815130019097'),
  ('FB03 - AC',  'Foster''s Burger - Águas Claras','Foster Burguer',   '37.492.271/0005-45', 'Santander', '0815', '0815130019107'),
  ('FB04 - SIG', 'Foster''s Burger - Sudoeste',   'Foster Burguer',    '34.492.271/0006-26', 'Santander', '0815', '0815130019114'),
  ('FB05 - ANS', 'Foster''s Burger - Asa Norte',  'Foster Burguer',    '34.492.271/0007-07', 'Santander', '0815', '0815130019121'),
  -- Itaú — novas
  ('MULT 12', 'Caminito Parrilla - Águas Claras', 'Caminito Parrilla',  '35.631.524/0012-18', 'Itaú', '8090', '8090972723'),
  ('MULT 14', 'Caminito Parrilla - Asa Sul',      'Caminito Parrilla',  '35.631.524/0014-80', 'Itaú', '8090', '8090972715'),
  ('NFE 01',  'Nazo Japanese Food - Asa Sul',     'Nazo Japanese Food', '21.131.221/0001-79', 'Itaú', '8090', '8090972699'),
  ('NFE 03',  'Nazo Japanese Food - Águas Claras','Nazo Japanese Food', '21.131.221/0003-30', 'Itaú', '8090', '8090972673'),
  ('NFE 04',  'Nazo Japanese Food - Sudoeste',    'Nazo Japanese Food', '21.131.221/0004-11', 'Itaú', '8090', '8090972657'),
  ('CAJU 01', 'Boteco Caju Limão - Asa Norte',    'Caju',              '37.119.545/0001-21', 'Itaú', '4147', '4147984209'),
  ('CAJU 03', 'Boteco Caju Limão - Sudoeste',     'Caju',              '37.119.545/0003-93', 'Itaú', '4147', '4147984217'),
  ('RESPONSA',   'Bar Responsa',                   'Responsa Bar',      '37.492.271/0001-11', 'Itaú', '6557', '6557984587'),
  ('FB01 - ASS', 'Foster''s Burger - Asa Sul',    'Foster Burguer',    '37.492.271/0003-83', 'Itaú', '1670', '1670998028'),
  ('FB02 - BOS', 'Foster''s Burger - Bosque',     'Foster Burguer',    '37.492.271/0002-00', 'Itaú', '1670', '1670998093'),
  ('FB03 - AC',  'Foster''s Burger - Águas Claras','Foster Burguer',   '37.492.271/0005-45', 'Itaú', '6557', '6557979264'),
  ('FB04 - SIG', 'Foster''s Burger - Sudoeste',   'Foster Burguer',    '34.492.271/0006-26', 'Itaú', '4147', '4147983649'),
  ('FB05 - ANS', 'Foster''s Burger - Asa Norte',  'Foster Burguer',    '34.492.271/0007-07', 'Itaú', '4739', '4739989467')
) as v(loja, empresa, marca, cnpj, banco, agencia, conta)
where not exists (
  select 1 from public.contas c where c.banco = v.banco and c.conta = v.conta
);


-- ──────────────────────────────────────────────────────────────
-- 14. COMO ADICIONAR UMA NOVA CONTA (template)
-- ──────────────────────────────────────────────────────────────
--
--  Passo 1 — Calcule o ACCTID:
--    Santander: agência (4 dig) + conta sem hífen (9 dig) = 13 dígitos
--               Ex: AG 0815, CONTA 13001904-2 → '0815130019042'
--    Itaú:      agência (4 dig) + conta sem hífen (6 dig) = 10 dígitos
--               Ex: AG 8090, CONTA 97276-4 → '8090972764'
--
--  Passo 2 — Execute o INSERT abaixo (substitua os valores):
--
--   insert into public.contas (loja, empresa, marca, cnpj, banco, agencia, conta, saldo_inicial)
--   values (
--     'LOJA XX',                      -- código da loja  (ex: 'FB06 - TAG')
--     'Nome Completo da Empresa',     -- empresa         (ex: 'Foster''s Burger - Taguatinga')
--     'Foster Burguer',               -- marca           (ver lista na seção 12)
--     '00.000.000/0000-00',           -- CNPJ
--     'Santander',                    -- banco: 'Santander' ou 'Itaú'
--     '0815',                         -- agência (4 dígitos)
--     '0815130019999',                -- ACCTID calculado no Passo 1
--     0                               -- saldo_inicial (ajuste depois em Contas → editar)
--   );
--
--  Passo 3 — Recarregue o dashboard (F5).
--


-- ══════════════════════════════════════════════════════════════
--  CONCLUÍDO — execute o arquivo acima e depois:
--  1. Vá em Authentication → Settings → Email auth
--     → desative "Confirm email" (para uso interno sem e-mail de confirmação)
--  2. Abra o index.html no navegador
--  3. Na primeira abertura, crie o administrador inicial
--  4. Configure o saldo inicial de cada conta em Contas → ícone de edição
-- ══════════════════════════════════════════════════════════════
