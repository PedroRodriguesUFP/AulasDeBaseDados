-- ==========================================
-- TAREFA 5: Consultar o catálogo
-- ==========================================

-- 1. Listar título, autor e categoria de todos os livros.
SELECT l.titulo, a.nome AS autor, c.nome AS categoria
FROM catalogo_livros AS l
JOIN autores_catalogo AS a ON a.id = l.autor_id
JOIN categorias_catalogo AS c ON c.id = l.categoria_id
ORDER BY l.titulo;

-- 2. Listar livros publicados a partir de 2000, incluindo autor e categoria.
SELECT l.titulo, l.ano, a.nome AS autor, c.nome AS categoria
FROM catalogo_livros AS l
JOIN autores_catalogo AS a ON a.id = l.autor_id
JOIN categorias_catalogo AS c ON c.id = l.categoria_id
WHERE l.ano >= 2000
ORDER BY l.ano ASC;

-- 3. Contar livros por categoria, por ordem decrescente.
SELECT c.nome AS categoria, COUNT(l.id) AS total_livros
FROM categorias_catalogo AS c
LEFT JOIN catalogo_livros AS l ON l.categoria_id = c.id
GROUP BY c.id, c.nome
ORDER BY total_livros DESC;

-- 4. Contar livros por autor.
SELECT a.nome AS autor, COUNT(l.id) AS total_livros
FROM autores_catalogo AS a
LEFT JOIN catalogo_livros AS l ON l.autor_id = a.id
GROUP BY a.id, a.nome
ORDER BY total_livros DESC;

-- 5. Mostrar categorias sem livros, se existirem.
SELECT c.nome AS categoria
FROM categorias_catalogo AS c
LEFT JOIN catalogo_livros AS l ON l.categoria_id = c.id
WHERE l.id IS NULL;