# Gestao Domestica

Aplicacao para profissional de servicos domesticos controlar agenda, compartilhar um link publico de disponibilidade com clientes e acompanhar uma gestao financeira simples.

## Tecnologias

- Backend: Node.js, Express e PostgreSQL
- App e pagina publica: Flutter
- Banco: PostgreSQL local ou hospedado

## Como rodar sem Docker

1. Crie um banco PostgreSQL local ou hospedado.

```powershell
createdb -U postgres gestao_domestica
```

Se preferir usar pgAdmin, crie um database chamado `gestao_domestica`.

2. Configure o backend em `backend/.env`.

Exemplo para PostgreSQL local:

```env
PORT=3000
DATABASE_URL=postgres://postgres:sua_senha@localhost:5432/gestao_domestica
PUBLIC_SLUG=sara-lima
PROFESSIONAL_NAME=Sara Lima
PROFESSIONAL_SERVICE=Empregada domestica e diarista
```

3. Instale e rode a API:

```powershell
cd backend
npm install
npm run dev
```

Ao iniciar, a API cria as tabelas automaticamente no banco configurado.

4. Rode o Flutter Web:

```powershell
cd frontend
flutter pub get
flutter run -d chrome --dart-define=API_URL=http://localhost:3000/api/v1
```

## Links principais

- App administrativo: `http://localhost:<porta-flutter>/`
- Pagina publica do cliente: `http://localhost:<porta-flutter>/#/public/sara-lima`
- API: `http://localhost:3000/api/v1`

## Teste local rapido

Para testar a interface sem configurar PostgreSQL, rode o backend temporario em memoria:

```powershell
cd backend
npm run dev:demo
```

Os dados desse modo sao apenas demonstrativos e voltam ao estado inicial quando o processo reinicia.

## Funcionalidades do MVP

- Cadastro e edicao dos dias disponiveis, ocupados ou indisponiveis.
- Link publico para o cliente visualizar a agenda e solicitar contratacao.
- Lista de solicitacoes recebidas pelo link.
- Registro financeiro de entradas e saidas.
- Resumo mensal com saldo, receitas e despesas.

## Publicar no Render

O arquivo `render.yaml` cria o banco PostgreSQL, a API Node e o site Flutter Web sem Docker.

1. Envie este projeto para um repositorio no GitHub.
2. Acesse `https://dashboard.render.com/blueprints`.
3. Clique em `New Blueprint Instance`.
4. Conecte o repositorio e confirme a criacao dos recursos.
5. Aguarde a API e o site ficarem com status `Live`.

O endereco publico esperado para a agenda sera:

`https://sara-lima-agenda.onrender.com/#/public/sara-lima`

O plano gratuito pode hibernar a API quando ela fica sem uso. A primeira abertura apos um periodo de inatividade pode levar alguns segundos.
