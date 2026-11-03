-- =====================================================================
-- BDAD 2026/27 - Ficha 5 - Introducao ao SQL
-- Exercicios 1 a 50
-- Executar:  psql -d university -f ficha5_resolucao.sql
-- Os erros marcados "ERRO ESPERADO" sao propositados.
-- Nenhuma tabela original da university e alterada: os exercicios de
-- DDL/DML (5, 41-46) usam tabelas de teste, apagadas no fim.
-- =====================================================================

-- =====================================================================
-- A. Conceitos fundamentais
-- =====================================================================

-- 1) SQL = linguagem declarativa padrao dos SGBD relacionais. Permite:
--    definir estruturas (CREATE/ALTER/DROP), consultar (SELECT) e
--    modificar dados (INSERT/UPDATE/DELETE). Descreve O QUE se quer, nao COMO.

-- 2) DDL define/altera a estrutura; DML consulta/modifica os dados.
--    DDL: CREATE TABLE, ALTER TABLE, DROP TABLE
--    DML: SELECT, INSERT INTO, UPDATE, DELETE FROM

\echo '=== Ex 3 ==='
SELECT name
FROM instructor
WHERE dept_name = 'Comp. Sci.';
-- 3a) Nomes dos docentes do departamento Comp. Sci.
-- 3b) Selecao (sigma) e projecao (pi).
-- 3c) pi_name( sigma_dept_name='Comp. Sci.' (instructor) )
-- 3d) FROM -> relacao de entrada; WHERE -> selecao sigma (filtra tuplos);
--     SELECT -> projecao pi (escolhe colunas).

-- 4) Relacao classica = conjunto (sem tuplos repetidos). Tabela SQL =
--    multiconjunto: admite duplicados (em resultados e, sem PK, nas tabelas).
--    DISTINCT elimina os duplicados do resultado.

-- 5) FUNCIONARIO(num_func, nome, salario, cod_dep) / DEPARTAMENTO(cod_dep, ...)
--    PK: DEPARTAMENTO.cod_dep, FUNCIONARIO.num_func
--    FK: FUNCIONARIO.cod_dep -> DEPARTAMENTO.cod_dep
--    Integridade referencial: todo cod_dep em FUNCIONARIO tem de existir em
--    DEPARTAMENTO (ou ser NULL).
DROP TABLE IF EXISTS funcionario_ex5;
DROP TABLE IF EXISTS departamento_ex5;
CREATE TABLE departamento_ex5 (
    cod_dep     VARCHAR(5) PRIMARY KEY,
    nome_dep    VARCHAR(50) NOT NULL,
    localizacao VARCHAR(50)
);
CREATE TABLE funcionario_ex5 (
    num_func INTEGER PRIMARY KEY,
    nome     VARCHAR(50) NOT NULL,
    salario  NUMERIC(10,2),
    cod_dep  VARCHAR(5) REFERENCES departamento_ex5(cod_dep)
);
-- 5d) ERRO ESPERADO: departamento inexistente -> violacao de FK, insercao recusada
INSERT INTO funcionario_ex5 VALUES (1, 'Ana', 1000, 'XXX');
DROP TABLE funcionario_ex5;
DROP TABLE departamento_ex5;

-- 6) INTEGER: inteiros normais (ex. num_func, ate ~2 mil milhoes).
--    SMALLINT: inteiros pequenos (ex. idade, ano letivo).
--    VARCHAR(n): texto de tamanho variavel ate n (ex. nome).
--    CHAR(n): texto de tamanho fixo n, preenchido com espacos (ex. codigo
--             postal, sigla de 2 letras).
--    NUMERIC(p,d): decimal exato, p digitos no total, d decimais (ex. preco,
--             salario: sem erros de arredondamento).
--    REAL: virgula flutuante aproximada, 4 bytes (ex. medicao cientifica);
--             pode ter erros de arredondamento -> nao usar para dinheiro.

