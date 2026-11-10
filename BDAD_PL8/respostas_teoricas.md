# Respostas Teóricas — Ficha 7 (BDAD)

## Grupo A — Triggers

### 1. Conceito de trigger
Um *trigger* é um procedimento associado a uma tabela (ou visão) que o SGBD executa
**automaticamente** em reação a um evento de modificação de dados (`INSERT`, `UPDATE`, `DELETE`),
sem que o utilizador o invoque diretamente.

a) **Quando é executado?** Sempre que ocorre o evento para o qual foi definido, num dos momentos
`BEFORE`, `AFTER` ou `INSTEAD OF`, e opcionalmente só quando uma condição (`WHEN`) é verdadeira.

b) **Diferença para uma instrução explícita:** uma instrução SQL normal é executada porque o
utilizador/aplicação a envia deliberadamente; o trigger é executado *implicitamente*, como
consequência de outra operação, independentemente de quem ou o quê a provocou (aplicação, outro
trigger, importação em lote, etc.). O utilizador pode nem saber que o trigger foi disparado.

c) **Duas situações vantajosas:** (1) manter a integridade/consistência de dados derivados — ex.
atualizar `tot_cred` quando uma classificação passa a aprovação; (2) auditoria automática de
alterações (ex. registar quem/quando alterou um salário), garantindo que a regra é aplicada
*sempre*, independentemente da aplicação cliente usada.

d) **Desvantagem/risco:** lógica de negócio "escondida" na base de dados, difícil de depurar e de
documentar; cascatas de triggers (um trigger dispara outro) podem causar efeitos difíceis de
prever, problemas de desempenho em cargas massivas, ou até recursão infinita.

### 2. Eventos e momentos de execução
a) `INSERT` — inserção de novas linhas; `UPDATE` — modificação de valores de linhas existentes;
`DELETE` — remoção de linhas.

b) `BEFORE UPDATE` executa-se **antes** de a alteração ser aplicada à tabela — permite validar ou
modificar o valor que vai ser escrito (em PL/pgSQL, alterando `NEW`). `AFTER UPDATE` executa-se
**depois** de a alteração já estar efetivada — usa-se tipicamente para reagir ao facto consumado
(ex. registar auditoria, propagar o efeito para outras tabelas), já não podendo alterar a linha
que acabou de ser escrita.

c) Para **registar** alterações de salários (auditoria), o mais adequado é `AFTER UPDATE`: só
queremos gravar o que *de facto* aconteceu, depois de confirmado que a atualização foi aceite.

d) Para **validar/ajustar um valor antes de inserir**, o adequado é `BEFORE INSERT`: permite
rejeitar ou corrigir o valor (ex. forçar maiúsculas, impedir negativos) antes de ele ficar gravado.

### 3. Triggers por linha e por instrução
Considerando `UPDATE instructor SET salary = salary*1.05 WHERE dept_name='Comp. Sci.'`:

a) **`FOR EACH ROW`**: executa uma vez **por cada linha afetada** pela instrução — tantas vezes
quantos os docentes do departamento "Comp. Sci." (ex.: se há 7 docentes nesse departamento, o
trigger corre 7 vezes).

b) **`FOR EACH STATEMENT`**: executa **uma única vez**, independentemente do número de linhas
afetadas (mesmo que afete 0 ou 100 linhas).

c) É vantajoso usar trigger por instrução quando a ação não depende de valores linha-a-linha
(ex. registar "houve um aumento salarial no Comp. Sci. em 2026-11-10" uma só vez), ou quando se
quer evitar o custo de disparar o trigger centenas de vezes numa operação em massa.

### 4. Análise de um trigger de atualização de créditos
a) **Finalidade:** manter `student.tot_cred` sincronizado automaticamente com as aprovações
registadas em `takes`, sem exigir que a aplicação o faça manualmente em cada caso.

b) **Evento que desencadeia:** `AFTER UPDATE OF grade ON takes` (uma alteração à classificação de
uma inscrição existente).

c) **Papel dos valores antigos/novos:** o valor antigo (`OLD.grade`) diz-nos qual era a situação
antes (reprovado/pendente) e o valor novo (`NEW.grade`) diz-nos a nova situação; comparando os
dois, o trigger decide se houve uma transição de "não aprovado" para "aprovado" — só nesse caso é
que deve somar créditos.

