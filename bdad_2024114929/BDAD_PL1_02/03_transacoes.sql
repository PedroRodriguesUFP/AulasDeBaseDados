-- ==========================================
-- TAREFA 6: Regras de empréstimo
-- ==========================================

CREATE TABLE emprestimos (
    id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    livro_id INTEGER NOT NULL REFERENCES catalogo_livros(id),
    nome_leitor VARCHAR(100) NOT NULL,
    data_emprestimo DATE NOT NULL DEFAULT CURRENT_DATE,
    data_devolucao DATE,
    CHECK (data_devolucao IS NULL OR data_devolucao >= data_emprestimo)
);

-- Teste de violação da regra de validação (CHECK)
-- Descomentar para testar o erro esperado:
-- INSERT INTO emprestimos (livro_id, nome_leitor, data_emprestimo, data_devolucao)
-- VALUES (1, 'Leitor Teste', '2026-03-10', '2026-03-01');


-- ==========================================
-- TAREFA 7: Fazer e desfazer (Transações)
-- ==========================================

-- Teste de ROLLBACK:
BEGIN;
INSERT INTO emprestimos (livro_id, nome_leitor)
VALUES (1, 'Leitor de teste');
SELECT * FROM emprestimos;
ROLLBACK;

-- Confirmação de inserção definitiva com COMMIT:
BEGIN;
INSERT INTO emprestimos (livro_id, nome_leitor)
VALUES (1, 'Leitor Definitivo');
COMMIT;

SELECT * FROM emprestimos;