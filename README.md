# Folha — App

> *Sua vida financeira, escrita com clareza.*

**Folha** é o aplicativo mobile de finanças pessoais para jovens adultos (20–35) que estão tomando suas primeiras decisões financeiras de verdade. O produto fica entre o *caderno editorial de papel* e o *fintech moderno* — pense num caderno encadernado em couro onde você escreve suas metas, com gráficos ao vivo e categorização por swipe.

O nome **Folha** é português do Brasil e carrega três significados sobrepostos:
- 📄 página / papel — herança editorial
- 🌿 folha de planta — a paleta verde mata
- 💵 gíria para dinheiro — "folha de pagamento"

Este repositório é a **implementação Flutter** do design system Folha. Os tokens visuais, tipografia, vozes e ícones espelham o que está documentado em `Folha Design System/`.

## Sources

O app foi escrito do zero em Flutter sobre o design system Folha. Tudo aqui é original: a estrutura de módulos, os widgets `folha_*`, os tokens em `core/theme`, o tema GetX, as rotas. Caso uma marca real "Folha" venha a existir, você pode trocar:
- SVGs em `assets/svg/` (logo, ícone, leaf-mark)
- Tokens de cor em `lib/core/theme/folha_colors.dart` e `folha_tokens.dart`
- Tipografia em `lib/core/theme/folha_typography.dart`

As fontes são carregadas via **Google Fonts** (Instrument Serif + DM Sans) através do pacote `google_fonts`. Nenhum arquivo `.ttf` é empacotado localmente — para uso offline, baixe os `.woff2`/`.ttf` e registre em `pubspec.yaml`.

---

## Index

| Path | What it is |
|---|---|
| `README.md` | Este arquivo — visão geral do app e da arquitetura |
| `pubspec.yaml` | Dependências, assets e metadados Flutter |
| `lib/main.dart` | Bootstrap do app (GetMaterialApp, locale pt_BR, system UI) |
| `lib/app/modules/` | Features (auth, onboarding, dashboard, transactions, bills, profile, shell) |
| `lib/core/theme/` | Tokens, cores, tipografia e tema Material da Folha |
| `lib/core/widgets/` | Componentes `Folha*` reutilizáveis (botões, cards, pills, currency, etc.) |
| `lib/core/routes/` | Rotas GetX (`AppPages`, `AppRoutes`) |
| `lib/core/bindings/` | Injeção de dependência inicial (GetX) |
| `lib/core/network/` | Cliente Dio preparado para backend real |
| `lib/core/errors/` | `Failure`s e exceptions do padrão Clean Arch |
| `lib/core/usecases/` | Contratos base de use case |
| `assets/svg/` | Logo, app-icon e leaf-mark |

---

## TECH STACK

### Plataforma

- **Flutter** ≥ 3.x, Dart SDK `^3.11.3`
- **Material 3** com tema customizado Folha (`FolhaTheme.light()`)
- **Locale**: `pt_BR` por padrão (datas, moedas, formatação)

### Bibliotecas principais

| Pacote | Papel |
|---|---|
| `get` | State management, DI e rotas (padrão da casa) |
| `dio` | Networking — preparado para integração com backend real |
| `intl` | Formatação BR (datas, moeda) |
| `google_fonts` | Carregamento de Instrument Serif + DM Sans |
| `flutter_svg` | Renderização da logo e leaf-mark |
| `lucide_icons` | Mesma família de ícones do design system |
| `equatable` | Igualdade por valor em entidades / VOs |
| `dartz` | `Either<Failure, Success>` no estilo Clean Arch |

---

## ARQUITETURA

### Organização

O código vive em duas camadas:

- **`lib/core/`** — tudo que é transversal: tema, widgets `Folha*`, rotas, bindings, rede, errors, use cases base, utils.
- **`lib/app/modules/`** — features isoladas. Cada módulo segue Clean Arch quando precisa tocar dados:
  - `data/` — datasources, models, repository impl
  - `domain/` — entidades, repository abstrato, use cases
  - `presentation/` — controllers GetX, páginas, widgets locais

Módulos puramente visuais (ex.: `dashboard`, `shell`) podem ter apenas `presentation/`.

### Padrão por módulo

```
modules/transactions/
├── data/
│   ├── datasources/
│   ├── models/
│   └── repositories/
├── domain/
│   ├── entities/
│   ├── repositories/
│   └── usecases/
└── presentation/
    ├── controllers/
    └── pages/
```

### Rotas

Rotas centralizadas em `lib/core/routes/app_pages.dart` usando `GetPage`. Nomes de rota constam em `app_routes.dart` — nunca string solta no código.

### Injeção de dependência

`InitialBinding` registra dependências globais. Cada módulo pode ter seu próprio `Binding` carregado lazy via `GetPage`.

---

## VISUAL FOUNDATIONS

Tudo abaixo é a tradução fiel do design system para Flutter — veja `Folha Design System/README.md` para a referência canônica.

### Color

Cinco paletas, expostas em `FolhaColors`:

