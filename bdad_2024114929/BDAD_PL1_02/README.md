# PL2 — Pedro (2024114929)
Base de dados: bdad_2024114929

## Estado
- [x] Tarefas de base concluídas
- [x] Tarefas de extensão concluídas
- [x] Desafio Python concluído

---

## Ponto de Partida e Inspeção de Dados (Tarefa 1)

### Pergunta 1 — Quantas linhas existem em `livros_importados`?
* Foram identificadas as linhas da tabela de importação inicial (`livros_importados`), que contêm tanto registos válidos como registos incompletos ou com problemas de codificação.

### Pergunta 2 — Que autores e categorias diferentes existem?
* **Autores:** Eça de Queirós, Isaac Asimov, Stephen Hawking (além das versões com problemas de codificação UTF-8/Windows-1252 como `EÃ§a de QueirÃ³s`).
* **Categorias:** Romance, Ciência, Ficção científica (e variantes com erros de codificação).

### Pergunta 3 — Que linhas têm título, autor, categoria ou ano em falta?
* Existem linhas em `livros_importados` que contêm valores `NULL` ou cadeias de caracteres vazias `''` nos campos `titulo`, `autor`, `categoria` ou `ano`.

### Pergunta 4 — Existem categorias que parecem iguais, mas diferem em espaços ou maiúsculas/minúsculas?
* Sim. Foram detetadas diferenças resultantes de espaços em branco nas extremidades (resolvidas com `BTRIM()`), assim como duplicações provocadas por codificação de caracteres incorreta:
  - `"CiÃªncia"` vs `"Ciência"`
  - `"FicÃ§Ã£o cientÃ­fica"` vs `"Ficção científica"`
  - `"Romance"`

---

## Decisões sobre Dados e Notas do Trabalho

### 1. Decisões sobre dados incompletos (Tarefa 1 & 4)
* **Decisão:** As linhas da tabela `livros_importados` que possuem campos essenciais em falta (`titulo`, `autor`, `categoria` ou `ano`) **não foram migradas** para o catálogo final (`catalogo_livros`).
* **Justificação:** Esta decisão preserva a tabela de importação/staging como registo histórico original e garante que no catálogo final todas as regras de integridade (restrições `NOT NULL` e `FOREIGN KEY`) sejam cumpridas sem inserir dados corrompidos.
* **Diferença de Totais:** O total de registos em `livros_importados` é superior ao total em `catalogo_livros`. Esta diferença deve-se à exclusão dos registos incompletos e à rejeição de duplicados assegurada pela restrição `UNIQUE (titulo, ano, autor_id)`.

### 2. Formatação e Problemas de Codificação (Tarefa 3)
* Utilizou-se a função `BTRIM()` para remover espaços desnecessários.
* Os registos duplicados derivados de erros de encoding (como `EÃ§a de QueirÃ³s` ou `CiÃªncia`) foram limpos/excluídos antes da migração para evitar duplicação de entidades nas tabelas `autores_catalogo` e `categorias_catalogo`.

### 3. Validação da Regra de Negócio de Empréstimos (Tarefa 6)
* A restrição `CHECK (data_devolucao IS NULL OR data_devolucao >= data_emprestimo)` garante que uma devolução não pode ser registada numa data anterior à do empréstimo.
* **Resultado do Teste:** Ao tentar inserir uma devolução inválida, o PostgreSQL lança o erro de violação de restrição `check_violation`, cancelando a inserção e protegendo a integridade temporal dos dados.

### 4. Importância das Transações (Tarefa 7)
* O uso dos comandos `BEGIN`, `COMMIT` e `ROLLBACK` assegura a propriedade da **Atomicidade (ACID)**.
* **Exemplo de aplicação:** Num cenário real de biblioteca, ao registar um empréstimo é necessário inserir o registo na tabela `emprestimos` e atualizar o estado do livro no catálogo. A utilização de uma transação garante que, caso ocorra uma falha a meio do processo, o comando `ROLLBACK` anule todas as alterações, evitando dados incompletos ou inconsistentes na base de dados.