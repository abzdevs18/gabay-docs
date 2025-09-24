# Cashiering API Endpoints

## Session Management

### `GET /api/v2/finance/cashier`
- **Description**: Get active cashier session for the authenticated user
- **Authentication**: Required
- **Response**: Active session details or empty if no active session

### `POST /api/v2/finance/cashier`
- **Description**: Open a new cashier session
- **Authentication**: Required
- **Request Body**:
  ```typescript
  {
    cashierId: string;
    startBalance: number;
    denominations?: {
      ones?: number;
      fives?: number;
      tens?: number;
      twenties?: number;
      fifties?: number;
      hundreds?: number;
      twoHundreds?: number;
      fiveHundreds?: number;
      oneThousands?: number;
    };
  }
  ```
- **Response**: Newly created session details

### `GET /api/v2/finance/cashier/sessions/:id`
- **Description**: Get details for a specific cashier session
- **Authentication**: Required
- **URL Parameters**: `id` - Session ID
- **Response**: Session details or 404 if not found

### `PUT /api/v2/finance/cashier/sessions/:id`
- **Description**: Close a cashier session
- **Authentication**: Required
- **URL Parameters**: `id` - Session ID
- **Request Body**:
  ```typescript
  {
    endBalance: number;
    denominations?: {
      ones?: number;
      fives?: number;
      tens?: number;
      twenties?: number;
      fifties?: number;
      hundreds?: number;
      twoHundreds?: number;
      fiveHundreds?: number;
      oneThousands?: number;
    };
  }
  ```
- **Response**: Updated session details

### `GET /api/v2/finance/cashier/sessions/:id/summary`
- **Description**: Get a detailed summary for a specific cashier session
- **Authentication**: Required
- **URL Parameters**: `id` - Session ID
- **Response**: Session summary with transaction details and balance information

## Transaction Management

### `GET /api/v2/finance/cashier/transactions`
- **Description**: Get list of transactions for a specific date and cashier
- **Authentication**: Required
- **Query Parameters**:
  - `date`: Date in YYYY-MM-DD format
  - `cashierId`: (Optional) Filter by cashier ID
- **Response**: List of formatted transactions with student information
  ```typescript
  {
    transactions: Array<{
      id: string;
      amount: number;
      createdAt: string;
      paymentMethod: string;
      referenceNumber?: string;
      student: {
        id: string;
        name: string; // Formatted name with fallback to "Student {id}" if name fields unavailable
      };
      cashierId: string;
      sessionId: string;
      status: string;
      // Additional fields...
    }>;
  }
  ```

### `POST /api/v2/finance/cashier/transactions`
- **Description**: Process a new cash payment/transaction
- **Authentication**: Required
- **Request Body**:
  ```typescript
  {
    sessionId: string;
    studentId: string;
    amount: number;
    paymentMethod: string;
    referenceNumber?: string;
    feeId?: string;
    paidBy?: string;
  }
  ```
- **Response**: Created transaction details

### `PUT /api/v2/finance/cashier/transactions/:id/void`
- **Description**: Void/cancel a transaction
- **Authentication**: Required
- **URL Parameters**: `id` - Transaction ID
- **Request Body**:
  ```typescript
  {
    reason: string;
  }
  ```
- **Response**: Updated transaction with void status

## Cash Adjustments

### `POST /api/v2/finance/cashier/adjustments`
- **Description**: Create a cash adjustment (add or remove cash from drawer)
- **Authentication**: Required
- **Request Body**:
  ```typescript
  {
    sessionId: string;
    amount: number;
    adjustmentType: "ADD" | "REMOVE";
    reason: string;
  }
  ```
- **Response**: Created adjustment details

## Cashier Management

### `GET /api/v2/finance/cashier/cashiers`
- **Description**: Get list of all cashiers
- **Authentication**: Required (admin)
- **Response**: List of cashier accounts

### `POST /api/v2/finance/cashier/cashiers`
- **Description**: Create a new cashier account
- **Authentication**: Required (admin)
- **Request Body**:
  ```typescript
  {
    userId: string;
    name: string;
    email: string;
  }
  ```
- **Response**: Created cashier details

## Reports

### `GET /api/v2/finance/cashier/reports/daily`
- **Description**: Generate a daily report for transactions
- **Authentication**: Required
- **Query Parameters**:
  - `date`: Date in YYYY-MM-DD format
  - `cashierId`: (Optional) Filter by cashier ID
- **Response**: Daily report with transaction summaries and totals

### `GET /api/v2/finance/cashier/reports/session/:id`
- **Description**: Generate a report for a specific session
- **Authentication**: Required
- **URL Parameters**: `id` - Session ID
- **Response**: Session report with detailed transaction and balance information

## Data Handling Notes

### Student Information
- The transaction endpoints handle student information with a fallback mechanism:
  - Student data is extracted from the first fee payment in the transaction
  - The system attempts to format student names based on available fields
  - If name fields aren't available, a fallback format of "Student {id}" is used
  - This ensures robust display even when student model fields differ

### Transaction Status
- Transactions can have the following statuses:
  - `COMPLETED`: Successfully processed transaction
  - `VOIDED`: Transaction that has been canceled
  - `PENDING`: Transaction in process (rare)
  
### Error Handling
- All endpoints include proper error handling:
  - 400: Bad Request (invalid input)
  - 401: Unauthorized (missing or invalid auth)
  - 403: Forbidden (insufficient permissions)
  - 404: Resource Not Found
  - 405: Method Not Allowed
  - 500: Server Error (with detailed logging) 