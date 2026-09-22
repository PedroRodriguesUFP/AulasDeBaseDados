-- ==========================================
-- TAREFA 1: Inspecionar antes de transformar
-- ==========================================

-- 1. Quantas linhas existem em livros_importados?
SELECT COUNT(*) AS total_linhas
FROM livros_importados;

-- 2. Que autores e categorias diferentes existem?
SELECT DISTINCT NULLIF(BTRIM(autor), '') AS autor
FROM livros_importados
ORDER BY autor;

SELECT DISTINCT NULLIF(BTRIM(categoria), '') AS categoria
FROM livros_importados
ORDER BY categoria;

-- 3. Que linhas têm título, autor, categoria ou ano em falta?
SELECT *
FROM livros_importados
WHERE NULLIF(BTRIM(titulo), '') IS NULL
   OR NULLIF(BTRIM(autor), '') IS NULL
   OR NULLIF(BTRIM(categoria), '') IS NULL
   OR ano IS NULL;

-- 4. Categorias com espaços ou diferenças de maiúsculas/minúsculas
SELECT DISTINCT BTRIM(categoria) AS categoria_limpa, LOWER(BTRIM(categoria)) AS categoria_lower
FROM livros_importados
WHERE NULLIF(BTRIM(categoria), '') IS NOT NULL;


-- ==========================================
-- TAREFA 2: Criar o catálogo final
-- ==========================================

CREATE TABLE autores_catalogo (
    id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    nome VARCHAR(100) NOT NULL UNIQUE
);

CREATE TABLE categorias_catalogo (
    id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    nome VARCHAR(50) NOT NULL UNIQUE
);

CREATE TABLE catalogo_livros (
    id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    titulo VARCHAR(150) NOT NULL,
    ano INTEGER NOT NULL CHECK (ano BETWEEN 1450 AND 2100),
    autor_id INTEGER NOT NULL REFERENCES autores_catalogo(id),
    categoria_id INTEGER NOT NULL REFERENCES categorias_catalogo(id),
    UNIQUE (titulo, ano, autor_id)
);


-- ==========================================
-- TAREFA 3: Preencher autores e categorias
-- ==========================================

INSERT INTO autores_catalogo (nome)
SELECT DISTINCT BTRIM(autor)
FROM livros_importados
WHERE NULLIF(BTRIM(autor), '') IS NOT NULL;

INSERT INTO categorias_catalogo (nome)
SELECT DISTINCT BTRIM(categoria)
FROM livros_importados
WHERE NULLIF(BTRIM(categoria), '') IS NOT NULL;

-- Verificação:
SELECT * FROM autores_catalogo ORDER BY nome;
SELECT * FROM categorias_catalogo ORDER BY nome;


-- ==========================================
-- TAREFA 4: Migrar livros para o catálogo
-- ==========================================

-- Verificação dos dados antes de inserir
SELECT li.titulo, li.ano, a.id AS autor_id, a.nome AS autor,
       c.id AS categoria_id, c.nome AS categoria
FROM livros_importados AS li
JOIN autores_catalogo AS a ON a.nome = BTRIM(li.autor)
JOIN categorias_catalogo AS c ON c.nome = BTRIM(li.categoria)
WHERE NULLIF(BTRIM(li.titulo), '') IS NOT NULL
  AND li.ano IS NOT NULL;

-- Inserção no catálogo
INSERT INTO catalogo_livros (titulo, ano, autor_id, categoria_id)
SELECT li.titulo, li.ano, a.id, c.id
FROM livros_importados AS li
JOIN autores_catalogo AS a ON a.nome = BTRIM(li.autor)
JOIN categorias_catalogo AS c ON c.nome = BTRIM(li.categoria)
WHERE NULLIF(BTRIM(li.titulo), '') IS NOT NULL
  AND li.ano IS NOT NULL;

-- Validação de totais
SELECT COUNT(*) AS importados FROM livros_importados;
SELECT COUNT(*) AS catalogados FROM catalogo_livros;