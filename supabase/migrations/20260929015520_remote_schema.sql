SET local check_function_bodies = off;

CREATE TABLE "public"."aluno_responsavel" (
  "id_aluno"          uuid    NOT NULL,
  "id_responsavel"    uuid    NOT NULL,
  "autorizado_buscar" boolean DEFAULT true,
  CONSTRAINT "aluno_responsavel_pkey" PRIMARY KEY (id_aluno, id_responsavel)
);

CREATE TABLE "public"."alunos" (
  "id_aluno"        uuid                        NOT NULL DEFAULT gen_random_uuid(),
  "id_usuario"      uuid,
  "nome"            character varying(150)      NOT NULL,
  "data_nascimento" date                        NOT NULL,
  "matricula"       character varying(50)       NOT NULL,
  "criado_em"       timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT "alunos_id_usuario_key" UNIQUE (id_usuario),
  CONSTRAINT "alunos_matricula_key" UNIQUE (matricula),
  CONSTRAINT "alunos_pkey" PRIMARY KEY (id_aluno)
);

CREATE TABLE "public"."competencias" (
  "id_competencia" uuid                   NOT NULL DEFAULT gen_random_uuid(),
  "nome"           character varying(100) NOT NULL,
  "descricao"      text,
  "categoria"      character varying(50),
  CONSTRAINT "competencias_nome_key" UNIQUE (nome),
  CONSTRAINT "competencias_pkey" PRIMARY KEY (id_competencia)
);

CREATE TABLE "public"."curso_competencias" (
  "id_curso"       uuid NOT NULL,
  "id_competencia" uuid NOT NULL,
  CONSTRAINT "curso_competencias_pkey" PRIMARY KEY (id_curso, id_competencia)
);

CREATE TABLE "public"."cursos" (
  "id_curso"      uuid                        NOT NULL DEFAULT gen_random_uuid(),
  "nome"          character varying(150)      NOT NULL,
  "descricao"     text,
  "carga_horaria" integer                     NOT NULL,
  "ativo"         boolean                     DEFAULT true,
  "criado_em"     timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT "cursos_pkey" PRIMARY KEY (id_curso)
);

CREATE TABLE "public"."matriculas" (
  "id_aluno"       uuid                        NOT NULL,
  "id_turma"       uuid                        NOT NULL,
  "data_matricula" timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT "matriculas_pkey" PRIMARY KEY (id_aluno, id_turma)
);

CREATE TABLE "public"."professor_competencias" (
  "id_professor"       uuid    NOT NULL,
  "id_competencia"     uuid    NOT NULL,
  "nivel_proficiencia" integer DEFAULT 3,
  CONSTRAINT "professor_competencias_nivel_proficiencia_check" CHECK (((nivel_proficiencia >= 1) AND (nivel_proficiencia <= 5))),
  CONSTRAINT "professor_competencias_pkey" PRIMARY KEY (id_professor, id_competencia)
);

CREATE TABLE "public"."professores" (
  "id_professor" uuid                        NOT NULL DEFAULT gen_random_uuid(),
  "id_usuario"   uuid,
  "nome"         character varying(150)      NOT NULL,
  "cpf"          character varying(14)       NOT NULL,
  "biografia"    text,
  "criado_em"    timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT "professores_cpf_key" UNIQUE (cpf),
  CONSTRAINT "professores_id_usuario_key" UNIQUE (id_usuario),
  CONSTRAINT "professores_pkey" PRIMARY KEY (id_professor)
);

CREATE TABLE "public"."responsaveis" (
  "id_responsavel" uuid                        NOT NULL DEFAULT gen_random_uuid(),
  "id_usuario"     uuid,
  "nome"           character varying(150)      NOT NULL,
  "cpf"            character varying(14)       NOT NULL,
  "telefone"       character varying(20)       NOT NULL,
  "criado_em"      timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT "responsaveis_cpf_key" UNIQUE (cpf),
  CONSTRAINT "responsaveis_id_usuario_key" UNIQUE (id_usuario),
  CONSTRAINT "responsaveis_pkey" PRIMARY KEY (id_responsavel)
);

CREATE TABLE "public"."turmas" (
  "id_turma"     uuid                        NOT NULL DEFAULT gen_random_uuid(),
  "id_curso"     uuid,
  "id_professor" uuid,
  "nome_turma"   character varying(100)      NOT NULL,
  "semestre"     character varying(20)       NOT NULL,
  "horario"      character varying(100),
  "vagas_maxima" integer                     DEFAULT 30,
  "ativo"        boolean                     DEFAULT true,
  "criado_em"    timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT "turmas_pkey" PRIMARY KEY (id_turma)
);