-- 7) PRIMARY KEY: identifica cada tuplo (unica e nao nula). Ex.: ID INTEGER PRIMARY KEY
--    FOREIGN KEY: liga a PK de outra tabela. Ex.: FOREIGN KEY (dept_name) REFERENCES department
--    NOT NULL: proibe NULL. Ex.: name VARCHAR(20) NOT NULL

\echo '=== Ex 8 ==='
SELECT name, salary
FROM instructor
WHERE salary > 80000
ORDER BY salary DESC;
-- 8a) FROM: origem; WHERE: filtra tuplos; SELECT: colunas; ORDER BY: ordena.
-- 8b) name, salary.
-- 8c) Selecionados os de salary > 80000, ordenados por salary decrescente.
-- 8d) Nao: sem ORDER BY a ordem nao esta garantida.

-- =====================================================================
-- B. Consultas fundamentais
-- =====================================================================

\echo '=== Ex 9 ==='
SELECT * FROM instructor;                 -- a
SELECT name FROM instructor;              -- b
SELECT name, salary FROM instructor;      -- c
SELECT * FROM department;                 -- d
SELECT title, credits FROM course;        -- e

\echo '=== Ex 10 ==='
SELECT dept_name FROM instructor;                -- a
SELECT DISTINCT dept_name FROM instructor;       -- b
SELECT DISTINCT dept_name FROM student;          -- c
-- Sem DISTINCT cada docente gera uma linha (departamentos repetem-se);
-- com DISTINCT cada departamento surge uma so vez.

\echo '=== Ex 11 ==='
SELECT * FROM instructor WHERE dept_name = 'Comp. Sci.';                    -- a
SELECT * FROM instructor WHERE salary > 80000;                              -- b
SELECT * FROM instructor WHERE dept_name = 'Physics' AND salary > 85000;    -- c
SELECT * FROM instructor WHERE dept_name <> 'Comp. Sci.';                   -- d
SELECT * FROM instructor WHERE salary BETWEEN 70000 AND 90000;              -- e

\echo '=== Ex 12 ==='
SELECT * FROM instructor WHERE dept_name IN ('Comp. Sci.', 'Physics');      -- a
SELECT * FROM instructor WHERE salary < 60000 OR salary > 90000;            -- b
SELECT * FROM instructor                                                    -- c
WHERE (dept_name = 'Comp. Sci.' AND salary > 70000)
   OR (dept_name = 'Physics'    AND salary > 90000);
SELECT * FROM instructor WHERE dept_name NOT IN ('Biology', 'History');     -- d

\echo '=== Ex 13 ==='
SELECT name, salary AS salario_anual FROM instructor;                       -- a
SELECT name, salary / 12 AS salario_mensal FROM instructor;                 -- b
SELECT name, salary * 1.05 AS salario_com_aumento FROM instructor;          -- c
SELECT name, salary AS salario_atual, salary * 1.05 AS salario_aumentado    -- d
FROM instructor;

\echo '=== Ex 14 ==='
SELECT * FROM instructor ORDER BY name;                       -- a
SELECT * FROM instructor ORDER BY salary DESC;                -- b
SELECT * FROM instructor ORDER BY dept_name, name;            -- c
SELECT * FROM instructor ORDER BY dept_name, salary DESC;     -- d

\echo '=== Ex 15 ==='
SELECT * FROM instructor WHERE name LIKE 'S%';                -- a
SELECT * FROM instructor WHERE name LIKE '%n';                -- b
SELECT * FROM instructor WHERE name LIKE '%an%';              -- c
SELECT * FROM course WHERE title LIKE 'Intro%';               -- d
SELECT * FROM course WHERE title LIKE '%Computer%';           -- e
-- % = qualquer sequencia de 0 ou mais caracteres; _ = exatamente um caracter.
-- (LIKE e sensível a maiusculas no PostgreSQL; ILIKE ignora.)

\echo '=== Ex 16 ==='
SELECT * FROM instructor, teaches;     -- 16a) produto cartesiano: todos os pares
-- 16b) m x n tuplos:
SELECT (SELECT COUNT(*) FROM instructor) * (SELECT COUNT(*) FROM teaches) AS m_vezes_n,
       (SELECT COUNT(*) FROM (SELECT * FROM instructor, teaches) x) AS contagem_real;
