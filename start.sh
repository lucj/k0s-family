PORT=1330
hugo mod tidy  
echo "--- Running Hugo on port: $PORT ---"
hugo server --logLevel debug --disableFastRender -p $PORT --appendPort=false
