# 📊 System Architecture & Workflow Diagrams

## 🏗 System Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                        FLUTTER APP (Mobile)                      │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  ┌────────────────┐  ┌──────────────────┐  ┌─────────────────┐ │
│  │  Upload Screen │  │ Report Explorer  │  │  Home Screen    │ │
│  │   - Camera     │  │  - Lab Reports   │  │  - Recent       │ │
│  │   - Gallery    │  │  - Imaging       │  │  - Statistics   │ │
│  │   - PDF        │  │  - Comparison    │  │                 │ │
│  └────────┬───────┘  └────────┬─────────┘  └─────────────────┘ │
│           │                    │                                 │
│  ┌────────▼────────────────────▼──────────────────────────────┐ │
│  │                  OCR Processing Service                     │ │
│  │  - ML Kit Text Recognition                                  │ │
│  │  - Image Processing                                         │ │
│  │  - Backend Communication                                    │ │
│  └────────┬────────────────────────────────────────────────────┘ │
│           │                                                      │
└───────────┼──────────────────────────────────────────────────────┘
            │
            │ HTTP/REST API
            │
┌───────────▼──────────────────────────────────────────────────────┐
│                    NODE.JS BACKEND (Express)                      │
├───────────────────────────────────────────────────────────────────┤
│                                                                   │
│  ┌────────────────────────────────────────────────────────────┐ │
│  │                     API Routes                              │ │
│  │  POST /api/reports/enhanced                                 │ │
│  │  GET  /api/reports/by-category                              │ │
│  │  POST /api/reports/compare                                  │ │
│  └──────────────────────┬──────────────────────────────────────┘ │
│                         │                                         │
│  ┌──────────────────────▼─────────────────────────────────────┐ │
│  │               Report Controller                             │ │
│  │  - Validate requests                                        │ │
│  │  - Handle file uploads                                      │ │
│  │  - Coordinate services                                      │ │
│  └──────────────────────┬─────────────────────────────────────┘ │
│                         │                                         │
│  ┌─────────────┬────────▼────────┬──────────────────────────┐   │
│  │             │                 │                          │   │
│  ▼             ▼                 ▼                          ▼   │
│  ┌─────────────┐ ┌──────────────┐ ┌────────────────┐ ┌──────┐ │
│  │ OCR Service │ │  Report      │ │   Health       │ │ Auth │ │
│  │             │ │  Processing  │ │   Analysis     │ │      │ │
│  │ - Extract   │ │  Service     │ │   Service      │ │      │ │
│  │ - Classify  │ │              │ │                │ │      │ │
│  │ - Parse     │ │ - Workflow   │ │ - Summaries    │ │      │ │
│  └─────────────┘ │ - Comparison │ │ - Insights     │ └──────┘ │
│                  └──────┬───────┘ └────────────────┘           │
│                         │                                        │
└─────────────────────────┼────────────────────────────────────────┘
                          │
                          │ Prisma ORM
                          │
┌─────────────────────────▼────────────────────────────────────────┐
│                   POSTGRESQL DATABASE                             │
├───────────────────────────────────────────────────────────────────┤
│                                                                   │
│  ┌──────────┐  ┌───────────┐  ┌──────────────┐  ┌────────────┐ │
│  │  Users   │  │ LabCenters│  │  TestMaster  │  │  Reports   │ │
│  └─────┬────┘  └─────┬─────┘  └──────┬───────┘  └─────┬──────┘ │
│        │             │                │                 │         │
│  ┌─────▼─────────────▼────────────────▼─────────────────▼──────┐ │
│  │                     Relationships                             │ │
│  └───────────────────────────────────────────────────────────────┘ │
│                                                                   │
│  ┌──────────────┐  ┌───────────────┐  ┌──────────────────────┐ │
│  │ TestResults  │  │ TestParameters│  │  HealthSummaries     │ │
│  └──────────────┘  └───────────────┘  └──────────────────────┘ │
│                                                                   │
└───────────────────────────────────────────────────────────────────┘
```

---

## 🔄 Report Upload Workflow

```
┌─────────────────────────────────────────────────────────────────┐
│                        USER ACTION                               │
└────────────────────────┬────────────────────────────────────────┘
                         │
                    [Takes Photo] or [Selects Image]
                         │