d) **Necessidade de consultar `course`:** o número de créditos a somar está em
`course.credits` (não em `takes`), pelo que é necessário um `JOIN`/subconsulta a `course` usando
`course_id` para saber *quantos* créditos atribuir.

e) **De `'F'` para `'A'`:** é uma transição de reprovado→aprovado, logo os créditos da disciplina
devem ser **acrescentados** a `tot_cred` (o aluno não tinha os créditos antes, porque tinha
reprovado).

### 5. Análise de alterações de classificações

| Anterior | Nova | Créditos? | Justificação |
|---|---|---|---|
| `NULL` | `'A'` | **Sim, somar** | Passou de "sem classificação" a aprovado |
| `'F'` | `'B'` | **Sim, somar** | Passou de reprovado a aprovado |
| `'C'` | `'A'` | **Não** | Já estava aprovado antes e depois; não há transição |
| `'B'` | `'F'` | **Sim, subtrair** | Passou de aprovado a reprovado — deixou de ter direito aos créditos |
| `NULL` | `'F'` | **Não** | Continua não aprovado (nunca teve créditos a atribuir) |

Um mecanismo que **apenas soma** créditos é insuficiente porque não cobre o caso inverso
(aprovado → reprovado, como em `'B' → 'F'`), que exige **subtrair** créditos já contabilizados;
sem essa lógica simétrica, `tot_cred` ficaria inflacionado e deixaria de refletir a situação real
do aluno.

### 10. Triggers e restrições de integridade
a) **`CHECK (salary >= 30000)`**: restrição declarativa verificada automaticamente pelo motor em
qualquer `INSERT`/`UPDATE`; se o valor violar a condição, a instrução é rejeitada com erro, sem
qualquer lógica procedimental.
**Trigger `BEFORE INSERT OR UPDATE`**: lógica procedimental escrita pelo programador que corre
antes da escrita; pode rejeitar (`RAISE EXCEPTION`), mas também pode **corrigir** o valor
(ex. forçar `NEW.salary := 30000` em vez de rejeitar).

b) Para esta regra simples (um limite fixo e constante), o **`CHECK`** é mais adequado: é
declarativo, mais eficiente, mais legível e documenta a regra diretamente no esquema.

c) Um trigger é necessário quando a regra depende de **outros dados** ou de **lógica condicional**
que um `CHECK` simples não consegue exprimir — ex.: "o salário só pode ser inferior a 30000 se o
docente estiver a tempo parcial, consultando outra tabela"; ou quando a regra exige comparar o
valor novo com o valor antigo (`OLD` vs `NEW`), algo que `CHECK` (que só vê a linha, não o
histórico) não permite diretamente em todos os SGBD.

### 11. Riscos da utilização de triggers
a) **Trigger que atualiza uma tabela com outro trigger associado:** pode gerar uma **cascata de
triggers** (um dispara o outro, que pode dispar outro, etc.), tornando o comportamento difícil de
prever e depurar, e no limite causar **recursão infinita** ou ciclos.
*Mitigação:* limitar a profundidade/recursão permitida pelo SGBD, desenhar os triggers para serem
idempotentes, e documentar claramente as dependências entre eles.

b) **Erro durante uma operação importante:** se o trigger falhar (ex. exceção não tratada), em
muitos SGBD **toda a transação é abortada**, incluindo a operação original que o disparou — o que
pode impedir operações legítimas de serem concluídas.
*Mitigação:* tratar exceções dentro do trigger (ex. `EXCEPTION` em PL/pgSQL), testar
exaustivamente, e garantir que o trigger nunca falha por más condições de dados inesperadas.

c) **Importação massiva de dados a partir de uma cópia de segurança:** pode disparar milhares de
execuções de triggers desnecessariamente (ex. re-auditar dados que já existiam), degradando
fortemente o desempenho e podendo duplicar registos de auditoria/histórico.
*Mitigação:* desativar temporariamente os triggers durante a importação em massa
(`ALTER TABLE ... DISABLE TRIGGER ...` / `session_replication_role` em PostgreSQL) e reativá-los
no final, ou usar ferramentas de carga que contornem os triggers (`COPY` sem triggers de utilizador,
por exemplo).

