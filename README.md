# FloraCerta

Aplicativo mobile em Flutter para identificar plantas por foto, registrar localizacao e acompanhar a evolucao das plantas.

## Visao geral

O FloraCerta foi estruturado por features para evolucao incremental, com foco em:

- Identificacao de plantas por imagem com API externa.
- Registro de localizacao (exata, aproximada ou sem localizacao).
- Historico local de identificacoes.
- Gestao de plantas pessoais e diario.
- Diagnostico inicial de doencas e pragas.

## Funcionalidades implementadas

### Home
- Navegacao para todas as areas principais.
- Tema claro, escuro e sistema.

### Identificacao
- Captura por camera.
- Selecao da galeria.
- Preview com opcao de remover foto.
- Dica rapida de captura para melhorar o reconhecimento.
- Botao de identificar fixo no rodape.
- Integracao com API externa de identificacao.
- Tratamento robusto de falhas e casos sem correspondencia.

### Localizacao
- Captura de latitude e longitude.
- Conversao para endereco aproximado.
- Privacidade configuravel:
  - Nao salvar
  - Aproximada
  - Exata

### Historico e Minhas plantas
- Salvamento local das identificacoes.
- Filtros basicos no historico.
- Cadastro manual de plantas.
- Diario e status de saude.

### Diagnostico
- Formulario estruturado.
- Resultado de exemplo para evolucao do fluxo.
- Salvamento no historico da planta.

## Estrutura do projeto

```text
lib/
├── app.dart
├── main.dart
├── core/
│   ├── config/
│   ├── theme/
│   ├── utils/
│   └── widgets/
├── features/
│   ├── home/
│   ├── identification/
│   ├── history/
│   ├── map/
│   ├── my_plants/
│   ├── diagnosis/
│   └── settings/
└── services/
```

## Configuracao de ambiente

Crie ou atualize o arquivo `.env` na raiz:

```env
SUPABASE_URL=
SUPABASE_ANON_KEY=
PLANT_ID_API_URL=https://my-api.plantnet.org/v2/identify/all
PLANT_ID_API_KEY=sua_chave
```

## Como rodar localmente

```bash
flutter pub get
flutter analyze
flutter run
```

## Gerar APK

```bash
flutter build apk
```

Saida padrao:

`build/app/outputs/flutter-apk/app-release.apk`

## Roadmap tecnico

- Integrar Supabase (autenticacao e persistencia remota).
- Integrar mapa real com marcadores.
- Evoluir identificacao e diagnostico com IA real.
- Melhorar ainda mais tratamento de erro e estados de carregamento.