┌────────────────────────▼────────────────────────────────────────┐
│                     STEP 1: OCR EXTRACTION                       │
│  ┌────────────────────────────────────────────────────────────┐ │
│  │ ML Kit Text Recognition (On Device)                        │ │
│  │  - Process image                                            │ │
│  │  - Extract all visible text                                │ │
│  │  - Return raw OCR text                                     │ │
│  └────────────────────────────────────────────────────────────┘ │
│                                                                  │
│  Status: "🔍 Extracting text from image..."                     │
│  Time: ~1-2 seconds                                             │
└────────────────────────┬────────────────────────────────────────┘
                         │
                    [OCR Text Ready]
                         │
┌────────────────────────▼────────────────────────────────────────┐
│                   STEP 2: SEND TO BACKEND                        │
│  ┌────────────────────────────────────────────────────────────┐ │
│  │ HTTP POST /api/reports/enhanced                            │ │
│  │  Body:                                                      │ │
│  │   - ocrText: "extracted text..."                           │ │
│  │   - file: [image file]                                     │ │
│  │  Headers:                                                   │ │
│  │   - Authorization: Bearer <token>                          │ │
│  │   - Content-Type: multipart/form-data                      │ │
│  └────────────────────────────────────────────────────────────┘ │
│                                                                  │
│  Status: "☁️ Uploading to server..."                            │
│  Time: <1 second                                                │
└────────────────────────┬────────────────────────────────────────┘
                         │
                    [Received by Backend]
                         │
┌────────────────────────▼────────────────────────────────────────┐
│              STEP 3: AUTO-CLASSIFICATION                         │
│  ┌────────────────────────────────────────────────────────────┐ │
│  │ OCR Service: processOcrText()                              │ │
│  │                                                             │ │
│  │ 1. Extract Report Date                                     │ │
│  │    - Pattern: "Date: 12/01/2026" → 2026-01-12             │ │
│  │                                                             │ │
│  │ 2. Extract Lab Center Name                                 │ │
│  │    - First 5 lines with keywords                           │ │
│  │    - "ABC Diagnostics Lab" → Found                         │ │
│  │                                                             │ │
│  │ 3. Classify Category                                       │ │
│  │    - Search for keywords in text                           │ │
│  │    - "hemoglobin, wbc, rbc" → Lab Reports                  │ │
│  │                                                             │ │
│  │ 4. Classify Subcategory                                    │ │
│  │    - Match specific test type                              │ │
│  │    - "hemoglobin, platelet" → Blood Tests                  │ │
│  │                                                             │ │
│  │ 5. Extract Parameters                                      │ │
│  │    - "Hemoglobin  13.2  g/dL  12-16" →                     │ │
│  │      {name: "Hemoglobin", value: "13.2", unit: "g/dL"}    │ │
│  └────────────────────────────────────────────────────────────┘ │
│                                                                  │
│  Status: "🎯 Auto-classifying report..."                        │
│  Time: <1 second                                                │
└────────────────────────┬────────────────────────────────────────┘
                         │
                    [Classification Complete]
                         │
