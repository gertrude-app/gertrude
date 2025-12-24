# Maintenance

## CI Files-Changed Dependencies

The CI workflows use path-based filtering to skip unnecessary jobs when only certain parts
of the monorepo change. These filters must be kept in sync with actual package
dependencies.

### Workflow Files

- `.github/workflows/swift-ci.yml` - main swift monorepo CI (includes macapp, iosapp, podcasts, api, libs)
- `.github/workflows/web-ci.yml` - web monorepo CI

### Where Dependencies Are Expressed

#### swift-ci.yml

The `files-changed` job defines path filters for selective job execution:

```yaml
files-changed:
  outputs:
    macapp: ... # triggers macapp-lib job
    iosapp: ... # triggers iosapp-lib job
    podcasts: ... # triggers podcasts-lib job
    libs: ... # triggers linux-build-libs-* and linux-lib-test-* jobs
    api: ... # triggers linux-api-build and linux-api-test jobs
    swift: ... # triggers swift-lint and xml-lint jobs
```

Each filter lists the directories that should trigger that job. For example, `macapp`
includes `swift/pairql-macapp/**` because macapp depends on pairql-macapp.

#### web-ci.yml

The `files-changed` job defines:

```yaml
files-changed:
  outputs:
    appviews: ... # triggers appviews-comment job
    dashboard: ... # triggers dashboard job
    site: ... # triggers site job
    storybook: ... # triggers storybook job
```

Note: The `check` job runs on all web changes without filtering.

### Periodic Maintenance Steps

1. **Review Package.swift files** - Check each package's dependencies array:

   ```bash
   grep -r "\.package(path:" swift/*/Package.swift
   grep -r "\.package(path:" swift/*/App/Package.swift
   grep -r "\.package(path:" swift/*/lib-*/Package.swift
   ```

2. **Compare with CI filters** - Ensure each `files-changed` filter includes all
   transitive dependencies. If package A depends on package B, and B depends on C, then
   A's filter should include both B and C.

3. **Check for new packages** - If a new swift package is added:

   - Add it to the appropriate `libs` filter if it's a shared library
   - Add it to `api` filter if the API depends on it
   - Update app filters (macapp, iosapp) if they depend on it

4. **Check for new web packages** - If a new web package is added:

   - Determine which apps depend on it
   - Add to appropriate filters (dashboard, site, storybook)

5. **Check for moved/renamed packages** - If a package path changes, update filters
   accordingly.
