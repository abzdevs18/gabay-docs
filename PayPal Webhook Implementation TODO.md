# PayPal Webhook Implementation TODO

## Current Implementation Context

### Existing Files and Flow
1. **Frontend Components**:
   - `frontend/src/components/payment/PaymentDialog.tsx`
     - Main payment UI component
     - Handles payment method selection
     - Manages payment states and error handling
   - `frontend/src/components/payment/PayPalButton.tsx`
     - PayPal button integration
     - Handles order creation and capture
     - Manages immediate payment confirmation

2. **Backend Endpoints**:
   - `api/src/pages/api/payments/paypal/create-order.ts`
     - Creates PayPal order
     - Sets up payment intent
   - `api/src/pages/api/payments/paypal/capture-payment.ts`
     - Captures payment after approval
     - Updates payment records
     - Updates student fee status

3. **Service Layer**:
   - `api/src/services/payment.service.ts`
     - Handles payment processing
     - Updates student records
     - Manages transactions

4. **Current Payment Flow**:
   ```mermaid
   sequenceDiagram
      User->>PaymentDialog: Enters payment amount
      PaymentDialog->>PayPalButton: Initiates payment
      PayPalButton->>Backend: Creates order
      Backend->>PayPal: Creates PayPal order
      PayPal->>User: Shows payment UI
      User->>PayPal: Approves payment
      PayPal->>PayPalButton: Returns orderID
      PayPalButton->>Backend: Captures payment
      Backend->>PayPal: Captures payment
      Backend->>Database: Updates records
      Backend->>PayPalButton: Confirms success
      PayPalButton->>PaymentDialog: Updates UI
   ```

### Where Webhooks Fit In
1. **Current Limitations**:
   - No handling of post-payment events
   - No automatic dispute management
   - No refund tracking
   - Limited payment status updates

2. **Integration Points**:
   - New webhook endpoint will complement existing capture endpoint
   - Will handle events that occur after initial payment
   - Will provide backup for failed immediate confirmations
   - Will enable automated dispute and refund handling

3. **Database Integration**:
   - Current payment model will be extended
   - Will add webhook event tracking
   - Will add dispute and refund status tracking

4. **Updated Flow with Webhooks**:
   ```mermaid
   sequenceDiagram
      participant User
      participant Frontend
      participant Backend
      participant PayPal
      participant Webhook
      participant Database

      User->>Frontend: Initiates payment
      Frontend->>Backend: Creates order
      Backend->>PayPal: Creates PayPal order
      PayPal->>User: Shows payment UI
      User->>PayPal: Approves payment
      PayPal->>Frontend: Returns orderID
      Frontend->>Backend: Captures payment
      Backend->>PayPal: Captures payment
      Backend->>Database: Updates records
      Backend->>Frontend: Confirms success
      
      Note over PayPal,Webhook: Post-Payment Events
      PayPal->>Webhook: PAYMENT.CAPTURE.COMPLETED
      Webhook->>Database: Verify/Update payment
      PayPal->>Webhook: PAYMENT.CAPTURE.REFUNDED
      Webhook->>Database: Process refund
      PayPal->>Webhook: CUSTOMER.DISPUTE.CREATED
      Webhook->>Database: Handle dispute
   ```

## Overview
While the current PayPal integration provides immediate payment confirmation, implementing webhooks will make the system more robust and handle post-payment scenarios.

## Steps to Implement

### 1. PayPal Webhook Setup
- [ ] Log in to PayPal Developer Dashboard
- [ ] Navigate to Webhooks section
- [ ] Add webhook URL: `https://your-domain.com/api/payments/paypal/webhook`
- [ ] Select events to listen for:
  - `PAYMENT.CAPTURE.COMPLETED`
  - `PAYMENT.CAPTURE.DENIED`
  - `PAYMENT.CAPTURE.REFUNDED`
  - `CUSTOMER.DISPUTE.CREATED`
  - `CUSTOMER.DISPUTE.RESOLVED`
- [ ] Save webhook configuration and note the Webhook ID
- [ ] Store Webhook ID and signing secret in environment variables:
  ```env
  PAYPAL_WEBHOOK_ID=your_webhook_id
  PAYPAL_WEBHOOK_SECRET=your_webhook_secret
  ```

### 2. Create Webhook Endpoint
- [ ] Create new file: `api/src/pages/api/payments/paypal/webhook.ts`
- [ ] Implement webhook signature verification
- [ ] Handle different event types:
  ```typescript
  switch (event.event_type) {
    case 'PAYMENT.CAPTURE.COMPLETED':
      // Verify payment status
      // Update payment record if needed
      break;
    case 'PAYMENT.CAPTURE.DENIED':
      // Mark payment as failed
      // Notify admin
      break;
    case 'PAYMENT.CAPTURE.REFUNDED':
      // Process refund
      // Update payment status
      // Update student fee status
      break;
    case 'CUSTOMER.DISPUTE.CREATED':
      // Mark payment as disputed
      // Notify admin
      // Update student fee status
      break;
    case 'CUSTOMER.DISPUTE.RESOLVED':
      // Update dispute status
      // Take appropriate action based on resolution
      break;
  }
  ```

### 3. Database Updates
- [ ] Add new fields to Payment model:
  ```prisma
  model Payment {
    // ... existing fields ...
    disputeStatus String?
    refundStatus String?
    refundAmount Decimal?
    webhookEvents Json[]    // Store all webhook events
    lastWebhookAt DateTime?
  }
  ```

### 4. Error Handling
- [ ] Implement retry mechanism for failed webhook processing
- [ ] Create error logging for webhook failures
- [ ] Set up monitoring for webhook processing
- [ ] Create admin notification system for critical webhook events

### 5. Testing
- [ ] Test webhook endpoint with PayPal's simulator
- [ ] Test each event type:
  - Successful payment
  - Failed payment
  - Refund
  - Dispute creation
  - Dispute resolution
- [ ] Test error scenarios:
  - Invalid signature
  - Duplicate events
  - Server errors

### 6. Documentation
- [ ] Document webhook implementation
- [ ] Create troubleshooting guide
- [ ] Document admin procedures for handling:
  - Refunds
  - Disputes
  - Failed payments

### 7. Monitoring
- [ ] Set up logging for webhook events
- [ ] Create dashboard for webhook event monitoring
- [ ] Set up alerts for:
  - Failed webhook deliveries
  - Disputes
  - High-value refunds

## Security Considerations
1. Always verify webhook signatures
2. Store webhook secrets securely
3. Implement rate limiting
4. Log all webhook requests
5. Use HTTPS only
6. Implement request timeout

## Best Practices
1. Process webhooks idempotently
2. Acknowledge webhook receipt quickly
3. Process webhook events asynchronously
4. Keep webhook processing time minimal
5. Implement proper error handling
6. Store raw webhook data for debugging

## Additional Features
- [ ] Implement webhook retry mechanism
- [ ] Create webhook event viewer in admin panel
- [ ] Add webhook health monitoring
- [ ] Create automated reports for webhook events
- [ ] Implement notification system for critical events

## Resources
- [PayPal Webhook Documentation](https://developer.paypal.com/api/rest/webhooks/)
- [PayPal Webhook Event Types](https://developer.paypal.com/api/rest/webhooks/event-types/)
- [PayPal Webhook Signature Verification](https://developer.paypal.com/api/rest/webhooks/payload-verification/) 