-- SQL SCRIPT TO CREATE INDEXES
-- IMPORTANT: Execute these commands within the context of EACH tenant schema.
-- You can do this by:
-- 1. Setting the search_path: SET search_path TO your_tenant_schema;
-- 2. Or, qualifying table names: CREATE INDEX idx_user_email ON your_tenant_schema."User" (email);
-- This script uses unqualified table names, assuming search_path is set.
-- For tenant_alpha
SET search_path TO aans;

-- From user.prisma
CREATE UNIQUE INDEX IF NOT EXISTS idx_user_email ON "User" (email);
CREATE UNIQUE INDEX IF NOT EXISTS idx_user_username ON "User" (username);
CREATE INDEX IF NOT EXISTS idx_user_roleId ON "User" ("roleId");
CREATE INDEX IF NOT EXISTS idx_user_status ON "User" (status);
CREATE INDEX IF NOT EXISTS idx_user_clientId ON "User" ("clientId");

CREATE UNIQUE INDEX IF NOT EXISTS idx_role_name ON "Role" ("name");

CREATE UNIQUE INDEX IF NOT EXISTS idx_permission_name ON "Permission" ("name");

CREATE UNIQUE INDEX IF NOT EXISTS idx_unique_rolepermission_role_perm_client ON "RolePermission" ("roleId", "permissionId", "clientId");
CREATE INDEX IF NOT EXISTS idx_rolepermission_roleId ON "RolePermission" ("roleId");
CREATE INDEX IF NOT EXISTS idx_rolepermission_permissionId ON "RolePermission" ("permissionId");
CREATE INDEX IF NOT EXISTS idx_rolepermission_clientId ON "RolePermission" ("clientId"); -- Added based on common practice for FKs in unique constraint

CREATE UNIQUE INDEX IF NOT EXISTS idx_unique_userpermission_user_perm_client ON "UserPermission" ("userId", "permissionId", "clientId");
CREATE INDEX IF NOT EXISTS idx_userpermission_userId ON "UserPermission" ("userId");
CREATE INDEX IF NOT EXISTS idx_userpermission_permissionId ON "UserPermission" ("permissionId");
CREATE INDEX IF NOT EXISTS idx_userpermission_clientId ON "UserPermission" ("clientId"); -- Added based on common practice for FKs in unique constraint

CREATE UNIQUE INDEX IF NOT EXISTS idx_client_name ON "Client" ("name");
CREATE UNIQUE INDEX IF NOT EXISTS idx_client_clientApiKey ON "Client" ("clientApiKey");

CREATE UNIQUE INDEX IF NOT EXISTS idx_unique_address_user_type ON "Address" ("userId", "type");
CREATE INDEX IF NOT EXISTS idx_address_userId ON "Address" ("userId");
CREATE INDEX IF NOT EXISTS idx_address_type ON "Address" ("type");

CREATE UNIQUE INDEX IF NOT EXISTS idx_profile_userId ON "Profile" ("userId");

CREATE UNIQUE INDEX IF NOT EXISTS idx_unique_userrelation_relating_related_type ON "UserRelation" ("relatingUserId", "relatedUserId", "type");
CREATE INDEX IF NOT EXISTS idx_userrelation_relatingUserId ON "UserRelation" ("relatingUserId");
CREATE INDEX IF NOT EXISTS idx_userrelation_relatedUserId ON "UserRelation" ("relatedUserId");

CREATE INDEX IF NOT EXISTS idx_notification_userId ON "Notification" ("userId");
CREATE INDEX IF NOT EXISTS idx_notification_type ON "Notification" ("type");
CREATE INDEX IF NOT EXISTS idx_notification_read ON "Notification" ("read");

CREATE UNIQUE INDEX IF NOT EXISTS idx_unique_usersecurityanswer_user_question ON "UserSecurityAnswer" ("userId", "questionId");
CREATE INDEX IF NOT EXISTS idx_usersecurityanswer_userId ON "UserSecurityAnswer" ("userId");
CREATE INDEX IF NOT EXISTS idx_usersecurityanswer_questionId ON "UserSecurityAnswer" ("questionId");

CREATE INDEX IF NOT EXISTS idx_loginattempt_userId ON "LoginAttempt" ("userId");
CREATE INDEX IF NOT EXISTS idx_loginattempt_ipAddress ON "LoginAttempt" ("ipAddress");

CREATE UNIQUE INDEX IF NOT EXISTS idx_passwordresettoken_token ON "PasswordResetToken" (token);
CREATE INDEX IF NOT EXISTS idx_passwordresettoken_userId ON "PasswordResetToken" ("userId");

CREATE UNIQUE INDEX IF NOT EXISTS idx_emailverificationtoken_token ON "EmailVerificationToken" (token);
CREATE INDEX IF NOT EXISTS idx_emailverificationtoken_userId ON "EmailVerificationToken" ("userId");

CREATE INDEX IF NOT EXISTS idx_auditlog_userId ON "AuditLog" ("userId");
CREATE INDEX IF NOT EXISTS idx_auditlog_targetEntity ON "AuditLog" ("targetEntity");
CREATE INDEX IF NOT EXISTS idx_auditlog_targetId ON "AuditLog" ("targetId");
CREATE INDEX IF NOT EXISTS idx_auditlog_actionType ON "AuditLog" ("actionType");

CREATE UNIQUE INDEX IF NOT EXISTS idx_featureflag_name ON "FeatureFlag" ("name");

CREATE UNIQUE INDEX IF NOT EXISTS idx_unique_userfeatureflag_user_flag ON "UserFeatureFlag" ("userId", "featureFlagId");
CREATE INDEX IF NOT EXISTS idx_userfeatureflag_userId ON "UserFeatureFlag" ("userId");
CREATE INDEX IF NOT EXISTS idx_userfeatureflag_featureFlagId ON "UserFeatureFlag" ("featureFlagId");

-- From pos.prisma
CREATE UNIQUE INDEX IF NOT EXISTS idx_productcategory_name ON "ProductCategory" ("name");
CREATE INDEX IF NOT EXISTS idx_productcategory_parentId ON "ProductCategory" ("parentId");

