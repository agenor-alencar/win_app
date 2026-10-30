# win_app — Aplicativo WIN (cliente) · Flutter

> Leia `docs/planejamento-app-win.md` antes de qualquer ação — é o plano mestre.
> Após mudanças estruturais, atualize este arquivo e o planejamento.

## O que é
App mobile do CLIENTE do WIN Marketplace (quick commerce, Brasília/DF), em Flutter.
Consome a API de PRODUÇÃO do WIN (backend Spring Boot, repo `agenor-alencar/win`)
em https://www.winmarketplace.com.br/api/v1. Motorista e lojista são fases futuras.

## Decisões de arquitetura (não reverter sem combinar)
- Auth: telefone + OTP (`/auth/request-code` → `/auth/verify-code`) como primário;
  e-mail/senha (`/auth/login`) secundário.
- Token em flutter_secure_storage (nunca shared_preferences; nunca em log).
- Rede com dio + interceptors (auth, refresh automático no 401, retry, log só em debug).
- Estrutura por feature (lib/core + lib/features/*); estado com provider.
- Pagamento: PIX no v1; carteira digital (Google/Apple Pay) como fast-follow.
- Local de entrega: pino no mapa + geocodificação reversa + GPS (igual ao web).

## Regras
- Nunca commitar segredo/token/chave (.env fora do git).
- Manter o app compilando a cada etapa; mudanças sempre via PR.
- Backend é a fonte da verdade da API — validar endpoints contra o repo `win`.
- baseUrl única (unificar a duplicação atual AppConfig × AuthService).