| Palette | Role | Range |
|---|---|---|
| **Paper** | Backgrounds e surfaces | `#FBF8F1` → `#C7B895` |
| **Forest** | Brand, CTAs, acentos positivos | `#0B1F18` → `#D2E4D8` |
| **Ink** | Texto sobre creme | `#1A1612` → `#D5CDB8` |
| **Ocre** | Momentos premium / insight (raro) | `#8C6E2A` → `#F2E8CC` |
| **Terra** | Valores negativos (mais quente que vermelho) | `#6F2C1C` → `#F0D9CE` |

**Background padrão**: `paper100` (`#F4EFE3`) — creme quente. Nunca branco puro. Nunca cinza.
**Surface padrão**: `paper50` (`#FBF8F1`) — mais claro que o page, dispensa sombra.
**Primary**: `forest700` (`#1A3A2E`) — CTAs, hero card, estados ativos.

### Typography

Sistema de duas fontes via `google_fonts`:

- **Display**: `Instrument Serif` — itálico + roman, 16–84px. Wordmark, títulos de tela ("Movimentos", "Contas"), nomes de usuário e **todos os valores de moeda em hero**.
- **UI / Body**: `DM Sans` — 400/500/600, 11–17px. Labels, botões, listas, body. Configurada com **tabular-nums** para alinhar valores.

`FolhaTypography` expõe estilos semânticos (`h1`, `bodySm`, `num`, etc.) consumidos pelos widgets `Folha*`.

### Spacing, Radii & Shadows

Tokens em `lib/core/theme/folha_tokens.dart`:

- **Base unit**: 4px. Tokens `space1` (4px) → `space11` (96px).
- **Container padding**: 20px horizontal.
- **Card padding**: 14–22px conforme hierarquia.
- **Radii**: `xs 4` · `sm 8` · `md 12` · `lg 18` · `xl 28` · `pill 999`. Botões são sempre pill.
- **Shadows**: warm-tinted, derivadas de `ink900` em baixa alpha. Nada de drop shadow azul/cinza.

### Animação

- **Easing**: `Curves.easeOutCubic` aproximando `cubic-bezier(0.22, 0.61, 0.36, 1)`
- **Durações**: 140ms (fast), 240ms (medium), 420ms (slow)
- Count-up em valores monetários
- Bottom sheets sobem (320ms), detail screens deslizam horizontal (280ms)

Sem bounces, sem springs. Movimento **deliberado e calmo** — é um app de finanças, não um jogo.

---

## CONTENT FUNDAMENTALS

### Voz

**Próximo, casual, claro.** Folha fala com a pessoa do jeito que um amigo inteligente falaria: caloroso, sem peso, com bom humor leve quando cabe.

### Regras de tom

- **Você**, nunca "o senhor"
- **Primeiro nome** sempre que possível — `"Oi, Marina"` não `"Olá, usuário"`
- **Frases curtas**. Dinheiro estressa — a copy não pode estressar também.
- **Sem jargão**: nada de `extrato`, `débito`, `crédito`, `lançamento`. Use `movimento`, `saída`, `entrada`, `saldo`.
- **Sem emoji em UI de produto** (ícones de categoria usam Lucide, não emoji)

### Casing

| Onde | Estilo | Exemplo |
|---|---|---|
| Títulos de tela | Sentence case, serif itálico | *Movimentos* |
| Eyebrows / labels | UPPERCASE + letterspacing | `SALDO TOTAL` |
| Botões | Sentence case | `Adicionar transação` |
| Status pills | UPPERCASE | `PAGO` / `PENDENTE` |
| Body | Sentence case | "Você gastou…" |

---

## ICONOGRAFIA

Folha usa **Lucide** (`lucide_icons`), stroke fino (1.6) — mesma família do design system.

### Regras

- **Stroke**: 1.6 default; 1.8 para estados ativos
- **Tamanho**: 14 (chip), 18 (list row), 20–22 (nav/header), 28 (hero)
- **Cor**: `currentColor` — deixe o widget pai controlar
- **Outline only** — nada de ícone preenchido
- **Sem emoji** em superfícies do app

### Logo

- `assets/svg/logo.svg` — lockup horizontal (mark + wordmark)
- `assets/svg/app-icon.svg` — 64×64 com bordas arredondadas, mark invertida
- `assets/svg/leaf-mark.svg` — só a folha, em `currentColor`

---

## Como rodar

Pré-requisitos: Flutter SDK ≥ 3.11.3, Dart, um emulador ou device conectado.

```bash
flutter pub get
flutter run
```

Para gerar build de release:

```bash
flutter build apk        # Android
flutter build ios        # iOS (requer macOS)
```

Lints rodam com `flutter analyze` (config em `analysis_options.yaml`, baseada em `flutter_lints`).

---

## Caveats & flags

- **Fontes via Google Fonts CDN** — o pacote `google_fonts` baixa runtime. Para uso offline, registre os `.ttf` em `pubspec.yaml` e troque por `TextStyle(fontFamily: ...)`.
- **Sem backend ainda** — o `Dio` está montado em `core/network/` mas os módulos usam mock data por enquanto. Os contratos `domain/repositories/` já estão prontos para serem ligados a uma API real.
- **Lucide via pacote** — `lucide_icons: ^0.257.0`. Se um ícone novo for necessário e ainda não estiver no pacote, considere atualizar a versão antes de inliná-lo como SVG.
- **Persistência** — o app não persiste estado entre sessões. Mudanças (ex.: "marcar como pago") vivem só na memória do controller GetX.
