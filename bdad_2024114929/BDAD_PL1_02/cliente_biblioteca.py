from getpass import getpass
import psycopg

# Substitua 2024114929 pelo seu número real, se necessário
NOME_BD = "bdad_2024114929"

def main():
    password = getpass("Palavra-passe de postgres: ")
    
    try:
        with psycopg.connect(
            host="localhost",
            port=5432,
            dbname=NOME_BD,
            user="postgres",
            password=password,
        ) as conn:
            with conn.cursor() as cur:
                # Tarefa 8: Listar todos os livros
                print("\n--- Catálogo Completo ---")
                cur.execute("""
                    SELECT l.id, l.titulo, a.nome, c.nome
                    FROM catalogo_livros AS l
                    JOIN autores_catalogo AS a ON a.id = l.autor_id
                    JOIN categorias_catalogo AS c ON c.nome = BTRIM(l.categoria_id::text) -- Ajustado via JOIN no SQL
                    ORDER BY l.titulo
                """)
                # Consulta ajustada e limpa:
                cur.execute("""
                    SELECT l.id, l.titulo, a.nome, c.nome
                    FROM catalogo_livros AS l
                    JOIN autores_catalogo AS a ON a.id = l.autor_id
                    JOIN categorias_catalogo AS c ON c.id = l.categoria_id
                    ORDER BY l.titulo
                """)
                for livro_id, titulo, autor, categoria in cur.fetchall():
                    print(f"{livro_id}: {titulo} — {autor} [{categoria}]")

                # Tarefa 9: Filtrar por ano mínimo
                print("\n--- Pesquisa por Ano Mínimo ---")
                ano_str = input("Introduza o ano mínimo de publicação: ")
                if ano_str.isdigit():
                    ano_minimo = int(ano_str)
                    cur.execute(
                        "SELECT titulo, ano FROM catalogo_livros WHERE ano >= %s ORDER BY ano",
                        (ano_minimo,),
                    )
                    for titulo, ano in cur.fetchall():
                        print(f"• {titulo} ({ano})")

                # Tarefa 9: Registar Empréstimo
                print("\n--- Registar Novo Empréstimo ---")
                opcao = input("Deseja registar um empréstimo? (s/n): ")
                if opcao.lower() == 's':
                    livro_id = int(input("ID do Livro: "))
                    nome_leitor = input("Nome do Leitor: ")
                    cur.execute(
                        "INSERT INTO emprestimos (livro_id, nome_leitor) VALUES (%s, %s)",
                        (livro_id, nome_leitor),
                    )
                    conn.commit()
                    print("Empréstimo registado com sucesso!")

    except Exception as e:
        print(f"Erro na ligação ou execução: {e}")

if __name__ == "__main__":
    main()