-- Note: Assuming "Product" table from pos.prisma. If schema.prisma's "Product" is different, adjust accordingly.
-- Using definition from pos.prisma as it was more detailed.
CREATE INDEX IF NOT EXISTS idx_product_name ON "Product" ("name");
CREATE UNIQUE INDEX IF NOT EXISTS idx_product_sku ON "Product" (sku);
CREATE INDEX IF NOT EXISTS idx_product_categoryId ON "Product" ("categoryId");
CREATE INDEX IF NOT EXISTS idx_product_supplierId ON "Product" ("supplierId");
CREATE INDEX IF NOT EXISTS idx_product_barcode ON "Product" (barcode);
-- If the Product model in schema.prisma (with ownerId) is the one to use / is distinct:
-- CREATE INDEX IF NOT EXISTS idx_schema_product_name ON "Product" (name); -- (use a different table name or consolidate models)
-- CREATE INDEX IF NOT EXISTS idx_schema_product_ownerId ON "Product" ("ownerId");

CREATE INDEX IF NOT EXISTS idx_supplier_name ON "Supplier" ("name");
CREATE UNIQUE INDEX IF NOT EXISTS idx_supplier_contactEmail ON "Supplier" ("contactEmail");

CREATE UNIQUE INDEX IF NOT EXISTS idx_inventory_productId ON "Inventory" ("productId");
CREATE INDEX IF NOT EXISTS idx_inventory_locationId ON "Inventory" ("locationId");

CREATE INDEX IF NOT EXISTS idx_salestransaction_customerId ON "SalesTransaction" ("customerId");
CREATE INDEX IF NOT EXISTS idx_salestransaction_employeeId ON "SalesTransaction" ("employeeId");
CREATE INDEX IF NOT EXISTS idx_salestransaction_transactionDate ON "SalesTransaction" ("transactionDate");
CREATE INDEX IF NOT EXISTS idx_salestransaction_paymentMethod ON "SalesTransaction" ("paymentMethod");
CREATE INDEX IF NOT EXISTS idx_salestransaction_status ON "SalesTransaction" (status);

CREATE INDEX IF NOT EXISTS idx_salestransactionitem_transactionId ON "SalesTransactionItem" ("transactionId");
CREATE INDEX IF NOT EXISTS idx_salestransactionitem_productId ON "SalesTransactionItem" ("productId");

CREATE UNIQUE INDEX IF NOT EXISTS idx_customer_email ON "Customer" (email);
CREATE UNIQUE INDEX IF NOT EXISTS idx_customer_phone ON "Customer" (phone);

CREATE UNIQUE INDEX IF NOT EXISTS idx_employee_userId ON "Employee" ("userId");
CREATE INDEX IF NOT EXISTS idx_employee_storeId ON "Employee" ("storeId");
CREATE INDEX IF NOT EXISTS idx_employee_role ON "Employee" ("role");

CREATE UNIQUE INDEX IF NOT EXISTS idx_store_name ON "Store" ("name");
CREATE INDEX IF NOT EXISTS idx_store_locationId ON "Store" ("locationId");

CREATE UNIQUE INDEX IF NOT EXISTS idx_location_name ON "Location" ("name");

CREATE UNIQUE INDEX IF NOT EXISTS idx_discount_code ON "Discount" (code);
CREATE INDEX IF NOT EXISTS idx_discount_type ON "Discount" ("type");

CREATE UNIQUE INDEX IF NOT EXISTS idx_taxrate_name ON "TaxRate" ("name");
CREATE INDEX IF NOT EXISTS idx_taxrate_region ON "TaxRate" (region);

CREATE UNIQUE INDEX IF NOT EXISTS idx_paymenttype_name ON "PaymentType" ("name");

CREATE INDEX IF NOT EXISTS idx_shift_employeeId ON "Shift" ("employeeId");
CREATE INDEX IF NOT EXISTS idx_shift_storeId ON "Shift" ("storeId");
CREATE INDEX IF NOT EXISTS idx_shift_startTime ON "Shift" ("startTime");
CREATE INDEX IF NOT EXISTS idx_shift_endTime ON "Shift" ("endTime");

CREATE INDEX IF NOT EXISTS idx_cashregister_storeId ON "CashRegister" ("storeId");
CREATE INDEX IF NOT EXISTS idx_cashregister_name ON "CashRegister" ("name");

CREATE INDEX IF NOT EXISTS idx_registerlog_registerId ON "RegisterLog" ("registerId");
CREATE INDEX IF NOT EXISTS idx_registerlog_employeeId ON "RegisterLog" ("employeeId");
CREATE INDEX IF NOT EXISTS idx_registerlog_type ON "RegisterLog" ("type");

-- From payment.prisma
CREATE INDEX IF NOT EXISTS idx_paymentmethod_userId ON "PaymentMethod" ("userId");
CREATE INDEX IF NOT EXISTS idx_paymentmethod_type ON "PaymentMethod" ("type");
CREATE INDEX IF NOT EXISTS idx_paymentmethod_isDefault ON "PaymentMethod" ("isDefault");

CREATE INDEX IF NOT EXISTS idx_paymenttransaction_orderId ON "PaymentTransaction" ("orderId");
CREATE INDEX IF NOT EXISTS idx_paymenttransaction_userId ON "PaymentTransaction" ("userId");
CREATE INDEX IF NOT EXISTS idx_paymenttransaction_paymentMethodId ON "PaymentTransaction" ("paymentMethodId");
CREATE INDEX IF NOT EXISTS idx_paymenttransaction_status ON "PaymentTransaction" (status);
CREATE UNIQUE INDEX IF NOT EXISTS idx_paymenttransaction_gatewayTransactionId ON "PaymentTransaction" ("gatewayTransactionId");

CREATE INDEX IF NOT EXISTS idx_subscription_userId ON "Subscription" ("userId");
CREATE INDEX IF NOT EXISTS idx_subscription_planId ON "Subscription" ("planId");
CREATE INDEX IF NOT EXISTS idx_subscription_status ON "Subscription" (status);
CREATE UNIQUE INDEX IF NOT EXISTS idx_subscription_stripeSubscriptionId ON "Subscription" ("stripeSubscriptionId");

CREATE UNIQUE INDEX IF NOT EXISTS idx_subscriptionplan_name ON "SubscriptionPlan" ("name");
CREATE INDEX IF NOT EXISTS idx_subscriptionplan_price ON "SubscriptionPlan" (price);

CREATE INDEX IF NOT EXISTS idx_invoice_userId ON "Invoice" ("userId");
CREATE INDEX IF NOT EXISTS idx_invoice_subscriptionId ON "Invoice" ("subscriptionId");
CREATE INDEX IF NOT EXISTS idx_invoice_status ON "Invoice" (status);
CREATE UNIQUE INDEX IF NOT EXISTS idx_invoice_stripeInvoiceId ON "Invoice" ("stripeInvoiceId");

