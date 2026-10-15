# Bases de Dados

Repositório de exemplos de scripts SQL para a unidade curricular de **Bases de Dados**. Os ficheiros destinam-se a apoiar as aulas práticas e a experimentação autónoma em PostgreSQL.

## Conteúdos

- `BDAD_PL1/` — exemplo introdutório de uma base de dados de universidade: criação das tabelas `Cursos`, `Alunos` e `Matriculas`, seguida de inserções de teste.
- `BDAD_university/` — esquema **university** e exemplos de consultas SQL baseados no livro indicado abaixo. Inclui o DDL, conjuntos de dados pequeno e grande, e um script para remover/recriar o esquema.

## Execução

Com o PostgreSQL instalado e o comando `psql` disponível, execute os scripts pela ordem adequada. Por exemplo:

```bash
# Exemplo introdutório
psql -U postgres -f BDAD_PL1/01_criar_database.sql
psql -U postgres -d universidade -f BDAD_PL1/02_inserts.sql

# Esquema university do livro
psql -U postgres -f BDAD_university/10_DDL.sql
psql -U postgres -d university -f BDAD_university/12_smallRelationsInsertFile.sql
```

Depois de carregar os dados, pode executar as consultas em `BDAD_university/01_ch3_DML.sql` na base de dados `university`.

## Referência

Os exemplos da pasta `BDAD_university` baseiam-se no material de apoio do livro *Database System Concepts* (7.ª edição), de Avi Silberschatz, Henry F. Korth e S. Sudarshan:

<https://www.db-book.com/university-lab-dir/sample_tables-dir/index.html>
