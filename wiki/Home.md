# Projeto UnB RU

## 1. Identificação

| Campo | Informação |
|---|---|
| Projeto | UnB RU |
| Sprint entregue | Sprint 1 |
| Período da entrega 1 | 09/10/2026 a 16/10/2026 |
| Período da entrega 2 | 16/10/2026 a 23/10/2026 |

## 2. Integrantes

| Nome | Matrícula | Papel |
|---|---|---|
| Arthur Menezes Botelho | 231003362 | Scrum Master |
| Bruno Henrique Duarte | 221022239 | Desenvolvedor |
| Carlos Cauã Rocha | 231034304 | Desenvolvedor     |
| Vitor Carlos Fernandes | 190142332 | Product Owner |

## 3. Divisão das Issues

### Arthur Menezes Botelho

- [ ] [#16 - Validação Rigorosa FastPass](https://github.com/neatzzy/UnB_RU/issues/16)
  - Regras de negócio: No modo exclusivo FastPass, apenas alunos sorteados, dentro do horário reservado e com saldo suficiente podem ter a entrada liberada. Caso contrário, a entrada é bloqueada sem débito. O saldo só é descontado após a confirmação da passagem pela catraca.

- [ ] [#11 - Exportação em PDF do Histórico do Estudante](https://github.com/neatzzy/UnB_RU/issues/11)
  - Regras de negócio: O estudante pode exportar seu extrato de recargas e histórico de refeições em PDF. A exportação deve respeitar os filtros aplicados e incluir todos os registros correspondentes, mesmo se não aparecem na tela devido ao limite de paginação. Caso o histórico seja vazio, o PDF ainda assim deve ser gerado, sem registros.

- [ ] [#8 - Gestão de Restaurantes e Catracas](https://github.com/neatzzy/UnB_RU/issues/8)
  - Regras de negócio: Apenas administradores podem cadastrar, editar e remover restaurantes e catracas. Cada catraca deve estar associada a um restaurante. Usuários sem permissão administrativa não podem realizar essas operações.

- [ ] [#7 - Histórico Local da Catraca](https://github.com/neatzzy/UnB_RU/issues/7)
  - Regras de negócio: O funcionário pode visualizar apenas os registros de acesso da catraca que está gerenciando, incluindo acessos liberados e bloqueados. Registros de outras catracas não devem ser exibidos.


### Bruno Henrique Duarte

- [ ] [#3 - Extrato e Histórico](https://github.com/neatzzy/UnB_RU/issues/3)

    **Regras de negócio**

    - A consulta do extrato e do histórico exige que o estudante esteja autenticado.
    - O estudante deve visualizar somente as recargas e refeições vinculadas a sua identificação.
    - O extrato deve apresentar a data e o valor de cada recarga feita pelo estudante.
    - O histórico deve apresentar a data, o tipo de refeição e o valor debitado para cada uso.
    - Quando não houver registros, deve ser informado que não há recargas ou refeições.

- [ ] [#6 - Validação de Entrada](https://github.com/neatzzy/UnB_RU/issues/6)

    **Regras de negócio**

    - A aplicação de controle deve ler a identificação do aluno para consultar o saldo.
    - A aplicação deve enviar o comando de liberação para a catraca quando o saldo do aluno for maior ou igual ao valor da refeição.
    - Quando o saldo for menor que o valor da refeição a aplicação não deve liberar a catraca nem efetuar o débito.
    - O débito deve ser do valor da refeição e ocorrer somente com passagem do aluno pela catraca.
    - A leitura da identificação e o envio do comando de liberação, sem a passagem, não deve debitar a refeição.

- [ ] [#9 - Relatório Global de Acessos](https://github.com/neatzzy/UnB_RU/issues/9)

    **Regras de negócio**

    - Somente um administrador autenticado pode consultar o relatório.
    - A consulta sem filtros deve mostrar todos os acessos registrados.
    - O filtro por restaurante deve mostrar somente os acessos relacionados ao restaurante selecionado.
    - O filtro por catraca deve mostrar somente os acessos relacionados a catraca selacionada.
    - Quando os filtros de restaurante e catraca forem usados juntos, devem mostrar somente os acessos que atendem aos dois filtros.
    - Quando não houver acessos que atendam aos filtros, a consulta não deve mostrar nenhum acesso.

- [ ] [#14 - Inscrição Única no FastPass](https://github.com/neatzzy/UnB_RU/issues/14)

    **Regras de negócio**

    - O estudante deve estar autenticado para realizar sua inscrição no sorteio do FastPass.
    - A inscrição no sorteio é gratuita.
    - Para confirmar a inscrição, o estudante deve escolher um time-frame disponível no turno da refeição.
    - Cada estudante pode ter somente uma inscrição, em um único time-frame, por turno da refeição no mesmo sorteio.
    - A tentativa de inscrição em outro time-frame no mesmo turno não deve ser aceita e deve manter a inscrição original.
    - O estudante pode se inscrever em turnos diferentes do mesmo sorteio.

### Carlos Cauã Rocha

- [ ] [#4 - Autenticação do Funcionário](https://github.com/neatzzy/UnB_RU/issues/4)

    **Regras de negócio**

    - O funcionário deve informar credenciais válidas para realizar o login.
    - O sistema deve permitir autenticação apenas dentro do horário permitido de operação.
    - Credenciais válidas não garantem acesso caso o login ocorra fora do horário permitido.
    - Após autenticação bem-sucedida, o sistema deve criar uma sessão autenticada para o funcionário.
    - Apenas funcionários autenticados podem acessar e operar as funcionalidades administrativas.
    - Caso o sistema esteja indisponível durante a autenticação, nenhuma sessão deve ser criada.
    - O sistema deve informar ao funcionário quando o serviço de autenticação estiver indisponível.


- [ ] [#5 - Configuração de Ponto de Acesso](https://github.com/neatzzy/UnB_RU/issues/5)

    **Regras de negócio**

    - A seleção de restaurante só pode ser realizada por funcionários autenticados.
    - O funcionário deve selecionar um restaurante previamente cadastrado no sistema.
    - O restaurante selecionado deve ser definido como contexto de gerenciamento da sessão atual.
    - As regras de negócio aplicadas pelo sistema devem considerar o restaurante selecionado.
    - Todas as operações realizadas devem ser registradas em log associadas ao restaurante selecionado.
    - O sistema deve impedir o acesso à configuração caso o funcionário não esteja autenticado.
    - Caso o sistema esteja indisponível, a configuração do restaurante não deve ser realizada.
    - O sistema deve informar ao usuário quando houver indisponibilidade do serviço.

- [ ] [#15 - Notificação de Sorteio](https://github.com/neatzzy/UnBnB_RU/issues/15)

    **Regras de negócio**

    - Todo estudante participante do sorteio deve possuir um resultado associado (ganhou ou não ganhou).
    - As notificaçõesões devem ser enviadas quando faltar uma hora para o turno do estudante.
    - Estudantes contemplados devem receber uma notificação informando a obtenção do FastPass.
    - Estudantes não contemplados devem receber uma notificação informando que não foram sorteados.
    - O conteúdo da notificação deve refletir corretamente o resultado do sorteio.
    - O sistema deve confirmar o envio apenas quando a notificação for entregue com sucesso.
    - Caso o serviço de notificação esteja indisponível, o envio não deve ser confirmado.
    - Falhas de envio devem ser tratadas conforme a política de tratamento de erros definida pelo sistema.

- [ ] [#10 - Cardápio da Refeição Atual](https://github.com/neatzzy/UnB_RB_RU/issues/10)

    **Regras de negócio**

    - O sistema deve exibir apenas o cardápio referente à refeição que está sendo servida no momento.
    - O cardápio deve disponibilizar as opções padrão, ovolactovegetariana e vegetariana estrita quando cadastradas.
    - Os dados exibidos devem corresponder às informações cadastradas para a refeição atual.
    - O estudante deve poder consultar o cardápio da refeição atual
    - Quando houver cardápio disponível, o sistema deve apresentar suas opções ao usuário
    - Quando não houver cardápio disponível para a refeição atual, o sistema deve informar indisponibilidade do cardápio.



### Vitor Carlos Fernandes

- [ ] [#2 - Recarga de Saldo](https://github.com/neatzzy/UnB_RU/issues/2)
- [ ] [#1 - Cadastro de Usuário](https://github.com/neatzzy/UnB_RU/issues/1)
- [ ] [#17 - Gestão de Turnos e Time-Frames](https://github.com/neatzzy/UnB_RU/issues/17)
- [ ] [#12 - Exportação em PDF do Relatório de Operação](https://github.com/neatzzy/UnB_RU/issues/12)


## 4. Padrões do Grupo

### 4.1. Padrão de Commit

O padrão adotado pelo grupo é o **Conventional Commits**, seguindo o formato:

`<tipo>(<escopo opcional>): <descrição curta no imperativo>`

O corpo do commit é opcional.

| Tipo | Uso |
|---|---|
| `feat` | Nova funcionalidade |
| `fix` | Correção de bug |
| `docs` | Alterações na documentação |
| `style` | Formatação sem mudanças na lógica |
| `test` | Adição ou alteração de testes |

**Exemplo:**

```
feat(autenticacao): adicionar autenticacao de funcionarios
```

### 4.2. Política de Branching

| Branch | Finalidade |
|---|---|
| `main` | Código principal do projeto |
| `sprint-n` | Branch de integração da sprint |
| `sprint-n-feature-usuario/nome-curto` | Branch para desenvolvimento de funcionalidades |
| `sprint-n-fix-usuario/nome-curto` | Branch para correção de bugs |

Em que `n` representa o número da sprint, `usuario` identifica o integrante responsável e `nome-curto` descreve resumidamente a funcionalidade ou correção.

### 4.3. Política de Revisão

- Todo merge deve ser realizado por meio de um Pull Request (PR).
- Todo PR deve receber, no mínimo, uma aprovação de outro integrante do grupo.
- Todo PR deve referenciar a feature correspondente.

## 5. Uso de IA na Sprint

Durante a sprint, ferramentas de Inteligência Artificial podem ser utilizadas como apoio ao desenvolvimento. O uso dessas ferramentas deve ser documentado, especificando a ferramenta utilizada, as partes do projeto em que foi aplicada e a estratégia adotada.

| Ferramenta de IA | Parte do projeto | Estratégia de utilização |
|---|---|---|
| GitHub Copilot | Edições gerais de arquivos | O GitHub Copilot foi utilizado dentro do VS Code, auxiliando no autocomplete e na formatação de arquivos de forma geral, acelerando o processo de escrita e edição sem substituir o trabalho do desenvolvedor |
