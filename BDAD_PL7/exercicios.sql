-- =====================================================================
-- BDAD 2026/27 - Ficha 6 - SQL Intermedio
-- Exercicios: 2, 3, 4, 14, 15, 16, 29, 30, 31, 32, 35, 39, 40
-- Executar:  psql -d university -f ficha6_resolucao.sql
-- (ou colar bloco a bloco no psql)
-- Os erros marcados "ERRO ESPERADO" sao propositados.
-- =====================================================================

\echo '=== Ex 2 - INNER JOIN ==='

-- 2a) FROM com duas relacoes + condicao no WHERE
SELECT i.name, t.course_id
FROM instructor i, teaches t
WHERE i.ID = t.ID;

-- 2b) INNER JOIN ... ON
SELECT i.name, t.course_id
FROM instructor i
INNER JOIN teaches t ON i.ID = t.ID;

-- 2c) Equivalentes: ambas fazem o produto cartesiano instructor x teaches
--     e filtram os pares com i.ID = t.ID. O optimizador gera o mesmo plano.
--     A forma JOIN separa condicao de junção (ON) de filtros (WHERE).
-- 2d) Docentes sem registos em teaches NAO aparecem (nenhum par satisfaz
--     a condicao). Para os manter -> LEFT JOIN (ex. 6).

\echo '=== Ex 3 - NATURAL JOIN ==='

-- 3a) Junta instructor e teaches pelos atributos com o MESMO nome.
SELECT name, course_id
FROM instructor NATURAL JOIN teaches;

-- 3b) Atributo comum: ID.
-- 3c) NATURAL JOIN funde as colunas comuns numa so; por isso ID surge uma vez.
SELECT * FROM instructor NATURAL JOIN teaches;

-- 3d) Versao com INNER JOIN ... ON
SELECT i.name, t.course_id
FROM instructor i
INNER JOIN teaches t ON i.ID = t.ID;

-- 3e) Mesmos tuplos. Diferenca: em SELECT * o INNER JOIN ... ON mostra
--     ID duas vezes (instructor.ID e teaches.ID); o NATURAL JOIN so uma.
SELECT * FROM instructor i INNER JOIN teaches t ON i.ID = t.ID;

\echo '=== Ex 4 - NATURAL JOIN vs INNER JOIN ==='

-- 4 (consulta 1) - NATURAL: junta por todas as colunas comuns (course_id)
SELECT * FROM course NATURAL JOIN prereq;

-- 4 (consulta 2) - INNER JOIN ON: mesma condicao, escrita explicitamente
SELECT *
FROM course
INNER JOIN prereq ON course.course_id = prereq.course_id;

-- 4a) Ambas associam cada disciplina aos seus pre-requisitos.
-- 4b) Sim, selecionam os mesmos pares de tuplos.
-- 4c/d) NATURAL: course_id aparece 1 vez. INNER JOIN ON: aparece 2 vezes
--       (course.course_id e prereq.course_id), pois as colunas nao sao fundidas.
-- 4e) USING funde a coluna como o NATURAL, mas so nas colunas indicadas:
SELECT *
FROM course
JOIN prereq USING (course_id);

\echo '=== Ex 14 - Vista faculty ==='

-- 14a)
CREATE VIEW faculty AS
SELECT ID, name, dept_name
FROM instructor;

-- 14b)
SELECT * FROM faculty;

-- 14c)
SELECT * FROM faculty WHERE dept_name = 'Biology';

-- 14d) faculty expoe apenas ID, name, dept_name (sem salary); instructor
--      expoe todas as colunas. A vista e uma consulta guardada.
-- 14e) Nao: vista convencional guarda apenas a definicao (relacao virtual);
--      cada consulta a faculty e reescrita sobre instructor.

\echo '=== Ex 15 - Vista cs_instructors ==='

-- 15a)
CREATE VIEW cs_instructors AS
SELECT ID, name, salary
FROM instructor
WHERE dept_name = 'Comp. Sci.';

-- 15b)
SELECT * FROM cs_instructors;

-- 15c)
SELECT * FROM cs_instructors WHERE salary > 80000;

-- 15d) Equivalente direto
SELECT ID, name, salary
FROM instructor
WHERE dept_name = 'Comp. Sci.' AND salary > 80000;

-- 15e) Vantagem: encapsula o filtro do departamento (reutilizavel, sem
--      repetir a condicao) e pode ser usada para restringir acessos.

\echo '=== Ex 16 - Vista com agregacao ==='

-- 16a)
CREATE VIEW department_salary_stats AS
SELECT dept_name,
       COUNT(*)    AS num_instructors,
       AVG(salary) AS avg_salary,
       MAX(salary) AS max_salary
FROM instructor
GROUP BY dept_name;

-- 16b)
SELECT * FROM department_salary_stats;

-- 16c)
SELECT * FROM department_salary_stats WHERE avg_salary > 80000;

