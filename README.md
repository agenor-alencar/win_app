<div align="center">

# 🛒 WIN Marketplace — App Mobile

**Aplicativo do cliente do WIN Marketplace, o marketplace local que conecta você às lojas da sua região.**

[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.x-0175C2?logo=dart&logoColor=white)](https://dart.dev)
[![Plataformas](https://img.shields.io/badge/Plataformas-Android%20%7C%20iOS-success)](#-como-executar)
[![Status](https://img.shields.io/badge/Status-Em%20desenvolvimento-yellow)](#)

</div>

---

## 📱 Sobre o projeto

Este é o aplicativo mobile (Flutter) do **WIN Marketplace** ([winmarketplace.com.br](https://www.winmarketplace.com.br)). Ele consome a API REST da plataforma web e entrega ao cliente a experiência completa de compra na palma da mão:

| | Funcionalidade | Descrição |
|---|---|---|
| 🔐 | **Autenticação** | Login, criação de conta e recuperação de senha com token JWT |
| 🏬 | **Vitrine de produtos** | Catálogo com busca, categorias e detalhes do produto com avaliações |
| ❤️ | **Favoritos** | Marque e gerencie seus produtos preferidos |
| 🛒 | **Carrinho** | Adicione produtos, ajuste quantidades e acompanhe o subtotal |
| 📍 | **Endereços** | Cadastre, exclua e defina o endereço principal, com preenchimento automático por CEP |
| 💳 | **Checkout com PIX** | Criação do pedido e pagamento instantâneo via PIX (Pagar.me) |
| 📦 | **Meus pedidos** | Histórico de compras com acompanhamento de status e cancelamento |

## 🏗️ Arquitetura

O app segue uma separação simples em camadas — **models**, **services** (acesso à API) e **screens** (UI) — com gerenciamento de estado via [Provider](https://pub.dev/packages/provider):

```
lib/
├── main.dart                  # Entry point, rotas e tela inicial (vitrine)
├── config/
│   └── app_config.dart        # URL base da API (dev/prod em um único lugar)
├── models/                    # Entidades: Product, Cart, Address, Order, ...
├── screens/                   # Telas: login, carrinho, checkout, endereços, ...
└── services/                  # Integração com a API REST (http + JWT)
```

**Principais dependências:**

- [`provider`](https://pub.dev/packages/provider) — estado do carrinho e favoritos
- [`http`](https://pub.dev/packages/http) — consumo da API REST
- [`shared_preferences`](https://pub.dev/packages/shared_preferences) — persistência do token JWT e dados do usuário
- [`device_frame`](https://pub.dev/packages/device_frame) — moldura de celular ao rodar no desktop (DX)

## 🔌 Integração com a API

Toda a comunicação usa a API REST oficial da plataforma:

```
https://www.winmarketplace.com.br/api/v1
```

- As requisições autenticadas enviam o header `Authorization: Bearer <token>`.
- O catálogo de endpoints (`endpoints.json`) **não é versionado** — solicite a documentação da API à equipe.
- Para apontar para outro ambiente, altere apenas `lib/config/app_config.dart`.

## 🚀 Como executar

### Pré-requisitos

- [Flutter SDK 3.x](https://docs.flutter.dev/get-started/install) (canal `stable`)
- Para Android: Android Studio + um AVD configurado, ou um dispositivo físico com depuração USB

### Passo a passo

```bash
# 1. Clone o repositório
git clone <url-do-repositorio>
cd win_app

# 2. Instale as dependências
flutter pub get

# 3. Rode no dispositivo/emulador desejado
flutter emulators --launch <id-do-emulador>   # opcional: inicia um AVD
flutter run                                   # compila e instala
```

💡 **Dica de desenvolvimento:** `flutter run -d windows` abre o app numa janela do desktop com moldura de celular — bem mais leve que o emulador Android para iterar na UI (hot reload com `r`).

### Testes

```bash
flutter test      # testes de widget
flutter analyze   # análise estática
```

## 🤝 Contribuindo

1. Crie um branch a partir de `main`: `git checkout -b feature/minha-feature`
2. Faça commits pequenos e descritivos
3. Garanta que `flutter analyze` e `flutter test` passam
4. Abra um Pull Request

---

<div align="center">
Feito com 💙 e Flutter para o <strong>WIN Marketplace</strong>
</div>
