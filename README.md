# 🎓 Matrix Education System (Matrix.Edu) - Banco de Dados

Este repositório contém a estrutura e o versionamento do banco de dados do projeto **Matrix.Edu**, utilizando **Supabase CLI**, **Docker** e **PostgreSQL**.

---

## 🛠️ Tecnologias Utilizadas

- **Banco de Dados:** [Supabase](https://supabase.com/) / PostgreSQL
- **Ambiente Dev:** Docker Desktop + WSL 2
- **Runtime & CLI:** Node.js, Supabase CLI
- **Controle de Versão:** Git & GitHub

---

## 📁 Estrutura do Projeto
```text
matrix-edu-backend/
├── supabase/
│   ├── config.toml         # Configurações do Supabase CLI
│   └── migrations/          # Scripts SQL com a estrutura do banco de dados
└── README.md               # Documentação do repositório
```

## 📜 Estrutura dos Scripts
- `01_autenticacao.sql` - Tabelas base de utilizadores e perfis.

- `02_nucleo_de_pessoas.sql` - Relacionamento entre alunos e responsáveis.

- `03_catalogo_e_competencias.sql` - Cursos, competências e mapeamentos.

- `04_nucleo_academico.sql` - Turmas e matrículas.

- `05_dados_ficticios.sql` - Script de seed com dados iniciais de teste.

- `06_consultas_teste.sql` - Testes de validação de queries.

- `07_excluir_dados_ficticios.sql` - Script de limpeza.

- `08_algoritmo_match_professor_e_curso.sql` - View de afinidade docente/curso (vw_match_professor_curso).

- `09_funcoes_rpc.sql` - Função transacional de matrícula (fn_matricular_aluno).

- `10_seguranca_rls.sql` - Políticas de acesso (Atualmente configuradas em mode DISABLE para desenvolvimento).

## 🚀 Como Executar Localmente
### Pré-requisitos:
1. Node.js instalado.
2. Docker Desktop rodando.
3. Supabase CLI configurado.

### Comandos Úteis
Sincronizar migrações locais com o banco remoto:
```bash
npx supabase db pull
```

Iniciar ambiente local do Supabase:
```bash
npx supabase start
```

## 📝 Histórico de Versões
- Fase 1: Extração da estrutura inicial do banco remoto e primeiro commit no GitHub.