CREATE INDEX IF NOT EXISTS idx_invoiceitem_invoiceId ON "InvoiceItem" ("invoiceId");
CREATE INDEX IF NOT EXISTS idx_invoiceitem_productId ON "InvoiceItem" ("productId");

CREATE UNIQUE INDEX IF NOT EXISTS idx_refund_paymentTransactionId ON "Refund" ("paymentTransactionId");
CREATE INDEX IF NOT EXISTS idx_refund_status ON "Refund" (status);

CREATE INDEX IF NOT EXISTS idx_billingaddress_userId ON "BillingAddress" ("userId");
-- CREATE UNIQUE INDEX IF NOT EXISTS idx_billingaddress_userId_isDefault ON "BillingAddress" ("userId", "isDefault"); -- If combination should be unique

CREATE UNIQUE INDEX IF NOT EXISTS idx_wallet_userId ON "Wallet" ("userId");

CREATE INDEX IF NOT EXISTS idx_wallettransaction_walletId ON "WalletTransaction" ("walletId");
CREATE INDEX IF NOT EXISTS idx_wallettransaction_type ON "WalletTransaction" ("type");
CREATE INDEX IF NOT EXISTS idx_wallettransaction_relatedTransactionId ON "WalletTransaction" ("relatedTransactionId");

CREATE INDEX IF NOT EXISTS idx_payout_userId ON "Payout" ("userId");
CREATE INDEX IF NOT EXISTS idx_payout_status ON "Payout" (status);
CREATE INDEX IF NOT EXISTS idx_payout_payoutMethodId ON "Payout" ("payoutMethodId");

CREATE INDEX IF NOT EXISTS idx_payoutmethod_userId ON "PayoutMethod" ("userId");
CREATE INDEX IF NOT EXISTS idx_payoutmethod_type ON "PayoutMethod" ("type");

CREATE UNIQUE INDEX IF NOT EXISTS idx_ledgeraccount_name ON "LedgerAccount" ("name");
CREATE INDEX IF NOT EXISTS idx_ledgeraccount_type ON "LedgerAccount" ("type");

CREATE INDEX IF NOT EXISTS idx_journalentry_referenceId ON "JournalEntry" ("referenceId");
CREATE INDEX IF NOT EXISTS idx_journalentry_status ON "JournalEntry" (status);

CREATE INDEX IF NOT EXISTS idx_ledgerentry_journalEntryId ON "LedgerEntry" ("journalEntryId");
CREATE INDEX IF NOT EXISTS idx_ledgerentry_accountId ON "LedgerEntry" ("accountId");
CREATE INDEX IF NOT EXISTS idx_ledgerentry_type ON "LedgerEntry" ("type");

CREATE UNIQUE INDEX IF NOT EXISTS idx_fee_name ON "Fee" ("name");
CREATE INDEX IF NOT EXISTS idx_fee_type ON "Fee" ("type");

CREATE UNIQUE INDEX IF NOT EXISTS idx_tax_name ON "Tax" ("name");
CREATE INDEX IF NOT EXISTS idx_tax_rate ON "Tax" (rate);

CREATE UNIQUE INDEX IF NOT EXISTS idx_currency_code ON "Currency" (code);

CREATE UNIQUE INDEX IF NOT EXISTS idx_exchangerate_from_to_date ON "ExchangeRate" ("fromCurrencyId", "toCurrencyId", "date");
CREATE INDEX IF NOT EXISTS idx_exchangerate_fromCurrencyId ON "ExchangeRate" ("fromCurrencyId");
CREATE INDEX IF NOT EXISTS idx_exchangerate_toCurrencyId ON "ExchangeRate" ("toCurrencyId");


CREATE UNIQUE INDEX IF NOT EXISTS idx_gatewaycustomer_user_gateway ON "GatewayCustomer" ("userId", gateway);
CREATE INDEX IF NOT EXISTS idx_gatewaycustomer_userId ON "GatewayCustomer" ("userId");


CREATE UNIQUE INDEX IF NOT EXISTS idx_gatewaypaymentmethod_customer_method ON "GatewayPaymentMethod" ("gatewayCustomerId", "gatewayPaymentMethodId");
CREATE INDEX IF NOT EXISTS idx_gatewaypaymentmethod_gatewayCustomerId ON "GatewayPaymentMethod" ("gatewayCustomerId");

-- From schema.prisma (main large schema)
CREATE UNIQUE INDEX IF NOT EXISTS idx_configuration_key ON "Configuration" ("key");
CREATE INDEX IF NOT EXISTS idx_configuration_clientId ON "Configuration" ("clientId");

CREATE UNIQUE INDEX IF NOT EXISTS idx_configitem_config_itemkey ON "ConfigurationItem" ("configurationId", "itemKey");
CREATE INDEX IF NOT EXISTS idx_configitem_configurationId ON "ConfigurationItem" ("configurationId");

CREATE UNIQUE INDEX IF NOT EXISTS idx_assessmentconfig_name ON "AssessmentConfig" ("assessmentName");
CREATE INDEX IF NOT EXISTS idx_assessmentconfig_gradingSystemId ON "AssessmentConfig" ("gradingSystemId");
CREATE INDEX IF NOT EXISTS idx_assessmentconfig_academicYearId ON "AssessmentConfig" ("academicYearId");

CREATE UNIQUE INDEX IF NOT EXISTS idx_asstypeweight_config_type ON "AssessmentTypeWeight" ("assessmentConfigId", "assessmentType");
CREATE INDEX IF NOT EXISTS idx_asstypeweight_assessmentConfigId ON "AssessmentTypeWeight" ("assessmentConfigId");

CREATE UNIQUE INDEX IF NOT EXISTS idx_score_student_assessment_comp_crit ON "Score" ("studentId", "assessmentId", "componentId", "criteriaId");
CREATE INDEX IF NOT EXISTS idx_score_studentId ON "Score" ("studentId");
CREATE INDEX IF NOT EXISTS idx_score_assessmentId ON "Score" ("assessmentId");
CREATE INDEX IF NOT EXISTS idx_score_componentId ON "Score" ("componentId");
CREATE INDEX IF NOT EXISTS idx_score_criteriaId ON "Score" ("criteriaId");


