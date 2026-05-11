# FloraCerta

**FloraCerta** é um aplicativo Flutter para identificação, registro e acompanhamento de plantas.

O objetivo do projeto é permitir que o usuário identifique plantas por foto ou descrição, consulte informações importantes sobre cada espécie, registre suas próprias plantas e acompanhe cuidados, evolução, saúde e localização de cada registro.

---

## Objetivo do App

Criar uma solução prática para:

- Identificar plantas por imagem.
- Identificar plantas por descrição manual.
- Exibir informações confiáveis sobre cada espécie.
- Registrar plantas pessoais do usuário.
- Acompanhar evolução, cuidados, doenças, pragas e histórico.
- Salvar localização aproximada das plantas identificadas.
- Organizar um histórico completo de registros botânicos.

---

## Funcionalidades Planejadas

### Identificação de Plantas

- Identificação por foto.
- Identificação por descrição/manual.
- Exibição do nome popular.
- Exibição do nome científico.
- Nível de confiança da identificação.
- Lista de espécies parecidas.
- Comparação entre fotos antigas e novas.

---

### Informações da Planta

O app deverá exibir informações básicas e úteis sobre cada planta, incluindo:

- Necessidade de sol.
- Frequência de água.
- Tipo de solo recomendado.
- Cuidados com poda.
- Cuidados com adubação.
- Toxicidade para pets e crianças.
- Perfil completo da planta.
- Banco de conhecimento com pragas e doenças comuns.

---

### Registro Pessoal de Plantas

O usuário poderá cadastrar suas próprias plantas com:

- Nome/apelido personalizado.
- Fotos da planta.
- Diário da planta.
- Observações manuais.
- Histórico de evolução.
- Linha do tempo da planta.
- Perfil completo individual.

---

### Saúde, Doenças e Pragas

O app deverá ajudar no acompanhamento da saúde da planta com:

- Registro de doenças.
- Registro de pragas.
- Diagnóstico por IA usando foto ou sintomas.
- Plano de recuperação da planta.
- Histórico de tratamentos aplicados.
- Alertas preventivos baseados em clima/local.

---

### Lembretes e Cuidados

O usuário poderá configurar lembretes para:

- Rega.
- Adubação.
- Poda.
- Troca de vaso.

---

### Localização e Mapa

O app deverá registrar informações de localização para plantas identificadas ou cadastradas:

- Salvamento da localização aproximada.
- Data e hora do registro.
- Exibição das plantas identificadas no mapa.
- Tela de mapa da flora encontrada.
- Filtros por espécie, data e local.
- Controle de privacidade da localização.

---

### Histórico e Organização

O app deverá permitir:

- Salvar cada identificação no histórico.
- Salvar localização exata ou aproximada da identificação.
- Filtrar registros por espécie.
- Filtrar registros por data.
- Filtrar registros por local.
- Modo offline básico para plantas salvas.
- Relatório ou linha do tempo da planta.

---

## Tecnologias Utilizadas

- **Flutter**
- **Dart**
- Estrutura preparada para uso futuro de:
  - Banco de dados local.
  - Geolocalização.
  - Mapa.
  - Câmera.
  - Integração com IA.
  - API de identificação de plantas.

---

## Estrutura Inicial do Projeto

```text
floracerta/
├── lib/
│   ├── main.dart
│   ├── app/
│   ├── models/
│   ├── screens/
│   ├── services/
│   ├── widgets/
│   └── utils/
├── assets/
├── pubspec.yaml
└── README.md