-- 16d)
SELECT * FROM department_salary_stats
WHERE avg_salary > 80000
ORDER BY avg_salary DESC;

-- 16e) Esconde o GROUP BY e as funcoes de agregacao; consultas seguintes
--      sao simples SELECT/WHERE/ORDER BY sobre colunas ja calculadas.

\echo '=== Ex 29 - CHECK (produto) ==='

DROP TABLE IF EXISTS produto;

-- 29a)
CREATE TABLE produto (
    codigo INTEGER       PRIMARY KEY,
    nome   VARCHAR(100)  NOT NULL,
    preco  NUMERIC(10,2) CHECK (preco >= 0),
    stock  INTEGER       CHECK (stock >= 0)
);

-- 29b) Dois produtos validos
INSERT INTO produto VALUES (1, 'Teclado', 25.90, 10);
INSERT INTO produto VALUES (2, 'Rato',    12.50, 30);

-- 29c) ERRO ESPERADO: preco negativo
INSERT INTO produto VALUES (3, 'Monitor', -100.00, 5);

-- 29d) ERRO ESPERADO: stock negativo
INSERT INTO produto VALUES (4, 'Webcam', 40.00, -1);

-- 29e) O PostgreSQL rejeita a linha inteira com
--      "violates check constraint ...". Nada e inserido; as linhas 1 e 2
--      mantem-se. Em autocommit so a instrucao falhada e revertida.
SELECT * FROM produto;

\echo '=== Ex 30 - CHECK e NULL ==='

DROP TABLE IF EXISTS empregado_teste;

CREATE TABLE empregado_teste (
    id      INTEGER PRIMARY KEY,
    nome    VARCHAR(100),
    salario NUMERIC(10,2),
    CHECK (salario > 0)
);

-- 30a) Nao: -50 > 0 e FALSE -> ERRO ESPERADO
INSERT INTO empregado_teste VALUES (1, 'Ana', -50);

-- 30b) Nao: 0 > 0 e FALSE -> ERRO ESPERADO
INSERT INTO empregado_teste VALUES (2, 'Rui', 0);

-- 30c) SIM: NULL > 0 e UNKNOWN; CHECK so rejeita quando o resultado e FALSE
INSERT INTO empregado_teste VALUES (3, 'Eva', NULL);
SELECT * FROM empregado_teste;

-- 30d) CHECK aceita TRUE e UNKNOWN. Para proibir NULL e preciso NOT NULL.

-- 30e) Definicao corrigida
DROP TABLE empregado_teste;
CREATE TABLE empregado_teste (
    id      INTEGER PRIMARY KEY,
    nome    VARCHAR(100),
    salario NUMERIC(10,2) NOT NULL CHECK (salario > 0)
);
-- ERRO ESPERADO (not-null violation)
INSERT INTO empregado_teste VALUES (3, 'Eva', NULL);

\echo '=== Ex 31 - Integridade referencial ==='

-- 31a) PK: DEPARTAMENTO(cod_dep); FUNCIONARIO(num_func)
-- 31b) FK: FUNCIONARIO.cod_dep -> DEPARTAMENTO.cod_dep
-- 31c)
DROP TABLE IF EXISTS funcionario_ex31;
DROP TABLE IF EXISTS departamento_ex31;

CREATE TABLE departamento_ex31 (
    cod_dep VARCHAR(10)  PRIMARY KEY,
    nome    VARCHAR(100) NOT NULL
);

CREATE TABLE funcionario_ex31 (
    num_func INTEGER      PRIMARY KEY,
    nome     VARCHAR(100) NOT NULL,
    cod_dep  VARCHAR(10)  NOT NULL
             REFERENCES departamento_ex31(cod_dep)
);

INSERT INTO departamento_ex31 VALUES ('INF', 'Informatica');
INSERT INTO funcionario_ex31  VALUES (1, 'Joao', 'INF');

-- 31d) ERRO ESPERADO: departamento inexistente -> violates foreign key
INSERT INTO funcionario_ex31 VALUES (2, 'Maria', 'XYZ');

-- 31e) ERRO ESPERADO: por omissao (NO ACTION) a eliminacao e recusada
--      enquanto existirem funcionarios que referenciam o departamento.
DELETE FROM departamento_ex31 WHERE cod_dep = 'INF';

DROP TABLE funcionario_ex31;
DROP TABLE departamento_ex31;

\echo '=== Ex 32 - ON DELETE CASCADE ==='

DROP TABLE IF EXISTS funcionario_teste;
DROP TABLE IF EXISTS departamento_teste;

CREATE TABLE departamento_teste (
    codigo VARCHAR(10) PRIMARY KEY,
    nome   VARCHAR(100)
);

CREATE TABLE funcionario_teste (
    numero  INTEGER PRIMARY KEY,
    nome    VARCHAR(100),
    cod_dep VARCHAR(10),
    FOREIGN KEY (cod_dep)
        REFERENCES departamento_teste(codigo)
        ON DELETE CASCADE
);

