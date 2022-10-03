help:
	echo ""; cat ./help.txt; echo ""

# local dev

storybook:
	make sync-clean
	$(CONCURRENTLY) -n rs,sb -c cyan.dim,magenta.dim "make watchsync" "make start-storybook"

marketing:
	make sync-clean
	$(CONCURRENTLY) -n rs,nx -c cyan.dim,magenta.dim "make watchsync" "make start-marketing"

dashboard:
	make sync-clean
	$(CONCURRENTLY) -n rs,sp -c cyan.dim,magenta.dim "make watchsync" "make start-dashboard"

all:
	make sync-clean
	$(CONCURRENTLY) \
	  -n rs,sb,mk,ds,dx \
	  -c cyan.dim,magenta.dim,yellow.dim,green.dim,red.dim \
	  "make watchsync" "make start-storybook" "make start-marketing" "make start-dashboard" "make start-docs"

# scaffold

component:
	node ./scripts/make-component.js $(CLI_ARGS)

# utility

sync:
	rsync --recursive --delete --exclude '*.stories.tsx' ./components/src/shared ./dashboard/src/components
	rsync --recursive --delete --exclude '*.stories.tsx' --exclude 'dashboard' ./components/src/shared ./marketing/components
	rsync --recursive --delete --exclude '*.stories.tsx' --exclude 'dashboard' ./components/src/shared ./docs/src/components

clean: sync-clean
	rm -rf docs/.next
	rm -rf docs/out
	rm -rf marketing/.next
	rm -rf marketing/out
	rm -rf dashboard/build
	rm -rf dashboard/node_modules/.cache
	rm -rf components/node_modules/.cache

sync-clean:
	rm -rf ./dashboard/src/components/shared
	rm -rf ./docs/src/components/shared
	rm -rf ./marketing/components/shared

watchsync:
	watchexec --restart --watch ./components/src/shared --exts tsx,ts make sync

start-storybook:
	cd components && npm run storybook

start-marketing:
	cd marketing && npm run dev

start-dashboard:
	cd dashboard && npm run start

start-docs:
	cd docs && npm run dev

npm-install:
	$(CONCURRENTLY) \
	  -n root,comp,mark,dash \
	  -c magenta.dim,yellow.dim,green.dim,cyan.dim,red.dim \
	  "npm i" "cd components && npm i" "cd marketing && npm i" "cd dashboard && npm i" "cd docs && npm i"

codegen:
	cd dashboard && node ./scripts/codegen.js

# build & deploy

npm-install-root:
	npm install

build-marketing: sync npm-install-root
	cd marketing && npm install && npx next build && npx next export

build-storybook: sync npm-install-root
	cd components && npm install && npm run build-storybook

build-dashboard: sync npm-install-root
	cd dashboard && npm install && npm run build

build-docs: sync npm-install-root
	cd docs && npm install && npx next build && npx next export

# ci type things

test:
	cd dashboard && npx vitest run

test-watch:
	cd dashboard && npx vitest watch

format:
	npx prettier --config ./.prettierrc.json --loglevel warn --write .

format-check:
	npx prettier --config ./.prettierrc.json --loglevel warn --check .

lint:
	npx eslint .

lint-fix:
	npx eslint . --fix

ts-check:
	npx tsc --noEmit --project ./dashboard
	npx tsc --noEmit --project ./marketing
	npx tsc --noEmit --project ./components
	npx tsc --noEmit --project ./docs

ts-watch:
	$(CONCURRENTLY) \
	  -n ds,mk,sb,dx \
		-c cyan.dim,magenta.dim,yellow.dim,red.dim \
	  "npx tsc --noEmit --project ./dashboard --watch --preserveWatchOutput" \
	  "npx tsc --noEmit --project ./marketing --watch --preserveWatchOutput" \
	  "npx tsc --noEmit --project ./components --watch --preserveWatchOutput" \
	  "npx tsc --noEmit --project ./docs --watch --preserveWatchOutput"

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
  sync watchsync clean sync-clean \
  npm-install \
  help \
  component \
  storybook marketing dashboard all \
  start-storybook start-marketing start-dashboard start-docs \
  build-storybook build-marketing build-dashboard build-docs \
  fix ts-watch ts-check lint lint-fix format format-check check \
  test test-watch \
  codegen

.PHONY: $(ALL_CMDS)
.SILENT: $(ALL_CMDS)

# do nothing when target doesn't match (allow passing args thru to scripts)
%:
	@:
