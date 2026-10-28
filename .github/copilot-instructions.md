# JobFinder: project rules

You are a senior Flutter engineer and UI/UX designer. Build "JobFinder", a premium, brand-grade job search app. Match the attached 10-screen mockup pixel-perfectly, but elevate it to a polished brand-app feel: generous whitespace, soft blue-tinted shadows, consistent radii, crisp typography.

## Stack
- Flutter 3.x stable, Dart 3, null safety, Material 3 enabled but fully custom-themed.
- State: flutter_riverpod (Notifier / NotifierProvider). Routing: go_router (StatefulShellRoute.indexedStack for the 5 tabs).
- Fonts: google_fonts, Plus Jakarta Sans. Icons: Material rounded icons only (Icons.xxx_rounded). Never invent icon names.
- Design frame: 390 x 844. Must also look right from 360 to 430 px wide (use Expanded/Flexible, never fixed screen-width numbers).

## Architecture (feature-first)
lib/
  main.dart
  app.dart                      MaterialApp.router + theme
  core/
    theme/  app_colors.dart  app_typography.dart  app_spacing.dart  app_theme.dart
    router/ app_router.dart
    widgets/ primary_button.dart  outline_button.dart  soft_button.dart  app_chip.dart
             status_tag.dart  company_logo.dart  user_avatar.dart  icon_circle_button.dart
             app_search_bar.dart  section_header.dart  underline_tabs.dart  empty_state.dart
  data/
    models/ job.dart  company.dart  application.dart  message.dart
    mock/   mock_data.dart
  providers/ job_providers.dart
  features/
    shell/        main_shell.dart            (bottom navigation)
    onboarding/   onboarding_screen.dart  widgets/hero_illustration.dart  widgets/brand_mark.dart
    home/         home_screen.dart  widgets/ai_match_card.dart  widgets/job_card.dart
    search/       search_screen.dart
    saved/        saved_screen.dart
    applications/ applications_screen.dart
    profile/      profile_screen.dart
    job_details/  job_details_screen.dart
    company/      company_profile_screen.dart
    apply/        apply_screen.dart
    messages/     messages_screen.dart

## Design tokens (single source of truth: never hardcode colors, sizes or text styles in screens)

### Colors (AppColors)
brand50 #EEF3FF, brand100 #DDE7FF, brand200 #BDD0FF, brand300 #8FADFF, brand400 #5C83FF,
brand500 #2F5BFF (primary), brand600 #2347E6, brand700 #1A37B8
ink #0B1633 (headings), ink2 #3A4668 (body), muted #7C88A6, placeholder #A3ADC4
bg #F6F8FE, surface #FFFFFF, border #E6EBF6, divider #EEF1F8
success #0E9F6E, successBg #E6F7F0, warn #C2410C, warnBg #FFEEDD, danger #E5484D
gold #F5B544 (ratings + AI sparkle accent), goldBg #FFF6E2

### Gradients
primary: #4D7DFF -> #2347E6 (topLeft -> bottomRight)
hero (AI card): #F3F7FF -> #DCE7FF
onboarding bg: #FFFFFF -> #E9F0FF (top -> bottom)
company cover: #13214D -> #2F5BFF
avatar: #8FADFF -> #2F5BFF

### Typography: Plus Jakarta Sans (Flutter `height` = lineHeight / fontSize)
display 34/42 w800 ls -0.9 | h1 28/36 w700 ls -0.6 | h2 22/30 w700 ls -0.4 | h3 17/24 w700 ls -0.2
title 15/21 w600 | bodyLg 16/25 w400 | body 14/22 w400 | bodyMedium 14/20 w500
label 13/18 w600 | caption 12/16 w500 | tiny 11/14 w600 | button 15/20 w600
Headings use ink; body uses ink2; captions use muted.

### Spacing / radius / shadow
Spacing (4pt grid): 4, 8, 12, 16, 20, 24, 32. Screen horizontal gutter: 20.
Radius: sm 10, md 14, lg 18, xl 24, pill 999.
Shadow card: color #1B2B6B @ 7% alpha, blur 16, offset (0, 6). Shadow brand (primary buttons): #2347E6 @ 32% alpha, blur 16, offset (0, 8).
Never use pure black shadows.

## Component specs
- PrimaryButton: height 52, radius 16, primary gradient, brand shadow, white label (button style), optional leading/trailing icon, pressed = scale 0.98. Sizes: lg 52 / md 46 (r14) / sm 34 (r12, font 12.5).
- OutlineButton: white bg, 1.2px brand500 border, brand500 label. SoftButton: brand50 bg, brand600 label.
- AppChip: height 36, pill, horizontal padding 14, label style. Active = brand500 bg + white text. Inactive = white bg + 1px border. "soft" tone = brand50 bg.
- StatusTag: padding 9x5, radius 8, tiny text. Tones: brand (brand50/brand600), success, orange (warnBg/warn), neutral (divider/ink2).
- IconCircleButton: 42 circle, white bg, 1px border, card shadow; "glass" variant = white @ 92% alpha, no border; optional 9px brand dot badge.
- AppSearchBar: height 52, radius 18, white, 1px border, card shadow, brand500 search icon, placeholder color placeholder.
- JobCard: padding 14, radius 20, white, 1px border, card shadow, margin-bottom 12. Row: CompanyLogo 48 | column (title style `title`, "Company · Location" caption muted, tags row: job type = brand tag, salary = success tag) | right column (heart icon top, posted-ago tiny muted bottom). Saved heart = filled brand500.
- CompanyLogo: rounded tile (radius = 30% of size), company tint @ 10% bg, bold first letter in tint color. NEVER use real brand logos (copyright). Leave a clear spot to swap in an Image later.
- UserAvatar: circle with avatar gradient and white initials.
- Bottom nav: height 62 + bottom safe area, white, 0.5px top border. 5 tabs: Home, Search, Saved (heart), Applications (clipboard, badge "3"), Profile. Active = brand500 + filled icon, inactive = muted, label 10.5 w600.
- UnderlineTabs: label style, active brand500 with 2.5px rounded underline, 1px bottom border across the row.

## Coding rules
- const constructors everywhere possible; small widgets; no widget method returning Widget (use classes).
- Use Color.withValues(alpha: x), not withOpacity (deprecated).
- Every tappable: min 44x44 hit area, InkWell/GestureDetector with press feedback, and Semantics labels on icon-only buttons.
- SafeArea on every screen. Scroll views use BouncingScrollPhysics and bottom padding so content clears the nav bar.
- No magic numbers outside core/theme and the component specs above.
- Mock data lives only in data/mock/mock_data.dart behind a repository interface so an API can replace it.
- Code must pass `flutter analyze` with zero warnings. Add short doc comments on public widgets.

## Lessons learned
- In PowerShell, do not rewrite Dart source using string replacement; `$` can be interpolated. Escape currency symbols in Dart literals as `\$`.
- Avoid placing `ListTile` inside tightly constrained rows or decorated cards. Prefer responsive `Row` layouts with `Expanded`, `maxLines`, and `TextOverflow.ellipsis`.
- Use `Wrap` for chip and tag groups, and give row text flexible constraints.
- Check the installed package source before relying on package APIs; package major versions may change them.
- Bundle Plus Jakarta Sans locally and disable Google Fonts runtime fetching so tests and offline devices use the intended font.
- After each feature, run `dart format .`, `flutter analyze`, and `flutter test`; address any failures before proceeding.
- Keep widget-flow tests covering 360x640 and 430x932. Fix overflows in the UI rather than weakening the tests.