CREATE TABLE "public"."usuarios" (
  "id_usuario" uuid                        NOT NULL DEFAULT gen_random_uuid(),
  "email"      character varying(255)      NOT NULL,
  "senha_hash" character varying(255)      NOT NULL,
  "ativo"      boolean                     DEFAULT true,
  "criado_em"  timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT "usuarios_email_key" UNIQUE (email),
  CONSTRAINT "usuarios_pkey" PRIMARY KEY (id_usuario)
);

CREATE TYPE "public"."status_matricula" AS ENUM (
  'ATIVA',
  'TRANCADA',
  'CANCELADA',
  'CONCLUIDA'
);

ALTER TABLE "public"."matriculas"
  ADD COLUMN "status" public.status_matricula DEFAULT 'ATIVA'::public.status_matricula;

CREATE TYPE "public"."tipo_parentesco" AS ENUM (
  'PAI',
  'MAE',
  'TUTOR_LEGAL',
  'AVO',
  'OUTRO'
);

ALTER TABLE "public"."aluno_responsavel"
  ADD COLUMN "grau_parentesco" public.tipo_parentesco NOT NULL;

CREATE TYPE "public"."tipo_perfil" AS ENUM (
  'ALUNO',
  'PROFESSOR',
  'RESPONSAVEL',
  'ADMIN'
);

ALTER TABLE "public"."usuarios"
  ADD COLUMN "perfil" public.tipo_perfil NOT NULL;

CREATE OR REPLACE FUNCTION public.fn_matricular_aluno (
  p_id_aluno uuid,
  p_id_turma uuid
)
  RETURNS text
  LANGUAGE plpgsql
  AS $function$
DECLARE
  v_vagas_max INT;
  v_total_matriculados INT;
BEGIN
  -- 1. Busca o limite de vagas da turma
  SELECT vagas_maxima INTO v_vagas_max
  FROM turmas
  WHERE id_turma = p_id_turma;

  IF v_vagas_max IS NULL THEN
    RAISE EXCEPTION 'Turma não encontrada.';
  END IF;

  -- 2. Conta quantas matrículas ativas já existem na turma
  SELECT COUNT(*) INTO v_total_matriculados
  FROM matriculas
  WHERE id_turma = p_id_turma AND status = 'ATIVA';

  -- 3. Valida se a turma atingiu o limite
  IF v_total_matriculados >= v_vagas_max THEN
    RAISE EXCEPTION 'Matrícula recusada: a turma já atingiu o limite de % vagas.', v_vagas_max;
  END IF;

  -- 4. Insere ou reativa a matrícula
  INSERT INTO matriculas (id_aluno, id_turma, status)
  VALUES (p_id_aluno, p_id_turma, 'ATIVA')
  ON CONFLICT (id_aluno, id_turma) 
  DO UPDATE SET status = 'ATIVA';

  RETURN 'Matrícula realizada com sucesso!';
END;
$function$;

ALTER TABLE "public"."aluno_responsavel"
  ADD CONSTRAINT "aluno_responsavel_id_aluno_fkey" FOREIGN KEY (id_aluno) REFERENCES public.alunos(id_aluno) ON DELETE CASCADE;

ALTER TABLE "public"."curso_competencias"
  ADD CONSTRAINT "curso_competencias_id_competencia_fkey" FOREIGN KEY (id_competencia) REFERENCES public.competencias(id_competencia) ON DELETE CASCADE;

ALTER TABLE "public"."curso_competencias"
  ADD CONSTRAINT "curso_competencias_id_curso_fkey" FOREIGN KEY (id_curso) REFERENCES public.cursos(id_curso) ON DELETE CASCADE;

ALTER TABLE "public"."matriculas"
  ADD CONSTRAINT "matriculas_id_aluno_fkey" FOREIGN KEY (id_aluno) REFERENCES public.alunos(id_aluno) ON DELETE CASCADE;

ALTER TABLE "public"."professor_competencias"
  ADD CONSTRAINT "professor_competencias_id_competencia_fkey" FOREIGN KEY (id_competencia) REFERENCES public.competencias(id_competencia) ON DELETE CASCADE;

ALTER TABLE "public"."professor_competencias"
  ADD CONSTRAINT "professor_competencias_id_professor_fkey" FOREIGN KEY (id_professor) REFERENCES public.professores(id_professor) ON DELETE CASCADE;