### 12. Avaliação da necessidade de triggers
1. **Impedir salários negativos** → restrição **`CHECK (salary >= 0)`** (ou `> 0`); não precisa de
   trigger, é uma regra simples e estática.
2. **Registar alterações aos salários** → **trigger** `AFTER UPDATE`, porque é necessário executar
   uma ação procedimental (inserir numa tabela de auditoria) em reação ao evento.
3. **Calcular periodicamente o salário médio por departamento** → **não é um trigger**; é uma
   tarefa agendada (ex. `pg_cron`, job externo, view materializada refrescada periodicamente), pois
   não está associada a um evento de modificação mas sim ao tempo.
4. **Manter uma cópia da base de dados noutro servidor** → mecanismo do SGBD de **replicação**
   (ex. replicação física/lógica do PostgreSQL), não um trigger — é uma funcionalidade de
   infraestrutura, não lógica de negócio linha-a-linha.
5. **Atualizar créditos acumulados após aprovação** → **trigger** `AFTER UPDATE OF grade`,
   combinando-o possivelmente com uma restrição que impeça classificações inválidas.

---

## Grupo B — Consultas Recursivas

### 13. Conceito de consulta recursiva
Uma consulta recursiva (`WITH RECURSIVE`) permite calcular o **fecho transitivo** de uma relação,
combinando repetidamente uma tabela consigo mesma até não serem produzidas novas linhas.

a) Resolve problemas de **travessia de hierarquias/grafos** de profundidade desconhecida à partida
(árvores organizacionais, pré-requisitos encadeados, rotas numa rede, listas de materiais, etc.).

b) **Relação direta:** associação explícita entre dois elementos existente como uma linha na
tabela base (ex. `CS-347` tem pré-requisito direto `CS-101`, porque existe a linha
`(CS-347, CS-101)` em `prereq`). **Relação indireta:** associação que só existe através de uma
cadeia de relações diretas (ex. `CS-347` depende indiretamente de `CS-002` se `CS-347 → CS-101` e
`CS-101 → CS-002`).

c) Exemplo: encontrar todas as disciplinas, diretas e indiretas, de que `CS-347` depende, ou
todos os subordinados (diretos e indiretos) de um funcionário/diretor numa hierarquia de
`employee(manager_id)`.

d) Uma junção com número fixo de `JOIN`s só consegue percorrer um número fixo de "níveis" da
hierarquia (ex. 3 `JOIN`s chegam a 3 níveis de profundidade). Se a cadeia de pré-requisitos for
mais profunda do que esse número (ou variar de disciplina para disciplina), a consulta deixa de
capturar todas as dependências; a recursão resolve isto porque continua a aplicar o mesmo passo
"enquanto houver novas linhas a produzir", sem limite prévio.

### 14. Estrutura de uma consulta recursiva
a) **Consulta inicial (âncora):** fornece o(s) ponto(s) de partida da recursão — as linhas base de
onde a travessia começa (caso base).

b) **Consulta recursiva:** refere-se a si própria (à CTE `resultado`), combinando o resultado já
acumulado com a tabela base para produzir o "próximo nível"; é reaplicada repetidamente.

c) **Finalidade do `UNION`:** juntar o conjunto inicial com cada novo conjunto de linhas produzido
pela parte recursiva, acumulando o resultado final.

d) **Termina** quando uma iteração da parte recursiva não produz nenhuma linha nova (não há mais
combinações possíveis) — o motor para automaticamente nesse ponto.

e) **`UNION` vs `UNION ALL`:** `UNION` elimina duplicados a cada iteração (necessário, por exemplo,
quando o mesmo pré-requisito pode ser alcançado por caminhos diferentes, e também é o que evita
loops infinitos em grafos com ciclos); `UNION ALL` mantém todas as linhas, incluindo duplicadas, o
que é mais rápido mas pode entrar em ciclo infinito se existirem dependências circulares.

### 15. Pré-requisitos diretos
(ver `grupoB_recursive.sql`, exercício 15)

d) Estas consultas **não precisam de recursividade** porque pedem apenas relações **diretas**: uma
única leitura (ou um único `JOIN`) à tabela `prereq`/`course` é suficiente — não é necessário
percorrer níveis adicionais de dependência.