┌────────────────────────▼────────────────────────────────────────┐
│                 STEP 4: DATABASE STORAGE                         │
│  ┌────────────────────────────────────────────────────────────┐ │
│  │ Report Processing Service: processReport()                 │ │
│  │                                                             │ │
│  │ 1. Find or Create Lab Center                               │ │
│  │    LabCenter.findOrCreate("ABC Diagnostics Lab")           │ │
│  │    → centerId: "uuid-123"                                  │ │
│  │                                                             │ │
│  │ 2. Create Report                                           │ │
│  │    Report.create({                                         │ │
│  │      userId, centerId,                                     │ │
│  │      category: "Lab Reports",                              │ │
│  │      subcategory: "Blood Tests",                           │ │
│  │      reportDate: 2026-01-12                                │ │
│  │    })                                                       │ │
│  │    → reportId: "uuid-456"                                  │ │
│  │                                                             │ │
│  │ 3. Create Test Results                                     │ │
│  │    TestResult.createMany([                                 │ │
│  │      {reportId, param: "Hemoglobin", value: "13.2", ...}, │ │
│  │      {reportId, param: "WBC", value: "7000", ...},        │ │
│  │      {reportId, param: "Platelets", value: "2.5L", ...}   │ │
│  │    ])                                                       │ │
│  │                                                             │ │
│  │ 4. Generate Health Summary                                 │ │
│  │    - Count abnormal results                                │ │
│  │    - Determine overall status                              │ │
│  │    - Calculate risk level                                  │ │
│  │    - Generate recommendations                              │ │
│  │    HealthSummary.create({                                  │ │
│  │      reportId, userId,                                     │ │
│  │      overallStatus: "NORMAL",                              │ │
│  │      riskLevel: "LOW"                                      │ │
│  │    })                                                       │ │
│  └────────────────────────────────────────────────────────────┘ │
│                                                                  │
│  Status: "📊 Storing report data..."                            │
│  Time: <1 second                                                │
└────────────────────────┬────────────────────────────────────────┘
                         │
                    [Stored Successfully]
                         │
┌────────────────────────▼────────────────────────────────────────┐
│                  STEP 5: RETURN RESPONSE                         │
│  ┌────────────────────────────────────────────────────────────┐ │
│  │ Response Payload                                            │ │
│  │ {                                                           │ │
│  │   "message": "Report processed successfully",              │ │
│  │   "report": {                                              │ │
│  │     "category": "Lab Reports",                             │ │
│  │     "subcategory": "Blood Tests",                          │ │
│  │     "labCenter": {                                         │ │
│  │       "centerName": "ABC Diagnostics Lab"                  │ │
│  │     },                                                      │ │
│  │     "testResults": [                                       │ │
│  │       {"parameter": "Hemoglobin", "value": "13.2", ...},  │ │
│  │       {"parameter": "WBC", "value": "7000", ...}          │ │
│  │     ],                                                      │ │
│  │     "healthSummaries": [{                                  │ │
│  │       "overallStatus": "NORMAL",                           │ │
│  │       "riskLevel": "LOW"                                   │ │
│  │     }]                                                      │ │
│  │   }                                                         │ │
│  │ }                                                           │ │
│  └────────────────────────────────────────────────────────────┘ │
│                                                                  │
│  Time: <100ms                                                   │
└────────────────────────┬────────────────────────────────────────┘
                         │
                    [Display Success]
                         │
┌────────────────────────▼────────────────────────────────────────┐
│                    USER SEES RESULT                              │
│  ┌────────────────────────────────────────────────────────────┐ │
│  │  ✅ Report Processed Successfully!                          │ │
│  │                                                             │ │
│  │  Category: Lab Reports                                     │ │
│  │  Subcategory: Blood Tests                                  │ │
│  │  Lab/Center: ABC Diagnostics Lab                           │ │
│  │  Parameters Found: 15                                      │ │
│  │                                                             │ │
│  │  [Done]                                                    │ │
│  └────────────────────────────────────────────────────────────┘ │
│                                                                  │
│  ⏱ Total Time: 3-5 seconds                                      │
└──────────────────────────────────────────────────────────────────┘
```

---

## 📊 Report Comparison Workflow

```
┌──────────────────────────────────────────────────────────────────┐
│                      USER OPENS REPORT EXPLORER                  │
└────────────────────────┬─────────────────────────────────────────┘
                         │
                [Selects: Lab Reports → Blood Tests]
                         │
