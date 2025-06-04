_default:
  @just --choose

# local dev

dash:
	@pnpm --filter @dash/app start

site:
	@pnpm --filter site start

hmr-docs:
  @watchexec --watch site/markdoc --exts .md "just hmr-comment"

storybook:
	@pnpm --filter @storybook/app start

dev:
  pnpm concurrently \
  -n ds,st,sb \
  -c cyan.dim,magenta.dim,green.dim \
  "just dash" "just site" "just storybook"

# utility

clean:
  @rm -rf site/.next
  @rm -rf site/out
  @rm -rf dash/app/build
  @find . -name "node_modules" -type d -prune -exec rm -rf {} + && pnpm i

codegen: && lint-fix format
	@cd dash/app && node ./scripts/codegen.js

nuke-node-modules:
  @pnpm store prune
  @find . -name "node_modules" -type d -prune -exec rm -rf {} + && pnpm i

# build & deploy

appviews isolate="":
	@cd appviews && pnpm typecheck && node generate.cjs {{isolate}}

build-site:
	@pnpm --filter site build

build-storybook:
	@pnpm --filter @storybook/app build

build-dash:
	@pnpm --filter @dash/app build

# ci/test type things

cy-open:
	@pnpm cypress open --project dash/app

cy-run:
	@pnpm cypress run --project dash/app

smoke-open:
	@pnpm cypress open --project smoke

smoke-run:
	@pnpm cypress run --project smoke

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
	@pnpm prettier --config ./.prettierrc.json --log-level warn --write .

format-check:
	@pnpm prettier --config ./.prettierrc.json --log-level warn --check .

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

[private]
hmr-comment:
  @bash -c "echo // $(date) >> './site/app/docs/[slug]/page.tsx'"

