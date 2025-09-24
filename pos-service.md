# Point of Sale (POS) API Documentation

## Overview
This document outlines the API endpoints for the Point of Sale (POS) system. All endpoints require authentication and proper tenant identification.

## Base URL
```
/api/v2/pos
```

## Authentication
All requests must include an authentication token in the header:
```
Authorization: Bearer <token>
```

## Common Response Format
All endpoints follow a standard response format:

Success Response:
```json
{
  "success": true,
  "message": "Operation successful",
  "data": { ... }
}
```

Error Response:
```json
{
  "error": "Error message",
  "details": "Detailed error description"
}
```

## Products API

### Create Product
Create a new product in the POS system.

**Endpoint:** `POST /products/create`

**Request Body:**
```typescript
{
  name: string;
  price: number;
  category: string;
  inventory: number;
  sku: string;
  type: "MENU" | "SHELF";
  isCommonItem?: boolean;
  minStockThreshold?: number;
  imageUrl?: string;
}
```

**Response:**
```typescript
{
  success: true,
  message: "Product created successfully",
  data: {
    id: string;
    name: string;
    price: Decimal;
    category: string;
    inventory: number;
    sku: string;
    type: string;
    isCommonItem: boolean;
    minStockThreshold: number;
    imageUrl?: string;
    metadata: Json;
    createdAt: Date;
    updatedAt: Date;
    createdBy: string;
    isDeleted: boolean;
  }
}
```

### List Products
Retrieve a list of all products.

**Endpoint:** `GET /products`

**Query Parameters:**
```typescript
{
  category?: string;
  type?: "MENU" | "SHELF";
  lowStock?: boolean;
  page?: number;  // default: 1
  limit?: number; // default: 10
}
```

**Response:**
```typescript
{
  success: true,
  data: {
    items: Array<{
      id: string;
      name: string;
      price: Decimal;
      category: string;
      inventory: number;
      sku: string;
      type: string;
      isCommonItem: boolean;
      minStockThreshold: number;
      imageUrl?: string;
      metadata: Json;
      createdAt: Date;
      updatedAt: Date;
      createdBy: string;
      isDeleted: boolean;
    }>;
    total: number;
    page: number;
    limit: number;
    totalPages: number;
  }
}
```

### Get Products by Category
Retrieve products filtered by category.

**Endpoint:** `GET /products/category/:category`

**Response:**
```typescript
{
  success: true,
  data: Array<{
    id: string;
    name: string;
    price: Decimal;
    category: string;
    inventory: number;
    sku: string;
    type: string;
    isCommonItem: boolean;
    minStockThreshold: number;
    imageUrl?: string;
    metadata: Json;
    createdAt: Date;
    updatedAt: Date;
    createdBy: string;
    isDeleted: boolean;
  }>
}
```

### Get Product Detail
Retrieve details of a specific product.

**Endpoint:** `GET /products/:id`

**Response:**
```typescript
{
  success: true,
  data: {
    id: string;
    name: string;
    price: Decimal;
    category: string;
    inventory: number;
    sku: string;
    type: string;
    isCommonItem: boolean;
    minStockThreshold: number;
    imageUrl?: string;
    metadata: Json;
    createdAt: Date;
    updatedAt: Date;
    createdBy: string;
    isDeleted: boolean;
  }
}
```

### Update Product
Update an existing product.

**Endpoint:** `PUT /products/:id`

**Request Body:**
```typescript
{
  name?: string;
  price?: number;
  category?: string;
  inventory?: number;
  sku?: string;
  type?: "MENU" | "SHELF";
  isCommonItem?: boolean;
  minStockThreshold?: number;
  imageUrl?: string;
}
```

**Response:**
```typescript
{
  success: true,
  message: "Product updated successfully",
  data: {
    // Updated product object
  }
}
```

### Delete Product
Soft delete a product (marks as deleted but keeps in database).

**Endpoint:** `DELETE /products/:id`

**Response:**
```typescript
{
  success: true,
  message: "Product deleted successfully",
  data: {
    // Product object with isDeleted: true
  }
}
```

## Transactions API

### Create Transaction
Create a new POS transaction.

**Endpoint:** `POST /transactions/create`

**Request Body:**
```typescript
{
  studentId?: string; // Required for credit payments
  products: Array<{
    productId: string;
    quantity: number;
    price: number;
  }>;
  paymentMethod: "CASH" | "CREDIT";
  total: number;
}
```

**Response:**
```typescript
{
  success: true,
  message: "Transaction created successfully",
  data: {
    id: string;
    studentId?: string;
    total: Decimal;
    paymentMethod: string;
    status: string;
    reference: string;
    createdAt: Date;
    items: Array<{
      id: string;
      productId: string;
      quantity: number;
      priceAtPurchase: Decimal;
    }>;
  }
}
```

### Get Transaction Details
Retrieve details of a specific transaction.

**Endpoint:** `GET /transactions/:id`

**Response:**
```typescript
{
  success: true,
  data: {
    id: string;
    date: Date;
    student?: {
      id: string;
      name: string;
    };
    cashier: {
      id: string;
      name: string;
    };
    items: Array<{
      id: string;
      name: string;
      quantity: number;
      price: Decimal;
      total: Decimal;
    }>;
    total: Decimal;
    paymentMethod: string;
    reference: string;
    status: string;
    voidInfo?: {
      date: Date;
      reason: string;
      voidedBy: {
        id: string;
        name: string;
      };
    };
  }
}
```