┌────────────────────────▼─────────────────────────────────────────┐
│               LOAD REPORTS FOR SUBCATEGORY                       │
│  ┌─────────────────────────────────────────────────────────────┐ │
│  │ ReportExplorerProvider.loadReportsForSubCategory()          │ │
│  │                                                              │ │
│  │ 1. Filter reports matching "Blood Tests"                    │ │
│  │ 2. Sort by date (newest first)                              │ │
│  │ 3. Load test results for each report                        │ │
│  │ 4. Build parameter maps                                     │ │
│  │ 5. Update currentReports list                               │ │
│  └─────────────────────────────────────────────────────────────┘ │
│                                                                   │
│  Result: 3 reports found                                         │
│   - 12 Jan 2026 (15 parameters)                                 │
│   - 05 Dec 2025 (14 parameters)                                 │
│   - 22 Oct 2025 (15 parameters)                                 │
└────────────────────────┬─────────────────────────────────────────┘
                         │
                [Render Excel-Style Table]
                         │
┌────────────────────────▼─────────────────────────────────────────┐
│                    DISPLAY TABLE                                 │
│  ┌─────────────────────────────────────────────────────────────┐ │
│  │                                                              │ │
│  │  Parameter    │ 12 Jan 2026 │ 05 Dec 2025 │ 22 Oct 2025    │ │
│  │  ───────────────────────────────────────────────────────────│ │
│  │  Hemoglobin   │   13.2 🟢   │   12.8 🟢   │   12.5 🟢      │ │
│  │  WBC          │   7000 🟢   │   6800 🟢   │   7200 🟢      │ │
│  │  Platelets    │   2.5L 🟠   │   2.3L 🔴   │   2.4L 🟠      │ │
│  │  RBC          │   4.5 🟢    │   4.4 🟢    │   4.6 🟢       │ │
│  │  ───────────────────────────────────────────────────────────│ │
│  │  Summary      │   Normal    │   Caution   │   Normal       │ │
│  │                                                              │ │
│  │  [Compare Reports]                                          │ │
│  └─────────────────────────────────────────────────────────────┘ │
└────────────────────────┬─────────────────────────────────────────┘
                         │
                [User Clicks "Compare Reports"]
                         │
┌────────────────────────▼─────────────────────────────────────────┐
│                   ENTER COMPARISON MODE                          │
│  ┌─────────────────────────────────────────────────────────────┐ │
│  │ ReportExplorerProvider.toggleComparisonMode()               │ │
│  │  → isComparisonMode = true                                  │ │
│  └─────────────────────────────────────────────────────────────┘ │
│                                                                   │
│  UI Changes:                                                     │
│   - Checkboxes appear on date columns                           │
│   - Selection info banner appears                               │
│   - "Exit Comparison Mode" button shows                         │
└────────────────────────┬─────────────────────────────────────────┘
                         │
            [User Selects 2 Date Columns]
                         │
┌────────────────────────▼─────────────────────────────────────────┐
│                    SELECT REPORTS                                │
│  ┌─────────────────────────────────────────────────────────────┐ │
│  │  Parameter    │ ☑ 12 Jan    │ □ 05 Dec    │ ☑ 22 Oct       │ │
│  │  ───────────────────────────────────────────────────────────│ │
│  │  Hemoglobin   │   13.2      │   12.8      │   12.5         │ │
│  │  WBC          │   7000      │   6800      │   7200         │ │
│  │  Platelets    │   2.5L      │   2.3L      │   2.4L         │ │
│  │                                                              │ │
│  │  ℹ️  Selected: 2 / 2                                         │ │
│  │  [Generate Comparison]                                      │ │
│  └─────────────────────────────────────────────────────────────┘ │
└────────────────────────┬─────────────────────────────────────────┘
                         │
            [User Clicks "Generate Comparison"]
                         │
