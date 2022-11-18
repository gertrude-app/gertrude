help:
	echo ""; cat ./help.txt; echo ""

# local dev

dash:
	pnpm --filter @dash/app start

marketing:
	pnpm --filter @marketing/app start

docs:
	pnpm --filter @docs/app start

storybook:
	pnpm --filter @storybook/app start

all:
	$(CONCURRENTLY) \
	  -n ds,mk,dx,sb \
	  -c cyan.dim,magenta.dim,yellow.dim,green.dim \
	  "make dash" "make marketing" "make docs" "make storybook"

# scaffold

component:
	node ./make-component.js $(CLI_ARGS)

# utility

install:
	which -s pnpm || npm install -g pnpm
	pnpm install

clean:
	rm -rf dash/app/node_modules/.vite
	rm -rf storybook/node_modules/.cache/storybook
	rm -rf node_modules/.cache/nx
	rm -rf docs/app/.next
	rm -rf docs/app/out
	rm -rf marketing/app/.next
	rm -rf marketing/app/out
	rm -rf dash/app/build

codegen:
	cd dash/app && node ./scripts/codegen.js
	bash ./dash/app/scripts/fix-imports.sh

# build & deploy

build-marketing:
	pnpm --filter @marketing/app build
	pnpm --filter @marketing/app export
	cp marketing/app/_redirects marketing/app/out

build-storybook:
	pnpm --filter @storybook/app build

build-dash:
	pnpm --filter @dash/app build

build-docs:
	pnpm --filter @docs/app build
	pnpm --filter @docs/app export

# ci/test type things

cy-open:
	pnpm cypress open --project dash/app

cy-run:
	pnpm cypress run --project dash/app

test:
	pnpm vitest run

test-watch:
	pnpm vitest watch

visual-test:
	rm -rf storybook/visual-tests/screenshots/argos
	cd storybook/visual-tests && ../node_modules/.bin/ts-node --project tsconfig.json run.ts

visual-test-reset:
	git restore --source=HEAD --staged --worktree -- storybook/visual-tests/screenshots/argos

format:
	pnpm prettier --config ./.prettierrc.json --loglevel warn --write .

format-check:
	pnpm prettier --config ./.prettierrc.json --loglevel warn --check .

lint:
	pnpm eslint .

lint-fix:
	pnpm eslint . --fix

ts-check:
	pnpm exec nx run-many --parallel=10 --target=typecheck

# see https://gist.github.com/jaredh159/e75d59ca2fd6abdc5262a87ee43d1344 for alternate method
ts-watch:
	pnpm exec nx run-many --parallel=50 --output-style=stream --target=typecheck:watch

fix:
	make format
	make lint-fix

check:
	make lint
	make format-check
	make ts-check
	make test

# helpers

CONCURRENTLY = node_modules/.bin/concurrently
CLI_ARGS = $(filter-out $@, $(MAKECMDGOALS))
ALL_CMDS = \
  clean \
  install \
  help \
  component \
  storybook marketing dash docs all \
  build-storybook build-marketing build-dash build-docs \
  test test-watch \
  cy-open cy-run \
  visual-test visual-test-reset \
  fix ts-watch ts-check lint lint-fix format format-check check \
  codegen

.PHONY: $(ALL_CMDS)
.SILENT: $(ALL_CMDS)

# do nothing when target doesn't match (allow passing args thru to scripts)
%:
	@:
