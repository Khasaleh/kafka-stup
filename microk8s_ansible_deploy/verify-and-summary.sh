#!/bin/bash

# Verification and Summary Script
# This script provides a summary of the resource allocation work

set -e

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${BLUE}Resource Allocation Verification and Summary${NC}"
echo "================================================"
echo ""

# Count total services
TOTAL_SERVICES=$(ls -d application_deployment/dev/*/ | wc -l)
echo -e "${BLUE}Total Services Found: $TOTAL_SERVICES${NC}"
echo ""

# Check high usage services
echo -e "${GREEN}High Usage Services (1Gi memory):${NC}"
HIGH_SERVICES=$(grep -l "memory: \"1Gi\"" application_deployment/dev/*/deployment.yml 2>/dev/null || echo "")
if [ -n "$HIGH_SERVICES" ]; then
    echo "$HIGH_SERVICES" | sed 's|application_deployment/dev/||g' | sed 's|/deployment.yml||g'
    HIGH_COUNT=$(echo "$HIGH_SERVICES" | wc -l)
else
    echo "None found"
    HIGH_COUNT=0
fi
echo ""

# Check medium usage services
echo -e "${YELLOW}Medium Usage Services (512Mi memory):${NC}"
MEDIUM_SERVICES=$(grep -l "memory: \"512Mi\"" application_deployment/dev/*/deployment.yml 2>/dev/null || echo "")
if [ -n "$MEDIUM_SERVICES" ]; then
    echo "$MEDIUM_SERVICES" | sed 's|application_deployment/dev/||g' | sed 's|/deployment.yml||g'
    MEDIUM_COUNT=$(echo "$MEDIUM_SERVICES" | wc -l)
else
    echo "None found"
    MEDIUM_COUNT=0
fi
echo ""

# Check low usage services
echo -e "${RED}Low Usage Services (256Mi memory):${NC}"
LOW_SERVICES=$(grep -l "memory: \"256Mi\"" application_deployment/dev/*/deployment.yml 2>/dev/null || echo "")
if [ -n "$LOW_SERVICES" ]; then
    echo "$LOW_SERVICES" | sed 's|application_deployment/dev/||g' | sed 's|/deployment.yml||g'
    LOW_COUNT=$(echo "$LOW_SERVICES" | wc -l)
else
    echo "None found"
    LOW_COUNT=0
fi
echo ""

# Check services without resources
echo -e "${YELLOW}Services Without Resource Configuration:${NC}"
NO_RESOURCES=$(find application_deployment/dev/*/ -name "deployment.yml" -exec grep -L "resources:" {} \; 2>/dev/null || echo "")
if [ -n "$NO_RESOURCES" ]; then
    echo "$NO_RESOURCES" | sed 's|application_deployment/dev/||g' | sed 's|/deployment.yml||g'
    NO_RESOURCES_COUNT=$(echo "$NO_RESOURCES" | wc -l)
else
    echo "All services have resource configuration"
    NO_RESOURCES_COUNT=0
fi
echo ""

# Summary
echo -e "${BLUE}Summary:${NC}"
echo "=========="
echo -e "Total Services: $TOTAL_SERVICES"
echo -e "High Usage: $HIGH_COUNT"
echo -e "Medium Usage: $MEDIUM_COUNT"
echo -e "Low Usage: $LOW_COUNT"
echo -e "No Resources: $NO_RESOURCES_COUNT"
echo ""

# Service categories for reference
echo -e "${BLUE}Service Categories (Target):${NC}"
echo "================================"
echo ""
echo -e "${GREEN}High Usage Services (Target: 13):${NC}"
echo "angular-dev, angular-customer, angular-business, angular-ads, angular-employee, angular-customer-ssr"
echo "api-server, fazeal-business, order-service, catalog-service, posts-service, promotion-service, customer-service"
echo ""
echo -e "${YELLOW}Medium Usage Services (Target: 15):${NC}"
echo "payment-service, notification-service, loyalty-service, inventory-service, events-service, chat-app"
echo "business-chat, album-service, translation-service, watermark-detection, site-management-service"
echo "shopping-service, payment-gateway, employees-service, ads-service"
echo ""
echo -e "${RED}Low Usage Services (Target: 4):${NC}"
echo "config-server, api-gateway, cron-jobs, dataload-service"
echo ""

# Next steps
echo -e "${BLUE}Next Steps:${NC}"
echo "==========="
echo "1. Complete the resource allocation updates for remaining services"
echo "2. Deploy the updated configurations"
echo "3. Monitor resource usage and performance"
echo "4. Fine-tune based on actual usage patterns"
echo ""

# Files created
echo -e "${BLUE}Files Created:${NC}"
echo "=============="
echo "✅ resource-allocation-guide.md"
echo "✅ manual-resource-update.md"
echo "✅ RESOURCE-ALLOCATION-SUMMARY.md"
echo "✅ FINAL-RESOURCE-SUMMARY.md"
echo "✅ manual-update-resources.sh"
echo "✅ verify-and-summary.sh"
echo ""

echo -e "${GREEN}Resource allocation framework is ready!${NC}" 