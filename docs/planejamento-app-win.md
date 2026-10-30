# Planejamento — Aplicativo WIN (cliente) · Flutter

> Documento de planejamento do app mobile do cliente (`win_app`), consumindo a API de produção do WIN. Foco inicial: **Android / Play Store**, iOS em seguida. Motorista e lojista ficam para fases futuras.

## 1. Visão e princípios
Construir o app de e-commerce hiperlocal onde o cliente se sinta **confortável, confiante e motivado a comprar**. Princípios que guiam toda decisão:
- **Fricção mínima** até o pagamento (poucos toques; login só quando necessário).
- **Transparência** (preço, frete e prazo claros antes de pagar).
- **Encantamento no pós-compra** (acompanhamento de entrega ao vivo = fidelização).
- **Rápido e confiável** (performance, offline gracioso, zero crash).
- **Confiança** (dados seguros, LGPD, visual profissional).

## 2. Estado atual do `win_app` (diagnóstico)
- **Stack:** Flutter 3.11, `provider`, `http`, `shared_preferences`, `qr_flutter`. `AppConfig.baseUrl` → `https://www.winmarketplace.com.br/api/v1` (produção).
- **13 telas em esqueleto:** login, forgot_password, product_details, cart, checkout, pix_payment, orders, order_detail, addresses, favorites, my_coupons, notifications, profile.
- **10 models** (product, order, cart, address, category, coupon, delivery, review, favorites, notification) e `api_service` já chamando categorias/produtos/busca/avaliações/endereços.
- **Veredito:** base real. O trabalho é **fundação técnica + encantamento + publicação**, não reescrever.

## 3. Decisões de arquitetura (confirmadas)
1. **Auth = telefone + OTP como primário** (`/auth/request-code` → `/auth/verify-code`, Twilio Verify, já em produção), com e-mail/senha (`/auth/login`) como secundário.
2. **Token em `flutter_secure_storage`** (Keychain/Keystore) — não mais `shared_preferences`. App movimenta dinheiro.
3. **Rede com `dio` + interceptors:** auth automático, **refresh de token**, retry e logging centralizados.
4. **Estrutura por feature** (não `screens/models/services` flat), preparando a adição de motorista/lojista sem virar bagunça. Mantém `provider` (sem reescrita de estado).

## 4. Escopo do v1 (cliente — MVP publicável)
1. **Login por telefone/OTP** (+ e-mail/senha).
2. **Home:** vitrine, categorias, lojas próximas, busca.
3. **Produto:** detalhe, galeria, avaliações, favoritos, ETA/estoque.
4. **Carrinho → checkout com PIX** (QR).
5. **Endereços** — incluindo **marcação do local de entrega no mapa** (mesma lógica do repositório principal: pino arrastável + geocodificação reversa preenchendo os campos; "usar minha localização" por GPS).
6. **Acompanhamento do pedido ao vivo** — status, entregador, veículo, ETA, código, **mapa ao vivo** (espelhando o `AcompanhamentoEntrega` do web).
7. **Histórico de pedidos, cupons, notificações in-app, perfil.**

## 5. Estratégia de pagamento
- **v1: PIX** (já pronto, instantâneo, barato, dominante no BR).
- **Fast-follow: carteira digital** — **Google Pay (Android)** e **Apple Pay (iOS)** via pacote `pay`; cartão tokenizado processado pelo Pagar.me.
  - **Pré-condições:** confirmar suporte a Apple/Google Pay na conta/doc atual do Pagar.me; habilitar **cartão com split**; Merchant ID + certificado (Apple) e Google Pay API (Android).
  - **Nota:** cartão tem taxa/prazo/chargeback diferentes do PIX — decisão de negócio antes de ligar.

## 6. Padrões de mercado a adotar (priorizados)
**v1:** navegar como visitante (login só no checkout) · endereço por GPS + pino no mapa · ETA/estoque no produto · skeleton loading, UI otimista, estados vazios, acessibilidade, dark mode · recompra a partir do histórico.
**Fase 2:** push (FCM) de status + reengajamento · login biométrico · home personalizada (comprar de novo, vistos recentemente) · busca rica (autocomplete, filtros, ordenação) · deep links / universal links · avaliação pós-entrega + in-app review · force-update + feature flags/remote config.
**Fase 3 (crescimento):** indique-e-ganhe / fidelidade · alertas de "voltou ao estoque" / "baixou o preço" · carteira digital ampla.

