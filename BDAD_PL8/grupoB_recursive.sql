-- =====================================================================
-- Ficha 7 - Grupo B: CONSULTAS RECURSIVAS
-- Base de dados: university (Silberschatz)
-- =====================================================================

-- ---------------------------------------------------------------------
-- Exercício 15: Pré-requisitos diretos
-- ---------------------------------------------------------------------

-- a) Pré-requisitos diretos de CS-347
SELECT prereq_id
FROM prereq
WHERE course_id = 'CS-347';

-- b) Com títulos
SELECT c.course_id, c.title AS disciplina,
       p.prereq_id, cp.title AS titulo_prereq
FROM prereq p
JOIN course c  ON c.course_id = p.course_id
JOIN course cp ON cp.course_id = p.prereq_id
WHERE p.course_id = 'CS-347';

-- c) Todos os pares disciplina-pré-requisito
SELECT c.course_id, c.title AS disciplina,
       p.prereq_id, cp.title AS titulo_prereq
FROM prereq p
JOIN course c  ON c.course_id = p.course_id
JOIN course cp ON cp.course_id = p.prereq_id
ORDER BY c.course_id;

-- d) ver respostas_teoricas.md (não precisam de recursividade: só pedem
--    relações diretas, uma única leitura/junção à tabela prereq chega)


-- ---------------------------------------------------------------------
-- Exercício 16: Análise da consulta recursiva (fornecida no enunciado)
-- ---------------------------------------------------------------------
WITH RECURSIVE rec_prereq(course_id, prereq_id) AS (
    SELECT course_id, prereq_id
    FROM prereq
    UNION
    SELECT r.course_id, p.prereq_id
    FROM rec_prereq AS r
    JOIN prereq AS p
      ON r.prereq_id = p.course_id
)
SELECT *
FROM rec_prereq
ORDER BY course_id;


-- ---------------------------------------------------------------------
-- Exercício 17: Pré-requisitos diretos e indiretos de CS-347
-- ---------------------------------------------------------------------
WITH RECURSIVE rec_prereq(course_id, prereq_id) AS (
    SELECT course_id, prereq_id
    FROM prereq
    UNION
    SELECT r.course_id, p.prereq_id
    FROM rec_prereq AS r
    JOIN prereq AS p
      ON r.prereq_id = p.course_id
)
SELECT rp.course_id,
       rp.prereq_id,
       c.title AS titulo_prereq
FROM rec_prereq rp
JOIN course c ON c.course_id = rp.prereq_id
WHERE rp.course_id = 'CS-347'
ORDER BY rp.prereq_id;

-- Comparar com o exercício 15: este resultado inclui também pré-requisitos
-- INDIRETOS (toda a cadeia de dependências), não apenas os diretos.


-- ---------------------------------------------------------------------
-- Exercício 18: Disciplinas dependentes de CS-101 (direta/indiretamente)
-- ---------------------------------------------------------------------
WITH RECURSIVE rec_depende(course_id, prereq_id) AS (
    -- caso base: disciplinas que têm CS-101 como pré-requisito direto
    SELECT course_id, prereq_id
    FROM prereq
    UNION
    -- passo recursivo: disciplinas que dependem de algo que já depende de CS-101
    SELECT p.course_id, r.prereq_id
    FROM rec_depende AS r
    JOIN prereq AS p
      ON p.prereq_id = r.course_id
)
SELECT DISTINCT rd.course_id, c.title
FROM rec_depende rd
JOIN course c ON c.course_id = rd.course_id
WHERE rd.prereq_id = 'CS-101'
ORDER BY c.title;

-- d) ver respostas_teoricas.md: percorre o grafo no sentido inverso
--    relativamente ao exercício 17.


-- ---------------------------------------------------------------------
-- Exercício 20: Hierarquia de funcionários (tabela hipotética)
-- ---------------------------------------------------------------------
-- Criação de uma tabela de teste (não faz parte de university, é só para
-- este exercício ilustrativo - criar numa base de testes / schema à parte
-- se não quiseres misturar com university)

-- DROP TABLE IF EXISTS employee;
-- CREATE TABLE employee (
--     employee_id INT PRIMARY KEY,
--     name        VARCHAR(50),
--     manager_id  INT REFERENCES employee(employee_id)
-- );

-- c) Subordinados diretos e indiretos de employee_id = 10
WITH RECURSIVE subordinados AS (
    SELECT employee_id, name, manager_id
    FROM employee
    WHERE manager_id = 10
    UNION
    SELECT e.employee_id, e.name, e.manager_id
    FROM employee e
    JOIN subordinados s ON e.manager_id = s.employee_id
)
SELECT * FROM subordinados;

-- d) Versão com nível hierárquico
WITH RECURSIVE subordinados(employee_id, name, manager_id, nivel) AS (
    SELECT employee_id, name, manager_id, 1
    FROM employee
    WHERE manager_id = 10
    UNION
    SELECT e.employee_id, e.name, e.manager_id, s.nivel + 1
    FROM employee e
    JOIN subordinados s ON e.manager_id = s.employee_id
)
SELECT * FROM subordinados
ORDER BY nivel;
