#!/bin/bash
# Get a trusted certificate from Let's Encrypt using certbot

set -e

echo "🔍 Checking requirements..."

# Check if running as root or can sudo
if ! sudo -n true 2>/dev/null; then
    echo "⚠️  This script needs sudo access. You may be prompted for your password."
fi

# Check if port 80 is available
if lsof -Pi :80 -sTCP:LISTEN -t >/dev/null 2>&1; then
    echo "❌ Port 80 is already in use. Please stop any service using it."
    lsof -Pi :80 -sTCP:LISTEN
    exit 1
fi

echo "✅ Port 80 is available"

# Prompt for email
read -p "📧 Enter your email for Let's Encrypt notifications: " EMAIL

if [ -z "$EMAIL" ]; then
    echo "❌ Email is required"
    exit 1
fi

echo ""
echo "📝 This will:"
echo "   - Request a certificate for 2lfin.ir"
echo "   - Use Let's Encrypt (free, trusted by all browsers)"
echo "   - Certificate valid for 90 days (auto-renewal recommended)"
echo ""
read -p "Continue? (y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    exit 1
fi

echo ""
echo "🔐 Requesting certificate from Let's Encrypt..."

# Get certificate using standalone mode
sudo certbot certonly --standalone \
  -d 2lfin.ir \
  --agree-tos \
  --email "$EMAIL" \
  --non-interactive \
  --preferred-challenges http

if [ $? -eq 0 ]; then
    echo ""
    echo "✅ Certificate obtained successfully!"
    echo ""
    echo "📋 Copying certificates to current directory..."
    
    # Copy certificates to current directory
    sudo cp /etc/letsencrypt/live/2lfin.ir/fullchain.pem ./cert.pem
    sudo cp /etc/letsencrypt/live/2lfin.ir/privkey.pem ./key.pem
    sudo chown $(whoami) ./cert.pem ./key.pem
    chmod 644 ./cert.pem ./key.pem
    
    echo "✅ Certificates copied to:"
    echo "   - cert.pem (certificate)"
    echo "   - key.pem (private key)"
    echo ""
    echo "🎉 Done! You can now run your media server:"
    echo "   cargo run --release"
    echo ""
    echo "⏰ Certificate expires in 90 days. Set up auto-renewal with:"
    echo "   sudo certbot renew --dry-run"
else
    echo ""
    echo "❌ Failed to obtain certificate. Common issues:"
    echo "   - Domain 2lfin.ir doesn't point to this server"
    echo "   - Port 80 is blocked by firewall"
    echo "   - DNS propagation not complete"
    echo ""
    echo "💡 Check your domain DNS settings and firewall rules"
fi
