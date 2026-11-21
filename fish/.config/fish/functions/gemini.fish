function gemini --description 'Gemini CLI via local HTTP proxy'
    env HTTP_PROXY=http://localhost:3456 \
        HTTPS_PROXY=http://localhost:3456 \
        NO_PROXY=localhost,127.0.0.1,::1 \
        NODE_USE_ENV_PROXY=1 \
        GEMINI_MODEL=gemini-3.8-flash \
        /opt/homebrew/bin/gemini $argv
end
