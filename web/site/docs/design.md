# Gertrude Marketing Site Design System

## Overview

The Gertrude marketing site uses a bold, modern design centered around vibrant violet and
fuchsia gradients, creating a confident and tech-forward brand identity.

## Color Palette

### Primary Colors

- **Violet-500**: `#8B5CF6` - Main brand color
- **Fuchsia-500**: `#D946EF` - Accent brand color
- **Violet to Fuchsia Gradient**: Primary brand gradient used throughout

### Background Colors

- **Violet-500**: Primary background for most marketing pages
- **Fuchsia-500**: Used in gradient transitions and accent sections
- **Slate-900**: `#0F172A` - Dark sections, CTAs, and testimonial backgrounds
- **Slate-800**: `#1E293B` - Card backgrounds on dark sections
- **Violet-100**: `#EDE9FE` - Light accent backgrounds

### Text Colors

- **White**: Primary text on colored backgrounds
- **White with opacity**: Secondary text (80%, 30% opacity variations)
- **Slate-700**: Dark text on light backgrounds
- **Violet-100/200/300**: Light text variations on dark backgrounds

### UI Element Colors

- **Violet-600/700**: Darker accent colors for buttons and interactive elements
- **Fuchsia-300/400**: Light gradient accents
- **Slate variations**: Used for dark UI components

## Typography

### Fonts

**Lexend** (Marketing content)

- Weight range: 100-900
- Format: Variable woff2
- Usage: Primary font for marketing pages
- Applied via: `font-lexend`

**Inter-Docs** (Documentation)

- Weight range: 100-900
- Variants: Roman (normal) and Italic
- Format: Variable woff2
- Usage: Documentation pages
- Applied via: `font-docs-inter`

**Lato** (Legacy headings)

- Weight: 900
- Usage: Specific legacy headings
- Applied via: `font-lato`

**Inter** (Shared components)

- Usage: General purpose in shared components
- Applied via: `font-inter`

### Typography Scale

Headings use responsive sizing:

- **H1**: `text-5xl xs:text-6xl sm:text-7xl` (Hero headings)
- **H2**: `text-4xl xs:text-5xl md:text-6xl` (Section headings)
- **H3**: `text-3xl md:text-4xl` (Sub-headings)
- **Body Large**: `text-lg xs:text-xl md:text-2xl`
- **Body**: `text-base` to `text-xl`
- **Small**: `text-sm` to `text-base`

### Font Weights

- **Bold**: `font-bold` (700)
- **Semibold**: `font-semibold` (600) - Most common for headings
- **Medium**: `font-medium` (500)
- **Normal**: (400)

## Gradients

### Brand Gradients

- **Violet to Fuchsia**: `from-violet-500 to-fuchsia-500` or
  `from-violet-600 to-fuchsia-500`
- **Violet to Violet (darker)**: `from-violet-700 to-fuchsia-700`
- **Light accent**: `from-violet-200 to-fuchsia-300` or `from-white to-violet-200`

### Gradient Applications

- Background gradients: `bg-gradient-to-b` (top to bottom)
- Inline gradients: `bg-gradient-to-r` (left to right)
- Text gradients: `bg-gradient-to-r bg-clip-text text-transparent`

### Logo

The site uses static SVG wordmarks from `public/gertrude-logo.svg` and
`public/gertrude-logo-white.svg` through `components/Logo.tsx`. Icon-only placements use
`public/logo-icon.svg`.

The default logo uses a violet-to-fuchsia icon with black wordmark text; the white variant
is used on violet or dark backgrounds.

## Spacing

### Custom Spacing Values

- `112`: 28rem (448px)
- `128`: 32rem (512px)
- `152`: 38rem (608px)
- `176`: 44rem (704px)

### Common Patterns

- Section padding: `px-4 xs:px-8 sm:px-12 md:px-20`
- Vertical padding: `py-20 xs:py-24 md:py-40`
- Gap spacing: `gap-6`, `gap-8`, `gap-12` (24px, 32px, 48px)

## Breakpoints

Custom breakpoints (in addition to Tailwind defaults):

- `xs`: 500px
- `sm`: 640px
- `md`: 768px
- `md+`: 900px
- `lg`: 1024px
- `lg+`: 1152px
- `xl`: 1280px
- `2xl`: 1600px

## Border Radius

### Rounded Corners

- **Large**: `rounded-3xl` (24px) - Primary buttons (lg size), cards
- **Medium**: `rounded-2xl` (16px) - Secondary buttons (sm size)
- **Top Only**: `rounded-t-[40px]` - CTA block sections

## Components

### Buttons (`Button`)

Use `web/site/components/Button.tsx` for site CTAs, form submits, and button-styled links.

**Primary Button**

- Gradient background: `from-violet-500 to-fuchsia-500`
- White text, with subtle fuchsia shadow and shine on hover
- Hover: Translates up slightly (-0.5)
- Sizes: `lg` (px-8 py-4), `sm` (px-6 py-3), `xs` (px-4 py-2)

**Secondary Button**

- Light background: `bg-violet-100` (normal) or translucent white (inverted)
- Violet text on light surfaces, white text on dark/brand surfaces
- Subtle border to keep secondary actions legible

**Inverted Variants**

- Primary: White background with violet text
- Secondary: Translucent white background with white text

### Cards

**Testimonial Cards**

- Background: `bg-slate-800`
- Padding: `p-8 xs:p-12`
- Rounded: `rounded-3xl`
- Shadow: `shadow-xl shadow-black/20` (on XL screens)
- Text: `text-violet-100`
- Name: Gradient text `from-violet-200 to-fuchsia-300`

## Animations

### Built-in Animations

- **bounce-right**: Horizontal bounce (0.5s linear infinite)
- **progress-right**: Progress bar (1.5s ease-in-out infinite)

### Transition Patterns

- Standard transitions: `transition-[opacity,transform] duration-500`
- Button transitions: `transition-[transform,background-color] duration-200`
- Fast interactions: `duration-200`
- Smooth page transitions: `duration-500`

### Transform Effects

- Scale on scroll: `scale(${1 + scrollY / 500})`
- Blur on scroll: `blur(${scrollY / 30}px)`
- Hover lift: `-translate-y-0.5`
- Active press: `translate-y-0.5`

## Design Patterns

### Hero Sections

- Full viewport height: `h-screen`
- Gradient backgrounds: Violet to fuchsia
- Large, bold typography
- Centered content
- Scroll indicators with animated chevron

### Content Sections

- Alternating backgrounds (violet-500, fuchsia-500, slate-900)
- Generous padding: `py-28` to `py-40`
- Responsive horizontal padding
- Sticky positioning for text blocks on large screens

### CTAs

- Dark slate-900 background with rounded corners
- Prominent buttons with gradients
- Pricing information with gradient text
- Multiple CTA options (primary + secondary)

### Text Styling

- White text with reduced opacity (80%) for body content
- Gradient text for emphasis and pricing
- Large line heights: `leading-[1.1em]` to `leading-[1.5em]`
- Letter spacing: `tracking-[0.02em]` for headlines, `tracking-[3px]` for small caps

### Interactive States

- Hover: Brightness changes, subtle transforms
- Active: Scale down or translate
- Disabled: `opacity-50 cursor-not-allowed`
- Focus: Subtle highlights (follow Tailwind forms plugin defaults)

## Misc

NB: we can't use Next.js Image component because we deploy statically to Cloudflare.