CREATE INDEX IF NOT EXISTS idx_writtenworkitem_sectionId ON "WrittenWorkItem" ("sectionId");
CREATE INDEX IF NOT EXISTS idx_writtenworkitem_subjectId ON "WrittenWorkItem" ("subjectId");
CREATE INDEX IF NOT EXISTS idx_writtenworkitem_gradingPeriod ON "WrittenWorkItem" ("gradingPeriod");
CREATE INDEX IF NOT EXISTS idx_writtenworkitem_itemNumber ON "WrittenWorkItem" ("itemNumber");

CREATE INDEX IF NOT EXISTS idx_performancetaskitem_sectionId ON "PerformanceTaskItem" ("sectionId");
CREATE INDEX IF NOT EXISTS idx_performancetaskitem_subjectId ON "PerformanceTaskItem" ("subjectId");
CREATE INDEX IF NOT EXISTS idx_performancetaskitem_gradingPeriod ON "PerformanceTaskItem" ("gradingPeriod");
CREATE INDEX IF NOT EXISTS idx_performancetaskitem_itemNumber ON "PerformanceTaskItem" ("itemNumber");

CREATE UNIQUE INDEX IF NOT EXISTS idx_studentscore_student_item_type ON "StudentScore" ("studentId", "itemId", "itemType");
CREATE INDEX IF NOT EXISTS idx_studentscore_studentId ON "StudentScore" ("studentId");
CREATE INDEX IF NOT EXISTS idx_studentscore_itemId ON "StudentScore" ("itemId");
CREATE INDEX IF NOT EXISTS idx_studentscore_itemType ON "StudentScore" ("itemType");

CREATE UNIQUE INDEX IF NOT EXISTS idx_gradingperiod_name ON "GradingPeriod" ("name");
CREATE INDEX IF NOT EXISTS idx_gradingperiod_startDate ON "GradingPeriod" ("startDate");
CREATE INDEX IF NOT EXISTS idx_gradingperiod_endDate ON "GradingPeriod" ("endDate");

CREATE UNIQUE INDEX IF NOT EXISTS idx_gradingsystem_name ON "GradingSystem" ("name");

CREATE UNIQUE INDEX IF NOT EXISTS idx_subject_code ON "Subject" (code);
CREATE INDEX IF NOT EXISTS idx_subject_name ON "Subject" ("name");
CREATE INDEX IF NOT EXISTS idx_subject_departmentId ON "Subject" ("departmentId");

CREATE INDEX IF NOT EXISTS idx_section_name ON "Section" ("name");
CREATE INDEX IF NOT EXISTS idx_section_gradeLevel ON "Section" ("gradeLevel");
CREATE INDEX IF NOT EXISTS idx_section_adviserId ON "Section" ("adviserId");
CREATE INDEX IF NOT EXISTS idx_section_schoolYearId ON "Section" ("schoolYearId");

CREATE UNIQUE INDEX IF NOT EXISTS idx_studentsection_student_section_year ON "StudentSection" ("studentId", "sectionId", "schoolYearId");
CREATE INDEX IF NOT EXISTS idx_studentsection_studentId ON "StudentSection" ("studentId");
CREATE INDEX IF NOT EXISTS idx_studentsection_sectionId ON "StudentSection" ("sectionId");
CREATE INDEX IF NOT EXISTS idx_studentsection_schoolYearId ON "StudentSection" ("schoolYearId");

CREATE UNIQUE INDEX IF NOT EXISTS idx_clearancefield_name ON "ClearanceField" ("name");
CREATE INDEX IF NOT EXISTS idx_clearancefield_type ON "ClearanceField" ("type");

CREATE UNIQUE INDEX IF NOT EXISTS idx_clearancesignatory_field_user_section ON "ClearanceSignatory" ("clearanceFieldId", "userId", "sectionId");
CREATE INDEX IF NOT EXISTS idx_clearancesignatory_clearanceFieldId ON "ClearanceSignatory" ("clearanceFieldId");
CREATE INDEX IF NOT EXISTS idx_clearancesignatory_userId ON "ClearanceSignatory" ("userId");
CREATE INDEX IF NOT EXISTS idx_clearancesignatory_sectionId ON "ClearanceSignatory" ("sectionId");

CREATE UNIQUE INDEX IF NOT EXISTS idx_studentclearance_student_field ON "StudentClearance" ("studentId", "clearanceFieldId");
CREATE INDEX IF NOT EXISTS idx_studentclearance_studentId ON "StudentClearance" ("studentId");
CREATE INDEX IF NOT EXISTS idx_studentclearance_clearanceFieldId ON "StudentClearance" ("clearanceFieldId");
CREATE INDEX IF NOT EXISTS idx_studentclearance_signatoryId ON "StudentClearance" ("signatoryId");
CREATE INDEX IF NOT EXISTS idx_studentclearance_status ON "StudentClearance" (status);

CREATE INDEX IF NOT EXISTS idx_enrollment_studentId ON "Enrollment" ("studentId");
CREATE INDEX IF NOT EXISTS idx_enrollment_schoolYearId ON "Enrollment" ("schoolYearId");
CREATE INDEX IF NOT EXISTS idx_enrollment_gradeLevelId ON "Enrollment" ("gradeLevelId");
CREATE INDEX IF NOT EXISTS idx_enrollment_status ON "Enrollment" (status);

CREATE INDEX IF NOT EXISTS idx_enrollmentapproval_enrollmentId ON "EnrollmentApproval" ("enrollmentId");
CREATE INDEX IF NOT EXISTS idx_enrollmentapproval_approverId ON "EnrollmentApproval" ("approverId");
CREATE INDEX IF NOT EXISTS idx_enrollmentapproval_status ON "EnrollmentApproval" (status);

CREATE INDEX IF NOT EXISTS idx_post_authorId ON "Post" ("authorId");
CREATE INDEX IF NOT EXISTS idx_post_status ON "Post" (status);
CREATE INDEX IF NOT EXISTS idx_post_type ON "Post" ("type");
CREATE UNIQUE INDEX IF NOT EXISTS idx_post_slug ON "Post" (slug);
CREATE INDEX IF NOT EXISTS idx_post_visibility ON "Post" (visibility);

CREATE INDEX IF NOT EXISTS idx_comment_postId ON "Comment" ("postId");
CREATE INDEX IF NOT EXISTS idx_comment_authorId ON "Comment" ("authorId");
CREATE INDEX IF NOT EXISTS idx_comment_parentId ON "Comment" ("parentId");