### 16. Análise de uma consulta recursiva
a) **Objetivo:** calcular, para cada disciplina, **todos** os pré-requisitos (diretos e indiretos),
isto é, o fecho transitivo da relação `prereq`.

b) **Parte inicial:** `SELECT course_id, prereq_id FROM prereq` — os pré-requisitos diretos, que
servem de base. **Parte recursiva:** o `JOIN` entre `rec_prereq` (o que já foi acumulado) e
`prereq`, que estende as cadeias em mais um "salto".

c) **Condição de junção:** `r.prereq_id = p.course_id` — liga o pré-requisito já encontrado (para
uma disciplina `r.course_id`) à disciplina da qual ele próprio é dependente em `prereq`,
"avançando" mais um nível na cadeia.

d) Em relação a uma consulta simples sobre `prereq` (que só dá pré-requisitos diretos), esta
consulta também devolve pré-requisitos **indiretos** — por exemplo, se `A` exige `B` e `B` exige
`C`, esta consulta também inclui `(A, C)`.

e) **Fecho transitivo:** o conjunto de todos os pares `(x, y)` tais que existe um caminho de `x`
para `y` através de uma ou mais relações diretas na relação original — aqui, todas as disciplinas
`y` de que `x` depende, direta ou indiretamente.

### 17–18. Ver `grupoB_recursive.sql`
(comparação pedida na alínea do ex. 17: o resultado do exercício 17 inclui também os pré-requisitos
**indiretos**, que o exercício 15 — sem recursão — não apresenta.)

**18d)** A diferença entre o exercício 18 e o 17 é o **sentido** da travessia: o exercício 17
percorre "para trás" (quais as disciplinas de que `CS-347` depende), enquanto o 18 percorre "para
a frente" (quais as disciplinas que dependem de `CS-101`) — tecnicamente é a mesma recursão
aplicada na direção inversa do grafo de pré-requisitos (basta trocar os papéis de `course_id` e
`prereq_id` na condição de junção e no caso base).

### 19. Análise de níveis de dependência (exercício só de raciocínio, sem SQL)

Estrutura: `BD2→BD1`, `BD1→FPG`, `IA→BD2`, `VC→IA`.

a) **Pré-requisitos diretos de `VC`:** apenas `IA`.

b) **Todos os pré-requisitos (diretos e indiretos) de `VC`:** `IA`, `BD2`, `BD1`, `FPG`.

c) **Distância (nº de relações) entre `VC` e cada pré-requisito:**
- `VC → IA`: 1 relação
- `VC → BD2`: 2 relações (`VC→IA→BD2`)
- `VC → BD1`: 3 relações (`VC→IA→BD2→BD1`)
- `VC → FPG`: 4 relações (`VC→IA→BD2→BD1→FPG`)

d) Uma consulta recursiva não precisa de saber a profundidade antecipadamente porque aplica o
**mesmo passo** (juntar o resultado acumulado com a tabela base, seguindo mais um elo da cadeia)
repetidamente, até que uma iteração não produza nenhuma linha nova — a recursão "para sozinha"
quando chega ao fim da cadeia, seja ela de profundidade 1 ou de profundidade 10.

### 20. Consultas recursivas e hierarquias
a) `employee(employee_id, name, manager_id)` representa uma hierarquia porque cada funcionário
aponta (via `manager_id`) para o seu superior direto, que é outra linha da mesma tabela —
é uma relação **reflexiva** que, seguida repetidamente, forma uma árvore (ou cadeia) de chefias.

b) Um funcionário **sem superior** (o topo da hierarquia) caracteriza-se por `manager_id IS NULL`.

c) e d) Ver `grupoB_recursive.sql`, exercício 20 (inclui coluna de nível hierárquico, incrementada a
cada passo recursivo: `nivel + 1`).

### 21. Limitações e cuidados com a recursividade
a) **Dependências circulares** (`A` exige `B` e `B` exige `A`): se a consulta usar `UNION ALL`
(que não elimina duplicados), a recursão **nunca termina** — entra em ciclo infinito, produzindo
cada vez mais linhas repetidas até esgotar recursos/tempo.

b) `UNION` elimina duplicados a cada iteração: ao detetar que uma combinação já tinha sido gerada
antes, não a volta a acrescentar, o que faz parar a recursão mesmo perante um ciclo, porque deixa
de haver *linhas novas* para produzir.

c) `UNION ALL` pode produzir resultados indesejados sempre que o mesmo par `(x, y)` possa ser
alcançado por **mais do que um caminho** (duplicação legítima de resultados) ou, pior, sempre que
existam ciclos no grafo (recursão infinita, como em a)).

d) Uma dependência circular entre disciplinas representa também um problema de **integridade dos
dados** porque, logicamente, nenhum aluno poderia nunca satisfazer os pré-requisitos (para fazer
`A` precisava de já ter feito `B`, mas para fazer `B` precisava de já ter feito `A`) — é uma
situação semanticamente impossível que a modelação deveria idealmente impedir (ex. com uma
restrição ou validação aplicacional), e não apenas um problema de desempenho da consulta.

---

## Grupo C — Agregação Avançada, Window Functions e OLAP

### 22. Funções de ranking
`RANK()`, `DENSE_RANK()` e `ROW_NUMBER()` atribuem uma posição a cada linha de um conjunto
ordenado (opcionalmente particionado).

a) Em caso de **empate** (valores iguais na coluna de ordenação), `RANK()` e `DENSE_RANK()`
atribuem a **mesma posição** a todas as linhas empatadas; `ROW_NUMBER()` atribui sempre posições
**distintas**, desempatando de forma arbitrária (ou segundo critério de desempate adicional no
`ORDER BY`).

b) **`RANK()` vs `DENSE_RANK()`:** depois de um empate, `RANK()` "salta" números (ex.: 1, 2, 2, 4),
enquanto `DENSE_RANK()` não deixa buracos na numeração (ex.: 1, 2, 2, 3).

c) `ROW_NUMBER()` é útil quando se quer **uma linha por posição**, sem empates, tipicamente para
paginação ou para escolher exatamente uma linha "representante" por grupo (ex. "a primeira
inscrição de cada aluno").

d) Exemplo na `university`: ordenar os docentes de `instructor` por `salary` decrescente e atribuir
`RANK()` para identificar o(s) docente(s) mais bem pago(s) por departamento.

### 24. Análise de empates no ranking (exercício de raciocínio)

| Estudante | Média | RANK() | DENSE_RANK() | ROW_NUMBER() (desempate por nome asc) |
|---|---|---|---|---|
| Ana | 18 | 1 | 1 | 1 |
| Bruno | 17 | 2 | 2 | 2 |
| Carla | 17 | 2 | 2 | 3 |
| Daniel | 15 | 4 | 3 | 4 |
| Eva | 14 | 5 | 4 | 5 |

d) `RANK()` produz intervalos (ex. salta de 2 para 4) porque conta todas as linhas anteriores,
incluindo as empatadas, antes de atribuir a posição seguinte — duas linhas em 2.º lugar "ocupam"
as posições 2 e 3, pelo que a próxima posição livre é a 4.

### 26d) Nota
`ROW_NUMBER()` pode não ser adequado para encontrar "o(s) docente(s) com salário mais elevado" por
departamento quando há empates, porque atribui sempre **exatamente uma linha** por posição,
"escolhendo" arbitrariamente um dos empatados e escondendo os restantes — ao passo que `RANK()`
(ou `DENSE_RANK()`) mostra todos os empatados na 1.ª posição.

### 27b) Nota
`PARTITION BY` define os **grupos independentes** dentro dos quais o ranking é recalculado do
zero (aqui, cada departamento); `ORDER BY` dentro de `OVER(...)` define o **critério de
ordenação** usado para atribuir as posições dentro de cada partição (aqui, salário decrescente).

### 27d) Nota
`DENSE_RANK() ... PARTITION BY dept_name` corretamente preserva **todos** os docentes empatados na
2.ª posição de cada departamento; `ORDER BY salary DESC LIMIT 2` aplicado a toda a tabela
devolveria apenas os 2 salários mais altos **de toda a universidade**, e não os 2 melhores **de
cada departamento** — não respeita o agrupamento por departamento.

### 29a) Nota sobre as funções de distribuição
- `PERCENT_RANK()`: posição relativa da linha, entre 0 e 1 (0 = primeira, 1 = última).
- `CUME_DIST()`: distribuição cumulativa — fração de linhas com valor menor ou igual ao da linha
  atual.
