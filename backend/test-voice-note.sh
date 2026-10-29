#!/bin/bash

# Voice Note Feedback API Test Script
# This script tests the voice note endpoints

BASE_URL="http://localhost:3000"
TOKEN=""  # Add your authentication token here
FEEDBACK_ID=""  # Add a feedback ID to test with
AUDIO_FILE=""  # Path to a test audio file (e.g., test.m4a)

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${YELLOW}Voice Note Feedback API Tests${NC}\n"

# Check if required variables are set
if [ -z "$TOKEN" ]; then
    echo -e "${RED}Error: TOKEN is not set. Please add your authentication token.${NC}"
    exit 1
fi

if [ -z "$FEEDBACK_ID" ]; then
    echo -e "${RED}Error: FEEDBACK_ID is not set. Please add a feedback ID.${NC}"
    exit 1
fi

# Test 1: Upload Voice Note
echo -e "${YELLOW}Test 1: Upload Voice Note${NC}"
if [ -n "$AUDIO_FILE" ] && [ -f "$AUDIO_FILE" ]; then
    RESPONSE=$(curl -s -w "\n%{http_code}" -X POST \
        -H "Authorization: Bearer $TOKEN" \
        -F "voiceNote=@$AUDIO_FILE" \
        -F "duration=30" \
        "$BASE_URL/v1/feedback/$FEEDBACK_ID/voice-note")

    HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
    BODY=$(echo "$RESPONSE" | sed '$d')

    if [ "$HTTP_CODE" -eq 200 ]; then
        echo -e "${GREEN}✓ Upload successful${NC}"
        echo "$BODY" | jq '.'
    else
        echo -e "${RED}✗ Upload failed (HTTP $HTTP_CODE)${NC}"
        echo "$BODY" | jq '.'
    fi
else
    echo -e "${YELLOW}⊘ Skipped (no audio file provided)${NC}"
fi

echo ""

# Test 2: Get Voice Note URL
echo -e "${YELLOW}Test 2: Get Voice Note URL${NC}"
RESPONSE=$(curl -s -w "\n%{http_code}" -X GET \
    -H "Authorization: Bearer $TOKEN" \
    "$BASE_URL/v1/feedback/$FEEDBACK_ID/voice-note")

HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
BODY=$(echo "$RESPONSE" | sed '$d')

if [ "$HTTP_CODE" -eq 200 ]; then
    echo -e "${GREEN}✓ Retrieved successfully${NC}"
    echo "$BODY" | jq '.'
elif [ "$HTTP_CODE" -eq 404 ]; then
    echo -e "${YELLOW}⊘ No voice note found (expected if not uploaded)${NC}"
    echo "$BODY" | jq '.'
else
    echo -e "${RED}✗ Request failed (HTTP $HTTP_CODE)${NC}"
    echo "$BODY" | jq '.'
fi

echo ""

# Test 3: Get Feedback (includes voice note)
echo -e "${YELLOW}Test 3: Get Feedback (includes voice note)${NC}"
SUBMISSION_ID=""  # Add submission ID if available

if [ -n "$SUBMISSION_ID" ]; then
    RESPONSE=$(curl -s -w "\n%{http_code}" -X GET \
        -H "Authorization: Bearer $TOKEN" \
        "$BASE_URL/v1/feedback/$SUBMISSION_ID")

    HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
    BODY=$(echo "$RESPONSE" | sed '$d')

    if [ "$HTTP_CODE" -eq 200 ]; then
        echo -e "${GREEN}✓ Retrieved successfully${NC}"
        echo "$BODY" | jq '.'
    else
        echo -e "${RED}✗ Request failed (HTTP $HTTP_CODE)${NC}"
        echo "$BODY" | jq '.'
    fi
else
    echo -e "${YELLOW}⊘ Skipped (no submission ID provided)${NC}"
fi

echo ""

# Test 4: Delete Voice Note
echo -e "${YELLOW}Test 4: Delete Voice Note${NC}"
read -p "Do you want to delete the voice note? (y/n): " -n 1 -r
echo ""

if [[ $REPLY =~ ^[Yy]$ ]]; then
    RESPONSE=$(curl -s -w "\n%{http_code}" -X DELETE \
        -H "Authorization: Bearer $TOKEN" \
        "$BASE_URL/v1/feedback/$FEEDBACK_ID/voice-note")

    HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
    BODY=$(echo "$RESPONSE" | sed '$d')

    if [ "$HTTP_CODE" -eq 200 ]; then
        echo -e "${GREEN}✓ Deleted successfully${NC}"
        echo "$BODY" | jq '.'
    elif [ "$HTTP_CODE" -eq 404 ]; then
        echo -e "${YELLOW}⊘ No voice note found${NC}"
        echo "$BODY" | jq '.'
    else
        echo -e "${RED}✗ Delete failed (HTTP $HTTP_CODE)${NC}"
        echo "$BODY" | jq '.'
    fi
else
    echo -e "${YELLOW}⊘ Skipped${NC}"
fi

echo ""
echo -e "${GREEN}Tests completed${NC}"
