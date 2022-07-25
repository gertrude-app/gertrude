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
	  -n rs,sb,mk,ds \
	  -c cyan.dim,magenta.dim,yellow.dim,green.dim \
	  "make watchsync" "make start-storybook" "make start-marketing" "make start-dashboard"

# scaffold

component:
	node ./scripts/make-component.js $(CLI_ARGS)

# utility

sync:
	rsync --recursive --delete --exclude '*.stories.tsx' ./components/src/shared ./dashboard/src/components
	rsync --recursive --delete --exclude '*.stories.tsx' ./components/src/shared ./marketing/components

sync-clean:
	rm -rf ./dashboard/src/components/shared
	rm -rf ./marketing/components/shared

watchsync:
	watchexec --restart --watch ./components/src/shared --exts tsx make sync

start-storybook:
	cd components && npm run storybook

start-marketing:
	cd marketing && npm run dev

start-dashboard:
	cd dashboard && npm run start

npm-install:
	$(CONCURRENTLY) \
	  -n root,comp,mark,dash \
	  -c magenta.dim,yellow.dim,green.dim,cyan.dim \
	  "npm i" "cd components && npm i" "cd marketing && npm i" "cd dashboard && npm i"

# build & deploy

build-marketing: sync
	cd marketing && npm install && npx next build && npx next export

build-storybook: sync
	cd components && npm install && npm run build-storybook

build-dashboard: sync
	cd dashboard && npm install && npm run build

# ci type things

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

ts-watch:
	$(CONCURRENTLY) \
	  -n ds,mk,sb \
		-c cyan.dim,magenta.dim,yellow.dim \
	  "npx tsc --noEmit --project ./dashboard --watch --preserveWatchOutput" \
	  "npx tsc --noEmit --project ./marketing --watch --preserveWatchOutput" \
	  "npx tsc --noEmit --project ./components --watch --preserveWatchOutput"

fix:
	make format
	make lint-fix

check:
	make lint
	make format-check
	make ts-check

# helpers

CONCURRENTLY = node_modules/.bin/concurrently
CLI_ARGS = $(filter-out $@, $(MAKECMDGOALS))
ALL_CMDS = \
  sync \
  sync-clean \
  watchsync \
  npm-install \
  help \
  component \
  storybook marketing dashboard all \
  start-storybook start-marketing start-dashboard \
  build-storybook build-marketing build-dashboard \
  fix ts-watch ts-check lint lint-fix format format-check check

.PHONY: $(ALL_CMDS)
.SILENT: $(ALL_CMDS)

# do nothing when target doesn't match (allow passing args thru to scripts)
%:
	@:
