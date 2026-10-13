# Política de cobertura

Os testes unitários, de widget e de contrato geram cobertura de linhas. As metas
fixas estão em [`tool/coverage_rules.json`](../tool/coverage_rules.json), que é a
fonte de verdade para execução local e CI. Não são recalculadas a cada execução.

## Executar

Na raiz do projeto, com as dependências instaladas:

```sh
flutter test test --coverage
dart tool/check_coverage.dart
```

Para validar um LCOV existente, sem executar testes:

```sh
dart tool/check_coverage.dart coverage/lcov.info
```

O comando funciona no Windows e no Linux. Termina com código diferente de zero
quando alguma área fica abaixo da meta, não tem linhas medidas ou o arquivo de
cobertura está ausente/inválido.

## Relatórios automáticos

Cada execução substitui `reports/coverage-summary.md` e
`reports/coverage-summary.json`. Esses arquivos e o LCOV são ignorados pelo Git.
Não é preciso editar ou commitar percentuais após executar testes.

Os workflows **Tests** e **Release APK** publicam o resumo na página da execução
e disponibilizam os relatórios e o LCOV como artifacts, inclusive quando a
validação falha. A release só continua para o build se todas as metas passarem.
Este documento só precisa mudar quando a política ou os comandos mudarem.

## Método e limites

- Os registros `DA` determinam linhas medidas e executadas; contagem positiva
  significa linha coberta. Registros repetidos são unidos por arquivo e linha.
- Caminhos Windows e Linux são normalizados; `.g.dart` e `.freezed.dart` são
  excluídos de todas as áreas.
- Metas são comparadas sem arredondamento. O relatório exibe duas casas decimais.
- As features, camadas e total geral se sobrepõem; seus totais não devem ser somados.
- `Core/app` reúne os arquivos de `lib/` fora de `features/`.
- A cobertura representa somente as linhas presentes no LCOV. Arquivos ausentes
  não são considerados automaticamente 0%, e o relatório não comprova cobertura
  de toda linha existente no repositório.
- Não há gate de branches ou funções. Cobertura de integração Android e E2E
  não é incorporada a este LCOV. Essas suítes continuam complementando os testes.

Cobertura é um indicador, não substitui assertions relevantes, regras de negócio,
casos de erro, revisão ou verificações manuais dos serviços externos.
