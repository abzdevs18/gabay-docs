# SiteMetadataService

## Overview

The `SiteMetadataService` provides a centralized way to access and modify site metadata for tenants. This service handles fetching, caching, and updating the metadata stored in the `SiteMetadata` table.

Site metadata contains configuration information for a tenant such as site name, school information, appearance settings, and other configuration values that are specific to a tenant.

## Usage

### Initialization

```typescript
import { SiteMetadataService } from '@/services/siteMetadata.service';

// In an API route handler
export default async function handler(req: NextApiRequest, res: NextApiResponse) {
  const metadataService = new SiteMetadataService(req);
  // Use the service...
}
```

### Fetching Metadata

```typescript
// Get all metadata as an object with key-value pairs
const allMetadata = await metadataService.getAllMetadata();

// Get a specific metadata value
const siteTitle = await metadataService.getMetadata(
  SiteMetadataService.KEYS.SITE_TITLE, 
  'Default Title' // Optional default value
);

// Get a boolean metadata value
const hasElementary = await metadataService.getBooleanMetadata(
  SiteMetadataService.KEYS.HAS_ELEMENTARY,
  false // Optional default value
);

// Get a numeric metadata value
const maxStudents = await metadataService.getNumericMetadata(
  SiteMetadataService.KEYS.MAX_STUDENTS_PER_SECTION,
  50 // Optional default value
);
```

### Updating Metadata

```typescript
// Set a single metadata value
const success = await metadataService.setMetadata(
  SiteMetadataService.KEYS.SITE_TITLE,
  'My School Site'
);

// Update multiple metadata values at once
const updated = await metadataService.setBulkMetadata({
  [SiteMetadataService.KEYS.SITE_TITLE]: 'My School Site',
  [SiteMetadataService.KEYS.SCHOOL_NAME]: 'Example High School',
  [SiteMetadataService.KEYS.SLOGAN]: 'Excellence in Education'
});
```

## Available Metadata Keys

The service defines a set of standard keys as static properties. This ensures consistency when accessing metadata values throughout the application.

```typescript
// Access keys using the static KEYS object
SiteMetadataService.KEYS.SITE_TITLE
SiteMetadataService.KEYS.SCHOOL_NAME
SiteMetadataService.KEYS.HAS_ELEMENTARY
// etc.
```

### General Site Settings

- `SITE_TITLE`: The title of the site
- `BRAND`: Brand name
- `LOGO_URL`: URL to the site logo
- `FAVICON_URL`: URL to the site favicon
- `SITE_URL`: The main URL of the site
- `THUMBNAIL_URL`: URL to the site thumbnail/preview image
- `SITE_DESCRIPTION`: Description of the site
- `SLOGAN`: Site slogan
- `ORG_FULL_NAME`: Full organization name

### School Information

- `SCHOOL_NAME`: Name of the school
- `SCHOOL_ID`: School ID number
- `SCHOOL_STREET`: Street address
- `SCHOOL_CITY`: City
- `SCHOOL_PROVINCE`: Province/State
- `SCHOOL_ZIP`: ZIP/Postal code
- `SCHOOL_CONTACT`: Contact number
- `SCHOOL_DIVISION`: School division
- `SCHOOL_REGION`: School region
- `SCHOOL_EMAIL`: School email address

### School Levels Configuration

- `HAS_ELEMENTARY`: Whether the school has elementary education
- `HAS_JUNIOR_HIGH`: Whether the school has junior high education
- `HAS_SENIOR_HIGH`: Whether the school has senior high education
- `HAS_TERTIARY`: Whether the school has tertiary education
- `MAX_STUDENTS_PER_SECTION`: Maximum number of students per section

### Prefix Configurations

- `PREFIX_ELEMENTARY_ADMISSION`: Prefix for elementary admission IDs
- `PREFIX_JUNIOR_HIGH_ADMISSION`: Prefix for junior high admission IDs
- `PREFIX_SENIOR_HIGH_ADMISSION`: Prefix for senior high admission IDs
- `PREFIX_ELEMENTARY_STUDENT`: Prefix for elementary student IDs
- `PREFIX_JUNIOR_HIGH_STUDENT`: Prefix for junior high student IDs
- `PREFIX_SENIOR_HIGH_STUDENT`: Prefix for senior high student IDs

## Technical Details

### Caching

The service implements caching in two layers:

1. Redis cache for shared access across multiple server instances
2. In-memory instance cache for repeated requests during the same request lifecycle

### Tenant-specific Behavior

The service automatically handles tenant-specific data:

- Fetches tenant details based on the request
- Merges default settings with tenant-specific overrides
- Maintains proper separation between tenant data

### Error Handling

All methods that modify data return boolean values indicating success or failure, with errors appropriately logged. 