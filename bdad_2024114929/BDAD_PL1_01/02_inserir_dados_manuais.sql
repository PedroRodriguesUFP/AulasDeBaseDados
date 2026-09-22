-- Inserir categorias base do guião
INSERT INTO categorias (id, nome)
VALUES
    (1, 'Romance'),
    (2, 'Ficção científica'),
    (3, 'História'),
    (4, 'Tecnologia'); -- Categoria extra pedida pelo guião

-- Inserir livros base do guião + 2 livros extra
INSERT INTO livros (id, titulo, autor, ano, categoria_id)
VALUES
    (1, 'Ensaio sobre a Cegueira', 'José Saramago', 1995, 1),
    (2, 'Duna', 'Frank Herbert', 1965, 2),
    (3, 'Sapiens', 'Yuval Noah Harari', 2011, 3),
    (4, 'Clean Code', 'Robert C. Martin', 2008, 4),                     
    (5, 'Designing Data-Intensive Applications', 'Martin Kleppmann', 2017, 4); 

-- Desafio D1: Demonstração de falha por chave estrangeira (comentado conforme pedido)
INSERT INTO livros (id, titulo, autor, ano, categoria_id)
VALUES (6, 'Livro Inválido', 'Autor Desconhecido', 2024, 99);
--Erro esperado: violates foreign key constraint "livros_categoria_id_fkey"