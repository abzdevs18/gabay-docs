# RFID Reader Setup and Management Guide

## Overview
This guide will help you set up and manage RFID readers for entrance and exit gates.

## Prerequisites
- Ensure all RFID readers are connected via USB
- Have the application running (`npm run dev`)

## Step-by-Step Setup

### 1. Navigate to Reader Configuration
- Open the application
- Go to the "Gate Management" page
- Click on the "Reader Configuration" tab

### 2. Identify Available Devices
- The "Available Devices" dropdown will show:
  - Connected USB devices
  - Device manufacturer
  - Device path (e.g., `/dev/ttyUSB0`)

### 3. Assign Devices to Gate Types
#### For Entrance Gate:
1. Open the "Entrance Gate" section
2. Select a device from the "Available Devices" dropdown
3. The device will be automatically assigned to the entrance gate

#### For Exit Gate:
1. Open the "Exit Gate" section
2. Select a device from the "Available Devices" dropdown
3. The device will be automatically assigned to the exit gate

## Important Notes
- Only one device can be assigned to each gate type
- Assigning a new device will automatically unassign the previous device
- Device assignments persist between application restarts

## Troubleshooting
### Device Not Showing Up
- Ensure the RFID reader is properly connected
- Check USB cable and connection
- Restart the application

### Connection Issues
- Verify the reader is compatible with the system
- Check for any driver or permission issues
- Consult your system administrator

## Technical Details
- Device assignments are stored in `reader-config.json`
- Real-time updates via WebSocket
- Supports multiple USB RFID reader types

## Support
For further assistance, contact your technical support team.
