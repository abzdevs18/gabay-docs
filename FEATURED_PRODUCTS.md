# Featured Products of the Day - Complete Documentation

**Version:** 1.0  
**Last Updated:** October 13, 2025  
**Author:** Development Team

---

## Table of Contents

1. [Overview](#overview)
2. [System Architecture](#system-architecture)
3. [Database Schema](#database-schema)
4. [Backend Implementation](#backend-implementation)
5. [POS Frontend Implementation](#pos-frontend-implementation)
6. [RFID Frontend Implementation](#rfid-frontend-implementation)
7. [User Guide](#user-guide)
8. [API Reference](#api-reference)
9. [Configuration](#configuration)
10. [Troubleshooting](#troubleshooting)

---

## Overview

### Purpose
The **Featured Products of the Day** feature allows canteen administrators to showcase specific products on RFID kiosk displays during standby mode. This increases product visibility and helps drive sales of featured items.

### Key Features
- ✅ Admin management interface in POS Settings
- ✅ Drag-and-drop product ordering
- ✅ Active/inactive toggle per product
- ✅ Custom promotional images
- ✅ Date range scheduling (optional)
- ✅ Full-screen carousel on RFID displays
- ✅ Automatic 30-second rotation between carousel and background
- ✅ Real-time updates via polling

### User Flow
```
POS Admin → Select Products → Set Order → RFID displays featured products in carousel
```

---

## System Architecture

### Components Overview

```
┌─────────────────────────────────────────────────────────┐
│                     DATABASE                            │
│  - POSFeaturedProduct (stores featured product data)   │
└─────────────────┬───────────────────────────────────────┘
                  │
    ┌─────────────┴──────────────┐
    │                            │
    ▼                            ▼
┌─────────────┐          ┌──────────────┐
│   BACKEND   │          │   BACKEND    │
│ Admin APIs  │          │  Public API  │
│ (Protected) │          │ (No Auth)    │
└──────┬──────┘          └──────┬───────┘
       │                        │
       ▼                        ▼
┌────────────┐          ┌──────────────┐
│ POS Admin  │          │ RFID Kiosk   │
│ Management │          │   Display    │
│     UI     │          │   Carousel   │
└────────────┘          └──────────────┘
```

### Technology Stack
- **Backend:** Next.js API Routes, Prisma ORM, PostgreSQL
- **POS Frontend:** React, TypeScript, shadcn/ui, @dnd-kit
- **RFID Frontend:** React, TypeScript, Framer Motion
- **Caching:** Redis (via CacheService)
- **Authentication:** JWT with CASL RBAC

---

## Database Schema

### POSFeaturedProduct Model

**Location:** `api/prisma/schema/pos.prisma`

```prisma
model POSFeaturedProduct {
  id             String      @id @default(uuid())
  productId      String
  product        POSProduct  @relation(fields: [productId], references: [id], onDelete: Cascade)
  displayOrder   Int         @default(0)
  featuredImage  String?     // Optional custom promotional image URL
  isActive       Boolean     @default(true)
  startDate      DateTime?   // Optional: when to start featuring
  endDate        DateTime?   // Optional: when to stop featuring
  createdBy      String
  createdByUser  User        @relation(fields: [createdBy], references: [id])
  createdAt      DateTime    @default(now())
  updatedAt      DateTime    @updatedAt

  @@map("pos_featured_products")
}
```

### Relationships
- **POSProduct:** One product can have one featured entry
- **User:** Tracks who added the featured product

### Indexes
- Primary key on `id`
- Foreign keys on `productId` and `createdBy`

---

## Backend Implementation

### File Structure
```
api/src/
├── services/
│   └── FeaturedProductService.ts       # Business logic
├── pages/api/v2/pos/featured-products/
│   ├── index.tsx                       # GET (list), POST (create)
│   ├── [id].tsx                        # GET, PUT, DELETE
│   └── reorder.tsx                     # POST (bulk reorder)
└── pages/api/v2/public/
    └── featured-products.tsx           # GET (public, no auth)
```

### FeaturedProductService

**Location:** `api/src/services/FeaturedProductService.ts`

**Key Methods:**
- `getFeaturedProducts(filters)` - Get all featured products
- `getActiveFeaturedProducts(date)` - Get active products for RFID
- `setFeaturedProduct(userId, data)` - Add product to featured list
- `updateFeaturedProduct(id, data)` - Update featured product
- `removeFeaturedProduct(id)` - Remove from featured list
- `reorderFeaturedProducts(items)` - Bulk update display order

### API Endpoints

#### Admin Endpoints (Protected)

**Base URL:** `/api/v2/pos/featured-products`

| Method | Endpoint | Description | Auth |
|--------|----------|-------------|------|
| GET | `/` | List all featured products | POS Admin/Supervisor |
| POST | `/` | Add product to featured list | POS Admin/Supervisor |
| GET | `/:id` | Get single featured product | POS Admin/Supervisor |
| PUT | `/:id` | Update featured product | POS Admin/Supervisor |
| DELETE | `/:id` | Remove from featured list | POS Admin/Supervisor |
| POST | `/reorder` | Bulk reorder products | POS Admin/Supervisor |

#### Public Endpoint (No Auth)

| Method | Endpoint | Description | Auth |
|--------|----------|-------------|------|
| GET | `/api/v2/public/featured-products?tenantTag=X` | Get active featured products | None |

### Permission Checking

Uses CASL RBAC with `buildAbilityForUser`:

```typescript
const ability = await buildAbilityForUser(user.id, prisma);
if (!ability.can('read', 'POS Admin') && !ability.can('read', 'POS Supervisor')) {
  return res.status(403).json({ error: 'Forbidden' });
}
```

### Caching Strategy

- **Admin endpoints:** 5-minute cache
- **Public endpoint:** 5-minute cache
- **Cache keys:**
  - `POS_FEATURED_PRODUCTS:{tenantId}:*`
  - `PUBLIC_FEATURED_PRODUCTS:{tenantId}:*`
- **Invalidation:** On create, update, delete, reorder

---

## POS Frontend Implementation

### File Structure
```
frontend/src/
├── services/pos/
│   └── featuredProducts.ts             # API client functions
├── components/pos/
│   └── FeaturedProductsManagement.tsx  # Management UI
└── pages/pos/
    └── index.tsx                       # Integration point
```

### Component: FeaturedProductsManagement

**Location:** `frontend/src/components/pos/FeaturedProductsManagement.tsx`

**Features:**
- Dual-panel layout (Available Products | Featured Products)
- Checkbox selection to add products
- Drag-and-drop reordering using @dnd-kit
- Active/inactive toggle switches
- Custom promotional image upload via dialog
- Real-time updates

**Props:**
```typescript
interface FeaturedProductsManagementProps {
  products: Product[];  // All available products
  onClose: () => void;  // Close callback
}
```

### Integration in POS

**Location:** `frontend/src/pages/pos/index.tsx`

Added as a new tab in Settings view:

```typescript
<Tabs defaultValue="general">
  <TabsList>
    <TabsTrigger value="general">General Settings</TabsTrigger>
    <TabsTrigger value="featured">Featured Products</TabsTrigger>
  </TabsList>
  
  <TabsContent value="featured">
    <FeaturedProductsManagement products={products} onClose={() => {}} />
  </TabsContent>
</Tabs>
```

### API Client Functions

**Location:** `frontend/src/services/pos/featuredProducts.ts`

```typescript
- getFeaturedProducts(includeInactive?: boolean)
- getFeaturedProductById(id: string)
- addFeaturedProduct(data: FeaturedProductCreateInput)
- updateFeaturedProduct(id: string, data: FeaturedProductUpdateInput)
- removeFeaturedProduct(id: string)
- reorderFeaturedProducts(items: { id: string; displayOrder: number }[])
```

---

## RFID Frontend Implementation

### File Structure
```
RFID/src/
├── components/
│   └── FeaturedProductsCarousel.tsx    # Carousel component
├── utils/
│   └── featuredProductsSync.ts         # Polling logic
└── pages/
    └── scan.tsx                        # Integration point
```

### Component: FeaturedProductsCarousel

**Location:** `RFID/src/components/FeaturedProductsCarousel.tsx`

**Features:**
- Full-screen fastfood-style carousel
- Auto-rotating every 6 seconds
- Manual navigation arrows
- Dot indicators
- Bright, vibrant colors
- Large product images
- Price badge (yellow circle)
- "Featured Today" banner
- Smooth animations (Framer Motion)

**Props:**
```typescript
interface FeaturedProductsCarouselProps {
  products: FeaturedProduct[];
  autoRotateInterval?: number; // default: 6000ms
}
```

**Performance Optimizations:**
- React.memo with custom comparison
- useMemo for computed values
- Prevents re-renders when props unchanged

### Polling Utility

**Location:** `RFID/src/utils/featuredProductsSync.ts`

**Functions:**
```typescript
- fetchFeaturedProducts(tenantTag: string): Promise<FeaturedProduct[]>
- startFeaturedProductsPolling(tenantTag, callback): NodeJS.Timeout
- stopFeaturedProductsPolling(): void
```

**Configuration:**
- Polling interval: 30 seconds
- API endpoint: `/api/v2/public/featured-products`
- No authentication required
- Returns empty array on error

### Integration in Scan Page

**Location:** `RFID/src/pages/scan.tsx`

**Behavior:**
1. **Polling starts on mount** if `tenantTag` is available
2. **Standby mode activates** after 30s of no card scans
3. **Display alternates** every 30 seconds:
   - 30s: Featured Products Carousel
   - 30s: Original Background (clock/date)
   - (repeats)
4. **Card scan immediately exits** standby mode
5. **Shows student profile** for 30 seconds
6. **Returns to standby** and resumes alternating cycle

**Key State Variables:**
```typescript
const [isStandby, setIsStandby] = useState(true);
const [featuredProducts, setFeaturedProducts] = useState<FeaturedProduct[]>([]);
const [showFeaturedCarousel, setShowFeaturedCarousel] = useState(true);
```

**Render Logic:**
```typescript
{scanSuccess ? (
  <StudentProfileCard />
) : isStandby && featuredProducts.length > 0 && showFeaturedCarousel ? (
  <FeaturedProductsCarousel products={featuredProducts} />
) : (
  <Background /> // Clock and date
)}
```

---

## User Guide

### For POS Administrators

#### How to Feature a Product

1. **Login** to POS with Admin or Supervisor account
2. Navigate to **Settings** tab
3. Click on **"Featured Products"** tab
4. **Select products:**
   - Check boxes next to products in the left panel
   - Products move to the right panel
5. **Reorder products:**
   - Drag and drop products in the right panel
   - Order determines carousel display sequence
6. **Customize (optional):**
   - Toggle **Active/Inactive** switches
   - Click **"Set Promo Image"** to add custom image URL
   - Click **"Remove"** to unfeature a product
7. **Done!** Changes take effect immediately

#### Best Practices

- **Feature 3-5 products** for optimal display
- **Use high-quality images** (at least 800x800px)
- **Update regularly** to keep content fresh
- **Test on RFID** after making changes
- **Use promotional images** for special offers

### For End Users (Students)

- **RFID displays** automatically show featured products during idle time
- **Carousel auto-advances** every 6 seconds
- **Manual navigation** available via arrows
- **Scan ID card** to exit carousel and proceed with purchase

---

## API Reference

### GET /api/v2/pos/featured-products

**Description:** List all featured products (admin view)

**Authentication:** Required (POS Admin/Supervisor)

**Query Parameters:**
- `includeInactive` (boolean, optional): Include inactive products

**Response:**
```json
{
  "success": true,
  "data": {
    "featuredProducts": [
      {
        "id": "uuid",
        "productId": "uuid",
        "displayOrder": 0,
        "isActive": true,
        "featuredImage": "https://...",
        "startDate": "2025-10-13T00:00:00Z",
        "endDate": null,
        "createdAt": "2025-10-13T10:00:00Z",
        "updatedAt": "2025-10-13T10:00:00Z",
        "product": {
          "id": "uuid",
          "name": "Product Name",
          "price": 50.00,
          "imageUrl": "https://...",
          "category": {
            "id": "uuid",
            "name": "Category Name"
          }
        }
      }
    ],
    "total": 5
  }
}
```

### POST /api/v2/pos/featured-products

**Description:** Add a product to featured list

**Authentication:** Required (POS Admin/Supervisor)

**Request Body:**
```json
{
  "productId": "uuid",
  "displayOrder": 0,
  "featuredImage": "https://...",
  "startDate": "2025-10-13",
  "endDate": "2025-10-20"
}
```

**Response:**
```json
{
  "success": true,
  "featuredProduct": { /* same structure as GET */ }
}
```

### PUT /api/v2/pos/featured-products/:id

**Description:** Update a featured product

**Authentication:** Required (POS Admin/Supervisor)

**Request Body:**
```json
{
  "displayOrder": 1,
  "isActive": false,
  "featuredImage": "https://new-image.jpg"
}
```

### DELETE /api/v2/pos/featured-products/:id

**Description:** Remove product from featured list

**Authentication:** Required (POS Admin/Supervisor)

**Response:**
```json
{
  "success": true,
  "message": "Featured product removed"
}
```

### POST /api/v2/pos/featured-products/reorder

**Description:** Bulk reorder featured products

**Authentication:** Required (POS Admin/Supervisor)

**Request Body:**
```json
{
  "items": [
    { "id": "uuid1", "displayOrder": 0 },
    { "id": "uuid2", "displayOrder": 1 },
    { "id": "uuid3", "displayOrder": 2 }
  ]
}
```

### GET /api/v2/public/featured-products

**Description:** Get active featured products for RFID display

**Authentication:** None (public endpoint)

**Query Parameters:**
- `tenantTag` (string, required): Tenant identifier

**Response:**
```json
{
  "products": [
    {
      "id": "uuid",
      "name": "Product Name",
      "description": "Product description",
      "price": 50.00,
      "image": "https://product-image.jpg",
      "promotionalImage": "https://promo-image.jpg",
      "displayOrder": 0
    }
  ],
  "lastUpdated": "2025-10-13T10:00:00Z"
}
```

---

## Configuration

### Environment Variables

#### Backend (API)
```env
# No specific env vars needed - uses existing database connection
```

#### Frontend (POS)
```env
BASE_URL=http://localhost:3000  # API base URL
```

#### RFID
```env
REACT_APP_API_URL=http://localhost:3000  # API base URL
REACT_APP_CLIENT_TAG=your-tenant-tag     # Tenant identifier
```

### Database Migration

Run migration to create the `POSFeaturedProduct` table:

```bash
cd api
npx prisma migrate dev --name add_featured_products
npx prisma generate
```

### Dependencies

#### POS Frontend
```json
{
  "@dnd-kit/core": "latest",
  "@dnd-kit/sortable": "latest",
  "@dnd-kit/utilities": "latest"
}
```

Install:
```bash
cd frontend
npm install @dnd-kit/core @dnd-kit/sortable @dnd-kit/utilities
```

#### RFID Frontend
Already has required dependencies:
- `framer-motion`
- `lucide-react`

### Permissions Setup

Ensure these permission subjects exist in your database:
- **POS Admin** - Full CRUD access
- **POS Supervisor** - Full CRUD access

Assign to user roles via the admin interface.

---

## Troubleshooting

### Issue: "Nothing happens when I click to feature a product"

**Cause:** Database migration not run or API not responding

**Solution:**
1. Check browser console for errors
2. Check Network tab for failed requests
3. Run database migration: `npx prisma migrate dev`
4. Verify backend server is running

### Issue: "Forbidden: You do not have permission"

**Cause:** User lacks required permissions

**Solution:**
1. Verify user has "POS Admin" or "POS Supervisor" role
2. Check permission subjects exist in database
3. Ensure CASL ability is properly configured

### Issue: "Featured products not showing on RFID"

**Possible Causes:**
1. No products have been featured yet
2. RFID not in standby mode (wait 30 seconds)
3. `REACT_APP_CLIENT_TAG` not set correctly
4. Backend server not accessible from RFID

**Solutions:**
1. Add products via POS Settings → Featured Products
2. Wait 30s without scanning, or refresh page
3. Check RFID `.env` file for correct tenant tag
4. Verify `REACT_APP_API_URL` points to running backend
5. Test public API directly: `http://localhost:3000/api/v2/public/featured-products?tenantTag=YOUR_TENANT`

### Issue: "Infinite re-rendering / Console spam"

**Cause:** Already fixed in current version

**Solution:**
Ensure you have the latest code with:
- React.memo on FeaturedProductsCarousel
- State comparison in polling callback

### Issue: "Images not showing in carousel"

**Cause:** Image URL incorrect or missing

**Solution:**
1. Check product has `imageUrl` in database
2. Verify promotional image URL is valid HTTPS
3. Check browser console for 404 errors
4. Ensure images are publicly accessible

---

## Performance Considerations

### Caching
- Admin endpoints cached for 5 minutes
- Public endpoint cached for 5 minutes
- Cache invalidated on any CRUD operation

### Polling
- RFID polls every 30 seconds
- Only updates state if data changed
- No offline caching (by design for simplicity)

### Optimization
- React.memo prevents unnecessary re-renders
- useMemo for computed values
- JSON comparison to avoid identical state updates

---

## Future Enhancements

Potential improvements for future versions:

1. **Offline Support:** IndexedDB caching for RFID
2. **WebSocket Updates:** Real-time push instead of polling
3. **Analytics:** Track featured product views and conversions
4. **Scheduling:** Advanced scheduling with recurring patterns
5. **A/B Testing:** Test different featured product combinations
6. **Video Support:** Allow video content in carousel
7. **Themes:** Customizable color schemes per tenant
8. **Multi-Language:** Support for multiple languages

---

## Support

For issues or questions:
1. Check this documentation
2. Review the implementation plan: `FEATURED_PRODUCTS_IMPLEMENTATION_PLAN.md`
3. Contact the development team

---

**Document Version:** 1.0  
**Last Updated:** October 13, 2025  
**Status:** Production Ready ✅