-- 16c) Combina cada docente com TODAS as turmas, incluindo as que nao lecionou.
-- 16d)
SELECT * FROM instructor, teaches WHERE instructor.ID = teaches.ID;

\echo '=== Ex 17 ==='
SELECT i.name, t.course_id                                                  -- a
FROM instructor i, teaches t WHERE i.ID = t.ID;
SELECT i.name, t.course_id                                                  -- b
FROM instructor i, teaches t
WHERE i.ID = t.ID AND i.dept_name = 'Comp. Sci.';
SELECT s.name, d.dept_name                                                  -- c
FROM student s, department d WHERE s.dept_name = d.dept_name;
SELECT c.title, d.dept_name                                                 -- d
FROM course c, department d WHERE c.dept_name = d.dept_name;
SELECT i.name, d.building                                                   -- e
FROM instructor i, department d WHERE i.dept_name = d.dept_name;

\echo '=== Ex 18 ==='
-- a) ligacoes: instructor.ID = teaches.ID e teaches.course_id = course.course_id
SELECT i.name, c.title
FROM instructor i, teaches t, course c
WHERE i.ID = t.ID AND t.course_id = c.course_id;
-- b)
SELECT i.name, c.title
FROM instructor i, teaches t, course c
WHERE i.ID = t.ID AND t.course_id = c.course_id AND c.dept_name = 'Comp. Sci.';
-- c)
SELECT i.name, c.title
FROM instructor i, teaches t, course c
WHERE i.ID = t.ID AND t.course_id = c.course_id
  AND t.semester = 'Fall' AND t.year = 2017;
-- d)
SELECT i.name, c.title
FROM instructor i, teaches t, course c
WHERE i.ID = t.ID AND t.course_id = c.course_id AND c.credits > 3;

-- =====================================================================
-- C. Analise e operacoes sobre conjuntos
-- =====================================================================

\echo '=== Ex 19 ==='
SELECT name FROM instructor WHERE dept_name = 'Physics' AND salary > 80000;
SELECT name FROM instructor WHERE salary > 80000 AND dept_name = 'Physics';
-- 19a/b) Sim. AND e comutativo; a ordem das condicoes nao altera o resultado.
-- 19c) Subconsulta simples:
SELECT name
FROM (SELECT * FROM instructor WHERE dept_name = 'Physics') AS p
WHERE salary > 80000;

\echo '=== Ex 20 ==='
SELECT name, course_id FROM instructor, teaches WHERE instructor.ID = teaches.ID;
-- 20a) Docentes com as disciplinas que lecionam (so quem lecionou).
-- 20b) Sim: aparece uma vez por cada registo em teaches (varias turmas/semestres).
-- 20c) Sem WHERE: produto cartesiano (todas as combinacoes, resultado errado).
-- 20d)
SELECT name, course_id FROM instructor JOIN teaches ON instructor.ID = teaches.ID;

\echo '=== Ex 21 ==='
SELECT T.name, S.name FROM instructor AS T, instructor AS S WHERE T.salary > S.salary;
-- 21a) Pares (docente, docente com salario inferior).
-- 21b) Auto-junção: a mesma relacao e usada duas vezes; precisa de aliases
--      para distinguir as duas "copias".
-- 21c) Sim: um docente pode ter varios com salario inferior.
-- 21d)
SELECT T.name, S.name
FROM instructor AS T, instructor AS S
WHERE T.salary > S.salary AND T.dept_name = S.dept_name;

\echo '=== Ex 22 - UNION ==='
(SELECT course_id FROM section WHERE semester = 'Fall'   AND year = 2017)
UNION
(SELECT course_id FROM section WHERE semester = 'Spring' AND year = 2018);
-- UNION elimina duplicados (UNION ALL mantem-nos).

