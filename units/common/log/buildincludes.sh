#!/usr/bin/env bash

uglifycss --output htmllog-mini.css htmllog.css
uglifyjs --output htmllog-mini.js htmllog.js

txt2passtr htmllog-mini.css > htmllog.css.inc
txt2passtr htmllog-mini.js > htmllog.js.inc
