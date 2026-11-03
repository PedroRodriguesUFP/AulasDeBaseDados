-- =====================================================================
-- Parte 2 - Empresa de aluguer de veículos
-- 03 - Modelo relacional (DDL) e dados de exemplo
-- Executar ligado à base de dados "aluguer_veiculos".
--   psql -U postgres -d aluguer_veiculos -f 03_alugueres_modelo_dados.sql
--
-- MODELO RELACIONAL (PK sublinhada, FK com ->):
--   marca        (marca_id, nome)
--   modelo       (modelo_id, nome, marca_id -> marca)
--   tipo_veiculo (tipo_id, nome)   -- utilitário, desportivo, comercial,
--                                  -- passageiros, luxo
--   local        (local_id, nome)
--   veiculo      (veiculo_id, matricula, modelo_id -> modelo,
--                 tipo_id -> tipo_veiculo, tarifa_diaria)
--   cliente      (cliente_id, nome, data_registo)
--   aluguer      (aluguer_id, cliente_id -> cliente, veiculo_id -> veiculo,
--                 data_inicio, data_entrega, local_entrega_id -> local,
--                 desconto)   -- desconto em % (0 = sem desconto)
-- =====================================================================

create table marca (
    marca_id int generated always as identity primary key,
    nome     varchar(50) not null unique
);

create table modelo (
    modelo_id int generated always as identity primary key,
    nome      varchar(50) not null,
    marca_id  int not null references marca(marca_id)
);

create table tipo_veiculo (
    tipo_id int generated always as identity primary key,
    nome    varchar(20) not null unique
        check (nome in ('utilitário','desportivo','comercial','passageiros','luxo'))
);

create table local (
    local_id int generated always as identity primary key,
    nome     varchar(100) not null
);

create table veiculo (
    veiculo_id    int generated always as identity primary key,
    matricula     varchar(10) not null unique,
    modelo_id     int not null references modelo(modelo_id),
    tipo_id       int not null references tipo_veiculo(tipo_id),
    tarifa_diaria numeric(8,2) not null check (tarifa_diaria > 0)
);

create table cliente (
    cliente_id    int generated always as identity primary key,
    nome          varchar(100) not null,
    data_registo  date not null
);

create table aluguer (
    aluguer_id       int generated always as identity primary key,
    cliente_id       int not null references cliente(cliente_id),
    veiculo_id       int not null references veiculo(veiculo_id),
    data_inicio      date not null,
    data_entrega     date,                              -- null = ainda não entregue
    local_entrega_id int references local(local_id),
    desconto         numeric(4,1) not null default 0 check (desconto between 0 and 100),
    check (data_entrega is null or data_entrega >= data_inicio)
);

-- ------------------------------ dados --------------------------------
insert into marca (nome) values ('Jaguar'), ('Toyota'), ('Ford');

insert into modelo (nome, marca_id) values
    ('XF',      (select marca_id from marca where nome = 'Jaguar')),
    ('F-Type',  (select marca_id from marca where nome = 'Jaguar')),
    ('Yaris',   (select marca_id from marca where nome = 'Toyota')),
    ('Transit', (select marca_id from marca where nome = 'Ford'));

insert into tipo_veiculo (nome) values
    ('utilitário'), ('desportivo'), ('comercial'), ('passageiros'), ('luxo');

insert into local (nome) values ('Lisboa - Aeroporto'), ('Porto - Centro'), ('Faro');

insert into veiculo (matricula, modelo_id, tipo_id, tarifa_diaria) values
    ('AA-11-AA', (select modelo_id from modelo where nome='XF'),
                 (select tipo_id from tipo_veiculo where nome='luxo'),       120.00),
    ('BB-22-BB', (select modelo_id from modelo where nome='F-Type'),
                 (select tipo_id from tipo_veiculo where nome='desportivo'), 150.00),
    ('CC-33-CC', (select modelo_id from modelo where nome='Yaris'),
                 (select tipo_id from tipo_veiculo where nome='utilitário'),  35.00),
    ('DD-44-DD', (select modelo_id from modelo where nome='Transit'),
                 (select tipo_id from tipo_veiculo where nome='comercial'),   60.00),
    ('EE-55-EE', (select modelo_id from modelo where nome='Yaris'),
                 (select tipo_id from tipo_veiculo where nome='passageiros'), 40.00);  -- nunca alugado

insert into cliente (nome, data_registo) values
    ('Ana Silva',   '1998-03-12'),
    ('Bruno Costa', '2000-01-01'),
    ('Carla Dias',  '2005-07-20');

-- veiculo 1 = AA-11-AA (XF), 2 = BB-22-BB (F-Type), 3 = Yaris, 4 = Transit
insert into aluguer (cliente_id, veiculo_id, data_inicio, data_entrega, local_entrega_id, desconto) values
    (1, 3, '2009-03-10', '2009-03-15', 1,  0),
    (2, 4, '2009-08-01', '2009-08-05', 2, 10),
    (2, 1, '2010-02-10', '2010-02-14', 1,  0),
    (3, 2, '2010-05-03', '2010-05-07', 3,  5),
    (1, 1, '2010-05-20', '2010-05-22', 1, 10);

-- 11 alugueres do veículo 3 (Yaris) em 2011 -> "mais de 10 vezes"
insert into aluguer (cliente_id, veiculo_id, data_inicio, data_entrega, local_entrega_id, desconto)
select 3, 3,
       date '2011-01-01' + (g * 10),
       date '2011-01-01' + (g * 10) + 2,
       2, 0
from generate_series(0, 10) g;
