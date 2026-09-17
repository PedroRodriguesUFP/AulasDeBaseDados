-- ==========================================================
-- Consultas de Exemplo do Guião
-- ==========================================================

-- Q1. Mostrar título e autor de todos os livros importados
SELECT titulo, autor
FROM livros_importados;

-- Q2. Mostrar livros publicados a partir de 2000
SELECT *
FROM livros_importados
WHERE ano >= 2000;

-- Q3. Ordenar livros por ano, do mais recente para o mais antigo
SELECT titulo, ano
FROM livros_importados
ORDER BY ano DESC;

-- Desafio E1. Livros sem ano definido
SELECT *
FROM livros_importados
WHERE ano IS NULL;


-- ==========================================================
-- Exercícios da Parte F
-- ==========================================================

-- 1. Mostrar todos os livros de uma categoria à sua escolha
SELECT *
FROM livros_importados
WHERE categoria = 'Ficção científica';

-- 2. Mostrar apenas título e ano dos livros publicados antes de 1980
SELECT titulo, ano
FROM livros_importados
WHERE ano < 1980;

-- 3. Contar todos os livros importados
SELECT COUNT(*) AS total_livros
FROM livros_importados;

-- 4. Contar quantos livros existem em cada categoria
SELECT categoria, COUNT(*) AS quantidade
FROM livros_importados
GROUP BY categoria;