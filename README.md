# PowerShell: Windows 10 Local Profile Cleanup
 Cleanup outdated user profiles on a computer

We all deal with dirty Windows 10 computers.  Well after dealing with some outdated profiles on over 3 dozen computers and realizing that I simply did not want to manually go to each computer, right-click on the Properties, Advanced then User Profiles then use that crappy non-resizable window MS gives you to manage the local profiles, this really was way too cumbersome to do.  So at the request of my ridiculous nature to automate, I wrote a script for it.

This will work with any version of Windows 10, probably Server 2017 and above as well.  It does not matter if you have the computer joined to a Domain or not, it will clean it up.
In fact if the computer IS a part of a Domain, it goes a bit further.  Here is a breakdown of the process.

1. Determine all the local user profiles
2. Determine if computer is a domain member
2.a. Grab all disabled profiles from the domain
2.b. Compares those disabled profiles against local profiles.
2.c. If they exist, add them to the list, if not, move on.
3. Check all local profiles older than 6 months that have NOT been used.
4. Add them to the list.
5. Remove the profiles from the Registry.
6. Remove profiles from the Disk.
7. Ensure the disk has been cleared.

That's all really.

As usual it has portions of my standard library even if the functions are not being used.