\echo '=== Ex 23 - INTERSECT ==='
(SELECT course_id FROM section WHERE semester = 'Fall'   AND year = 2017)
INTERSECT
(SELECT course_id FROM section WHERE semester = 'Spring' AND year = 2018);
-- Algebra relacional: interseccao A inter B.

\echo '=== Ex 24 - EXCEPT ==='
(SELECT course_id FROM section WHERE semester = 'Fall'   AND year = 2017)
EXCEPT
(SELECT course_id FROM section WHERE semester = 'Spring' AND year = 2018);
-- Algebra relacional: diferenca A - B.

\echo '=== Ex 25 ==='
SELECT dept_name FROM instructor
UNION
SELECT dept_name FROM student;
-- 25a) Departamentos que tem docentes ou estudantes, sem repeticoes.
SELECT dept_name FROM instructor
INTERSECT
SELECT dept_name FROM student;
-- 25b) Departamentos com docentes E estudantes.
SELECT dept_name FROM instructor
EXCEPT
SELECT dept_name FROM student;
-- 25c) Departamentos com docentes mas sem estudantes.
-- 25d) UNION elimina duplicados; UNION ALL conserva-os (mais rapido).
SELECT dept_name FROM instructor
UNION ALL
SELECT dept_name FROM student;
-- 25e) Mesmo numero de colunas e tipos compativeis (posicao a posicao).

-- =====================================================================
-- D. NULL e agregacao
-- =====================================================================

-- 26) NULL = valor desconhecido/ausente (nao e 0 nem ''). Qualquer comparacao
--     com NULL (=, <, >, <>) da UNKNOWN.
\echo '=== Ex 26 ==='
SELECT * FROM instructor WHERE salary = NULL;       -- devolve 0 linhas sempre
-- 26a/b) Nao: salary = NULL e UNKNOWN para todas as linhas, nunca TRUE.
-- 26c)
SELECT * FROM instructor WHERE salary IS NULL;
-- 26d) IS NULL: salario desconhecido; IS NOT NULL: salario conhecido.

\echo '=== Ex 27 ==='
-- Respostas sem executar:
--  a) salario > 60000            -> Bruno, Diogo
--  b) salario <= 60000           -> Ana
--  c) salario IS NULL            -> Carla
--  d) > 60000 OR IS NULL         -> Bruno, Carla, Diogo
-- Carla nao aparece em a) nem b): NULL > 60000 e NULL <= 60000 sao UNKNOWN.
-- NULL nao e 0: 0 e um valor conhecido; NULL e desconhecido (e AVG/SUM ignoram-no).
-- Verificacao:
CREATE TEMP TABLE funcionario (id INT, nome TEXT, salario NUMERIC);
INSERT INTO funcionario VALUES (1,'Ana',50000),(2,'Bruno',70000),(3,'Carla',NULL),(4,'Diogo',90000);
SELECT nome FROM funcionario WHERE salario > 60000;
SELECT nome FROM funcionario WHERE salario <= 60000;
SELECT nome FROM funcionario WHERE salario IS NULL;
SELECT nome FROM funcionario WHERE salario > 60000 OR salario IS NULL;
DROP TABLE funcionario;

\echo '=== Ex 28 ==='
SELECT COUNT(*)                    AS total_docentes   FROM instructor;     -- a
SELECT AVG(salary)                 AS salario_medio    FROM instructor;     -- b
SELECT MAX(salary)                 AS salario_maximo   FROM instructor;     -- c
SELECT MIN(salary)                 AS salario_minimo   FROM instructor;     -- d
SELECT SUM(salary)                 AS soma_salarios    FROM instructor;     -- e
SELECT COUNT(DISTINCT dept_name)   AS departamentos    FROM instructor;     -- f

\echo '=== Ex 29 ==='
SELECT COUNT(*) FROM teaches;
SELECT COUNT(DISTINCT ID) FROM teaches;
-- 29a) 1.o: numero de registos em teaches. 2.o: numero de docentes distintos.
-- 29b) Um docente pode ter varios registos (varias turmas) -> menos IDs distintos.
-- 29c)
SELECT COUNT(DISTINCT ID) AS docentes_spring_2018
FROM teaches
WHERE semester = 'Spring' AND year = 2018;

