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
	rm -rf dash/app/node_modules/.cache/snowpack
	rm -rf docs/app/.next
	rm -rf docs/app/out
	rm -rf marketing/app/.next
	rm -rf marketing/app/out
	rm -rf dash/app/build
	rm -rf storybook/node_modules/.cache/storybook

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

# ci type things

test:
	pnpm vitest run

test-watch:
	pnpm vitest watch

format:
	pnpm prettier --config ./.prettierrc.json --loglevel warn --write .

format-check:
	pnpm prettier --config ./.prettierrc.json --loglevel warn --check .

lint:
	pnpm eslint .

lint-fix:
	pnpm eslint . --fix

ts-check:
	$(CONCURRENTLY) --raw --success all \
    "pnpm tsc --noEmit --project dash/app" \
    "pnpm tsc --noEmit --project dash/ambient" \
    "pnpm tsc --noEmit --project dash/components" \
    "pnpm tsc --noEmit --project dash/datetime" \
    "pnpm tsc --noEmit --project dash/keys" \
    "pnpm tsc --noEmit --project dash/types" \
    "pnpm tsc --noEmit --project dash/utils" \
    "pnpm tsc --noEmit --project docs/app" \
    "pnpm tsc --noEmit --project marketing/app" \
    "pnpm tsc --noEmit --project marketing/components" \
    "pnpm tsc --noEmit --project shared/components" \
    "pnpm tsc --noEmit --project shared/datetime" \
    "pnpm tsc --noEmit --project storybook"

ts-watch:
	$(CONCURRENTLY) \
	  -n dash/app,dash/amb,dash/cmp,dash/dtm,dash/key,dash/typ,dash/utl,mark/app,mark/cmp,docs/app,shar/cmp,shar/dtm,shar/twd,strybook \
		-c cyan.dim,red.dim,green.dim,blue.dim,gray,magenta.dim,yellow.dim,cyan,red,green,blue,magenta,#f80 \
	  "pnpm tsc --noEmit --project dash/app --watch --preserveWatchOutput" \
	  "pnpm tsc --noEmit --project dash/ambient --watch --preserveWatchOutput" \
	  "pnpm tsc --noEmit --project dash/components --watch --preserveWatchOutput" \
	  "pnpm tsc --noEmit --project dash/datetime --watch --preserveWatchOutput" \
	  "pnpm tsc --noEmit --project dash/keys --watch --preserveWatchOutput" \
	  "pnpm tsc --noEmit --project dash/types --watch --preserveWatchOutput" \
	  "pnpm tsc --noEmit --project dash/utils --watch --preserveWatchOutput" \
	  "pnpm tsc --noEmit --project docs/app --watch --preserveWatchOutput" \
	  "pnpm tsc --noEmit --project marketing/app --watch --preserveWatchOutput" \
	  "pnpm tsc --noEmit --project marketing/components --watch --preserveWatchOutput" \
	  "pnpm tsc --noEmit --project shared/components --watch --preserveWatchOutput" \
	  "pnpm tsc --noEmit --project shared/datetime --watch --preserveWatchOutput" \
	  "pnpm tsc --noEmit --project storybook --watch --preserveWatchOutput"

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
  fix ts-watch ts-check lint lint-fix format format-check check test \
  codegen

.PHONY: $(ALL_CMDS)
.SILENT: $(ALL_CMDS)

# do nothing when target doesn't match (allow passing args thru to scripts)
%:
	@:
