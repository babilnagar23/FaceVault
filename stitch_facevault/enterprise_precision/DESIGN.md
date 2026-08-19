---
name: Enterprise Precision
colors:
  surface: '#FFFFFF'
  surface-dim: '#d8dadd'
  surface-bright: '#f7f9fc'
  surface-container-lowest: '#ffffff'
  surface-container-low: '#f2f4f7'
  surface-container: '#eceef1'
  surface-container-high: '#e6e8eb'
  surface-container-highest: '#e0e3e6'
  on-surface: '#191c1e'
  on-surface-variant: '#455A64'
  inverse-surface: '#2d3133'
  inverse-on-surface: '#eff1f4'
  outline: '#727780'
  outline-variant: '#c2c7d1'
  surface-tint: '#2d6197'
  primary: '#00355f'
  on-primary: '#ffffff'
  primary-container: '#0f4c81'
  on-primary-container: '#8ebdf9'
  inverse-primary: '#a0c9ff'
  secondary: '#0060a8'
  on-secondary: '#ffffff'
  secondary-container: '#47a1ff'
  on-secondary-container: '#003663'
  tertiary: '#532800'
  on-tertiary: '#ffffff'
  tertiary-container: '#743b00'
  on-tertiary-container: '#f9a767'
  error: '#D32F2F'
  on-error: '#ffffff'
  error-container: '#ffdad6'
  on-error-container: '#93000a'
  primary-fixed: '#d2e4ff'
  primary-fixed-dim: '#a0c9ff'
  on-primary-fixed: '#001c37'
  on-primary-fixed-variant: '#07497d'
  secondary-fixed: '#d3e4ff'
  secondary-fixed-dim: '#a2c9ff'
  on-secondary-fixed: '#001c38'
  on-secondary-fixed-variant: '#004881'
  tertiary-fixed: '#ffdcc4'
  tertiary-fixed-dim: '#ffb780'
  on-tertiary-fixed: '#2f1400'
  on-tertiary-fixed-variant: '#6f3800'
  background: '#f7f9fc'
  on-background: '#191c1e'
  surface-variant: '#e0e3e6'
  success: '#2E7D32'
  warning: '#ED6C02'
  border-subtle: '#E0E5EB'
typography:
  display-lg:
    fontFamily: Inter
    fontSize: 32px
    fontWeight: '700'
    lineHeight: 40px
    letterSpacing: -0.02em
  headline-lg:
    fontFamily: Inter
    fontSize: 24px
    fontWeight: '600'
    lineHeight: 32px
    letterSpacing: -0.01em
  headline-lg-mobile:
    fontFamily: Inter
    fontSize: 20px
    fontWeight: '600'
    lineHeight: 28px
  title-md:
    fontFamily: Inter
    fontSize: 18px
    fontWeight: '600'
    lineHeight: 24px
  body-lg:
    fontFamily: Inter
    fontSize: 16px
    fontWeight: '400'
    lineHeight: 24px
  body-md:
    fontFamily: Inter
    fontSize: 14px
    fontWeight: '400'
    lineHeight: 20px
  label-md:
    fontFamily: Inter
    fontSize: 12px
    fontWeight: '600'
    lineHeight: 16px
    letterSpacing: 0.01em
  label-sm:
    fontFamily: Inter
    fontSize: 11px
    fontWeight: '500'
    lineHeight: 16px
    letterSpacing: 0.02em
rounded:
  sm: 0.25rem
  DEFAULT: 0.5rem
  md: 0.75rem
  lg: 1rem
  xl: 1.5rem
  full: 9999px
spacing:
  baseline: 4px
  container-padding-mobile: 16px
  container-padding-desktop: 24px
  gutter: 12px
  stack-sm: 8px
  stack-md: 16px
  stack-lg: 24px
---

## Brand & Style

This design system is engineered for high-stakes enterprise environments, specifically tailored for AI-powered workforce management. It prioritizes clarity, speed of data entry, and unquestionable reliability. 

The aesthetic is **Corporate Minimalism**, blending the structured logic of high-density productivity tools with the accessibility of modern Android interfaces. The interface avoids decorative flourishes in favor of functional density and clear information hierarchy. By utilizing a "White-Label Plus" approach, the UI feels invisible yet premium, ensuring that complex attendance data and AI insights remain the focal point. The emotional goal is to project security, institutional stability, and technical sophistication.

## Colors

The palette is anchored by **Deep Corporate Blue**, signaling authority and trust. We utilize a strictly light-mode environment to maximize readability in various lighting conditions (e.g., tablet kiosks or outdoor mobile use). 

- **Primary & Secondary:** Used for core actions and active states. Primary (#0F4C81) is reserved for high-level branding and primary buttons, while Secondary (#1E88E5) highlights interactive sub-elements or focused data points.
- **Background & Surface:** A cool-toned light gray (#F5F7FA) provides the canvas, with pure white (#FFFFFF) reserved for cards and input containers to create "islands" of information.
- **Semantic Colors:** Green, Orange, and Red are used with high saturation for immediate status recognition (Success, Warning, Error), essential for attendance tracking and offline sync alerts.

## Typography

We employ **Inter** exclusively to leverage its exceptional legibility and neutral, professional tone. 

The type system is optimized for "scan-ability." We use semi-bold and bold weights for headings and labels to create clear visual anchors in data-heavy screens. For mobile views, we scale down headlines to prevent excessive wrapping. Labels (captions) are slightly tracked out to improve readability at small sizes, particularly for metadata like timestamps or offline status indicators.

## Layout & Spacing

This design system uses a **Fluid Grid** model with a 4px baseline. 

- **Mobile:** 4-column grid with 16px side margins and 12px gutters.
- **Tablet/Desktop:** 12-column grid with 24px margins.

We emphasize vertical rhythm through standardized "Stack" units (8px, 16px, 24px). High-density layouts (like attendance logs) should utilize 8px vertical spacing between items, while dashboard summaries use 24px spacing to allow for "breathable" content. Content reflow follows a "Card-to-Row" pattern: elements that appear as vertical cards on mobile may expand into horizontal table rows on larger screens.

## Elevation & Depth

Visual hierarchy is achieved through a combination of **Tonal Layers** and **Ambient Shadows**. 

1. **Level 0 (Background):** #F5F7FA – the base layer.
2. **Level 1 (Cards/Surfaces):** #FFFFFF – elevated with a very soft, diffused shadow (0px 2px 8px rgba(15, 76, 129, 0.08)).
3. **Level 2 (Active/Modal):** #FFFFFF – heightened depth (0px 8px 24px rgba(0, 0, 0, 0.12)).

We avoid heavy drop shadows in favor of subtle border-strokes (#E0E5EB) on surface containers, giving the UI a clean, "flat but layered" appearance similar to modern developer tools.

## Shapes

The shape language balances enterprise rigor with modern approachability. 

- **Main Containers/Cards:** Use 16px to 20px (rounded-lg to rounded-xl) to create a friendly, modern container for data.
- **Inputs & Buttons:** Use 8px (rounded) to maintain a professional, sturdy feel.
- **Badges/Chips:** Use pill-shaped (full-round) to distinguish them from interactive buttons.

## Components

- **Buttons:** Primary buttons use a solid #0F4C81 fill with white text. Secondary buttons use a #1E88E5 outline with a subtle light-blue hover state. Use a minimum height of 48dp for accessibility.
- **Input Fields:** Outlined style with #E0E5EB borders. Active/Focused states transition to #1E88E5 with a 2px stroke. Validation errors must include both a red border (#D32F2F) and a trailing icon for accessibility.
- **Chips & Badges:** Used for status (e.g., "Present", "Late", "Offline"). High-contrast background tints with dark-toned text for maximum legibility.
- **Attendance Cards:** Large white surfaces with 16px padding. Must include a "Status Indicator" dot (semantic colors) and a clear timestamp.
- **Offline Indicators:** A specialized persistent banner or status bar item that uses #ED6C02 (Warning) when data is pending sync, and #2E7D32 with a check icon once the AI-processed attendance is verified and synced.
- **Data Tables:** High-density, borderless rows with 1px horizontal dividers. Use "Inter" medium for headers.