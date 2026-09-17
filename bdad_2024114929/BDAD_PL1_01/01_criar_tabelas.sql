-- Criar tabela de categorias
CREATE TABLE categorias (
    id INTEGER PRIMARY KEY,
    nome VARCHAR(50) NOT NULL
);

-- Criar tabela de livros com chave estrangeira
CREATE TABLE livros (
    id INTEGER PRIMARY KEY,
    titulo VARCHAR(150) NOT NULL,
    autor VARCHAR(100) NOT NULL,
    ano INTEGER,
    categoria_id INTEGER REFERENCES categorias(id)
);

-- Desafio C1: Adicionar a coluna isbn
ALTER TABLE livros ADD COLUMN isbn VARCHAR(20);

-- Parte E: Tabela para receber os dados importados do CSV (página 6 do guião)
CREATE TABLE livros_importados (
    id INTEGER,
    titulo VARCHAR(150),
    autor VARCHAR(100),
    ano INTEGER,
    categoria VARCHAR(50)
);