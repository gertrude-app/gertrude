---
title: 'Setting up a Vapor + Postgres Github Action Test Workflow'
date: '2021-10-01T10:26:37Z'
slug: vapor-swift-postgres-github-action-test-workflow
description:
  Took me a bit of fiddling to figure out how to test my PostgreSQL+Vapor app on Github
  actions. Posting the basic workflow file for future googlers
categories:
  - Swift
  - Vapor
---

Took me a bit of fiddling to figure out how to test my PostgreSQL+Vapor app on Github
actions. Posting the basic workflow file for future googlers:

```yml
name: basic-ci

on: push

env:
  LOG_LEVEL: info
  DATABASE_USERNAME: vapor_username
  DATABASE_PASSWORD: vapor_password
  DATABASE_NAME: vapor_database

jobs:
  linux:
    runs-on: ubuntu-latest
    env:
      DATABASE_HOST: postgres
    services:
      postgres:
        image: postgres:latest
        env:
          POSTGRES_USER: vapor_username
          POSTGRES_PASSWORD: vapor_password
          POSTGRES_DB: vapor_database
    container: swift:5.4-focal
    steps:
      - name: checkout
        uses: actions/checkout@v2
      - name: run tests
        run: swift test

  macos:
    runs-on: macos-11
    steps:
      - name: setup xcode
        uses: maxim-lobanov/setup-xcode@v1
        with:
          xcode-version: 12.5
      - name: checkout
        uses: actions/checkout@v2
      - name: start postgres
        # if this isn't reliable, try this approach
        # https://gist.github.com/jaredh159/634285e52456fefc9f04fb2b4bd3af28
        run: brew services start postgres; sleep 5 && pg_isready
      - name: create db user and db
        run: |
          psql --command="CREATE USER vapor_username PASSWORD 'vapor_password'" --command="\du" postgres
          createdb --owner=vapor_username vapor_database
      - name: run tests
        run: swift test
```