\echo '=== Ex 30 ==='
SELECT dept_name, COUNT(*)    AS num_docentes   FROM instructor GROUP BY dept_name;  -- a
SELECT dept_name, AVG(salary) AS salario_medio  FROM instructor GROUP BY dept_name;  -- b
SELECT dept_name, MAX(salary) AS salario_maximo FROM instructor GROUP BY dept_name;  -- c
SELECT dept_name, COUNT(*)    AS num_estudantes FROM student    GROUP BY dept_name;  -- d
SELECT dept_name, COUNT(*)    AS num_disciplinas FROM course    GROUP BY dept_name;  -- e

\echo '=== Ex 31 ==='
SELECT dept_name, COUNT(*) AS num_docentes
FROM instructor GROUP BY dept_name HAVING COUNT(*) > 2;                              -- a
SELECT dept_name, AVG(salary) AS salario_medio
FROM instructor GROUP BY dept_name HAVING AVG(salary) > 80000;                       -- b
SELECT dept_name, COUNT(*) AS num_disciplinas
FROM course GROUP BY dept_name HAVING COUNT(*) >= 3;                                 -- c
SELECT dept_name, MAX(salary) AS salario_maximo
FROM instructor GROUP BY dept_name HAVING MAX(salary) > 90000;                       -- d

\echo '=== Ex 32 ==='
SELECT dept_name, AVG(salary) FROM instructor WHERE salary > 70000 GROUP BY dept_name;
SELECT dept_name, AVG(salary) FROM instructor GROUP BY dept_name HAVING AVG(salary) > 70000;
-- 32a) 1.a: media so dos docentes com salario > 70000, por departamento.
--      2.a: media de todos os docentes; mantem so os departamentos cuja media > 70000.
-- 32b) Nao. WHERE filtra tuplos ANTES de agrupar (altera o calculo da media);
--      HAVING filtra grupos DEPOIS de agregar.
-- 32c/d) Ex.: Comp. Sci. tem media 77333,33 com todos os docentes, mas se
--      so contarmos salarios > 70000 a media sobe; um departamento pode
--      aparecer so numa das consultas e com medias diferentes (compare resultados acima).

-- =====================================================================
-- E. Subconsultas
-- =====================================================================

\echo '=== Ex 33 ==='
SELECT name FROM instructor
WHERE salary > (SELECT AVG(salary) FROM instructor);
-- Interna: calcula a media (um valor). Externa: compara cada docente com esse valor.

\echo '=== Ex 34 ==='
SELECT DISTINCT course_id FROM section                                           -- a
WHERE semester = 'Fall' AND year = 2017
  AND course_id IN (SELECT course_id FROM section WHERE semester = 'Spring' AND year = 2018);
SELECT DISTINCT course_id FROM section                                           -- b
WHERE semester = 'Fall' AND year = 2017
  AND course_id NOT IN (SELECT course_id FROM section WHERE semester = 'Spring' AND year = 2018);
SELECT name FROM student                                                         -- c
WHERE ID IN (SELECT ID FROM takes
             WHERE course_id IN (SELECT course_id FROM course WHERE dept_name = 'Comp. Sci.'));

\echo '=== Ex 35 ==='
(SELECT course_id FROM section WHERE semester = 'Fall'   AND year = 2017)       -- a
INTERSECT
(SELECT course_id FROM section WHERE semester = 'Spring' AND year = 2018);
SELECT DISTINCT course_id FROM section                                           -- b
WHERE semester = 'Fall' AND year = 2017
  AND course_id IN (SELECT course_id FROM section WHERE semester = 'Spring' AND year = 2018);
-- Ambas dizem: course_id pertence ao conjunto de Fall 2017 E ao de Spring 2018.

