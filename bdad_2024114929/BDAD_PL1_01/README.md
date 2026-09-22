# Relatório PL1 — Tour inicial pelo PostgreSQL

* **Nome:** Pedro Rodrigues
* **Número de Aluno:** 2024114929
* **Base de Dados:** bdad_2024114929
* **Sistema Operativo:** Windows 11
* **Versão PostgreSQL:** PostgreSQL 18.x (obtida via `SELECT version();`)
* **Repositório GitHub:** https://github.com/PedroRodriguesUFP/AulasDeBaseDados.git

---

## Parte A — Conhecer o psql e o pgAdmin

1. **A que servidor e base de dados está ligado?**
   * Servidor: `localhost` (Porta: 5432, Utilizador: `postgres`)
   * Base de dados inicial: `postgres` (posteriormente mudada para `bdad_2024114929`).

2. **Que informação mostra `\l`?**
   * O comando `\l` lista todas as bases de dados existentes no servidor PostgreSQL, indicando o respetivo dono/proprietário (Owner), a codificação de caracteres (Encoding), as regras de ordenação regional (Collate/Ctype) e os privilégios de acesso associados.

---

## Parte C — Desafio C2

* **Explicação da relação entre `livros.categoria_id` e `categorias.id`:**
  A coluna `livros.categoria_id` é uma **chave estrangeira** (*Foreign Key*) que faz referência direta à **chave primária** (*Primary Key*) `categorias.id`. Esta relação impõe uma regra de integridade referencial, garantindo que nenhum livro pode ser associado a uma categoria inexistente e impedindo registos órfãos.

---

## Parte D — Desafio D1

* **Comportamento com `categoria_id` inexistente:**
  Ao tentar inserir um registo com uma categoria que não existe na tabela `categorias`, o PostgreSQL bloqueia a operação e devolve um erro de violação de integridade referencial:
  `ERROR: insert or update on table "livros" violates foreign key constraint "livros_categoria_id_fkey"`.

---

## Parte E — Análise do Ficheiro `livros.csv`

* **Quais são os nomes das colunas?**
  `id, titulo, autor, ano, categoria`
* **O ficheiro tem cabeçalho?**
  Sim, a primeira linha identifica as colunas.
* **Qual é o separador usado?**
  A vírgula (`,`).
* **Existem células vazias?**
  Sim, existem registos onde o campo correspondente ao `ano` se encontra vazio (que são importados para a base de dados como `NULL`).