- `NTILE(4)`: divide as linhas ordenadas em 4 grupos de tamanho (quase) igual (quartis).

### 30. Conceito de window function
Uma *window function* calcula um valor para **cada linha individual**, com base numa "janela" de
linhas relacionadas (definida por `PARTITION BY`/`ORDER BY`), **sem colapsar** as linhas num único
resultado por grupo.

a) Com `GROUP BY`, uma função de agregação (`AVG`, `SUM`, ...) produz **uma linha por grupo**,
perdendo o detalhe das linhas individuais. Com `OVER()`, a mesma função é calculada **por linha**,
mantendo todas as linhas originais e acrescentando-lhes o valor agregado correspondente ao seu
grupo/janela.

b) `PARTITION BY` divide as linhas em subgrupos independentes, dentro dos quais a função é
recalculada (equivalente, em espírito, ao `GROUP BY`, mas sem perder linhas).

c) `ORDER BY` dentro de `OVER()` define a ordem pela qual as linhas são consideradas dentro da
janela — essencial para funções sensíveis à ordem (`RANK`, somas acumuladas, `LAG`/`LEAD`, médias
móveis).

d) Exemplo útil: mostrar, para cada docente, o seu salário **e** a média do seu departamento na
mesma linha, para calcular facilmente o desvio de cada um em relação à média (ver exercício 31).

### 32c-d) Notas
c) `UNBOUNDED PRECEDING` significa "desde a primeira linha da janela (sem limite anterior)";
`CURRENT ROW` significa "até à linha atual, inclusive" — juntos definem uma janela que cresce,
linha a linha, acumulando a soma de tudo o que já apareceu até ali.

d) Incluir `ID` no `ORDER BY` desempata linhas com o mesmo salário, garantindo uma **ordem
determinística** (reprodutível) para a soma acumulada; sem esse desempate, o SGBD poderia
ordenar linhas empatadas de forma diferente em execuções distintas, tornando o resultado da soma
acumulada instável entre linhas empatadas.

### 33. Médias móveis
a) Média móvel centrada (3 observações) para `2026-01-03`: usa `2026-01-02` (150), `2026-01-03`
(120) e `2026-01-04` (180) → `(150+120+180)/3 = 150`.

c) Na **primeira linha** (`2026-01-01`), não existe observação anterior, logo a janela
`1 PRECEDING AND 1 FOLLOWING` só tem 2 valores (a própria e a seguinte); na **última linha**
(`2026-01-05`), não existe observação seguinte, pelo que a janela também só tem 2 valores — em
ambos os casos o motor calcula a média apenas com as linhas realmente disponíveis na janela
(não há erro, apenas menos valores a médiar).

d) Aplicação prática: suavizar séries temporais ruidosas (vendas diárias, temperatura, preços de
ações) para identificar tendências sem o "ruído" das flutuações dia a dia.

### 34d) Nota
A função de janela permite conservar a informação individual sobre cada inscrição porque, ao
contrário de `GROUP BY` (que reduziria a consulta a uma linha por aluno), `COUNT(*) OVER (PARTITION
BY ID)` calcula o total de inscrições do aluno e **devolve-o repetido em cada uma das suas
linhas** de `takes`, mantendo visíveis `course_id`, `semester` e `year` de cada inscrição
individual.

### 35. Conceitos fundamentais de OLAP
OLAP (Online Analytical Processing) é um paradigma de processamento orientado à **análise
multidimensional** de grandes volumes de dados (em contraste com o OLTP, orientado a transações
do dia a dia).

a) **Objetivo:** permitir explorar os dados segundo múltiplas perspetivas (dimensões) de forma
rápida e interativa, para apoio à decisão.

b) **Dimensão:** atributo pelo qual se quer "cortar"/agrupar a análise (categórico, ex.
departamento, ano, semestre). **Medida:** valor numérico que se quer agregar/analisar (ex. número
de inscrições, soma de créditos).

c) Dimensões possíveis em `takes`: `year`, `semester`, departamento da disciplina (via `course`),
disciplina (`course_id`), aluno (`ID`).

d) Medidas possíveis: número de inscrições (`COUNT(*)`), média de classificações, soma de créditos
inscritos.

