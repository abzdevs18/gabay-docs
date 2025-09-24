# Gabay Accounting Module: Backend Documentation

## 1. Overview

This document provides a comprehensive technical overview of the Gabay Accounting Module's backend implementation. It is intended for developers and AI agents to understand the system's architecture, data models, API endpoints, and overall business logic.

The accounting module is built on a robust, multi-tenant architecture using Node.js, TypeScript, and Prisma ORM. It is designed to handle core accounting functions, including chart of accounts management, journal entries, general ledger, financial statements, and integrations with other modules.

### Key Features:

- **Multi-Tenant Architecture**: Each tenant (e.g., a school or organization) has its own isolated database schema, ensuring data privacy and security.
- **Prisma ORM**: Provides a type-safe database client for interacting with the database.
- **Zod Validation**: All incoming API requests are rigorously validated using Zod schemas to ensure data integrity.
- **RESTful API**: A set of well-defined RESTful API endpoints for managing accounting data.
- **Service-Oriented Architecture**: Business logic is encapsulated in services, promoting code reusability and separation of concerns.

## 2. Architecture

The accounting module follows a standard service-oriented architecture:

- **API Routes**: Located in `api/src/pages/api/v2/accounting`, these files define the API endpoints and handle incoming requests and responses.
- **Services**: Business logic is encapsulated in services, primarily the `AccountingService` located in `api/src/services/accounting.service.ts`.
- **Prisma Schema**: The database schema is defined in `api/prisma/schema/accounting.prisma`, which includes models for accounts, journal entries, transactions, and more.
- **Utilities**: Helper functions and utilities are located in `api/src/utils`, such as `tenant-identifier.ts` for multi-tenancy and `accounting.utils.ts` for error handling.

## 3. API Endpoints

The following sections detail the available API endpoints in the accounting module.

### 3.1. Chart of Accounts

**Endpoint**: `/api/v2/accounting/chart-of-accounts`

This endpoint manages the Chart of Accounts (COA), which is a list of all financial accounts used by an organization.

#### `GET /`

- **Description**: Retrieves a list of accounts from the COA.
- **Query Parameters**:
    - `accountType` (optional, `AccountType`): Filters accounts by type (e.g., `ASSET`, `LIABILITY`).
    - `isActive` (optional, `boolean`): Filters accounts by their active status. Defaults to `true`.
- **Response**:
    - `success` (`boolean`): Indicates if the request was successful.
    - `data` (`Account[]`): An array of account objects.

#### `POST /`

- **Description**: Creates a new account in the COA.
- **Request Body**:
    - `accountCode` (`string`): The 4-digit code for the account.
    - `accountName` (`string`): The name of the account.
    - `accountType` (`AccountType`): The type of the account.
    - `parentAccountId` (optional, `string`): The ID of the parent account for hierarchical COA.
    - `description` (optional, `string`): A description of the account.
    - `isActive` (optional, `boolean`): The active status of the account. Defaults to `true`.
- **Response**:
    - `success` (`boolean`): Indicates if the request was successful.
    - `data` (`Account`): The newly created account object.

#### `GET /{id}`

- **Description**: Retrieves a single account by its ID.
- **Response**:
    - `success` (`boolean`): Indicates if the request was successful.
    - `data` (`Account`): The account object.

#### `PUT /{id}`

- **Description**: Updates an existing account.
- **Request Body**:
    - `accountName` (optional, `string`): The new name of the account.
    - `description` (optional, `string`): The new description of the account.
    - `isActive` (optional, `boolean`): The new active status of the account.
    - `parentAccountId` (optional, `string`): The new parent account ID.
- **Response**:
    - `success` (`boolean`): Indicates if the request was successful.
    - `data` (`Account`): The updated account object.

### 3.2. Financial Statements

**Endpoint**: `/api/v2/accounting/financial-statements`

This endpoint generates financial statements, such as the Balance Sheet and Income Statement.

#### `GET /`

- **Description**: Generates financial statements.
- **Query Parameters**:
    - `asOfDate` (optional, `string`): The date for which to generate the statements (e.g., `YYYY-MM-DD`). Defaults to the current date.
- **Response**:
    - `success` (`boolean`): Indicates if the request was successful.
    - `data`: An object containing the financial statements.

### 3.3. Financial Summary

**Endpoint**: `/api/v2/accounting/financial-summary`

This endpoint provides a summary of the organization's financial health.

#### `GET /`

- **Description**: Retrieves a financial summary.
- **Query Parameters**:
    - `asOfDate` (optional, `string`): The date for which to generate the summary. Defaults to the current date.
