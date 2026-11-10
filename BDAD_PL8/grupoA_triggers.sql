-- =====================================================================
-- Ficha 7 - Grupo A: TRIGGERS
-- Base de dados: university (Silberschatz)
-- =====================================================================

-- ---------------------------------------------------------------------
-- Exercício 6: Tabela de auditoria de salários
-- ---------------------------------------------------------------------
-- a) CREATE TABLE
-- b) chave primária: audit_id
-- c) tipos de dados: ver abaixo
-- d) útil para auditoria porque guarda um histórico imutável de quem
--    mudou o quê e quando, permitindo investigar alterações passadas
--    sem depender da memória de ninguém nem de logs externos.

DROP TABLE IF EXISTS salary_audit;

CREATE TABLE salary_audit (
    audit_id      SERIAL PRIMARY KEY,
    instructor_id VARCHAR(5)      NOT NULL,
    old_salary    NUMERIC(8,2),
    new_salary    NUMERIC(8,2),
    changed_at    TIMESTAMP       NOT NULL DEFAULT CURRENT_TIMESTAMP
);


-- ---------------------------------------------------------------------
-- Exercício 7: Trigger de auditoria de salários (AFTER UPDATE)
-- ---------------------------------------------------------------------
-- Regista automaticamente alterações a instructor.salary, evitando
-- registar quando o salário não se altera de facto (alínea extra do
-- exercício 10 / nota do exercício 7).

CREATE OR REPLACE FUNCTION fn_audit_salary()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.salary IS DISTINCT FROM OLD.salary THEN
        INSERT INTO salary_audit (instructor_id, old_salary, new_salary, changed_at)
        VALUES (OLD.ID, OLD.salary, NEW.salary, CURRENT_TIMESTAMP);
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_audit_salary ON instructor;

CREATE TRIGGER trg_audit_salary
AFTER UPDATE OF salary ON instructor
FOR EACH ROW
EXECUTE FUNCTION fn_audit_salary();

-- Teste do mecanismo (transação revertível, conforme pedido)
BEGIN;

UPDATE instructor
SET salary = salary + 1000
WHERE dept_name = 'Physics';

SELECT * FROM salary_audit;   -- verificar os registos criados

ROLLBACK;  -- reverte os salários; a tabela salary_audit fica vazia outra vez
           -- (troca para COMMIT se quiseres manter a alteração e a auditoria)


-- ---------------------------------------------------------------------
-- Exercício 8: Análise do funcionamento do trigger
-- ---------------------------------------------------------------------
-- a) Um registo de auditoria por cada docente do departamento 'Physics'
--    (um registo por linha afetada, porque o trigger é FOR EACH ROW).
-- b) old_salary = salário antes do UPDATE; new_salary = salário + 1000.
-- c) Após o ROLLBACK, os registos de auditoria TAMBÉM são revertidos
--    (deixam de existir), porque o INSERT em salary_audit ocorreu
--    dentro da MESMA transação que o UPDATE original.
-- d) O trigger participa na mesma transação da operação que o disparou:
--    por atomicidade, ou tudo é confirmado (UPDATE + INSERTs de
--    auditoria) ou tudo é desfeito junto (ROLLBACK desfaz ambos).


-- ---------------------------------------------------------------------
-- Exercício 9: Histórico de eliminação de docentes
-- ---------------------------------------------------------------------
-- a) Tabela de histórico
DROP TABLE IF EXISTS deleted_instructors;

CREATE TABLE deleted_instructors (
    instructor_id VARCHAR(5)   NOT NULL,
    name          VARCHAR(20),
    dept_name     VARCHAR(20),
    deleted_at    TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- b) Trigger AFTER DELETE
CREATE OR REPLACE FUNCTION fn_log_deleted_instructor()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO deleted_instructors (instructor_id, name, dept_name, deleted_at)
    VALUES (OLD.ID, OLD.name, OLD.dept_name, CURRENT_TIMESTAMP);
    RETURN OLD;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_log_deleted_instructor ON instructor;

CREATE TRIGGER trg_log_deleted_instructor
AFTER DELETE ON instructor
FOR EACH ROW
EXECUTE FUNCTION fn_log_deleted_instructor();

-- c) e d) Teste numa transação revertível, verificando ANTES do ROLLBACK
BEGIN;

DELETE FROM instructor WHERE ID = '10101';   -- ajustar ID conforme os dados existentes

SELECT * FROM deleted_instructors;   -- confirmar que o registo ficou gravado

ROLLBACK;  -- repõe o docente eliminado; deleted_instructors volta a ficar vazia

-- e) Este histórico não substitui backups porque só cobre eliminações
--    feitas através desta tabela via SQL normal (não cobre, por exemplo,
--    perda de todo o ficheiro de dados, corrupção, falhas de disco,
--    eliminação da própria base de dados, ou necessidade de restaurar
--    um estado completo anterior no tempo); é um registo pontual do
--    "quem/quando", não uma cópia integral recuperável dos dados.


-- ---------------------------------------------------------------------
-- Exercício 10: Restrição CHECK vs Trigger (parte prática)
-- ---------------------------------------------------------------------
-- Alternativa 1: restrição declarativa simples
ALTER TABLE instructor
    ADD CONSTRAINT chk_salary_min CHECK (salary >= 30000);

-- Alternativa 2 (ilustrativa): trigger BEFORE INSERT OR UPDATE
CREATE OR REPLACE FUNCTION fn_check_min_salary()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.salary < 30000 THEN
        RAISE EXCEPTION 'Salário % abaixo do mínimo permitido (30000)', NEW.salary;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- (não ativar as duas alternativas em simultâneo sobre a mesma tabela em produção;
--  manter apenas uma, aqui mostram-se ambas para efeitos de comparação/estudo)
-- DROP TRIGGER IF EXISTS trg_check_min_salary ON instructor;
-- CREATE TRIGGER trg_check_min_salary
-- BEFORE INSERT OR UPDATE ON instructor
-- FOR EACH ROW
-- EXECUTE FUNCTION fn_check_min_salary();
