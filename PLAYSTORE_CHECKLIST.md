# Checklist de Publicação - Play Store (FloraCerta)

## 1. Build e qualidade
- [ ] `flutter analyze` sem erros.
- [ ] Teste real em pelo menos 2 aparelhos Android.
- [ ] Fluxos críticos validados: identificação, permissões, GPS, histórico.
- [ ] Gerar AAB: `flutter build appbundle --release`.

## 2. Segurança
- [ ] `ALLOW_CLIENT_SIDE_PLANT_KEY=false` em produção.
- [ ] `PLANT_ID_RELAY_URL` apontando para backend seguro.
- [ ] Sem secrets no repositório (`.env` fora do git).
- [ ] Mensagens de erro sem dados sensíveis.
- [ ] Somente HTTPS para conteúdo remoto.

## 3. Privacidade e conformidade
- [ ] Política de privacidade publicada e acessível.
- [ ] Formulário de Data safety preenchido no Console.
- [ ] Permissões declaradas com finalidade clara:
  - Câmera (captura de planta)
  - Localização (registro opcional da identificação)
  - Internet (consulta de identificação/dados complementares)

## 4. Play Console
- [ ] Nome, descrição curta/longa, categoria e contato.
- [ ] Ícone 512x512 e screenshots atualizados.
- [ ] Classificação indicativa preenchida.
- [ ] Teste interno antes de produção.

## 5. Versão
- [ ] `version` atualizado no `pubspec.yaml`.
- [ ] Notas da versão (changelog) preparadas.
- [ ] Tag/release no Git correspondente à build.