\echo '=== Ex 36 ==='
SELECT name FROM instructor
WHERE salary > SOME (SELECT salary FROM instructor WHERE dept_name = 'Biology');  -- a
SELECT name FROM instructor
WHERE salary > ALL  (SELECT salary FROM instructor WHERE dept_name = 'Biology');  -- b
-- SOME: maior que pelo menos um (equivale a > MIN). ALL: maior que todos (> MAX).

\echo '=== Ex 37 ==='
SELECT i.name FROM instructor i
WHERE EXISTS (SELECT 1 FROM teaches t WHERE t.ID = i.ID);
-- Subconsulta correlacionada: usa i.ID da consulta externa, avaliada por docente.

\echo '=== Ex 38 ==='
SELECT i.name FROM instructor i
WHERE NOT EXISTS (SELECT 1 FROM teaches t WHERE t.ID = i.ID);
-- Equivalente com NOT IN:
SELECT name FROM instructor WHERE ID NOT IN (SELECT ID FROM teaches);
-- Se a subconsulta devolver algum NULL, "ID NOT IN (..., NULL)" nunca e TRUE
-- e o NOT IN devolve 0 linhas. NOT EXISTS nao tem esse problema.

\echo '=== Ex 39 ==='
SELECT dept_name, salario_medio
FROM (SELECT dept_name, AVG(salary) AS salario_medio
      FROM instructor GROUP BY dept_name) AS medias
WHERE salario_medio > 80000;
-- Equivalente:
SELECT dept_name, AVG(salary) AS salario_medio
FROM instructor GROUP BY dept_name HAVING AVG(salary) > 80000;

\echo '=== Ex 40 - WITH ==='
WITH medias AS (
    SELECT dept_name, AVG(salary) AS salario_medio
    FROM instructor
    GROUP BY dept_name
)
SELECT * FROM medias WHERE salario_medio > 80000;
-- 40a/b) 'medias' e uma relacao temporaria (CTE) com a media por departamento,
--        visivel so durante esta consulta; a consulta final filtra > 80000.
-- 40c)
SELECT dept_name, AVG(salary) AS salario_medio
FROM instructor GROUP BY dept_name HAVING AVG(salary) > 80000;
-- 40d) Divide consultas complexas em passos nomeados, reutilizaveis na mesma consulta.

-- =====================================================================
-- F. DDL e DML (tabelas de teste)
-- =====================================================================

\echo '=== Ex 41 ==='
DROP TABLE IF EXISTS produto;
DROP TABLE IF EXISTS categoria;
CREATE TABLE categoria (
    cod_categoria INTEGER      PRIMARY KEY,
    designacao    VARCHAR(50)  NOT NULL
);
CREATE TABLE produto (
    cod_produto   INTEGER       PRIMARY KEY,
    nome          VARCHAR(100)  NOT NULL,
    preco         NUMERIC(10,2) NOT NULL,
    cod_categoria INTEGER       NOT NULL REFERENCES categoria(cod_categoria)
);

\echo '=== Ex 42 ==='
DROP TABLE IF EXISTS empregado_teste;
DROP TABLE IF EXISTS departamento_teste;
CREATE TABLE departamento_teste (
    codigo VARCHAR(5) PRIMARY KEY,
    nome   VARCHAR(50) NOT NULL
);
CREATE TABLE empregado_teste (
    numero  INTEGER PRIMARY KEY,
    nome    VARCHAR(50) NOT NULL,
    cod_dep VARCHAR(5),
    FOREIGN KEY (cod_dep) REFERENCES departamento_teste(codigo)
);
INSERT INTO departamento_teste VALUES ('INF', 'Informatica');
INSERT INTO empregado_teste VALUES (1, 'Ana', 'INF');
-- a) ERRO ESPERADO: chave primaria duplicada (codigo)
INSERT INTO departamento_teste VALUES ('INF', 'Outro');
-- b) ERRO ESPERADO: chave primaria duplicada (numero)
INSERT INTO empregado_teste VALUES (1, 'Bruno', 'INF');
-- c) ERRO ESPERADO: FK - departamento inexistente
INSERT INTO empregado_teste VALUES (2, 'Carla', 'XXX');
-- d) ERRO ESPERADO: nome NOT NULL
INSERT INTO empregado_teste VALUES (3, NULL, 'INF');
-- e) PERMITIDO: cod_dep aceita NULL (sem NOT NULL); a FK nao valida NULL.
INSERT INTO empregado_teste VALUES (4, 'Diogo', NULL);
SELECT * FROM empregado_teste;
DROP TABLE empregado_teste;
DROP TABLE departamento_teste;

