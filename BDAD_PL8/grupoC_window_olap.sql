-- =====================================================================
-- Ficha 7 - Grupo C: AGREGAÇÃO AVANÇADA, WINDOW FUNCTIONS E OLAP
-- Base de dados: university (Silberschatz)
-- =====================================================================

-- ---------------------------------------------------------------------
-- Exercício 23: Ranking de salários
-- ---------------------------------------------------------------------
-- a) Ordenados por salário decrescente
SELECT ID, name, dept_name, salary
FROM instructor
ORDER BY salary DESC;

-- b) + RANK()
SELECT ID, name, dept_name, salary,
       RANK() OVER (ORDER BY salary DESC) AS posicao_rank
FROM instructor
ORDER BY salary DESC;

-- c) DENSE_RANK()
SELECT ID, name, dept_name, salary,
       DENSE_RANK() OVER (ORDER BY salary DESC) AS posicao_dense_rank
FROM instructor
ORDER BY salary DESC;

-- d) + ROW_NUMBER()
SELECT ID, name, dept_name, salary,
       RANK()       OVER (ORDER BY salary DESC) AS posicao_rank,
       DENSE_RANK() OVER (ORDER BY salary DESC) AS posicao_dense_rank,
       ROW_NUMBER() OVER (ORDER BY salary DESC) AS posicao_row_number
FROM instructor
ORDER BY salary DESC;

-- e) ver respostas_teoricas.md: RANK() salta números após empates,
--    DENSE_RANK() não salta, ROW_NUMBER() nunca tem empates.


-- ---------------------------------------------------------------------
-- Exercício 25: Ranking por departamento
-- ---------------------------------------------------------------------
SELECT ID, name, dept_name, salary,
       RANK() OVER (PARTITION BY dept_name ORDER BY salary DESC) AS posicao_no_departamento
FROM instructor
ORDER BY dept_name, posicao_no_departamento;


-- ---------------------------------------------------------------------
-- Exercício 26: Docente(s) com maior salário por departamento
-- ---------------------------------------------------------------------
-- a) e b) usando RANK() + CTE (preserva empates)
WITH ranking_dept AS (
    SELECT ID, name, dept_name, salary,
           RANK() OVER (PARTITION BY dept_name ORDER BY salary DESC) AS posicao
    FROM instructor
)
SELECT ID, name, dept_name, salary
FROM ranking_dept
WHERE posicao = 1
ORDER BY dept_name;

-- c) Alternativa com MAX() e subconsulta
SELECT i.ID, i.name, i.dept_name, i.salary
FROM instructor i
JOIN (
    SELECT dept_name, MAX(salary) AS max_salary
    FROM instructor
    GROUP BY dept_name
) m ON i.dept_name = m.dept_name AND i.salary = m.max_salary
ORDER BY i.dept_name;

-- d) ver respostas_teoricas.md (ROW_NUMBER esconderia empates)


-- ---------------------------------------------------------------------
-- Exercício 27: Top-2 por departamento
-- ---------------------------------------------------------------------
WITH ranking_dept AS (
    SELECT ID, name, dept_name, salary,
           DENSE_RANK() OVER (PARTITION BY dept_name ORDER BY salary DESC) AS posicao
    FROM instructor
)
SELECT ID, name, dept_name, salary, posicao
FROM ranking_dept
WHERE posicao <= 2
ORDER BY dept_name, posicao;


-- ---------------------------------------------------------------------
-- Exercício 28: Ranking de departamentos por salário médio
-- ---------------------------------------------------------------------
SELECT dept_name,
       AVG(salary) AS salario_medio,
       RANK() OVER (ORDER BY AVG(salary) DESC) AS posicao
FROM instructor
GROUP BY dept_name
ORDER BY posicao;


-- ---------------------------------------------------------------------
-- Exercício 29: Distribuição e percentis
-- ---------------------------------------------------------------------
SELECT ID, name, dept_name, salary,
       PERCENT_RANK() OVER (ORDER BY salary) AS percent_rank,
       CUME_DIST()    OVER (ORDER BY salary) AS cume_dist,
       NTILE(4)       OVER (ORDER BY salary DESC) AS quartil
FROM instructor
ORDER BY salary DESC;


-- ---------------------------------------------------------------------
-- Exercício 31: Comparação com a média do departamento
-- ---------------------------------------------------------------------
SELECT ID, name, dept_name, salary,
       AVG(salary) OVER (PARTITION BY dept_name) AS media_departamento,
       salary - AVG(salary) OVER (PARTITION BY dept_name) AS diferenca_para_media
FROM instructor
ORDER BY dept_name, salary DESC;


-- ---------------------------------------------------------------------
-- Exercício 32: Soma acumulada de salários
-- ---------------------------------------------------------------------
SELECT ID, name, dept_name, salary,
       SUM(salary) OVER (
           ORDER BY salary, ID
           ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
       ) AS soma_acumulada
FROM instructor
ORDER BY salary, ID;


-- ---------------------------------------------------------------------
-- Exercício 33: Médias móveis (tabela hipotética de vendas)
-- ---------------------------------------------------------------------
-- Criar tabela de teste
DROP TABLE IF EXISTS vendas_teste;
CREATE TABLE vendas_teste (
    data  DATE PRIMARY KEY,
    valor NUMERIC(8,2)
);

INSERT INTO vendas_teste (data, valor) VALUES
    ('2026-01-01', 100),
    ('2026-01-02', 150),
    ('2026-01-03', 120),
    ('2026-01-04', 180),
    ('2026-01-05', 200);

