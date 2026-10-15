
-- psql -U postgres -d universidade -f ./BDAD_PL1/02_inserts.sql
-- algumas inserções de teste para a base de dados universidade

INSERT INTO Cursos (nome_curso, carga_horaria) VALUES 
('Engenharia Informática', 3600),
('Gestão de Empresas', 3000);

INSERT INTO Alunos (nome_aluno, data_nascimento) VALUES 
('Ana', '2003-05-11'),
('Bruno', '2001-11-22');

INSERT INTO Matriculas (id_aluno, id_curso, data_matricula) VALUES 
(1, 1, '2026-02-10'),
(2, 1, '2026-02-11'),
(1, 2, '2026-02-15');

