-- =====================================================================
-- Parte 2 - Empresa de aluguer de veículos
-- 04 - Respostas às questões 2 a) a h)
-- Pré-requisito: 03_alugueres_modelo_dados.sql executado em "aluguer_veiculos".
--   psql -U postgres -d aluguer_veiculos -f 04_alugueres_respostas.sql
-- Intervalos de datas usam [início, fim[ para não depender da hora.
-- =====================================================================

-- a) Liste os veículos que foram alugados em 2009.
select distinct v.veiculo_id, v.matricula, ma.nome as marca, mo.nome as modelo
from veiculo v
join modelo mo on mo.modelo_id = v.modelo_id
join marca  ma on ma.marca_id  = mo.marca_id
join aluguer a on a.veiculo_id = v.veiculo_id
where a.data_inicio >= date '2009-01-01'
  and a.data_inicio <  date '2010-01-01'
order by v.veiculo_id;

-- b) Liste os clientes registados desde 2000 (inclusive).
select cliente_id, nome, data_registo
from cliente
where data_registo >= date '2000-01-01'
order by data_registo;

-- c) Liste os alugueres de veículos com descontos, em qualquer ano.
select a.aluguer_id, a.cliente_id, a.veiculo_id, a.data_inicio, a.desconto
from aluguer a
where a.desconto > 0
order by a.data_inicio;

-- d) Quais os veículos da marca "Jaguar" alugados em Maio de 2010?
select distinct v.veiculo_id, v.matricula, mo.nome as modelo
from aluguer a
join veiculo v on v.veiculo_id = a.veiculo_id
join modelo mo on mo.modelo_id = v.modelo_id
join marca  ma on ma.marca_id  = mo.marca_id
where ma.nome = 'Jaguar'
  and a.data_inicio >= date '2010-05-01'
  and a.data_inicio <  date '2010-06-01';

-- e) Para um dado cliente, liste todos os veículos que alugou.
-- Alterar o cliente_id (1) conforme pretendido.
select distinct v.veiculo_id, v.matricula, ma.nome as marca, mo.nome as modelo
from aluguer a
join veiculo v on v.veiculo_id = a.veiculo_id
join modelo mo on mo.modelo_id = v.modelo_id
join marca  ma on ma.marca_id  = mo.marca_id
where a.cliente_id = 1
order by v.veiculo_id;

-- f) Liste todos os alugueres do mês de Fevereiro de 2010.
select a.*
from aluguer a
where a.data_inicio >= date '2010-02-01'
  and a.data_inicio <  date '2010-03-01'
order by a.data_inicio;

-- g) Liste os veículos que nunca foram alugados.
select v.veiculo_id, v.matricula
from veiculo v
where not exists (select 1 from aluguer a where a.veiculo_id = v.veiculo_id);

-- h) Liste os veículos que foram alugados mais do que 10 vezes.
select v.veiculo_id, v.matricula, count(*) as n_alugueres
from veiculo v
join aluguer a on a.veiculo_id = v.veiculo_id
group by v.veiculo_id, v.matricula
having count(*) > 10;
