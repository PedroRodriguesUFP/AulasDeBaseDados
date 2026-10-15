
-- psql -U postgres -f ./BDAD_PL1/01_criar_database.sql

create database universidade;

\c universidade;

-- Tabela de Cursos
CREATE TABLE Cursos (
    id_curso INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    nome_curso VARCHAR(100) NOT NULL,
    carga_horaria INT NOT NULL
);

-- Tabela de Alunos
CREATE TABLE Alunos (
    id_aluno INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    nome_aluno VARCHAR(100) NOT NULL,
    data_nascimento DATE NOT NULL
);

-- Tabela de Matrículas
CREATE TABLE Matriculas (
    id_matricula INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    id_aluno INT,
    id_curso INT,
    data_matricula DATE NOT NULL,
    FOREIGN KEY (id_aluno) REFERENCES Alunos(id_aluno),
    FOREIGN KEY (id_curso) REFERENCES Cursos(id_curso)
);