## 7. Mapeamento feature ↔ API (backend de produção)
| Feature | Endpoints (base `/api/v1`) |
|---|---|
| Login OTP | `POST /auth/request-code`, `POST /auth/verify-code` (+ `/auth/login`, `/auth/refresh`, `/auth/me`) |
| Catálogo/Home | `GET /categoria/list/principais`, `GET /produtos`, `GET /produtos/{id}` |
| Busca | `GET /produtos/buscar?nome=` |
| Avaliações | `GET /avaliacoes-produtos/produto/{id}` |
| Endereços | `GET/POST /enderecos/usuario/{userId}`, `DELETE /enderecos/{id}`, `PATCH /enderecos/{id}/principal` |
| Pedido | `GET /pedidos/usuario/{id}`, `GET /pedidos/{id}`, `POST /pedidos`, `PUT /pedidos/{id}/itens`, `PATCH /pedidos/{id}/cancelar` |
| Pagamento PIX | `POST /pagamentos/pagarme/pix/{id}`, `/pagamentos/pedido/{id}/pix/obter-ou-recriar`, `GET /pagamentos/{orderId}/status` |
| Frete | `POST /fretes/calcular` |
| Acompanhamento entrega | `GET /entregas/pedido/{id}` + WebSocket ao vivo (mesmo do web) |
| Cupons | `GET /cupom/validar/{codigo}`, `GET /cupom/meus` |
| Notificações | `list/usuario/{id}`, `count-nao-lidas/usuario/{id}`, `PATCH /lida/{id}`, `/todas-lidas/usuario/{id}`, `DELETE /delete/{id}` |

## 8. Não-funcional (qualidade mobile)
- **Segurança:** `flutter_secure_storage`; sem logar token/PII; (opcional) cert pinning.
- **Observabilidade:** Firebase **Crashlytics** + **Analytics** (funil de compra).
- **Push:** **FCM** — status de pedido e reengajamento (com opt-out, alinhado à LGPD).
- **Ambientes:** *flavors* dev/prod (`AppConfig` por flavor).
- **Resiliência:** tratamento de erro consistente, offline gracioso, UI otimista.
- **Performance:** listas virtualizadas, imagens otimizadas/cacheadas, cold start enxuto.

## 9. Publicação (Play Store primeiro)
- **Trilhas:** teste interno → fechado (beta) → produção.
- **Play App Signing**, `applicationId`, versionamento (`version+build`).
- **Ícone + splash**, store listing (descrição, screenshots, vídeo).
- **Data Safety form** do Google — declarar dados coletados, alinhado à **Política de Privacidade** já redigida (link obrigatório).
- **iOS/App Store:** mesma base Flutter; usar a conta Apple em configuração; Apple Pay entra aqui.

## 10. Roadmap em fases
- **Fase 0 — Fundação:** secure storage; `dio` + interceptors (auth/refresh/retry/log); estrutura por feature; flavors dev/prod; design system base (cores/tipografia/componentes); **auth OTP**; fix da busca (`?nome=`); baseUrl única.
- **Fase 1 — Núcleo de compra:** home → produto → carrinho → **checkout PIX** → pedido → **acompanhamento ao vivo**; **mapa de local de entrega**; endereços. → **teste interno na Play**.
- **Fase 2 — Encantamento + publicação:** push (FCM), Crashlytics/Analytics, polish de UX (skeleton/dark mode/biometria), busca rica, deep links, in-app review, Data Safety → **produção Android**.
- **Fase 3 — Carteira digital + crescimento:** Google/Apple Pay, fidelidade/indicação, alertas de estoque/preço; **release iOS**.
- **Fase 4+ —** apps de **motorista** e **lojista**.

## 11. Riscos e mitigação
- **Endpoints divergentes** entre o `api_service` atual e o backend → validado no onboarding (ex.: busca `?q`→`?nome`).
- **Carteira digital** depende de habilitação no Pagar.me (cartão + split) → confirmar antes de prometer.
- **Reputação na loja** (crash/avaliações ruins no lançamento) → testar bem nas trilhas interna/fechada antes de produção.
- **Escopo inflar** → disciplina no recorte v1; encantamento vem em camadas.

## 12. Próximos passos
Começar pela **Fase 0** (fundação), que destrava tudo com baixo risco. Em seguida, Fase 1 tela a tela, sempre contra a API de produção, validando o fluxo de compra ponta a ponta antes de abrir a trilha de teste interno na Play.
