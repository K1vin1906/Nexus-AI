#!/bin/bash
# Fix Nexus AI keychain authorization prompts
# Updates partition list to allow any app signature to access the keys

echo "🔑 Nexus AI — Fix Keychain Authorization"
echo "This will stop the password prompts when rebuilding."
echo ""
read -s -p "Enter your Mac login password: " KPASS
echo ""
echo ""

SERVICE="notfullin.com.macai"
SUCCESS=0

for ITEM in $(security dump-keychain 2>/dev/null | grep "acct.*api_token" | sed 's/.*<blob>="//' | sed 's/".*//'); do
    echo -n "Fixing: $ITEM ... "
    
    if security set-generic-password-partition-list \
        -s "$SERVICE" -a "$ITEM" \
        -S "apple:,signer:,teamid:" \
        -k "$KPASS" >/dev/null 2>&1; then
        echo "✅"
        SUCCESS=$((SUCCESS + 1))
    else
        echo "❌ (wrong password or item locked)"
    fi
done

if [ $SUCCESS -gt 0 ]; then
    echo ""
    echo "Done! $SUCCESS items fixed. No more keychain prompts."
else
    echo ""
    echo "No items were fixed. Check your password and try again."
fi
