# Account component guidelines

## Stories

- Co-locate stories with the component they cover.
- Keep granular component stories simple and isolated; show the component itself, not a
  recreated page/header/parent layout. hooks, or app containers.
- Prefer a single curated assortment story for small components, with sections only for
  distinct states worth comparing.
- Avoid redundant examples: if one section already demonstrates a state, do not add
  another section for the same thing.
- Avoid helper components in stories, especially if they'd be complicated, unless it's
  really necessary.
- Use `StoryCanvas` and `StorySection` from `@gertrude/ui/src/storybook/StoryLayout`;
  `StoryCanvas` already provides the `@container/main` wrapper.
