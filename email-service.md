# Email Service Documentation

The Email Service provides a convenient way to send customized emails within the Gabay System. This document outlines how to use the email service and provides examples of common use cases.

## Usage

The email service exposes a `sendCustomEmail` function that allows you to send formatted HTML emails with various customization options.

### Function Signature

```typescript
interface EmailRecipient {
  email: string;
  name: string;
}

interface ReplyTo {
  email: string;
  name: string;
}

interface SendEmailParams {
  to: EmailRecipient[];
  subject: string;
  htmlContent: string;
  replyTo?: ReplyTo;
  tags?: string[];
}
```

### Example Usage

Here's a complete example of sending a welcome email:

```typescript
const sendWelcomeEmail = async () => {
  try {
    const result = await sendCustomEmail({
      to: [{ email: 'user@example.com', name: 'John Doe' }],
      subject: 'Welcome to Gabay System',
      htmlContent: `
        <html>
          <head>
            <style>
              body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
              .container { max-width: 600px; margin: 0 auto; padding: 20px; }
              .header { background: #f8f9fa; padding: 20px; text-align: center; }
              .content { padding: 20px; }
              .footer { text-align: center; padding: 20px; font-size: 12px; color: #666; }
            </style>
          </head>
          <body>
            <div class="container">
              <div class="header">
                <h1>Welcome to Gabay!</h1>
              </div>
              <div class="content">
                <p>Hello John,</p>
                <p>Thank you for joining Gabay System. We're excited to have you on board!</p>
                <p>If you have any questions, feel free to reply to this email.</p>
                <p>Best regards,<br/>The Gabay Team</p>
              </div>
              <div class="footer">
                <p>© 2024 Gabay System. All rights reserved.</p>
              </div>
            </div>
          </body>
        </html>
      `,
      replyTo: {
        email: 'support@example.com',
        name: 'Gabay Support'
      },
      tags: ['welcome_email', 'new_user']
    });

    if (result.success) {
      console.log('Email sent with message ID:', result.messageId);
    }
  } catch (error) {
    console.error('Failed to send email:', error);
  }
}
```

### Parameters

- `to`: Array of recipients, each with email and name
- `subject`: Email subject line
- `htmlContent`: HTML content of the email
- `replyTo` (optional): Email address and name for replies
- `tags` (optional): Array of strings for email categorization

### Response

The function returns a Promise that resolves to:

```typescript
{
  success: boolean;
  messageId?: string;
  error?: string;
}
```

### Error Handling

The service includes built-in error handling. It's recommended to wrap the email sending function in a try-catch block to handle potential errors gracefully:

```typescript
try {
  const result = await sendCustomEmail({ ... });
  if (result.success) {
    // Handle success
  }
} catch (error) {
  // Handle error
}
```

## Best Practices

1. **HTML Templates**: Use proper HTML structure with inline CSS for email compatibility
2. **Error Handling**: Always implement error handling for robustness
3. **Tags**: Use tags to categorize emails for better tracking and analytics
4. **Reply-To**: Set appropriate reply-to addresses for user responses
5. **Testing**: Test email sending in a development environment first