┌────────────────────────▼─────────────────────────────────────────┐
│                   CALCULATE CHANGES                              │
│  ┌─────────────────────────────────────────────────────────────┐ │
│  │ For each parameter:                                          │ │
│  │                                                              │ │
│  │ Hemoglobin:                                                  │ │
│  │   Older: 12.5 g/dL (22 Oct 2025)                            │ │
│  │   Newer: 13.2 g/dL (12 Jan 2026)                            │ │
│  │   Change: +0.7                                               │ │
│  │   Percent: +5.6%                                             │ │
│  │   Trend: INCREASE ↑                                          │ │
│  │                                                              │ │
│  │ WBC:                                                          │ │
│  │   Older: 7200 cells/µL                                       │ │
│  │   Newer: 7000 cells/µL                                       │ │
│  │   Change: -200                                               │ │
│  │   Percent: -2.8%                                             │ │
│  │   Trend: DECREASE ↓                                          │ │
│  │                                                              │ │
│  │ Platelets:                                                   │ │
│  │   Older: 2.4L lakhs/µL                                       │ │
│  │   Newer: 2.5L lakhs/µL                                       │ │
│  │   Change: +0.1                                               │ │
│  │   Percent: +4.2%                                             │ │
│  │   Trend: INCREASE ↑                                          │ │
│  └─────────────────────────────────────────────────────────────┘ │
└────────────────────────┬─────────────────────────────────────────┘
                         │
                [Show Comparison Dialog]
                         │
┌────────────────────────▼─────────────────────────────────────────┐
│                   DISPLAY COMPARISON                             │
│  ┌─────────────────────────────────────────────────────────────┐ │
│  │              📊 Detailed Comparison                          │ │
│  │  ─────────────────────────────────────────────────────────  │ │
│  │                                                              │ │
│  │  🩸 Hemoglobin                                               │ │
│  │  Older: 12.5 g/dL     ↑ +0.7 (+5.6%)     Newer: 13.2 g/dL  │ │
│  │                                                              │ │
│  │  🔬 WBC                                                       │ │
│  │  Older: 7200 cells/µL ↓ -200 (-2.8%)     Newer: 7000       │ │
│  │                                                              │ │
│  │  🩹 Platelets                                                │ │
│  │  Older: 2.4L lakhs/µL ↑ +0.1 (+4.2%)     Newer: 2.5L       │ │
│  │                                                              │ │
│  │  🔴 RBC                                                       │ │
│  │  Older: 4.6 M/µL      ↓ -0.1 (-2.2%)     Newer: 4.5 M/µL   │ │
│  │                                                              │ │
│  │  ─────────────────────────────────────────────────────────  │ │
│  │                        [Close]                               │ │
│  └─────────────────────────────────────────────────────────────┘ │
└──────────────────────────────────────────────────────────────────┘

Legend:
🟢 Normal    🟠 Low    🔴 High
↑ Increase   ↓ Decrease   → Stable
```

---

## 🎨 UI Component Hierarchy

```
MainScreen
└── HomeScreen
    ├── RecentsSection
    │   └── RecentReportCards (existing)
    │
    └── ReportExplorerSection ⭐ NEW
        ├── SectionHeader
        │   ├── Title: "Report Explorer"
        │   └── Description
        │
        ├── ExpandableCategoryCard (Lab Reports) ⭐ NEW
        │   ├── CategoryHeader
        │   │   ├── Icon (Science)
        │   │   └── Title
        │   ├── SubcategoryList (when expanded)
        │   │   ├── Blood Tests
        │   │   ├── Urine Tests
        │   │   ├── Liver Function Tests
        │   │   └── ... (11 total)
        │   └── OnTap → LoadReports
        │
        ├── ExpandableCategoryCard (Imaging Reports) ⭐ NEW
        │   ├── CategoryHeader
        │   │   ├── Icon (Medical Services)
        │   │   └── Title
        │   ├── SubcategoryList (when expanded)
        │   │   ├── X-Ray
        │   │   ├── CT Scan
        │   │   ├── MRI
        │   │   └── ... (7 total)
        │   └── OnTap → LoadReports
        │
        └── ExcelStyleComparisonTable ⭐ NEW
            ├── TableHeader
            │   ├── Title (Subcategory name)
            │   └── Report count
            │
            ├── ComparisonModeToggle
            │   └── "Compare Reports" button
            │
            ├── ComparisonControls (when mode active)
            │   ├── Selection info
            │   └── "Generate Comparison" button
            │
            └── DataTable
                ├── ParameterColumn (fixed)
                ├── DateColumns (scrollable)
                │   ├── Column Header (date + checkbox)
                │   └── Value Cells (color-coded)
                └── SummaryRow (overall status)