CREATE UNIQUE INDEX IF NOT EXISTS idx_like_user_target_type ON "Like" ("userId", "targetId", "targetType");
CREATE INDEX IF NOT EXISTS idx_like_userId ON "Like" ("userId");
CREATE INDEX IF NOT EXISTS idx_like_targetId ON "Like" ("targetId");
CREATE INDEX IF NOT EXISTS idx_like_targetType ON "Like" ("targetType");

CREATE INDEX IF NOT EXISTS idx_media_uploaderId ON "Media" ("uploaderId");
CREATE INDEX IF NOT EXISTS idx_media_type ON "Media" ("type");
CREATE UNIQUE INDEX IF NOT EXISTS idx_media_storagePath ON "Media" ("storagePath");

CREATE UNIQUE INDEX IF NOT EXISTS idx_email_email ON "Email" (email);
CREATE INDEX IF NOT EXISTS idx_email_userId ON "Email" ("userId");
CREATE INDEX IF NOT EXISTS idx_email_isPrimary ON "Email" ("isPrimary");

CREATE UNIQUE INDEX IF NOT EXISTS idx_phone_phoneNumber ON "Phone" ("phoneNumber");
CREATE INDEX IF NOT EXISTS idx_phone_userId ON "Phone" ("userId");
CREATE INDEX IF NOT EXISTS idx_phone_isPrimary ON "Phone" ("isPrimary");

CREATE UNIQUE INDEX IF NOT EXISTS idx_social_user_platform ON "Social" ("userId", platform);
CREATE INDEX IF NOT EXISTS idx_social_userId ON "Social" ("userId");
CREATE INDEX IF NOT EXISTS idx_social_platform ON "Social" (platform);

CREATE UNIQUE INDEX IF NOT EXISTS idx_friendrequest_sender_receiver ON "FriendRequest" ("senderId", "receiverId");
CREATE INDEX IF NOT EXISTS idx_friendrequest_senderId ON "FriendRequest" ("senderId");
CREATE INDEX IF NOT EXISTS idx_friendrequest_receiverId ON "FriendRequest" ("receiverId");
CREATE INDEX IF NOT EXISTS idx_friendrequest_status ON "FriendRequest" (status);

CREATE INDEX IF NOT EXISTS idx_chatroom_name ON "ChatRoom" ("name");
CREATE INDEX IF NOT EXISTS idx_chatroom_type ON "ChatRoom" ("type");
CREATE INDEX IF NOT EXISTS idx_chatroom_creatorId ON "ChatRoom" ("creatorId");

CREATE UNIQUE INDEX IF NOT EXISTS idx_chatroommembership_room_user ON "ChatRoomMembership" ("roomId", "userId");
CREATE INDEX IF NOT EXISTS idx_chatroommembership_roomId ON "ChatRoomMembership" ("roomId");
CREATE INDEX IF NOT EXISTS idx_chatroommembership_userId ON "ChatRoomMembership" ("userId");

CREATE INDEX IF NOT EXISTS idx_message_roomId ON "Message" ("roomId");
CREATE INDEX IF NOT EXISTS idx_message_senderId ON "Message" ("senderId");
CREATE INDEX IF NOT EXISTS idx_message_type ON "Message" ("type");

CREATE UNIQUE INDEX IF NOT EXISTS idx_messagereaction_message_user_reaction ON "MessageReaction" ("messageId", "userId", reaction);
CREATE INDEX IF NOT EXISTS idx_messagereaction_messageId ON "MessageReaction" ("messageId");
CREATE INDEX IF NOT EXISTS idx_messagereaction_userId ON "MessageReaction" ("userId");

CREATE UNIQUE INDEX IF NOT EXISTS idx_messageread_message_user ON "MessageRead" ("messageId", "userId");
CREATE INDEX IF NOT EXISTS idx_messageread_messageId ON "MessageRead" ("messageId");
CREATE INDEX IF NOT EXISTS idx_messageread_userId ON "MessageRead" ("userId");

CREATE INDEX IF NOT EXISTS idx_messageattachment_messageId ON "MessageAttachment" ("messageId");
CREATE INDEX IF NOT EXISTS idx_messageattachment_mediaId ON "MessageAttachment" ("mediaId");

CREATE INDEX IF NOT EXISTS idx_messagemention_messageId ON "MessageMention" ("messageId");
CREATE INDEX IF NOT EXISTS idx_messagemention_userId ON "MessageMention" ("userId");

CREATE INDEX IF NOT EXISTS idx_studentactivitylog_studentId ON "StudentActivityLog" ("studentId");
CREATE INDEX IF NOT EXISTS idx_studentactivitylog_activityType ON "StudentActivityLog" ("activityType");
CREATE INDEX IF NOT EXISTS idx_studentactivitylog_actorId ON "StudentActivityLog" ("actorId");

CREATE INDEX IF NOT EXISTS idx_smslog_recipientNumber ON "SmsLog" ("recipientNumber");
CREATE INDEX IF NOT EXISTS idx_smslog_status ON "SmsLog" (status);
CREATE INDEX IF NOT EXISTS idx_smslog_providerMessageId ON "SmsLog" ("providerMessageId");

CREATE INDEX IF NOT EXISTS idx_file_uploaderId ON "File" ("uploaderId");
CREATE INDEX IF NOT EXISTS idx_file_fileName ON "File" ("fileName");
CREATE INDEX IF NOT EXISTS idx_file_mimeType ON "File" ("mimeType");
CREATE UNIQUE INDEX IF NOT EXISTS idx_file_storagePath ON "File" ("storagePath");

CREATE INDEX IF NOT EXISTS idx_userloginlog_userId ON "UserLoginLog" ("userId");
CREATE INDEX IF NOT EXISTS idx_userloginlog_ipAddress ON "UserLoginLog" ("ipAddress");
CREATE INDEX IF NOT EXISTS idx_userloginlog_loginTime ON "UserLoginLog" ("loginTime"); -- String field
CREATE INDEX IF NOT EXISTS idx_userloginlog_loginAt ON "UserLoginLog" ("loginAt"); -- DateTime field

CREATE INDEX IF NOT EXISTS idx_scheduledsms_userId ON "ScheduledSms" ("userId");
CREATE INDEX IF NOT EXISTS idx_scheduledsms_status ON "ScheduledSms" (status);
CREATE INDEX IF NOT EXISTS idx_scheduledsms_scheduledTime ON "ScheduledSms" ("scheduledTime");

