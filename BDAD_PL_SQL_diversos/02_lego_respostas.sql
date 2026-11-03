-- =====================================================================
-- Parte 1 - Loja de brinquedos (Lego)
-- 02 - Respostas às questões 1.1 a 2.2
-- Pré-requisito: 01_lego_schema_dados.sql executado na base "lego".
--   psql -U postgres -d lego -f 02_lego_respostas.sql
-- comprador = cliente | vendedor = loja | compra/venda = encomenda
-- =====================================================================

-- 1.1 Quais os compradores com compras efectuadas?
-- Clientes que aparecem em pelo menos uma encomenda (EXISTS evita duplicados).
select c.cliente_id, c.nome
from cliente c
where exists (select 1 from encomenda e where e.cliente_id = c.cliente_id)
order by c.cliente_id;

-- 1.2 Quais os compradores que fizeram compras no mês de Novembro,
--     em mais do que um vendedor?
-- Filtra Novembro (de qualquer ano; acrescentar o ano se necessário),
-- agrupa por cliente e exige mais do que uma loja distinta.
select c.cliente_id, c.nome, count(distinct e.loja_id) as n_lojas
from encomenda e
join cliente c on c.cliente_id = e.cliente_id
where extract(month from e.data) = 11
group by c.cliente_id, c.nome
having count(distinct e.loja_id) > 1;

-- 1.3 Quais os vendedores que nunca venderam nada?
select l.loja_id, l.nome
from loja l
where not exists (select 1 from encomenda e where e.loja_id = l.loja_id);

-- 1.4 Liste as compras (data, total) por comprador.
-- Usa a vista encomenda_total (total com desconto aplicado).
select c.nome as comprador, t.data, t.total
from encomenda_total t
join cliente c on c.cliente_id = t.cliente_id
order by c.nome, t.data;

-- 1.5 Para um dado comprador, calcule o total de compras até ao momento.
-- Alterar o cliente_id (101) conforme pretendido.
select c.cliente_id, c.nome, coalesce(sum(t.total), 0) as total_compras
from cliente c
left join encomenda_total t on t.cliente_id = c.cliente_id
                           and t.data <= current_date
where c.cliente_id = 101
group by c.cliente_id, c.nome;

-- 1.6 Qual o número de vendas, por vendedor, relativamente a Junho de 2009?
-- LEFT JOIN com o filtro no ON para as lojas sem vendas aparecerem com 0.
select l.loja_id, l.nome, count(e.encomenda_id) as n_vendas
from loja l
left join encomenda e on e.loja_id = l.loja_id
                     and e.data >= date '2009-06-01'
                     and e.data <  date '2009-07-01'
group by l.loja_id, l.nome
order by l.loja_id;

-- 1.7 Quais os vendedores com mais vendas que a média dos vendedores,
--     referentes a Junho de 2009?
-- A média é calculada sobre todos os vendedores (incluindo os com 0 vendas).
with vendas as (
    select l.loja_id, l.nome, count(e.encomenda_id) as n_vendas
    from loja l
    left join encomenda e on e.loja_id = l.loja_id
                         and e.data >= date '2009-06-01'
                         and e.data <  date '2009-07-01'
    group by l.loja_id, l.nome
)
select loja_id, nome, n_vendas
from vendas
where n_vendas > (select avg(n_vendas) from vendas);

-- 2. Quais os compradores que nunca compraram nada?
select c.cliente_id, c.nome
from cliente c
where not exists (select 1 from encomenda e where e.cliente_id = c.cliente_id);

-- 2.1 Quantos compradores fizeram mais do que 2 compras?
select count(*) as n_compradores
from (
    select cliente_id
    from encomenda
    group by cliente_id
    having count(*) > 2
) t;

-- 2.2 Liste as vendas mais recentes, com desconto, de um dado vendedor.
-- Alterar o loja_id (1000) conforme pretendido. Mais recentes primeiro.
select e.encomenda_id, e.data, e.cliente_id, e.desconto
from encomenda e
where e.loja_id = 1000
  and e.desconto > 0
order by e.data desc;
