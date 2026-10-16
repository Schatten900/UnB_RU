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
- [ ] [#11 - Exportação em PDF do Histórico do Estudante](https://github.com/neatzzy/UnB_RU/issues/11)
- [ ] [#8 - Gestão de Restaurantes e Catracas](https://github.com/neatzzy/UnB_RU/issues/8)
- [ ] [#7 - Histórico Local da Catraca](https://github.com/neatzzy/UnB_RU/issues/7)

### Bruno Henrique Duarte

- [ ] [#16 - Extrato e Histórico](https://github.com/neatzzy/UnB_RU/issues/3)
- [ ] [#6 - Validação de Entrada](https://github.com/neatzzy/UnB_RU/issues/6)
- [ ] [#9 - Relatório Global de Acessos](https://github.com/neatzzy/UnB_RU/issues/9)
- [ ] [#14 - Inscrição Única no FastPass](https://github.com/neatzzy/UnB_RU/issues/14)

### Carlos Cauã Rocha

- [ ] [#4 - Autenticação do Funcionário](https://github.com/neatzzy/UnB_RU/issues/4)
- [ ] [#5 - Configuração de Ponto de Acesso](https://github.com/neatzzy/UnB_RU/issues/5)
- [ ] [#15 - Notificação de Sorteio](https://github.com/neatzzy/UnB_RU/issues/15)
- [ ] [#10 - Cardápio da Refeição Atual](https://github.com/neatzzy/UnB_RU/issues/10)

### Vitor Carlos Fernandes

- [ ] [#2 - Recarga de Saldo](https://github.com/neatzzy/UnB_RU/issues/2)
- **Regras de Negócio**
     - Usuário pode usar PIX ou cartão
     - Usuário deve ser um aluno
- [ ] [#1 - Cadastro de Usuário](https://github.com/neatzzy/UnB_RU/issues/1)
- **Regras de Negócio**
     - Alunos são separados de staff pelos 3 primeiros números (999 representa sempre staff, ano de matrícula representa aluno)
     - Usuário permanece logado após criar conta
     - Matrícula deve ser composta exatamente de 9 dígitos numéricos
- [ ] [#17 - Gestão de Turnos e Time-Frames](https://github.com/neatzzy/UnB_RU/issues/17)
- **Regras de Negócio**
     - Feito na pagina de staff
     - Apenas administradores ou superior podem fazer gestão
     - Página não é renderizada para staff normal
- [ ] [#12 - Exportação em PDF do Relatório de Operação](https://github.com/neatzzy/UnB_RU/issues/12)
- **Regras de Negócio**
     - Relatório deve conter cabeçalho padrão da UnB
     - Feito na pagina de staff
     - Apenas administradores gerais podem baixar relatório
     - Página não é renderizada para staff normal

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
| A preencher | A preencher | Descrever como a ferramenta foi utilizada, quais atividades auxiliou e como os resultados foram revisados e validados. |
