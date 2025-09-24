# Metadata Filters for Reports API

## Overview

The Gabay system now supports advanced filtering of application and enrollment data using a structured metadata format. This document explains the available filters and how to use them with the Reports API.

## Metadata Structure

Application metadata is structured in the following way:

```json
{
  "personalInfo": {
    "lastName": "Smith",
    "firstName": "John",
    "middleName": "Adam",
    "sex": "Male",
    "birthDate": "2010-05-15",
    "email": "example@email.com",
    "phone": "+63912345678",
    "religion": "Seventh-day Adventist",
    "isSDA": true,
    "baptismDate": "2020-01-15"
  },
  "address": {
    "street": "123 Main Street",
    "city": "Canlaon",
    "province": "Negros Oriental",
    "zipCode": "6223"
  },
  "education": {
    "gradeLevel": "Grade 6",
    "studentType": "NEW",
    "academicYear": "2024-2025",
    "learningModality": "Face to Face",
    "academicTrack": {
      "type": "STEM",
      "details": {
        "humss": false,
        "stem": true,
        "abm": false,
        "tvl": false
      }
    }
  },
  "health": {
    "vaccination": {
      "isVaccinated": true,
      "firstDoseDate": "2021-07-15",
      "secondDoseDate": "2021-08-15",
      "hasBooster": false
    }
  },
  "family": {
    "father": {
      "lastName": "Smith",
      "firstName": "Robert",
      "middleName": "James",
      "nationality": "Filipino",
      "phone": "+63912345678"
    },
    "mother": {
      "lastName": "Smith",
      "firstName": "Mary",
      "middleName": "Anne",
      "nationality": "Filipino",
      "phone": "+63912345678"
    }
  },
  "accommodation": {
    "type": "stayOutNoCafeteriaOption",
    "details": {
      "home": true,
      "cottage": false,
      "dormitory": false
    }
  },
  "transportation": {
    "mode": "privateTransport",
    "details": {
      "schoolBus": false,
      "privateTransport": true
    },
    "pickupPoint": "Main Gate",
    "driverName": "James Smith"
  },
  "financial": {
    "guardian": {
      "lastName": "Smith",
      "firstName": "Robert",
      "middleName": "James",
      "relation": "Father",
      "phone": "+63912345678",
      "address": "123 Main Street, Canlaon, Negros Oriental",
      "email": "parent@email.com"
    }
  },
  "documents": {
    "hasBirthCertificate": true,
    "hasForm138": true,
    "hasGoodMoral": true
  },
  "fullName": "Smith, John Adam",
  "gradeLevelValue": "8ed365ee-85e7-11ee-b8f5-ea4f36113868",
  "contactNumber": "+63912345678"
}
```

## Available Filters

The following filters are available for the Reports API:

| Filter | URL Parameter | Example | Description |
|--------|---------------|---------|-------------|
| Religion | `religion` | `religion=Seventh-day%20Adventist` | Filter by religion |
| SDA Member | `isAdventist` | `isAdventist=true` | Filter by SDA membership |
| Gender | `sex` | `sex=Female` | Filter by gender |
| Student Type | `studentType` | `studentType=NEW` | Filter by student type (NEW/TRANSFEREE) |
| Vaccination Status | `isVaccinated` | `isVaccinated=true` | Filter by vaccination status |
| Accommodation | `accommodation` | `accommodation=dormitory` | Filter by accommodation type |
| Transportation | `transportMode` | `transportMode=schoolBus` | Filter by transportation mode |
| Learning Modality | `learningModality` | `learningModality=Face%20to%20Face` | Filter by learning modality |
| City | `city` | `city=Canlaon` | Filter by city of residence |
| Academic Track | `academicTrack` | `academicTrack=STEM` | Filter by academic track |
| STEM Track | `isSTEM` | `isSTEM=true` | Filter by STEM track participation |
| HUMSS Track | `isHUMSS` | `isHUMSS=true` | Filter by HUMSS track participation |
| ABM Track | `isABM` | `isABM=true` | Filter by ABM track participation |
| TVL Track | `isTVL` | `isTVL=true` | Filter by TVL track participation |
| Birth Certificate | `hasBirthCertificate` | `hasBirthCertificate=true` | Filter by birth certificate status |
| Form 138 | `hasForm138` | `hasForm138=true` | Filter by Form 138 status |
| Good Moral | `hasGoodMoral` | `hasGoodMoral=true` | Filter by good moral certificate status |
| Father Nationality | `fatherNationality` | `fatherNationality=Filipino` | Filter by father's nationality |
| Mother Nationality | `motherNationality` | `motherNationality=Filipino` | Filter by mother's nationality |

In addition to these metadata filters, standard filters are also available:

- `startDate`/`endDate`: Filter by submission date range
- `gradeLevel`: Filter by grade level
- `section`: Filter by section
- `status`: Filter by application status

## Usage Examples

### Get All SDA Students

```
GET /api/v2/report?reportType=admission&isAdventist=true
```

### Get New Students for Grade 6

```
GET /api/v2/report?reportType=admission&studentType=NEW&gradeLevel=GRADE_6
```

### Get Vaccinated Female Students

```
GET /api/v2/report?reportType=admission&isVaccinated=true&sex=Female
```

### Get Dormitory Students

```
GET /api/v2/report?reportType=admission&accommodation=dormitory
```

### Get STEM Students with Birth Certificates

```
GET /api/v2/report?reportType=admission&isSTEM=true&hasBirthCertificate=true
```

### Get Face-to-Face Students from Canlaon City 

```
GET /api/v2/report?reportType=admission&learningModality=Face%20to%20Face&city=Canlaon
```

### Get Students with Filipino Mothers

```
GET /api/v2/report?reportType=admission&motherNationality=Filipino
```

## Implementing New Filters

To add new filters:

1. Update the `FilterParams` interface in `api/src/pages/api/v2/report/index.tsx`
2. Add the new filter parameter to the `buildMetadataFilters` function
3. Update the handler function to parse the new parameter
4. Update this documentation

## Report Types and Available Demographics

Each report type includes relevant demographic data:

### Admission Report

- Gender Distribution: Shows breakdown by male/female students
- Religion Distribution: Shows breakdown by religious affiliation
- Accommodation Distribution: Shows where students are staying
- Vaccination Distribution: Shows vaccinated vs. unvaccinated students
- Student Type Distribution: Shows new vs. transferee students
- Transportation Distribution: Shows transportation modes
- Learning Modality Distribution: Shows preferred learning modalities
- Academic Track Distribution: Shows breakdown by academic track
- City Distribution: Shows where students come from
- Document Status: Shows compliance with documentation requirements
- Nationality Distribution: Shows parent nationalities

## Processing Metadata

Metadata is automatically processed when an application is submitted, but you can also manually process it:

```
POST /api/v2/applications/form-submission/process-metadata
{
  "formSubmissionId": "2b5412ea-b483-4405-80bb-954670323f60"
}
```

This will refresh the metadata for a specific form submission, enabling it to be filtered using the above parameters. 