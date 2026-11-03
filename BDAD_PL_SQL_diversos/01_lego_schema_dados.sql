-- =====================================================================
-- Parte 1 - Loja de brinquedos (Lego)
-- 01 - Esquema e dados
-- Executar ligado à base de dados "lego".
--   psql -U postgres -d lego -f 01_lego_schema_dados.sql
-- (no pgAdmin: Query Tool sobre a base "lego")
--
-- Convenções de interpretação:
--   comprador = cliente
--   vendedor  = loja
--   venda/compra = encomenda (liga loja, cliente e lista de peças)
--   desconto  = percentagem (10 = 10%)
-- =====================================================================

-- ---------------------------- catálogo -------------------------------
create table peca (peca_id int2, nome text);
create table peca_cor (peca_cor_id int2, peca_id int2, cor text);
create table conjunto (conjunto_id int2, nome text, ano int2);
create table peca_conjunto (conjunto_id int2, peca_cor_id int2, qtd int2);
create table loja (loja_id int2, nome text);
create table loja_peca (loja_id int2, peca_cor_id int2, qtd int2,
                        estado char(1), custo int2); -- N(ovo) U(sado)
create table encomenda (encomenda_id int2, loja_id int2, cliente_id int2,
                        lista_id int2, data date, desconto int2);
create table cliente (cliente_id int2, nome text);
create table lista (lista_id int2, peca_cor_id int2, qtd int2,
                    estado char(1), custo int2);

-- ------------------------ dados da ficha -----------------------------
insert into peca (peca_id, nome) values (1, 'cubo');
insert into peca (peca_id, nome) values (2, 'placa');
insert into peca (peca_id, nome) values (3, 'porta');

insert into peca_cor (peca_cor_id, peca_id, cor) values (10, 1, 'verde');
insert into peca_cor (peca_cor_id, peca_id, cor) values (20, 1, 'vermelha');
insert into peca_cor (peca_cor_id, peca_id, cor) values (30, 2, 'azul');
insert into peca_cor (peca_cor_id, peca_id, cor) values (40, 2, 'amarela');
insert into peca_cor (peca_cor_id, peca_id, cor) values (50, 3, 'castanha');
insert into peca_cor (peca_cor_id, peca_id, cor) values (60, 3, 'preta');

insert into conjunto (conjunto_id, nome, ano) values (1000, 'Castelo', 1990);

-- NOTA: o enunciado usa conjunto_id = 100 aqui, mas o conjunto existente
-- tem id 1000 (provável gralha). Mantido como no enunciado; não há FK.
insert into peca_conjunto (conjunto_id, peca_cor_id, qtd) values (100, 10, 2);

insert into loja (loja_id, nome) values (1000, 'Os cubos');
insert into loja (loja_id, nome) values (2000, 'Legolândia');
insert into loja (loja_id, nome) values (3000, 'Sem sorte');

insert into cliente (cliente_id, nome) values (101, 'Darth Vader');
insert into cliente (cliente_id, nome) values (102, 'Luke Skywalker');

insert into loja_peca (loja_id, peca_cor_id, qtd, estado, custo)
values (1000, 10, 100, 'u', 2);

insert into encomenda (encomenda_id, loja_id, cliente_id, lista_id, data, desconto)
values (1, 1000, 101, 11, '2009-11-01', 10);
insert into lista (lista_id, peca_cor_id, qtd, estado, custo) values (11, 10, 1, 'u', 2);
insert into lista (lista_id, peca_cor_id, qtd, estado, custo) values (11, 20, 1, 'u', 3);

insert into encomenda (encomenda_id, loja_id, cliente_id, lista_id, data, desconto)
values (2, 2000, 101, 12, '2009-12-01', 10);
insert into lista (lista_id, peca_cor_id, qtd, estado, custo) values (12, 10, 1, 'u', 2);
insert into lista (lista_id, peca_cor_id, qtd, estado, custo) values (12, 20, 1, 'u', 3);

-- ----------------- dados EXTRA (não estão no enunciado) ---------------
-- Acrescentados para as consultas devolverem resultados em todas as
-- alíneas (Junho de 2009, Novembro em 2 lojas, cliente sem compras...).
insert into cliente (cliente_id, nome) values (103, 'Han Solo');  -- sem compras

-- Junho de 2009
insert into encomenda values (3, 1000, 102, 13, '2009-06-10', 0);
insert into lista values (13, 10, 2, 'n', 2);
insert into encomenda values (4, 2000, 102, 14, '2009-06-15', 5);
insert into lista values (14, 20, 1, 'u', 3);
insert into encomenda values (7, 1000, 101, 17, '2009-06-20', 0);
insert into lista values (17, 10, 1, 'u', 2);

-- Novembro de 2009, cliente 102 em duas lojas diferentes
insert into encomenda values (5, 1000, 102, 15, '2009-11-05', 0);
insert into lista values (15, 10, 1, 'n', 2);
insert into encomenda values (6, 2000, 102, 16, '2009-11-20', 0);
insert into lista values (16, 20, 1, 'n', 3);

-- ---------------------------- vista auxiliar -------------------------
-- Total de cada encomenda = soma(qtd * custo) das linhas da lista,
-- já com o desconto (em %) aplicado.
create view encomenda_total as
select e.encomenda_id,
       e.loja_id,
       e.cliente_id,
       e.data,
       e.desconto,
       sum(l.qtd * l.custo)                                  as total_bruto,
       round(sum(l.qtd * l.custo) * (100 - e.desconto) / 100.0, 2) as total
from encomenda e
join lista l on l.lista_id = e.lista_id
group by e.encomenda_id, e.loja_id, e.cliente_id, e.data, e.desconto;