CREATE INDEX IF NOT EXISTS idx_event_calendarId ON "Event" ("calendarId");
CREATE INDEX IF NOT EXISTS idx_event_calendarType ON "Event" ("calendarType");
CREATE INDEX IF NOT EXISTS idx_event_creatorId ON "Event" ("creatorId");
CREATE INDEX IF NOT EXISTS idx_event_type ON "Event" ("type");
CREATE INDEX IF NOT EXISTS idx_event_status ON "Event" (status);
CREATE INDEX IF NOT EXISTS idx_event_start ON "Event" ("start");
CREATE INDEX IF NOT EXISTS idx_event_end ON "Event" ("end");

CREATE INDEX IF NOT EXISTS idx_announcement_userId ON "Announcement" ("userId");
CREATE INDEX IF NOT EXISTS idx_announcement_status ON "Announcement" (status);
CREATE INDEX IF NOT EXISTS idx_announcement_type ON "Announcement" ("type");
CREATE INDEX IF NOT EXISTS idx_announcement_audienceType ON "Announcement" ("audienceType");

CREATE UNIQUE INDEX IF NOT EXISTS idx_approvalflow_name ON "ApprovalFlow" ("name");
CREATE INDEX IF NOT EXISTS idx_approvalflow_entityType ON "ApprovalFlow" ("entityType");

CREATE UNIQUE INDEX IF NOT EXISTS idx_approvalstep_flow_order ON "ApprovalStep" ("flowId", "stepOrder");
CREATE INDEX IF NOT EXISTS idx_approvalstep_flowId ON "ApprovalStep" ("flowId");
CREATE INDEX IF NOT EXISTS idx_approvalstep_roleId ON "ApprovalStep" ("roleId");

CREATE INDEX IF NOT EXISTS idx_formapproval_formId ON "FormApproval" ("formId");
CREATE INDEX IF NOT EXISTS idx_formapproval_formType ON "FormApproval" ("formType");
CREATE INDEX IF NOT EXISTS idx_formapproval_currentStepId ON "FormApproval" ("currentStepId");
CREATE INDEX IF NOT EXISTS idx_formapproval_status ON "FormApproval" (status);
CREATE INDEX IF NOT EXISTS idx_formapproval_requesterId ON "FormApproval" ("requesterId");

CREATE UNIQUE INDEX IF NOT EXISTS idx_formkeyvalues_form_key ON "FormKeyValues" ("formId", "key");
CREATE INDEX IF NOT EXISTS idx_formkeyvalues_formId ON "FormKeyValues" ("formId");

CREATE INDEX IF NOT EXISTS idx_student_accommodation_fk_id ON "student_accommodation" ("fk_id");
CREATE INDEX IF NOT EXISTS idx_student_accommodation_type ON "student_accommodation" ("type");
CREATE INDEX IF NOT EXISTS idx_student_accommodation_option ON "student_accommodation" ("accommodation_option");

CREATE INDEX IF NOT EXISTS idx_student_family_fk_id ON "student_family" ("fk_id");
CREATE INDEX IF NOT EXISTS idx_student_family_relationship ON "student_family" (relationship);

-- Product from schema.prisma (assuming distinct or specific version for schema.prisma context)
-- If this is the SAME "Product" table as in pos.prisma, these might be redundant or need merging.
-- The edit for Product was on schema.prisma adding name and ownerId.
CREATE INDEX IF NOT EXISTS idx_sproduct_name ON "Product" ("name"); -- Using sproduct to distinguish if needed
CREATE INDEX IF NOT EXISTS idx_sproduct_ownerId ON "Product" ("ownerId");


CREATE INDEX IF NOT EXISTS idx_transfercredit_studentId ON "TransferCredit" ("studentId");
CREATE INDEX IF NOT EXISTS idx_transfercredit_subjectId ON "TransferCredit" ("subjectId");
CREATE INDEX IF NOT EXISTS idx_transfercredit_status ON "TransferCredit" (status);
CREATE INDEX IF NOT EXISTS idx_transfercredit_processedBy ON "TransferCredit" ("processedBy");
CREATE INDEX IF NOT EXISTS idx_transfercredit_schoolYear ON "TransferCredit" ("schoolYear");
CREATE INDEX IF NOT EXISTS idx_transfercredit_previousSchool ON "TransferCredit" ("previousSchool");

-- From enrollment.prisma
CREATE UNIQUE INDEX IF NOT EXISTS idx_student_userId ON "Student" ("userId");
CREATE UNIQUE INDEX IF NOT EXISTS idx_student_lrn ON "Student" (lrn);
CREATE INDEX IF NOT EXISTS idx_student_gradeLevelId ON "Student" ("gradeLevelId");
CREATE INDEX IF NOT EXISTS idx_student_sectionId ON "Student" ("sectionId");
CREATE INDEX IF NOT EXISTS idx_student_courseId ON "Student" ("courseId");
CREATE INDEX IF NOT EXISTS idx_student_majorId ON "Student" ("majorId");
CREATE INDEX IF NOT EXISTS idx_student_strand ON "Student" (strand);
CREATE INDEX IF NOT EXISTS idx_student_track ON "Student" (track);

CREATE INDEX IF NOT EXISTS idx_schedule_subjectId ON "Schedule" ("subjectId");
CREATE INDEX IF NOT EXISTS idx_schedule_professorId ON "Schedule" ("professorId");
CREATE INDEX IF NOT EXISTS idx_schedule_semesterId ON "Schedule" ("semesterId");
CREATE INDEX IF NOT EXISTS idx_schedule_schoolYearId ON "Schedule" ("schoolYearId");
CREATE INDEX IF NOT EXISTS idx_schedule_sectionSubjectId ON "Schedule" ("sectionSubjectId");
CREATE INDEX IF NOT EXISTS idx_schedule_status ON "Schedule" (status);
CREATE INDEX IF NOT EXISTS idx_schedule_room ON "Schedule" (room);

CREATE INDEX IF NOT EXISTS idx_sectionsubject_sectionId ON "SectionSubject" ("sectionId");
CREATE INDEX IF NOT EXISTS idx_sectionsubject_subjectId ON "SectionSubject" ("subjectId");
CREATE INDEX IF NOT EXISTS idx_sectionsubject_teacherId ON "SectionSubject" ("teacherId");