```

---

## 🗄 Database Entity Relationships

```
┌─────────────────────┐
│       User          │
│ ─────────────────── │
│ id (PK)             │
│ name                │
│ email               │
│ phoneNumber         │
└──────────┬──────────┘
           │ 1
           │
           │ *
┌──────────▼──────────┐        ┌─────────────────────┐
│      Report         │        │     LabCenter       │
│ ─────────────────── │ *    1 │ ─────────────────── │
│ id (PK)             ├────────┤ id (PK)             │
│ userId (FK)         │        │ centerName          │
│ centerId (FK) ──────┘        │ type (lab/scan)     │
│ testType            │        │ location            │
│ reportDate          │        └─────────────────────┘
│ category ⭐          │
│ subcategory ⭐       │
│ filePath ⭐          │
│ fileName ⭐          │
└──────────┬──────────┘
           │ 1
           │
           │ *
┌──────────▼──────────┐        ┌─────────────────────┐
│    TestResult       │        │  TestParameter      │
│ ─────────────────── │ *    1 │ ─────────────────── │
│ id (PK)             ├────────┤ id (PK)             │
│ reportId (FK)       │        │ testId (FK)         │
│ parameterId (FK) ⭐──┘        │ parameterName       │
│ testCategory        │        │ unit                │
│ parameterName       │        │ normalMin           │
│ value               │        │ normalMax           │
│ unit                │        └─────────┬───────────┘
│ status              │                  │ *
│ testDate            │                  │
└─────────────────────┘                  │ 1
                                ┌────────▼───────────┐
┌─────────────────────┐         │    TestMaster      │
│  HealthSummary      │         │ ─────────────────  │
│ ─────────────────── │         │ id (PK)            │
│ id (PK)             │         │ testName           │
│ userId (FK)         │         │ category           │
│ reportId (FK) ⭐     │         │ subcategory        │
│ summaryText         │         │ description        │
│ overallStatus       │         └────────────────────┘
│ riskLevel           │
│ keyIssues ⭐         │
│ recommendations ⭐   │
└─────────────────────┘

Legend:
PK = Primary Key
FK = Foreign Key
⭐ = New/Enhanced Field
1 = One
* = Many
```

---

## 📱 Screen Flow Diagram

```
┌──────────────────────────────────────────────────────────┐
│                      LOGIN SCREEN                         │
└────────────────────┬─────────────────────────────────────┘
                     │ Login Success
                     ▼
┌──────────────────────────────────────────────────────────┐
│                      HOME SCREEN                          │
│ ───────────────────────────────────────────────────────  │
│  📊 Recent Reports Section                                │
│  [Card 1] [Card 2] [Card 3]                              │
│                                                           │
│  🔍 Report Explorer Section ⭐ NEW                        │
│  ┌─────────────────────────────────────────────────────┐ │
│  │ 🔬 Lab Reports            [Expand ▼]                │ │
│  └─────────────────────────────────────────────────────┘ │
│  ┌─────────────────────────────────────────────────────┐ │
│  │ 🏥 Imaging Reports        [Expand ▼]                │ │
│  └─────────────────────────────────────────────────────┘ │
│                                                           │
│  [Upload Report FAB +]                                   │
└────────┬─────────────┬────────────────────────────────────┘
         │             │
         │ Expand      │ Click FAB
         │             │
         ▼             ▼
