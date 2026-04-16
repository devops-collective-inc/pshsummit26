# Profile Anywhere

## Centralize Your Profile

Remember how we were calling the Oh My Posh themes with a URL from Github?
You can do the same with your profile!

Steps:

1. Store your PowerShell profile in a Github Gist or Repository (I use a Gist)

[Profile Code](https://gist.github.com/ephos/816a963a8bcebd0ba1795765d551dc88#file-pwshprofile-ps1)

2. Change your profile to call the Gist
  a. I generally call this the profile-launch

[Profile Launch](https://gist.github.com/ephos/816a963a8bcebd0ba1795765d551dc88#file-profile-launch-ps1)

3. Make your 'profile-launch' code your `$PROFILE` on any machine you want your profile

That's it.

Now you can centrally update your profile and have a consistent experience.
Great for:

- Multiple machines
- Using the same profile at work and home
- centrally locating your profile for easy maintenance 

## My Profile

[My Gist](https://gist.github.com/ephos/ba04ce3b9ad12860cfbf4302438aa2a4)

This includes my:

- My profile launch code
- oh-my-posh custom theme (omp.json) file
- `$PROFILE` code

## Other Options

This doesn't need to be a Git repo, others have used Dropbox and One Drive to sync their profiles.