### Get Transaction Receipt
Retrieve a formatted receipt for a transaction.

**Endpoint:** `GET /transactions/:id/receipt`

**Response:**
```typescript
{
  success: true,
  data: {
    transactionId: string;
    date: Date;
    studentName?: string;
    cashierName: string;
    items: Array<{
      name: string;
      quantity: number;
      price: Decimal;
      total: Decimal;
    }>;
    total: Decimal;
    paymentMethod: string;
    reference: string;
    status: string;
  }
}
```

### Void Transaction
Void an existing transaction and restore inventory/balance.

**Endpoint:** `POST /transactions/void`

**Request Body:**
```typescript
{
  transactionId: string;
  reason: string;
}
```

**Response:**
```typescript
{
  success: true,
  message: "Transaction voided successfully",
  data: {
    id: string;
    status: "VOIDED";
    voidedAt: Date;
    voidedBy: string;
    voidReason: string;
  }
}
```

### Get Student Transactions
Retrieve transaction history for a specific student.

**Endpoint:** `GET /transactions/student/:studentId`

**Query Parameters:**
```typescript
{
  page?: number;  // default: 1
  limit?: number; // default: 10
}
```

**Response:**
```typescript
{
  success: true,
  data: {
    items: Array<{
      id: string;
      total: Decimal;
      paymentMethod: string;
      status: string;
      reference: string;
      createdAt: Date;
      items: Array<{
        product: {
          name: string;
          category: string;
        };
        quantity: number;
        priceAtPurchase: Decimal;
      }>;
    }>;
    total: number;
    page: number;
    limit: number;
    totalPages: number;
  }
}
```

### List Transactions
Retrieve a paginated list of all transactions with optional filtering.

**Endpoint:** `GET /transactions`

**Query Parameters:**
```typescript
{
  status?: "COMPLETED" | "VOIDED";
  paymentMethod?: "CASH" | "CREDIT";
  startDate?: string;  // ISO date string
  endDate?: string;    // ISO date string
  page?: number;       // default: 1
  limit?: number;      // default: 10
}
```

**Response:**
```typescript
{
  success: true,
  data: {
    items: Array<{
      id: string;
      date: Date;
      student?: {
        id: string;
        name: string;
      };
      cashier: {
        id: string;
        name: string;
      };
      items: Array<{
        name: string;
        quantity: number;
        price: Decimal;
        total: Decimal;
      }>;
      total: Decimal;
      paymentMethod: string;
      reference: string;
      status: string;
    }>;
    total: number;
    page: number;
    limit: number;
    totalPages: number;
  }
}
```

**Example Request:**
```
GET /api/v2/pos/transactions?status=COMPLETED&paymentMethod=CREDIT&startDate=2024-03-01&endDate=2024-03-31&page=1&limit=20
```

This will return completed credit transactions from March 2024, 20 items per page.

## Student Credit API

### Get Student Balance
Retrieve a student's current balance.

**Endpoint:** `GET /students/:id/balance`

**Response:**
```typescript
{
  success: true,
  data: {
    id: string;
    balance: Decimal;
  }
}
```

### Add Student Credit
Add credit to a student's balance.

**Endpoint:** `POST /students/:id/credit`

**Request Body:**
```typescript
{
  amount: number;
  reference?: string;
  notes?: string;
}
```

**Response:**
```typescript
{
  success: true,
  message: "Credit added successfully",
  data: {
    studentId: string;
    previousBalance: Decimal;
    newBalance: Decimal;
    amount: Decimal;
    reference: string;
    createdAt: Date;
  }
}
```

## Error Codes

Common error responses include:

- `400 Bad Request`: Invalid input data or missing required fields
- `401 Unauthorized`: Missing or invalid authentication token
- `403 Forbidden`: Insufficient permissions
- `404 Not Found`: Resource not found
- `405 Method Not Allowed`: HTTP method not supported
- `409 Conflict`: Business rule violation (e.g., insufficient inventory)
- `500 Internal Server Error`: Server-side error

## Business Rules

1. Inventory Management:
   - Inventory cannot be negative
   - Low stock warning when inventory ≤ minStockThreshold (default: 5)
   - Automatic inventory updates after sales
   - Stock validation before sales
   - Soft deletion of products (isDeleted flag)

2. Payment Processing:
   - Supported payment methods: CASH, CREDIT
   - Credit payments require sufficient student balance
   - Transaction voiding restores inventory and student balance
   - Each transaction has a unique reference number

3. Student Credit:
   - Balance cannot be negative for credit purchases
   - All credit transactions are recorded
   - Balance updates are atomic operations
   - Credit operations include transaction records

4. Transactions:
   - Each transaction has a unique reference
   - Transaction history is immutable
   - Price at purchase is stored for historical accuracy
   - Void operation available for error correction
   - Full audit trail with cashier and void information

## Caching

The API implements caching for improved performance:
- Product listings: Cache key format - `pos-products_{queryParams}`
- Product details: Cache key format - `pos-product_{id}`
- Student balance: Cache key format - `student-list_{id}_balance` (1-minute TTL)
- Transaction details: Cache key format - `pos-transaction_{id}`
- Transaction receipt: Cache key format - `pos-transaction_{id}_receipt`
- Student transactions: Cache key format - `pos-transactions_student_{studentId}_{page}_{limit}`

Cache is automatically invalidated when related data is modified.