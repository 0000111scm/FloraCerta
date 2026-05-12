# FloraCerta

App Flutter para identificar plantas por foto, registrar localização e organizar histórico/coleção pessoal.

## Status atual
- Identificação por imagem (1 a 5 fotos por análise).
- Captura de localização com precisão estimada.
- Histórico local, Minhas Plantas e Diagnóstico inicial.
- Tema claro/escuro e interface em PT-BR.

## Requisitos
- Flutter estável
- Android Studio (SDK + JDK)

## Configuração de ambiente
Crie `.env` na raiz com:

```env
SUPABASE_URL=
SUPABASE_ANON_KEY=
PLANT_ID_RELAY_URL=
ALLOW_CLIENT_SIDE_PLANT_KEY=false

# Opcional somente para testes locais, não recomendado em produção:
PLANT_ID_API_URL=https://my-api.plantnet.org/v2/identify/all
PLANT_ID_API_KEY=
```

## Segurança recomendada (produção)
- Use `PLANT_ID_RELAY_URL` (backend seu) e mantenha `ALLOW_CLIENT_SIDE_PLANT_KEY=false`.
- Não distribuir chave de provedor de identificação no app cliente.
- Não commitar `.env` (já está no `.gitignore`).

## Comandos úteis
```bash
flutter pub get
flutter analyze
flutter run
flutter build apk --release
flutter build appbundle --release
```

## Artefatos
- APK: `build/app/outputs/flutter-apk/app-release.apk`
- AAB (Play Store): `build/app/outputs/bundle/release/app-release.aab`

## Publicação Play Store
Use o checklist: [PLAYSTORE_CHECKLIST.md](PLAYSTORE_CHECKLIST.md)