-- 32a) CASCADE: ao apagar a linha referenciada (pai), o SGBD apaga
--      automaticamente as linhas que a referenciam (filhas).

-- 32b) 2 departamentos, 3 funcionarios
INSERT INTO departamento_teste VALUES ('INF', 'Informatica'), ('MAT', 'Matematica');
INSERT INTO funcionario_teste VALUES
    (1, 'Joao',  'INF'),
    (2, 'Maria', 'INF'),
    (3, 'Pedro', 'MAT');

-- 32c)
DELETE FROM departamento_teste WHERE codigo = 'INF';

-- 32d)
SELECT * FROM departamento_teste;
SELECT * FROM funcionario_teste;

-- 32e) Cada funcionario de INF tem uma FK para INF; todos sao apagados
--      em cadeia (Joao e Maria). So Pedro (MAT) permanece.
-- 32f) Vantagem: mantem integridade sem apagar manualmente os filhos.
--      Risco: um unico DELETE pode apagar muitos dados sem aviso (perda
--      acidental, em cascata por varias tabelas).

DROP TABLE funcionario_teste;
DROP TABLE departamento_teste;

\echo '=== Ex 35 - Tipos temporais ==='

-- 35a) Exemplos
SELECT DATE '2026-10-27'                    AS exemplo_date,
       TIME '14:30:00'                      AS exemplo_time,
       TIMESTAMP '2026-10-27 14:30:00'      AS exemplo_timestamp,
       INTERVAL '3 days 2 hours'            AS exemplo_interval;

-- Finalidades:
--   DATE      -> so data (ano-mes-dia)
--   TIME      -> so hora do dia
--   TIMESTAMP -> data + hora
--   INTERVAL  -> duracao/diferenca de tempo
-- 35b) DATE nao tem componente horario; TIMESTAMP tem (ate microssegundos).
-- 35c) INTERVAL permite somar/subtrair duracoes e representar diferencas:
SELECT TIMESTAMP '2026-10-27 18:00' - TIMESTAMP '2026-10-27 09:30' AS duracao;

-- 35d) Data e hora atuais
SELECT CURRENT_TIMESTAMP;   -- ou NOW()

-- 35e) Data daqui a 30 dias
SELECT CURRENT_DATE + 30                       AS data_mais_30;   -- tipo date
SELECT CURRENT_DATE + INTERVAL '30 days'       AS data_mais_30_ts; -- tipo timestamp

\echo '=== Ex 39 - Papeis ==='

-- Limpeza previa (permite re-executar o script)
DROP ROLE IF EXISTS utilizador1;
DROP ROLE IF EXISTS bd_admin_dados;
DROP ROLE IF EXISTS bd_editor;
DROP ROLE IF EXISTS bd_leitor;

-- 39a)
CREATE ROLE bd_leitor;
CREATE ROLE bd_editor;
CREATE ROLE bd_admin_dados;

-- 39b) Privilegios sobre student
GRANT SELECT                         ON student TO bd_leitor;
GRANT SELECT, INSERT, UPDATE         ON student TO bd_editor;
GRANT SELECT, INSERT, UPDATE, DELETE ON student TO bd_admin_dados;

-- 39c) Gerir permissoes num unico sitio: ao mudar as permissoes de um
--      perfil alteram-se todos os membros; evita repeticao e erros.

-- 39d) Utilizador de teste + atribuicao do papel
CREATE ROLE utilizador1 LOGIN;
GRANT bd_leitor TO utilizador1;

-- 39e) Privilegio = permissao sobre um objeto (SELECT, INSERT...).
--      Papel = conjunto nomeado de privilegios (e/ou de outros papeis)
--      que se atribui a utilizadores.

-- Verificacao
\dp student
\du

\echo '=== Ex 40 - Vistas e controlo de acesso ==='

DROP ROLE IF EXISTS consulta_publica;

-- 40a)
CREATE VIEW instructor_public AS
SELECT ID, name, dept_name
FROM instructor;

-- 40b)
CREATE ROLE consulta_publica;

-- 40c)
GRANT SELECT ON instructor_public TO consulta_publica;

-- 40d) SELECT em instructor daria acesso a salary, anulando o objetivo
--      da vista. Deve ter acesso apenas a vista.
-- 40e) A vista limita colunas/linhas visiveis; os privilegios limitam quem
--      acede. Principio do menor privilegio: o utilizador so ve o necessario.
-- 40f) Ex.: aplicacao web publica com diretorio de docentes (nome e
--      departamento) sem expor dados confidenciais como o salario.

\dp instructor_public

-- Limpeza opcional (descomentar para repor o estado inicial)
-- DROP VIEW IF EXISTS instructor_public, department_salary_stats,
--                     cs_instructors, faculty;
-- DROP TABLE IF EXISTS produto, empregado_teste;
-- DROP ROLE IF EXISTS consulta_publica, utilizador1,
--                     bd_admin_dados, bd_editor, bd_leitor;