\echo '=== Ex 43 ==='
INSERT INTO categoria VALUES (1, 'Perifericos'), (2, 'Audio'), (3, 'Monitores');     -- a
INSERT INTO produto VALUES                                                            -- b
    (1, 'Teclado',        25.90, 1),
    (2, 'Rato',           12.50, 1),
    (3, 'Auscultadores',  59.90, 2),
    (4, 'Colunas',        45.00, 2),
    (5, 'Monitor 24',    149.99, 3);
INSERT INTO produto (cod_produto, nome, preco, cod_categoria)                         -- c
VALUES (6, 'Cabo HDMI', 5.99, 3);
-- d) ERRO ESPERADO: categoria 99 nao existe
INSERT INTO produto VALUES (7, 'Fantasma', 10.00, 99);
-- e) Recusado por violacao da FK: cod_categoria tem de existir em categoria.
SELECT * FROM produto ORDER BY cod_produto;

\echo '=== Ex 44 ==='
UPDATE produto SET preco = preco * 1.05;                                               -- a
UPDATE produto SET preco = preco * 1.10 WHERE cod_categoria = 1;                       -- b
UPDATE produto SET nome = 'Teclado Mecanico' WHERE cod_produto = 1;                    -- c
SELECT * FROM produto ORDER BY cod_produto;                                            -- d
-- e) Sem WHERE, UPDATE altera TODAS as linhas (como em a).

\echo '=== Ex 45 ==='
DELETE FROM produto WHERE cod_produto = 5;                                             -- a
DELETE FROM produto WHERE preco < 10;                                                  -- b
-- c) ERRO ESPERADO: categoria 1 ainda tem produtos
DELETE FROM categoria WHERE cod_categoria = 1;
-- d) A FK (comportamento por omissao, NO ACTION) impede apagar a categoria
--    enquanto existirem produtos que a referenciam.
-- e) DELETE FROM produto: apaga as linhas, a tabela (estrutura) permanece.
--    DROP TABLE produto: apaga a tabela inteira (estrutura + dados).
SELECT * FROM produto ORDER BY cod_produto;

\echo '=== Ex 46 ==='
ALTER TABLE produto ADD COLUMN stock INTEGER;                                          -- a
UPDATE produto SET stock = 10;                                                         -- b
\d produto                                                                             -- c
SELECT * FROM produto ORDER BY cod_produto;
-- d) Esquema = estrutura (colunas, tipos, restricoes); dados = linhas.
-- e) Esquema: CREATE/ALTER/DROP (DDL). Dados: INSERT/UPDATE/DELETE (DML).

DROP TABLE produto;
DROP TABLE categoria;

-- =====================================================================
-- G. Integradores
-- =====================================================================

\echo '=== Ex 47 ==='
-- a)
SELECT DISTINCT c.title
FROM course c JOIN section s ON c.course_id = s.course_id
WHERE s.year = 2017;
-- b)
SELECT c.course_id, c.title, COUNT(*) AS num_turmas
FROM course c JOIN section s ON c.course_id = s.course_id
WHERE s.year = 2017
GROUP BY c.course_id, c.title;
-- c)
SELECT DISTINCT i.name
FROM instructor i JOIN teaches t ON i.ID = t.ID
WHERE t.semester = 'Fall' AND t.year = 2017;
-- d)
SELECT t.course_id, COUNT(DISTINCT t.ID) AS docentes_distintos
FROM teaches t
WHERE t.year = 2017
GROUP BY t.course_id;
-- e)
SELECT c.title
FROM course c
WHERE NOT EXISTS (SELECT 1 FROM section s
                  WHERE s.course_id = c.course_id AND s.year = 2017);

