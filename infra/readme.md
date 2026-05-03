# add this server config in vite.config.js
    server: {
        host: '0.0.0.0',   // listen on all interfaces inside container
        port: 5173,
        hmr: {
            host: 'localhost',  // what the BROWSER connects to (your machine)
        },
    },
# comment or remove ./bootstrap import from app.js