CREATE UNIQUE INDEX IF NOT EXISTS idx_subjectenrollment_student_schedule ON "SubjectEnrollment" ("studentId", "scheduleId");
CREATE INDEX IF NOT EXISTS idx_subjectenrollment_studentId ON "SubjectEnrollment" ("studentId");
CREATE INDEX IF NOT EXISTS idx_subjectenrollment_scheduleId ON "SubjectEnrollment" ("scheduleId");
CREATE INDEX IF NOT EXISTS idx_subjectenrollment_status ON "SubjectEnrollment" (status);
CREATE INDEX IF NOT EXISTS idx_subjectenrollment_academicYear ON "SubjectEnrollment" ("academicYear");
CREATE INDEX IF NOT EXISTS idx_subjectenrollment_semester ON "SubjectEnrollment" (semester);

CREATE INDEX IF NOT EXISTS idx_enrollmenthistory_student_year_semester ON "EnrollmentHistory" ("studentId", "year", semester);
CREATE INDEX IF NOT EXISTS idx_enrollmenthistory_studentId ON "EnrollmentHistory" ("studentId");
CREATE INDEX IF NOT EXISTS idx_enrollmenthistory_year ON "EnrollmentHistory" ("year");
CREATE INDEX IF NOT EXISTS idx_enrollmenthistory_semester ON "EnrollmentHistory" (semester);

CREATE INDEX IF NOT EXISTS idx_subjecthistory_enrollmentHistoryId ON "SubjectHistory" ("enrollmentHistoryId");
CREATE INDEX IF NOT EXISTS idx_subjecthistory_subjectName ON "SubjectHistory" ("subjectName");
CREATE INDEX IF NOT EXISTS idx_subjecthistory_status ON "SubjectHistory" (status);

CREATE INDEX IF NOT EXISTS idx_action_studentId ON "Action" ("studentId");
CREATE INDEX IF NOT EXISTS idx_action_action ON "Action" ("action");
CREATE INDEX IF NOT EXISTS idx_action_subjectId ON "Action" ("subjectId");
CREATE INDEX IF NOT EXISTS idx_action_timestamp ON "Action" (timestamp);

CREATE UNIQUE INDEX IF NOT EXISTS idx_applicant_email ON "Applicant" (email);
CREATE UNIQUE INDEX IF NOT EXISTS idx_applicant_phone ON "Applicant" (phone);
CREATE INDEX IF NOT EXISTS idx_applicant_type ON "Applicant" ("type");
CREATE INDEX IF NOT EXISTS idx_applicant_status ON "Applicant" (status);
CREATE INDEX IF NOT EXISTS idx_applicant_lastName_firstName ON "Applicant" ("lastName", "firstName");

CREATE UNIQUE INDEX IF NOT EXISTS idx_transfereerecord_applicantId ON "TransfereeRecord" ("applicantId");

CREATE UNIQUE INDEX IF NOT EXISTS idx_schoolyear_start_end ON "SchoolYear" ("startYear", "endYear");
CREATE INDEX IF NOT EXISTS idx_schoolyear_startYear ON "SchoolYear" ("startYear");
CREATE INDEX IF NOT EXISTS idx_schoolyear_endYear ON "SchoolYear" ("endYear");
CREATE INDEX IF NOT EXISTS idx_schoolyear_syStatus ON "SchoolYear" ("syStatus");
CREATE INDEX IF NOT EXISTS idx_schoolyear_syLabel ON "SchoolYear" ("syLabel");

CREATE UNIQUE INDEX IF NOT EXISTS idx_semester_schoolyear_name ON "Semester" ("schoolYearId", "name");
CREATE INDEX IF NOT EXISTS idx_semester_schoolYearId ON "Semester" ("schoolYearId");
CREATE INDEX IF NOT EXISTS idx_semester_name ON "Semester" ("name");
CREATE INDEX IF NOT EXISTS idx_semester_status ON "Semester" (status);
CREATE INDEX IF NOT EXISTS idx_semester_type ON "Semester" ("type");

CREATE UNIQUE INDEX IF NOT EXISTS idx_quarter_semester_name ON "Quarter" ("semesterId", "name");
CREATE INDEX IF NOT EXISTS idx_quarter_semesterId ON "Quarter" ("semesterId");
CREATE INDEX IF NOT EXISTS idx_quarter_name ON "Quarter" ("name");
CREATE INDEX IF NOT EXISTS idx_quarter_status ON "Quarter" (status);

CREATE UNIQUE INDEX IF NOT EXISTS idx_course_code ON "Course" (code);
CREATE INDEX IF NOT EXISTS idx_course_name ON "Course" ("name");
CREATE INDEX IF NOT EXISTS idx_course_status ON "Course" (status);

CREATE UNIQUE INDEX IF NOT EXISTS idx_curriculum_major_effectivity ON "Curriculum" ("majorId", "effectivityDate");
CREATE INDEX IF NOT EXISTS idx_curriculum_majorId ON "Curriculum" ("majorId");
CREATE INDEX IF NOT EXISTS idx_curriculum_status ON "Curriculum" (status);
CREATE INDEX IF NOT EXISTS idx_curriculum_effectivityDate ON "Curriculum" ("effectivityDate");

CREATE UNIQUE INDEX IF NOT EXISTS idx_curriculumsubject_curriculum_subject ON "CurriculumSubject" ("curriculumId", "subjectId");
CREATE INDEX IF NOT EXISTS idx_curriculumsubject_curriculumId ON "CurriculumSubject" ("curriculumId");
CREATE INDEX IF NOT EXISTS idx_curriculumsubject_subjectId ON "CurriculumSubject" ("subjectId");
CREATE INDEX IF NOT EXISTS idx_curriculumsubject_yearLevel ON "CurriculumSubject" ("yearLevel");
CREATE INDEX IF NOT EXISTS idx_curriculumsubject_semester ON "CurriculumSubject" (semester);
CREATE INDEX IF NOT EXISTS idx_curriculumsubject_category ON "CurriculumSubject" (category);

CREATE UNIQUE INDEX IF NOT EXISTS idx_major_course_name ON "Major" ("courseId", "name");
CREATE INDEX IF NOT EXISTS idx_major_name ON "Major" ("name");
CREATE INDEX IF NOT EXISTS idx_major_courseId ON "Major" ("courseId");
CREATE INDEX IF NOT EXISTS idx_major_status ON "Major" (status);