┌──────────────────┐  ┌──────────────────────────────────────┐
│  EXPANDED VIEW   │  │  ENHANCED UPLOAD SCREEN ⭐ NEW       │
│ ───────────────  │  │ ───────────────────────────────────  │
│ 🔬 Lab Reports   │  │  📋 Choose Upload Method             │
│  └ Blood Tests   │  │  ┌────────────────────────────────┐  │
│  └ Urine Tests   │  │  │ 📷 Take Photo                  │  │
│  └ Liver Tests   │  │  └────────────────────────────────┘  │
│  └ Thyroid Tests │  │  ┌────────────────────────────────┐  │
│  └ ...           │  │  │ 🖼 Gallery                     │  │
│                  │  │  └────────────────────────────────┘  │
│ [Tap any] ──────►│  │  ┌────────────────────────────────┐  │
│                  │  │  │ 📄 PDF                         │  │
│                  │  │  └────────────────────────────────┘  │
│                  │  └────────────┬─────────────────────────┘
│                  │               │ Select Image
│                  │               ▼
│                  │  ┌──────────────────────────────────────┐
│                  │  │  IMAGE PREVIEW                       │
│                  │  │  [Image displayed]                   │
│                  │  │  [Process & Upload]                  │
│                  │  └────────────┬─────────────────────────┘
│                  │               │ Process
│                  │               ▼
│                  │  ┌──────────────────────────────────────┐
│                  │  │  PROCESSING...                       │
│                  │  │  🔍 Extracting text...               │
│                  │  │  🎯 Auto-classifying...              │
│                  │  │  📊 Extracting parameters...         │
│                  │  │  ☁️  Uploading...                     │
│                  │  └────────────┬─────────────────────────┘
│                  │               │ Complete
│                  │               ▼
│                  │  ┌──────────────────────────────────────┐
│                  │  │  ✅ SUCCESS                          │
│                  │  │  Category: Lab Reports               │
│                  │  │  Subcategory: Blood Tests            │
│                  │  │  Lab: ABC Diagnostics                │
│                  │  │  Parameters: 15                      │
│                  │  │  [Done] → Back to Home              │
│                  │  └──────────────────────────────────────┘
│                  │
▼                  │
┌──────────────────────────────────────────────────────────┐
│           EXCEL-STYLE COMPARISON TABLE ⭐ NEW            │
│ ───────────────────────────────────────────────────────  │
│ 🩸 Blood Tests                          3 reports found  │
│                                                           │
│ ┌───────────────┬─────────┬─────────┬─────────┐         │
│ │ Parameter     │ 12 Jan  │ 05 Dec  │ 22 Oct  │         │
│ ├───────────────┼─────────┼─────────┼─────────┤         │
│ │ Hemoglobin    │ 13.2 🟢 │ 12.8 🟢 │ 12.5 🟢 │         │
│ │ WBC           │ 7000 🟢 │ 6800 🟢 │ 7200 🟢 │         │
│ │ Platelets     │ 2.5L 🟠 │ 2.3L 🔴 │ 2.4L 🟠 │         │
│ │ RBC           │ 4.5 🟢  │ 4.4 🟢  │ 4.6 🟢  │         │
│ ├───────────────┼─────────┼─────────┼─────────┤         │
│ │ Summary       │ Normal  │ Caution │ Normal  │         │
│ └───────────────┴─────────┴─────────┴─────────┘         │
│                                                           │
│ [Compare Reports]                                        │
└────────────┬──────────────────────────────────────────────┘
             │ Click Compare
             ▼
