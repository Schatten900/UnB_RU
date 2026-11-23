# RU Manager

Sistema demonstrativo de gerenciamento dos Restaurantes Universitários (RUs) da Universidade de Brasília (UnB).

## Requisitos

- Ruby 3.2.3
- Bundler
- SQLite
- Serviço `cron` ativo no host, caso queira agendar as notificações do FastPass

## Como executar

No terminal, a partir da raiz do repositório:

```
cd projeto-rails
bundle install
bin/rails db:prepare
bin/rails server
```

A aplicação ficará disponível em `http://localhost:3000`. Para carregar os dados de demonstração:

```
bin/rails db:seed
```

Os dados de demonstração são carregados apenas no ambiente de desenvolvimento. As contas criadas são:

| Perfil | Matrícula | Senha |
|---|---|---|
| Estudante | `232040501` | `Demo1234!` |
| Funcionário | `999000001` | `Demo1234!` |
| Funcionário | `999000002` | `Demo1234!` |

O seed não cria uma conta de administrador. Para criar uma conta administrativa local, abra o console Rails com `bin/rails console` e execute:

```ruby
admin = Usuario.find_or_initialize_by(matricula: "999900001")
admin.nome = "Administrador de demonstração"
admin.senha = "Demo1234!"
admin.save!
```

Depois, entre em `http://localhost:3000/login` com a matrícula `999900001` e a senha `Demo1234!`.

## Perfis e permissões

O perfil não é escolhido manualmente: o sistema o calcula a partir do prefixo da matrícula durante a validação do usuário. As matrículas devem ter nove dígitos.

- **Estudante:** matrícula que não começa com `999`. Acessa cardápio, FastPass, notificações, recargas e o próprio extrato e histórico. Após o login, é encaminhado à área de estudante.
- **Funcionário:** matrícula que começa com `999`, mas não com `9999`. Acessa as ferramentas de operação, como configuração do ponto de acesso, terminal de validação e histórico local da catraca. Após o login, é encaminhado à área de operador.
- **Administrador:** matrícula que começa com `9999`. Acessa as funções administrativas, incluindo gestão de restaurantes, catracas, turnos, cotas e sorteios. Após o login, é encaminhado à administração geral.

O valor enviado pelo formulário para o campo `perfil` não altera essa classificação: ela é determinada pelo prefixo da matrícula.

## Testes automatizados

Execute os comandos abaixo no diretório `projeto-rails`. As suítes usam o banco de dados de teste (`storage/test.sqlite3`), separado do banco de desenvolvimento.

Para executar todos os testes RSpec:

```
bundle exec rspec
```

Para executar um arquivo RSpec específico:

```
bundle exec rspec spec/requests/fastpass_integracao_spec.rb
```

Para executar todas as funcionalidades Cucumber:

```
bundle exec cucumber
```

Para executar uma funcionalidade específica:

```
bundle exec cucumber features/fastpass_registration.feature
```

## Funcionalidades

### Arthur Menezes Botelho

- **Validação rigorosa do FastPass:** libera a entrada somente para estudantes contemplados, dentro do horário reservado e com saldo suficiente. O saldo só é debitado após a confirmação da passagem.
- **PDF do histórico do estudante:** exporta o extrato e o histórico respeitando os filtros e incluindo todos os registros correspondentes, mesmo os que não aparecem na página atual.
- **Gestão de restaurantes e catracas:** permite que administradores cadastrem, editem e removam restaurantes e catracas, mantendo cada catraca vinculada a um restaurante.
- **Histórico local da catraca:** permite ao funcionário consultar os acessos liberados e bloqueados da catraca que está operando.

### Bruno Henrique Duarte

- **Extrato e histórico:** permite ao estudante autenticado consultar somente suas próprias recargas e refeições, com data e valores correspondentes.
- **Validação de entrada:** verifica o saldo para o acesso comum e só debita o valor da refeição após a passagem ser confirmada.
- **Relatório global de acessos:** permite que administradores consultem os acessos e filtrem por restaurante e/ou catraca.
- **Inscrição única no FastPass:** permite ao estudante se inscrever gratuitamente em janelas disponíveis, com no máximo uma inscrição por turno no mesmo sorteio.

### Carlos Cauã Rocha

- **Autenticação do funcionário:** autentica funcionários dentro do horário permitido e cria uma sessão apenas após o login bem-sucedido.
- **Configuração do ponto de acesso:** permite ao funcionário autenticado selecionar um restaurante cadastrado como contexto de operação.
- **Notificação do sorteio:** informa se o estudante foi contemplado ou não, com mensagem correspondente ao resultado e registro de falhas de envio.
- **Cardápio da refeição atual:** exibe as opções cadastradas para a refeição em andamento e informa quando não há cardápio disponível.

### Vitor Carlos Fernandes

- **Recarga de saldo:** permite que estudantes façam recargas simuladas usando os métodos de pagamento disponíveis, como PIX ou cartão.
- **Cadastro de usuário:** cria contas com matrícula numérica de nove dígitos e identifica o perfil do usuário a partir da matrícula.
- **Gestão de turnos e janelas:** permite que administradores configurem turnos e time-frames de atendimento.
- **PDF do relatório de operações:** exporta o relatório com cabeçalho padrão da UnB; o acesso à exportação é restrito a administradores gerais.

As regras de negócio detalhadas estão na [wiki do projeto](../wiki/Home.md).

## Agendamento das notificações FastPass

O agendamento periódico é opcional para desenvolvimento local. Em um host com o ambiente de produção e o acesso ao banco configurados, instale a agenda no `cron` a partir do diretório `projeto-rails`:

```
RAILS_ENV=production bundle exec whenever --update-crontab projeto-rails
```

A agenda chama `NotificarFastPassJob` a cada minuto. Para removê-la:

```
bundle exec whenever --clear-crontab projeto-rails
```

O serviço `cron` do host precisa estar ativo. Para instalar a agenda em outro ambiente, substitua `production` pelo valor correspondente de `RAILS_ENV`.