ALTER TABLE "public"."aluno_responsavel"
  ADD CONSTRAINT "aluno_responsavel_id_responsavel_fkey" FOREIGN KEY (id_responsavel) REFERENCES public.responsaveis(id_responsavel) ON DELETE CASCADE;

ALTER TABLE "public"."turmas"
  ADD CONSTRAINT "turmas_id_curso_fkey" FOREIGN KEY (id_curso) REFERENCES public.cursos(id_curso) ON DELETE CASCADE;

ALTER TABLE "public"."turmas"
  ADD CONSTRAINT "turmas_id_professor_fkey" FOREIGN KEY (id_professor) REFERENCES public.professores(id_professor) ON DELETE SET NULL;

ALTER TABLE "public"."matriculas"
  ADD CONSTRAINT "matriculas_id_turma_fkey" FOREIGN KEY (id_turma) REFERENCES public.turmas(id_turma) ON DELETE CASCADE;

ALTER TABLE "public"."alunos"
  ADD CONSTRAINT "alunos_id_usuario_fkey" FOREIGN KEY (id_usuario) REFERENCES public.usuarios(id_usuario) ON DELETE CASCADE;

ALTER TABLE "public"."professores"
  ADD CONSTRAINT "professores_id_usuario_fkey" FOREIGN KEY (id_usuario) REFERENCES public.usuarios(id_usuario) ON DELETE CASCADE;

ALTER TABLE "public"."responsaveis"
  ADD CONSTRAINT "responsaveis_id_usuario_fkey" FOREIGN KEY (id_usuario) REFERENCES public.usuarios(id_usuario) ON DELETE CASCADE;

CREATE VIEW "public"."vw_match_professor_curso" AS  SELECT p.id_professor,
    p.nome AS professor_nome,
    c.id_curso,
    c.nome AS curso_nome,
    count(DISTINCT cc.id_competencia) AS total_requisitos_curso,
    count(DISTINCT pc.id_competencia) AS requisitos_atendidos,
    round((((count(DISTINCT pc.id_competencia))::numeric / (NULLIF(count(DISTINCT cc.id_competencia), 0))::numeric) * (100)::numeric), 0) AS porcentagem_match
   FROM (((public.professores p
     CROSS JOIN public.cursos c)
     JOIN public.curso_competencias cc ON ((c.id_curso = cc.id_curso)))
     LEFT JOIN public.professor_competencias pc ON (((p.id_professor = pc.id_professor) AND (cc.id_competencia = pc.id_competencia))))
  GROUP BY p.id_professor, p.nome, c.id_curso, c.nome;

CREATE POLICY "Admins podem ver todos os alunos" ON "public"."alunos"
  FOR ALL
  TO PUBLIC
  USING ((EXISTS ( SELECT 1
   FROM public.usuarios
  WHERE ((usuarios.id_usuario = auth.uid()) AND (usuarios.perfil = 'ADMIN'::public.tipo_perfil)))));

CREATE POLICY "Alunos veem apenas seus próprios dados" ON "public"."alunos"
  FOR SELECT
  TO PUBLIC
  USING ((id_usuario = auth.uid()));

GRANT EXECUTE ON FUNCTION "public"."fn_matricular_aluno"(uuid, uuid) TO PUBLIC, "anon", "authenticated", "postgres", "service_role";

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE "public"."aluno_responsavel" TO "anon", "authenticated", "postgres", "service_role";

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE "public"."alunos" TO "anon", "authenticated", "postgres", "service_role";

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE "public"."competencias" TO "anon", "authenticated", "postgres", "service_role";

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE "public"."curso_competencias" TO "anon", "authenticated", "postgres", "service_role";

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE "public"."cursos" TO "anon", "authenticated", "postgres", "service_role";

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE "public"."matriculas" TO "anon", "authenticated", "postgres", "service_role";

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE "public"."professor_competencias" TO "anon", "authenticated", "postgres", "service_role";

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE "public"."professores" TO "anon", "authenticated", "postgres", "service_role";

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE "public"."responsaveis" TO "anon", "authenticated", "postgres", "service_role";

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE "public"."turmas" TO "anon", "authenticated", "postgres", "service_role";

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE "public"."usuarios" TO "anon", "authenticated", "postgres", "service_role";

GRANT USAGE ON TYPE "public"."status_matricula" TO "postgres";

GRANT USAGE ON TYPE "public"."tipo_parentesco" TO "postgres";

GRANT USAGE ON TYPE "public"."tipo_perfil" TO "postgres";

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE "public"."vw_match_professor_curso" TO "anon", "authenticated", "postgres", "service_role";

