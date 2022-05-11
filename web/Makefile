sync:
	rsync -r ./components/src/shared ./dashboard/src/components
	rsync -r ./components/src/shared ./marketing/components

watchsync:
	watchexec --restart --watch ./components/src/shared --exts tsx make sync

start-storybook:
	cd components && npm run storybook

start-marketing:
	cd marketing && npm run dev

start-dashboard:
	cd dashboard && npm run start

storybook:
	$(CONCURRENTLY) -n rs,sb -c cyan.dim,magenta.dim "make watchsync" "make start-storybook"

marketing:
	$(CONCURRENTLY) -n rs,nx -c cyan.dim,magenta.dim "make watchsync" "make start-marketing"

dashboard:
	$(CONCURRENTLY) -n rs,sp -c cyan.dim,magenta.dim "make watchsync" "make start-dashboard"

npm-install:
	$(CONCURRENTLY) \
	-n root,components,marketing,dashboard \
	-c magenta.dim,yellow.dim,green.dim,cyan.dim \
	"npm i" "cd components && npm i" "cd marketing && npm i" "cd dashboard && npm i"

# helpers

CONCURRENTLY = node_modules/.bin/concurrently
.PHONY: sync watchsync storybook start-storybook marketing start-marketing npm-install dashboard start-dashboard
.SILENT: sync watchsync storybook start-storybook marketing start-marketing npm-install dashboard start-dashboard
