# WH4BAutomation README

## Owner(s)

Lucas Allman

## Usage

UpdateWH4BDeviceGroup.ps1 can be used to get a list of Windows 11, EntraID joined devices that are owned by the users in the HelloForBusiness-Authorize group and add them to the WindowsHelloforBusiness-AuthorizedDevices group.

```powerhshell

. UpdateWH4BDeviceGroup.ps1 -userGroupId "123456789-1234-1234-1234-123456789012" -deviceGroupId "123456789-1234-1234-1234-123456789012"

```

## Dependencies

This code requires the following modules/dependencies to be installed:
*List all dependencies here*

## Scheduled

The code runs every 30 minutes.

## Down Stream

An EntraID AD group will be populated with the owned devices of the users listed in the HelloForBusiness-Authorize group.

## End Date

Review after WH4B project completion.
