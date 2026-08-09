-- ══════════════════════════════════════════════════════════════
--  DIAGNÓSTICO — encontra contas que podem estar pegando OFX
--  de outras contas por engano (match frouxo).
--  Rode no SQL Editor do Supabase.
-- ══════════════════════════════════════════════════════════════

-- 1) Contas sem ACCTID cadastrado (campo "conta" vazio)
--    Essas contas vão pegar QUALQUER OFX da mesma agência
--    via passo 3 do match (se forem a única naquela agência).
select '🔴 SEM ACCTID' as problema, id, banco, agencia, conta, empresa, ativo
from public.contas
where (conta is null or conta = '' or length(regexp_replace(conta,'\D','','g')) < 5)
  and ativo = true
order by banco, agencia;

-- 2) Contas com ACCTID CURTO (< 13 dígitos Santander, < 10 Itaú)
--    Match endsWith pode roubar OFX de outras contas que terminam
--    com esses mesmos dígitos.
select '🟡 ACCTID CURTO' as problema, id, banco, agencia, conta,
       length(regexp_replace(conta,'\D','','g')) as digitos,
       empresa, ativo
from public.contas
where ativo = true
  and conta is not null and conta <> ''
  and (
    (banco ilike '%santander%' and length(regexp_replace(conta,'\D','','g')) < 13)
    or
    (banco ilike '%ita%'       and length(regexp_replace(conta,'\D','','g')) < 10)
  )
order by banco, agencia, conta;

-- 3) ACCTIDs DUPLICADOS (mesma conta cadastrada 2x — match pega a primeira)
select '🔴 DUPLICADO' as problema,
       banco, regexp_replace(conta,'\D','','g') as acctid_normalizado,
       count(*) as qtd,
       string_agg(id::text || ' (' || empresa || ')', ', ') as contas
from public.contas
where ativo = true and conta is not null and conta <> ''
group by banco, regexp_replace(conta,'\D','','g')
having count(*) > 1;

-- 4) ACCTIDs onde um TERMINA com o outro (endsWith ambíguo)
--    Ex: conta A = '3739130046204' e conta B = '46204' →
--    OFX da A iria pra B no passo 2 do match.
with norm as (
  select id, banco, empresa, regexp_replace(conta,'\D','','g') as cd
  from public.contas
  where ativo = true and conta is not null and conta <> ''
)
select '🟠 ENDS-WITH AMBÍGUO' as problema,
       a.banco, a.id as conta_a_id, a.empresa as conta_a, a.cd as acctid_a,
       b.id as conta_b_id, b.empresa as conta_b, b.cd as acctid_b
from norm a
join norm b on a.banco = b.banco and a.id <> b.id
            and length(a.cd) > length(b.cd)
            and a.cd like '%' || b.cd
order by a.banco;

-- 5) Distribuição de transações por conta — se uma conta tem
--    MUITO mais que as outras, talvez esteja roubando OFX alheios.
select '📊 TX POR CONTA' as info, c.id, c.banco, c.agencia, c.conta,
       c.empresa, count(t.id) as qtd_tx,
       round(sum(t.valor)::numeric, 2) as soma_valores
from public.contas c
left join public.transacoes_view t on t.conta_id = c.id
where c.ativo = true
group by c.id, c.banco, c.agencia, c.conta, c.empresa
order by qtd_tx desc;

-- 6) Top 20 transações com descrição duplicada em CONTAS DIFERENTES
--    Pode indicar que o mesmo OFX foi roteado pra mais de uma conta.
select '🟠 DESC DUPLICADA EM CONTAS DIFERENTES' as problema,
       t.descricao, t.data, t.valor, t.fitid,
       string_agg(distinct c.empresa, ' | ') as contas
from public.transacoes_view t
join public.contas c on c.id = t.conta_id
group by t.descricao, t.data, t.valor, t.fitid
having count(distinct t.conta_id) > 1
order by t.data desc
limit 20;
