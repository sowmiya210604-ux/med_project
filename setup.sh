#!/bin/bash

# AI-Powered Medical Report System - Setup Script
# Run this script to set up the complete system

echo "🏥 AI-Powered Medical Report System - Setup"
echo "================================================"
echo ""

# Step 1: Backend Setup
echo "📦 Step 1: Setting up Backend..."
echo ""

cd med_backend

# Install dependencies
echo "Installing Node.js dependencies..."
npm install

if [ $? -ne 0 ]; then
    echo "❌ Failed to install dependencies"
    exit 1
fi

echo "✅ Dependencies installed successfully"
echo ""

# Update database schema
echo "Updating database schema..."
npm run prisma:push

if [ $? -ne 0 ]; then
    echo "⚠️  Database schema update failed. Make sure PostgreSQL is running."
    echo "You can run 'npm run prisma:push' manually later."
else
    echo "✅ Database schema updated successfully"
fi

echo ""

# Go back to root
cd ..

# Step 2: Flutter Setup
echo "📱 Step 2: Setting up Flutter..."
echo ""

# Install Flutter dependencies
echo "Installing Flutter dependencies..."
flutter pub get

if [ $? -ne 0 ]; then
    echo "❌ Failed to install Flutter dependencies"
    exit 1
fi

echo "✅ Flutter dependencies installed successfully"
echo ""

# Complete
echo "================================================"
echo "🎉 Setup Complete!"
echo ""
echo "Next Steps:"
echo "1. Start backend server:"
echo "   cd med_backend"
echo "   npm start"
echo ""
echo "2. Run Flutter app:"
echo "   flutter run"
echo ""
echo "📚 Documentation:"
echo "   - Quick Start: QUICKSTART_AI_REPORT_SYSTEM.md"
echo "   - Full Guide: AI_REPORT_SYSTEM_IMPLEMENTATION_GUIDE.md"
echo "   - Summary: IMPLEMENTATION_SUMMARY.md"
echo "   - Diagrams: SYSTEM_ARCHITECTURE_DIAGRAMS.md"
echo ""
echo "🚀 Ready to test your AI-powered report system!"
echo ""
