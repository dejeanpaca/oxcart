call uglifycss --output htmllog-mini.css htmllog.css
call uglifyjs --output htmllog-mini.js htmllog.js

call txt2passtr htmllog-mini.css > htmllog.css.inc
call txt2passtr htmllog-mini.js > htmllog.js.inc