-- b) Média móvel centrada em 3 observações
SELECT data, valor,
       AVG(valor) OVER (
           ORDER BY data
           ROWS BETWEEN 1 PRECEDING AND 1 FOLLOWING
       ) AS media_movel
FROM vendas_teste
ORDER BY data;


-- ---------------------------------------------------------------------
-- Exercício 34: Window functions e agrupamento (takes)
-- ---------------------------------------------------------------------
-- a) e b)
SELECT ID, course_id, semester, year,
       COUNT(*) OVER (PARTITION BY ID) AS total_inscricoes_aluno
FROM takes
ORDER BY ID, year, semester;

-- c) Comparação com GROUP BY (perde o detalhe por inscrição)
SELECT ID, COUNT(*) AS total_inscricoes_aluno
FROM takes
GROUP BY ID
ORDER BY ID;


-- ---------------------------------------------------------------------
-- Exercício 37: Agregação com ROLLUP
-- ---------------------------------------------------------------------
-- a) Inscrições por (dept_name, year), sem ROLLUP
SELECT c.dept_name, t.year, COUNT(*) AS num_inscricoes
FROM takes t
JOIN course c ON c.course_id = t.course_id
GROUP BY c.dept_name, t.year
ORDER BY c.dept_name, t.year;

-- b) Com ROLLUP
SELECT c.dept_name, t.year, COUNT(*) AS num_inscricoes
FROM takes t
JOIN course c ON c.course_id = t.course_id
GROUP BY ROLLUP (c.dept_name, t.year)
ORDER BY c.dept_name, t.year;


-- ---------------------------------------------------------------------
-- Exercício 38: Agregação com CUBE
-- ---------------------------------------------------------------------
-- a) Com CUBE, incluindo GROUPING() para distinguir subtotais (alínea e)
SELECT
    CASE WHEN GROUPING(c.dept_name) = 1 THEN '(TODOS OS DEPARTAMENTOS)' ELSE c.dept_name END AS dept_name,
    CASE WHEN GROUPING(t.year)      = 1 THEN '(TODOS OS ANOS)'         ELSE t.year::text END AS year,
    COUNT(*) AS num_inscricoes,
    GROUPING(c.dept_name) AS grp_dept,
    GROUPING(t.year)      AS grp_year
FROM takes t
JOIN course c ON c.course_id = t.course_id
GROUP BY CUBE (c.dept_name, t.year)
ORDER BY c.dept_name, t.year;


-- ---------------------------------------------------------------------
-- Exercício 40: Caso prático integrado
-- ---------------------------------------------------------------------

-- a) Nº de inscrições por departamento da disciplina
SELECT c.dept_name, COUNT(*) AS num_inscricoes
FROM takes t
JOIN course c ON c.course_id = t.course_id
GROUP BY c.dept_name
ORDER BY num_inscricoes DESC;

-- b) Nº de inscrições por departamento e por ano
SELECT c.dept_name, t.year, COUNT(*) AS num_inscricoes
FROM takes t
JOIN course c ON c.course_id = t.course_id
GROUP BY c.dept_name, t.year
ORDER BY c.dept_name, t.year;

-- c) Top-3 disciplinas com mais inscrições (DENSE_RANK)
WITH inscricoes_por_disciplina AS (
    SELECT course_id, COUNT(*) AS num_inscricoes
    FROM takes
    GROUP BY course_id
),
ranking AS (
    SELECT course_id, num_inscricoes,
           DENSE_RANK() OVER (ORDER BY num_inscricoes DESC) AS posicao
    FROM inscricoes_por_disciplina
)
SELECT r.course_id, c.title, r.num_inscricoes, r.posicao
FROM ranking r
JOIN course c ON c.course_id = r.course_id
WHERE r.posicao <= 3
ORDER BY r.posicao;

-- d) Ranking das disciplinas mais procuradas dentro de cada departamento
WITH inscricoes_por_disciplina AS (
    SELECT c.dept_name, t.course_id, COUNT(*) AS num_inscricoes
    FROM takes t
    JOIN course c ON c.course_id = t.course_id
    GROUP BY c.dept_name, t.course_id
)
SELECT dept_name, course_id, num_inscricoes,
       RANK() OVER (PARTITION BY dept_name ORDER BY num_inscricoes DESC) AS posicao_no_departamento
FROM inscricoes_por_disciplina
ORDER BY dept_name, posicao_no_departamento;

-- e) Subtotais por departamento + total geral com ROLLUP
SELECT c.dept_name, COUNT(*) AS num_inscricoes
FROM takes t
JOIN course c ON c.course_id = t.course_id
GROUP BY ROLLUP (c.dept_name)
ORDER BY c.dept_name;

-- f) Análise multidimensional por departamento e ano com CUBE
SELECT
    CASE WHEN GROUPING(c.dept_name) = 1 THEN '(TODOS OS DEPARTAMENTOS)' ELSE c.dept_name END AS dept_name,
    CASE WHEN GROUPING(t.year)      = 1 THEN '(TODOS OS ANOS)'         ELSE t.year::text END AS year,
    COUNT(*) AS num_inscricoes
FROM takes t
JOIN course c ON c.course_id = t.course_id
GROUP BY CUBE (c.dept_name, t.year)
ORDER BY dept_name, year;

-- g) ver respostas_teoricas.md:
-- Estes resultados apoiam decisões de distribuição de docentes (departamentos/
-- disciplinas com mais procura precisam de mais docentes/turmas), planeamento
-- de turmas (nº de inscrições por disciplina/ano ajuda a dimensionar turmas e
-- evitar turmas sobrelotadas ou subaproveitadas), e utilização de salas
-- (cruzando nº de inscrições por semestre/ano com a capacidade das salas
-- disponíveis em cada período).