\echo '=== Ex 48 ==='
-- a) student, takes: existe linha em takes para o estudante
SELECT DISTINCT s.name FROM student s JOIN takes t ON s.ID = t.ID;
-- b) student, takes: anti-juncao
SELECT s.name FROM student s WHERE NOT EXISTS (SELECT 1 FROM takes t WHERE t.ID = s.ID);
-- c) student, takes: COUNT por estudante (so os que tem inscricoes)
SELECT s.ID, s.name, COUNT(*) AS num_inscricoes
FROM student s JOIN takes t ON s.ID = t.ID
GROUP BY s.ID, s.name;
-- d) mais de 3 inscricoes
SELECT s.ID, s.name, COUNT(*) AS num_inscricoes
FROM student s JOIN takes t ON s.ID = t.ID
GROUP BY s.ID, s.name
HAVING COUNT(*) > 3;
-- e) student, takes, course: disciplinas de Comp. Sci.
SELECT DISTINCT s.name
FROM student s
JOIN takes t  ON s.ID = t.ID
JOIN course c ON t.course_id = c.course_id
WHERE c.dept_name = 'Comp. Sci.';

\echo '=== Ex 49 ==='
-- a) LEFT JOIN + COUNT(coluna) para mostrar tambem departamentos sem docentes (0)
SELECT d.dept_name, COUNT(i.ID) AS num_docentes
FROM department d LEFT JOIN instructor i ON d.dept_name = i.dept_name
GROUP BY d.dept_name;
-- b)
SELECT d.dept_name, COUNT(s.ID) AS num_estudantes
FROM department d LEFT JOIN student s ON d.dept_name = s.dept_name
GROUP BY d.dept_name;
-- c)
SELECT d.dept_name, COUNT(c.course_id) AS num_disciplinas
FROM department d LEFT JOIN course c ON d.dept_name = c.dept_name
GROUP BY d.dept_name;
-- d)
SELECT dept_name, budget
FROM department
WHERE budget > (SELECT AVG(budget) FROM department);
-- e)
SELECT dept_name, AVG(salary) AS salario_medio
FROM instructor
GROUP BY dept_name
HAVING AVG(salary) > (SELECT AVG(salary) FROM instructor);
-- f)
SELECT d.dept_name
FROM department d
WHERE NOT EXISTS (SELECT 1 FROM instructor i WHERE i.dept_name = d.dept_name);

\echo '=== Ex 50 ==='
-- a) GROUP BY + HAVING
SELECT dept_name, COUNT(*) AS num_docentes, AVG(salary) AS salario_medio
FROM instructor
GROUP BY dept_name
HAVING COUNT(*) > 2 AND AVG(salary) > 70000;
-- b) subconsulta no FROM
SELECT dept_name, num_docentes, salario_medio
FROM (SELECT dept_name, COUNT(*) AS num_docentes, AVG(salary) AS salario_medio
      FROM instructor GROUP BY dept_name) AS stats
WHERE num_docentes > 2 AND salario_medio > 70000;
-- c) WITH
WITH stats AS (
    SELECT dept_name, COUNT(*) AS num_docentes, AVG(salary) AS salario_medio
    FROM instructor
    GROUP BY dept_name
)
SELECT * FROM stats
WHERE num_docentes > 2 AND salario_medio > 70000;
-- d) a) e a mais curta; b) e c) separam "calcular" de "filtrar" e permitem
--    filtrar por nome de coluna; c) le-se de cima para baixo (passos nomeados).
-- e) As tres calculam os mesmos grupos e aplicam os mesmos dois filtros
--    sobre os mesmos valores agregados; so muda a forma de os escrever.
-- f) Opiniao: a) para este caso simples (menos codigo, sem aninhamento);
--    c) quando a consulta cresce, por ser mais legivel e reutilizavel.