CREATE UNIQUE INDEX IF NOT EXISTS idx_basiceducationapplication_applicantId ON "BasicEducationApplication" ("applicantId");
CREATE INDEX IF NOT EXISTS idx_basiceducationapplication_academicYear ON "BasicEducationApplication" ("academicYear");
CREATE INDEX IF NOT EXISTS idx_basiceducationapplication_gradeLevel ON "BasicEducationApplication" ("gradeLevel");
CREATE INDEX IF NOT EXISTS idx_basiceducationapplication_type ON "BasicEducationApplication" ("type");
CREATE INDEX IF NOT EXISTS idx_basiceducationapplication_status ON "BasicEducationApplication" (status);

CREATE UNIQUE INDEX IF NOT EXISTS idx_applicationrequirement_app_req ON "ApplicationRequirement" ("applicationId", "requirementId");
CREATE INDEX IF NOT EXISTS idx_applicationrequirement_applicationId ON "ApplicationRequirement" ("applicationId");
CREATE INDEX IF NOT EXISTS idx_applicationrequirement_requirementId ON "ApplicationRequirement" ("requirementId");
CREATE INDEX IF NOT EXISTS idx_applicationrequirement_status ON "ApplicationRequirement" (status);
CREATE INDEX IF NOT EXISTS idx_applicationrequirement_type ON "ApplicationRequirement" ("type"); -- Note: This field was mentioned but not in the unique constraint.

CREATE INDEX IF NOT EXISTS idx_applicationtimeline_applicationId ON "ApplicationTimeline" ("applicationId");
CREATE INDEX IF NOT EXISTS idx_applicationtimeline_action ON "ApplicationTimeline" ("action");
CREATE INDEX IF NOT EXISTS idx_applicationtimeline_actorId ON "ApplicationTimeline" ("actorId");

CREATE UNIQUE INDEX IF NOT EXISTS idx_studentdocument_student_name ON "StudentDocument" ("studentId", "documentName");
CREATE INDEX IF NOT EXISTS idx_studentdocument_studentId ON "StudentDocument" ("studentId");
CREATE INDEX IF NOT EXISTS idx_studentdocument_documentName ON "StudentDocument" ("documentName");
CREATE INDEX IF NOT EXISTS idx_studentdocument_type ON "StudentDocument" ("type");

-- From submissions.prisma (No changes were made, but listing existing ones for completeness if needed)
-- model SubjectGradeSubmission
CREATE UNIQUE INDEX IF NOT EXISTS unique_subject_period_submission ON "SubjectGradeSubmission" ("subjectId", "sectionId", "schoolYearId", "quarterId", "semesterId");
CREATE INDEX IF NOT EXISTS idx_subjectgradesubmission_status ON "SubjectGradeSubmission" (status);
CREATE INDEX IF NOT EXISTS idx_subjectgradesubmission_submittedById ON "SubjectGradeSubmission" ("submittedById");
-- CREATE INDEX IF NOT EXISTS idx_subjectgradesubmission_adviserReviewedById ON "SubjectGradeSubmission" ("adviserReviewedById"); -- If relation becomes active

-- model AdvisoryGradeSubmission
CREATE UNIQUE INDEX IF NOT EXISTS idx_advisorygradesubmission_section_year ON "AdvisoryGradeSubmission" ("sectionId", "schoolYearId");
CREATE INDEX IF NOT EXISTS idx_advisorygradesubmission_status ON "AdvisoryGradeSubmission" (status);
CREATE INDEX IF NOT EXISTS idx_advisorygradesubmission_submittedById ON "AdvisoryGradeSubmission" ("submittedById");
CREATE INDEX IF NOT EXISTS idx_advisorygradesubmission_reviewedById ON "AdvisoryGradeSubmission" ("reviewedById");


-- From sf10.prisma
CREATE INDEX IF NOT EXISTS idx_academichistory_student_year ON "AcademicHistory" ("studentId", "schoolYear");
CREATE INDEX IF NOT EXISTS idx_academichistory_formType ON "AcademicHistory" ("formType");
CREATE INDEX IF NOT EXISTS idx_academichistory_schoolName ON "AcademicHistory" ("schoolName");
CREATE INDEX IF NOT EXISTS idx_academichistory_gradeLevel ON "AcademicHistory" ("gradeLevel");
CREATE INDEX IF NOT EXISTS idx_academichistory_track ON "AcademicHistory" (track);
CREATE INDEX IF NOT EXISTS idx_academichistory_strand ON "AcademicHistory" (strand);

CREATE INDEX IF NOT EXISTS idx_academicrecord_academicHistoryId ON "AcademicRecord" ("academicHistoryId");
CREATE INDEX IF NOT EXISTS idx_academicrecord_subjectName ON "AcademicRecord" ("subjectName");
CREATE INDEX IF NOT EXISTS idx_academicrecord_classification ON "AcademicRecord" (classification);

CREATE UNIQUE INDEX IF NOT EXISTS idx_remedialrecord_academicRecordId ON "RemedialRecord" ("academicRecordId"); -- This is already a @unique in schema

CREATE INDEX IF NOT EXISTS idx_sf10record_studentId ON "SF10Record" ("studentId");
CREATE INDEX IF NOT EXISTS idx_sf10record_formType ON "SF10Record" ("formType");
CREATE INDEX IF NOT EXISTS idx_sf10record_schoolYear ON "SF10Record" ("schoolYear");

CREATE UNIQUE INDEX IF NOT EXISTS idx_sf10eligibility_sf10RecordId ON "SF10Eligibility" ("sf10RecordId"); -- This is already a @unique in schema

CREATE INDEX IF NOT EXISTS idx_sf10certification_sf10RecordId ON "SF10Certification" ("sf10RecordId");

CREATE INDEX IF NOT EXISTS idx_externalschoolrecord_sf10RecordId ON "ExternalSchoolRecord" ("sf10RecordId");
CREATE INDEX IF NOT EXISTS idx_externalschoolrecord_schoolName ON "ExternalSchoolRecord" ("schoolName");
CREATE INDEX IF NOT EXISTS idx_externalschoolrecord_schoolYear ON "ExternalSchoolRecord" ("schoolYear");
CREATE INDEX IF NOT EXISTS idx_externalschoolrecord_yearLevel ON "ExternalSchoolRecord" ("yearLevel");

CREATE INDEX IF NOT EXISTS idx_transfergrade_externalSchoolRecordId ON "TransferGrade" ("externalSchoolRecordId");
CREATE INDEX IF NOT EXISTS idx_transfergrade_equivalentSubjectId ON "TransferGrade" ("equivalentSubjectId");
CREATE INDEX IF NOT EXISTS idx_transfergrade_subjectName ON "TransferGrade" ("subjectName");