┌──────────────────────────────────────────────────────────┐
│              COMPARISON MODE ACTIVE                       │
│ ───────────────────────────────────────────────────────  │
│ ℹ️  Select exactly 2 reports to compare                  │
│ Selected: 2 / 2                                          │
│                                                           │
│ ┌───────────────┬──────────┬─────────┬──────────┐        │
│ │ Parameter     │ ☑ 12 Jan │ □ 05Dec │ ☑ 22 Oct │        │
│ ├───────────────┼──────────┼─────────┼──────────┤        │
│ │ ...values...  │          │         │          │        │
│ └───────────────┴──────────┴─────────┴──────────┘        │
│                                                           │
│ [Generate Comparison]                                    │
└────────────┬──────────────────────────────────────────────┘
             │ Generate
             ▼
┌──────────────────────────────────────────────────────────┐
│            COMPARISON DIALOG ⭐ NEW                       │
│ ───────────────────────────────────────────────────────  │
│ 📊 Detailed Comparison                                   │
│                                                           │
│ 🩸 Hemoglobin                                             │
│ Older: 12.5 g/dL    ↑ +0.7 (+5.6%)    Newer: 13.2 g/dL  │
│                                                           │
│ 🔬 WBC                                                     │
│ Older: 7200         ↓ -200 (-2.8%)    Newer: 7000       │
│                                                           │
│ 🩹 Platelets                                              │
│ Older: 2.4L         ↑ +0.1 (+4.2%)    Newer: 2.5L       │
│                                                           │
│ [Close]                                                  │
└──────────────────────────────────────────────────────────┘
```

---

## 🎯 Complete Feature Map

```
AI-POWERED MEDICAL REPORT SYSTEM
│
├── 📷 UPLOAD FEATURES
│   ├── Camera capture
│   ├── Gallery selection
│   ├── PDF selection (planned)
│   ├── Multi-page support (planned)
│   └── File validation (10MB limit)
│
├── 🔍 OCR & PROCESSING
│   ├── ML Kit text recognition
│   ├── Report date extraction
│   ├── Lab center detection
│   ├── Auto-classification
│   │   ├── Lab Reports (11 types)
│   │   └── Imaging Reports (7 types)
│   ├── Parameter extraction
│   │   ├── Parameter name
│   │   ├── Value
│   │   ├── Unit
│   │   └── Reference range
│   └── Status determination
│       ├── Normal
│       ├── High
│       └── Low
│
├── 🗄 DATABASE OPERATIONS
│   ├── Lab center management
│   ├── Report storage
│   ├── Test result storage
│   ├── Health summary generation
│   └── Relationship management
│
├── 🏠 HOME SCREEN UI
│   ├── Recent reports section
│   └── Report Explorer ⭐
│       ├── Expandable categories
│       ├── Subcategory selection
│       └── Auto-load reports
│
├── 📊 EXCEL-STYLE TABLE ⭐
│   ├── Dynamic columns (dates)
│   ├── Dynamic rows (parameters)
│   ├── Color-coded values
│   │   ├── Green (Normal)
│   │   ├── Red (High)
│   │   └── Orange (Low)
│   ├── Status badges
│   ├── Summary row
│   └── Smooth scrolling
│       ├── Horizontal
│       └── Vertical
│
├── 🔄 COMPARISON FEATURES ⭐
│   ├── Comparison mode toggle
│   ├── Visual selection (checkboxes)
│   ├── 2-report limit
│   ├── Generate comparison
│   ├── Detailed comparison dialog
│   │   ├── Parameter-by-parameter
│   │   ├── Value changes
│   │   ├── Percentage changes
│   │   └── Trend indicators
│   └── Export (planned)
│
├── 🏥 HEALTH INSIGHTS
│   ├── Overall status
│   │   ├── Normal
│   │   ├── Caution
│   │   └── Critical
│   ├── Risk level
│   │   ├── Low
│   │   ├── Medium
│   │   └── High
│   ├── Key issues list
│   └── Recommendations
│
└── 📡 API ENDPOINTS
    ├── POST /api/reports/enhanced
    ├── GET  /api/reports/by-category
    ├── POST /api/reports/compare
    └── POST /api/reports/comparison-data
```

---

**🎉 All diagrams complete! Reference these for understanding the system architecture and workflows.**