- **Response**:
    - `success` (`boolean`): Indicates if the request was successful.
    - `data`: An object containing the financial summary.

### 3.4. General Ledger

**Endpoint**: `/api/v2/accounting/general-ledger`

This endpoint provides access to the General Ledger (GL), which is a complete record of all financial transactions.

#### `GET /`

- **Description**: Retrieves the General Ledger.
- **Query Parameters**:
    - `startDate` (optional, `string`): The start date for the GL entries.
    - `endDate` (optional, `string`): The end date for the GL entries.
    - `accountId` (optional, `string`): Filters the GL by a specific account.
- **Response**:
    - `success` (`boolean`): Indicates if the request was successful.
    - `data` (`Transaction[]`): An array of transaction objects.

### 3.5. Integrations

These endpoints handle integrations with other modules, such as fee assignments and payments.

#### `POST /api/v2/accounting/integrations/fee-assignment`

- **Description**: Creates a journal entry for a fee assignment.
- **Request Body**:
    - `feeId` (`string`): The ID of the fee.
    - `studentId` (`string`): The ID of the student.
    - `amount` (`number`): The amount of the fee.
- **Response**:
    - `success` (`boolean`): Indicates if the request was successful.
    - `data` (`JournalEntry`): The newly created journal entry.

#### `POST /api/v2/accounting/integrations/payment`

- **Description**: Creates a journal entry for a payment.
- **Request Body**:
    - `paymentId` (`string`): The ID of the payment.
    - `amount` (`number`): The amount of the payment.
- **Response**:
    - `success` (`boolean`): Indicates if the request was successful.
    - `data` (`JournalEntry`): The newly created journal entry.

### 3.6. Journal Entries

**Endpoint**: `/api/v2/accounting/journal-entries`

This endpoint manages journal entries, which are records of financial transactions.

#### `GET /`

- **Description**: Retrieves a list of journal entries.
- **Query Parameters**:
    - `startDate` (optional, `string`): The start date for the journal entries.
    - `endDate` (optional, `string`): The end date for the journal entries.
    - `status` (optional, `JournalEntryStatus`): Filters journal entries by status (e.g., `DRAFT`, `POSTED`).
- **Response**:
    - `success` (`boolean`): Indicates if the request was successful.
    - `data` (`JournalEntry[]`): An array of journal entry objects.

#### `POST /`

- **Description**: Creates a new journal entry.
- **Request Body**:
    - `date` (`string`): The date of the journal entry.
    - `description` (`string`): A description of the journal entry.
    - `transactions` (`Transaction[]`): An array of transaction objects.
- **Response**:
    - `success` (`boolean`): Indicates if the request was successful.
    - `data` (`JournalEntry`): The newly created journal entry.

#### `GET /{id}`

- **Description**: Retrieves a single journal entry by its ID.
- **Response**:
    - `success` (`boolean`): Indicates if the request was successful.
    - `data` (`JournalEntry`): The journal entry object.

#### `POST /{id}/approve`

- **Description**: Approves and posts a journal entry.
- **Response**:
    - `success` (`boolean`): Indicates if the request was successful.
    - `data` (`JournalEntry`): The approved journal entry.

### 3.7. Trial Balance

**Endpoint**: `/api/v2/accounting/trial-balance`

This endpoint generates a trial balance, which is a report of all account balances.

#### `GET /`

- **Description**: Generates a trial balance.
- **Query Parameters**:
    - `asOfDate` (optional, `string`): The date for which to generate the trial balance. Defaults to the current date.
- **Response**:
    - `success` (`boolean`): Indicates if the request was successful.
    - `data`: An object containing the trial balance.

## 4. Data Models

The core data models for the accounting module are defined in the Prisma schema. Here are some of the key models:

- **`Account`**: Represents a financial account in the Chart of Accounts.
- **`JournalEntry`**: Represents a journal entry, which contains a set of transactions.
- **`Transaction`**: Represents a single transaction, which is a debit or credit to an account.
- **`GeneralLedger`**: Represents an entry in the General Ledger.

For a complete list of models and their fields, please refer to the `api/prisma/schema/accounting.prisma` file.

## 5. Error Handling

The accounting module uses a centralized error handling mechanism. The `handleAccountingError` function in `api/src/utils/accounting.utils.ts` is used to catch and format errors.

When an error occurs, the API will respond with a JSON object containing the following fields:

- `success` (`boolean`): `false`
- `error` (`string`): A description of the error.
- `details` (optional, `any`): Additional details about the error.

This consistent error handling approach makes it easier to debug and handle errors on the client-side.