e) Analisar os mesmos dados por dimensões diferentes permite responder a perguntas distintas com o
mesmo conjunto de factos (ex. "quais os departamentos mais procurados" vs. "em que anos houve mais
inscrições"), sem necessidade de recolher novos dados.

### 36. Cross-tabulation e data cubes
a) **Cross-tabulation (tabela cruzada):** apresentação dos dados com uma dimensão nas linhas e
outra nas colunas, mostrando na interseção a medida agregada para essa combinação.

b) Dimensões: departamento, ano. Medida: número de inscrições.

c) Uma tabela cruzada teria uma linha por departamento e uma coluna por ano, com o número de
inscrições na célula correspondente a cada par (departamento, ano).

d) **Data cube:** generalização da tabela cruzada para **mais de duas dimensões** — uma estrutura
multidimensional onde cada "célula" corresponde a uma combinação de valores de todas as dimensões,
permitindo cortar os dados segundo qualquer subconjunto delas.

e) Acrescentar `semester` permite uma análise mais fina (por semestre dentro de cada ano),
possibilitando *drill-down* a partir do nível "ano" para o nível "ano+semestre".

### 37. Agregação com ROLLUP
c) **Níveis produzidos por `ROLLUP (dept_name, year)`:** (1) por `(dept_name, year)`; (2) subtotal
por `dept_name` (todos os anos); (3) total geral (sem agrupamento nenhum).

d) Os valores `NULL` nas colunas `dept_name`/`year` nas linhas de subtotal/total representam
**"todos os valores"** daquela dimensão (ex. `year = NULL` na linha de subtotal de um departamento
significa "este departamento, agregando todos os anos") — não significam ausência de dados.

e) Diferem dos `NULL` "reais" dos dados originais porque estes últimos representam genuinamente
um valor desconhecido/não aplicável numa linha de origem, enquanto os `NULL` do `ROLLUP`/`CUBE` são
**marcadores de agregação** introduzidos pelo motor; em PostgreSQL usa-se a função `GROUPING()`
precisamente para os distinguir sem ambiguidade.

### 38. Agregação com CUBE
b) **Agregações produzidas por `CUBE (dept_name, year)`:** todas as combinações possíveis —
`(dept_name, year)`, só `dept_name` (todos os anos), só `year` (todos os departamentos), e o total
geral (sem agrupamento). `ROLLUP` só produz um subconjunto hierárquico destas (não inclui "só
`year`").

d) `CUBE` é mais adequado quando se quer explorar **todas** as combinações possíveis das dimensões
(análise multidimensional completa/simétrica); `ROLLUP` é mais adequado quando existe uma
**hierarquia natural** entre as dimensões (ex. ano → semestre) e só interessam os subtotais que
respeitam essa ordem.

e) `GROUPING(coluna)` devolve `0` se a linha corresponde a um valor real daquela coluna, e `1` se
o `NULL` da linha é um marcador de agregação (subtotal) — permite distinguir programaticamente
"departamento desconhecido" de "subtotal de todos os departamentos", e filtrar/rotular as linhas
de subtotal de forma inequívoca.

### 39. Operações OLAP: pivot, slicing, rollup e drill-down
a) **Pivoting:** reorganizar a tabela de modo a trocar uma dimensão entre linhas e colunas (ex.
passar de "departamento nas linhas, ano nas colunas" para "ano nas linhas, departamento nas
colunas").

b) **Slicing:** fixar o valor de uma dimensão e analisar apenas esse "corte" (ex. `WHERE year =
2026`), reduzindo a dimensionalidade da análise.

c) **Rollup (subir de nível):** agregar de um nível mais detalhado (disciplina) para um nível mais
geral (departamento), somando os valores das disciplinas desse departamento.

d) **Drill-down (descer de nível):** o inverso — partir de totais por departamento e "abrir" para
ver o detalhe por disciplina dentro desse departamento.

e) Exemplo de questões de gestão: *slicing* → "quantas inscrições tivemos só em 2026?";
*rollup* → "qual o total de inscrições por departamento (independentemente da disciplina)?";
*drill-down* → "dentro do departamento de Comp. Sci., quais as disciplinas que mais pesam nesse
total?"; *pivoting* → "mostra-me a mesma informação mas com os anos em colunas, para comparar
visualmente ano a ano".
