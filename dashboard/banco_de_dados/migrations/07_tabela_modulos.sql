-- ══════════════════════════════════════════════════════════════
--  Migração 07 — Tabela de módulos (permissões dinâmicas)
--
--  Cria a tabela public.modulos, que alimenta a lista "Permissões
--  por módulo" na tela de Gestão de Usuários. Assim, todo módulo
--  novo cadastrado aqui aparece automaticamente no cadastro de
--  usuários e já entra no nível de permissão do grupo de cada um.
--
--  Já aplicada no projeto via MCP. Mantida aqui para versionamento.
-- ══════════════════════════════════════════════════════════════

create table if not exists public.modulos (
  id         bigint generated always as identity primary key,
  nome       text not null unique,
  ordem      int  not null default 0,
  ativo      boolean not null default true,
  created_at timestamptz default now()
);

alter table public.modulos enable row level security;

-- Qualquer usuário autenticado pode ler a lista de módulos
drop policy if exists "modulos_select_auth" on public.modulos;
create policy "modulos_select_auth" on public.modulos
  for select to authenticated using (true);

-- Apenas administradores podem criar/editar/remover módulos
drop policy if exists "modulos_admin_all" on public.modulos;
create policy "modulos_admin_all" on public.modulos
  for all to authenticated
  using      (exists (select 1 from public.profiles p where p.id = auth.uid() and p.role = 'admin'))
  with check (exists (select 1 from public.profiles p where p.id = auth.uid() and p.role = 'admin'));

-- Módulos iniciais (idempotente)
insert into public.modulos (nome, ordem) values
 ('Visão geral',1),('Fluxo de caixa',2),('Movimentações',3),('Contas bancárias',4),
 ('Tarifas',5),('Importar OFX',6),('Empréstimos',7),('Usuários',8)
on conflict (nome) do nothing;

-- ──────────────────────────────────────────────────────────────
--  Para adicionar um módulo novo depois, basta:
--    insert into public.modulos (nome, ordem) values ('Relatórios BI', 9);
--  Ele aparece sozinho no cadastro de usuários, no nível do grupo.
-- ──────────────────────────────────────────────────────────────
