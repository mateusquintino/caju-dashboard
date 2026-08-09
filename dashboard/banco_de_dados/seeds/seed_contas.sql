-- ══════════════════════════════════════════════════════════════
--  SEED v2 — Cadastro de contas com agência e conta SEPARADAS
--  Rode APÓS o TRUNCATE de contas/transacoes.
--
--  Mudança na semântica dos campos:
--    agencia → 4 dígitos da agência                    (ex: '3739')
--    conta   → SÓ o número da conta, em formato        (ex: '13004620-4')
--              amigável (com hífen quando o banco usa)
--
--  O ACCTID que o OFX traz (agência + conta sem hífen)
--  é calculado internamente pelo dashboard. Não precisa
--  ser digitado.
-- ══════════════════════════════════════════════════════════════

insert into public.contas (loja, empresa, marca, cnpj, banco, agencia, conta, saldo_inicial) values

  -- ════════════════════════════════════════════════════════════
  --  SANTANDER  (BANKID 033)
  -- ════════════════════════════════════════════════════════════

  -- ── Grupo Fermult  (CNPJ 35.631.524) ─────────────────────────
  ('MULT 01', 'CPD - Caminito Parrilla',          'CPD',                '35.631.524/0001-65', 'Santander', '3739', '13004620-4', 0),
  ('MULT 02', 'Nazo Japanese Food - Goiânia',     'Nazo Japanese Food', '35.631.524/0002-46', 'Santander', '3739', '13004941-0', 0),
  ('MULT 03', 'Caminito Parrilla - Sudoeste',     'Caminito Parrilla',  '35.631.524/0003-27', 'Santander', '3739', '13004942-7', 0),
  ('MULT 05', 'Caminito Parrilla - Asa Norte',    'Caminito Parrilla',  '35.631.524/0005-99', 'Santander', '3739', '13005854-2', 0),
  ('MULT 07', 'Holding - Fermult',                'Holding - Fermult',  '35.631.524/0007-50', 'Santander', '3739', '13006333-3', 0),
  ('MULT 12', 'Caminito Parrilla - Águas Claras', 'Caminito Parrilla',  '35.631.524/0012-18', 'Santander', '3739', '13006578-2', 0),
  ('MULT 14', 'Caminito Parrilla - Asa Sul',      'Caminito Parrilla',  '35.631.524/0014-80', 'Santander', '3739', '13006667-3', 0),

  -- ── Nazo Japanese Food  (CNPJ 21.131.221) ────────────────────
  ('NFE 01', 'Nazo Japanese Food - Asa Sul',      'Nazo Japanese Food', '21.131.221/0001-79', 'Santander', '0815', '13000915-3', 0),
  ('NFE 03', 'Nazo Japanese Food - Águas Claras', 'Nazo Japanese Food', '21.131.221/0003-30', 'Santander', '3739', '13006739-9', 0),
  ('NFE 04', 'Nazo Japanese Food - Sudoeste',     'Nazo Japanese Food', '21.131.221/0004-11', 'Santander', '3739', '13006742-3', 0),
  ('NFE 05', 'CPD - Nazo Japanese Food',          'CPD',                '21.131.221/0005-00', 'Santander', '3739', '13006771-5', 0),

  -- ── Boteco Caju Limão / Cajupar ──────────────────────────────
  ('CAJU 01',    'Boteco Caju Limão - Asa Norte', 'Caju',              '37.119.545/0001-21', 'Santander', '0815', '13001904-2', 0),
  ('CAJU 03',    'Boteco Caju Limão - Sudoeste',  'Caju',              '37.119.545/0003-93', 'Santander', '0815', '13001903-5', 0),
  ('CAJU ITAIM', 'Boteco Caju Limão - Itaim SP',  'Caju',              '62.723.936/0001-06', 'Santander', '0815', '13001917-6', 0),
  ('CAJUPAR',    'Holding - Cajupar',              'Holding - Cajupar', '37.119.545/0004-74', 'Santander', '3441', '13003252-0', 0),

  -- ── Foster's Burger / Responsa ───────────────────────────────
  ('RESPONSA',   'Bar Responsa',                   'Responsa Bar',  '37.492.271/0001-11', 'Santander', '0815', '13001907-3', 0),
  ('FB01 - ASS', 'Foster''s Burger - Asa Sul',     'Foster Burguer','37.492.271/0003-83', 'Santander', '0815', '13001909-7', 0),
  ('FB02 - BOS', 'Foster''s Burger - Bosque',      'Foster Burguer','37.492.271/0002-00', 'Santander', '0815', '13001908-0', 0),
  ('FB03 - AC',  'Foster''s Burger - Águas Claras','Foster Burguer','37.492.271/0005-45', 'Santander', '0815', '13001910-7', 0),
  ('FB04 - SIG', 'Foster''s Burger - Sudoeste',    'Foster Burguer','34.492.271/0006-26', 'Santander', '0815', '13001911-4', 0),
  ('FB05 - ANS', 'Foster''s Burger - Asa Norte',   'Foster Burguer','34.492.271/0007-07', 'Santander', '0815', '13001912-1', 0),

  -- ════════════════════════════════════════════════════════════
  --  ITAÚ  (BANKID 0341)
  -- ════════════════════════════════════════════════════════════

  -- ── Grupo Fermult ────────────────────────────────────────────
  ('MULT 02', 'Nazo Japanese Food - Goiânia',     'Nazo Japanese Food', '35.631.524/0002-46', 'Itaú', '8090', '97276-4', 0),
  ('MULT 03', 'Caminito Parrilla - Sudoeste',     'Caminito Parrilla',  '35.631.524/0003-27', 'Itaú', '8090', '97275-6', 0),
  ('MULT 05', 'Caminito Parrilla - Asa Norte',    'Caminito Parrilla',  '35.631.524/0005-99', 'Itaú', '8090', '97274-9', 0),
  ('MULT 12', 'Caminito Parrilla - Águas Claras', 'Caminito Parrilla',  '35.631.524/0012-18', 'Itaú', '8090', '97272-3', 0),
  ('MULT 14', 'Caminito Parrilla - Asa Sul',      'Caminito Parrilla',  '35.631.524/0014-80', 'Itaú', '8090', '97271-5', 0),

  -- ── Nazo Japanese Food ───────────────────────────────────────
  ('NFE 01', 'Nazo Japanese Food - Asa Sul',      'Nazo Japanese Food', '21.131.221/0001-79', 'Itaú', '8090', '97269-9', 0),
  ('NFE 03', 'Nazo Japanese Food - Águas Claras', 'Nazo Japanese Food', '21.131.221/0003-30', 'Itaú', '8090', '97267-3', 0),
  ('NFE 04', 'Nazo Japanese Food - Sudoeste',     'Nazo Japanese Food', '21.131.221/0004-11', 'Itaú', '8090', '97265-7', 0),

  -- ── Boteco Caju Limão ────────────────────────────────────────
  ('CAJU 01', 'Boteco Caju Limão - Asa Norte',    'Caju',              '37.119.545/0001-21', 'Itaú', '4147', '98420-9', 0),
  ('CAJU 03', 'Boteco Caju Limão - Sudoeste',     'Caju',              '37.119.545/0003-93', 'Itaú', '4147', '98421-7', 0),

  -- ── Foster's Burger / Responsa ───────────────────────────────
  ('RESPONSA',   'Bar Responsa',                   'Responsa Bar',  '37.492.271/0001-11', 'Itaú', '6557', '98458-7', 0),
  ('FB01 - ASS', 'Foster''s Burger - Asa Sul',     'Foster Burguer','37.492.271/0003-83', 'Itaú', '1670', '99802-8', 0),
  ('FB02 - BOS', 'Foster''s Burger - Bosque',      'Foster Burguer','37.492.271/0002-00', 'Itaú', '1670', '99809-3', 0),
  ('FB03 - AC',  'Foster''s Burger - Águas Claras','Foster Burguer','37.492.271/0005-45', 'Itaú', '6557', '97926-4', 0),
  ('FB04 - SIG', 'Foster''s Burger - Sudoeste',    'Foster Burguer','34.492.271/0006-26', 'Itaú', '4147', '98364-9', 0),
  ('FB05 - ANS', 'Foster''s Burger - Asa Norte',   'Foster Burguer','34.492.271/0007-07', 'Itaú', '4739', '98946-7', 0);

-- Confirmação
select count(*) as contas_cadastradas, banco
from public.contas group by banco order by banco;
