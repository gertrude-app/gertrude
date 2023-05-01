_default:
  @just --choose

# local dev

dash:
	@pnpm --filter @dash/app start

site:
	@pnpm --filter @site/app start

storybook:
	@pnpm --filter @storybook/app start

dev:
  pnpm concurrently \
  -n ds,st,sb \
  -c cyan.dim,magenta.dim,green.dim \
  "just dash" "just site" "just storybook"

# scaffold

component *args:
	@node ./make-component.js {{args}}

# utility

clean:
	@rm -rf appviews/node_modules/.vite
	@rm -rf dash/app/node_modules/.vite
	@rm -rf storybook/node_modules/.cache/storybook
	@rm -rf node_modules/.cache/nx
	@rm -rf site/app/.next
	@rm -rf site/app/out
	@rm -rf dash/app/build

codegen:
	@cd dash/app && node ./scripts/codegen.js

# build & deploy

appviews isolate="":
	@cd appviews && pnpm typecheck && node generate.cjs {{isolate}}

build-site:
	@pnpm --filter @site/app build
	@pnpm --filter @site/app export
	@cp site/app/_redirects site/app/out

build-storybook:
	@pnpm --filter @storybook/app build

build-dash:
	@pnpm --filter @dash/app build

# ci/test type things

cy-open:
	@pnpm cypress open --project dash/app

cy-run:
	@pnpm cypress run --project dash/app

test:
	@pnpm vitest run

test-watch:
	@pnpm vitest watch

visual-test:
	@rm -rf storybook/visual-tests/screenshots/argos
	@cd storybook/visual-tests && ../node_modules/.bin/ts-node --project tsconfig.json run.ts

visual-test-reset:
	@git restore --source=HEAD --staged --worktree -- storybook/visual-tests/screenshots/argos

format:
	@pnpm prettier --config ./.prettierrc.json --loglevel warn --write .

format-check:
	@pnpm prettier --config ./.prettierrc.json --loglevel warn --check .

format-codegen:
	@pnpm prettier --config ./.prettierrc.json --loglevel warn --write "appviews/**/*-{store,types}.ts"

lint:
	@pnpm eslint .

lint-fix:
	@pnpm eslint . --fix

typecheck:
	@pnpm exec nx run-many --parallel=10 --target=typecheck

# see https://gist.github.com/jaredh159/e75d59ca2fd6abdc5262a87ee43d1344 for alternate method
typecheck-watch:
	@pnpm exec nx run-many --parallel=50 --output-style=stream --target=typecheck:watch

fix: format lint-fix

check: lint format-check typecheck test


