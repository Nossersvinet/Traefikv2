
## Traefikv2 with Authelia over Cloudflare
---

## FYI
```
I am not a team-member of sudobox.io anymore
        and will not come back.
This is my Repository and not SudoBox LITE !!!
So if you see a broken part plz report it here !!
And not on the Forum or Discord of SudoBox.IO

All the real Contributors you can see at the end 

```


## You need Help 

```
https://discord.gg/A7h7bKBCVa
```
Or create one issue 
```
https://github.com/doob187/Traefikv2/issues
```



---

## minimum specs 
```
Ubuntu 18/20 or Server or Debian 9/10
2 Cores
4GB Ram
20GB Disk Space
```

---

## minimum requirement
```
1 VPS / VM / dedicated Sever
1 Domain
1 Cloudflare Account  ( free level )
```

---

## pre Install

```
Go to your CloudFlare Dashboard
Add 1 A Record > pointed to the ServerIp
Copy your CloudFlare-Global-Key and CloudFlare-Zone-ID
```
---

Set follow on Cloudflare
```
SSL = FULL ( not FULL/STRICT )
Always on = YES
http to https = YES
RocketLoader and Broli / Onion Routing = NO
Tls min = 1.2
TLS = v1.3
```
---

## Use the easy mode installer 

```
Long Line
sudo wget -qO- https://raw.githubusercontent.com/doob187/traefikv2installer/main/wgetfile.sh | sudo bash

or 

Short Line
sudo wget -qO- https://git.io/JO7vg | sudo bash
```


Then just follow the number and Press d/D to deploy

----

## Code and Permissions 
```
Copyright 2021 @doobsi 
Code owner @doobsi @mrfret
Dev Code @doobsi 
Co-Dev -APPS- @mrfret
```

Only @mrfret and @doobsi have access
to change or pr00f any Pull Request
( no one other )

---


## Contributors ✨

Thanks goes to these wonderful people ([emoji key](https://allcontributors.org/docs/en/emoji-key)):

<!-- ALL-CONTRIBUTORS-LIST:START - Do not remove or modify this section -->
<!-- prettier-ignore-start -->
<!-- markdownlint-disable -->
<table>
  <tr>
    <td align="center"><a href="https://github.com/doob187"><img src="https://avatars.githubusercontent.com/u/60312740?v=4?s=100" width="100px;" alt=""/><br /><sub><b>doob187</b></sub></a><br /><a href="#infra-doob187" title="Infrastructure (Hosting, Build-Tools, etc)">🚇</a> <a href="https://github.com/doob187/Traefikv2/commits?author=doob187" title="Code">💻</a></td>
    <td align="center"><a href="https://github.com/Hawkinzzz"><img src="https://avatars.githubusercontent.com/u/24587652?v=4?s=100" width="100px;" alt=""/><br /><sub><b>hawkinzzz</b></sub></a><br /><a href="#infra-Hawkinzzz" title="Infrastructure (Hosting, Build-Tools, etc)">🚇</a></td>
    <td align="center"><a href="https://github.com/mrfret"><img src="https://avatars.githubusercontent.com/u/72273384?v=4?s=100" width="100px;" alt=""/><br /><sub><b>mrfret</b></sub></a><br /><a href="https://github.com/doob187/Traefikv2/commits?author=mrfret" title="Tests">⚠️</a></td>
    <td align="center"><a href="https://github.com/aelfa"><img src="https://avatars.githubusercontent.com/u/60222501?v=4?s=100" width="100px;" alt=""/><br /><sub><b>Aelfa</b></sub></a><br /><a href="https://github.com/doob187/Traefikv2/commits?author=aelfa" title="Code">💻</a></td>
    <td align="center"><a href="https://github.com/DrAg0n141"><img src="https://avatars.githubusercontent.com/u/44865095?v=4?s=100" width="100px;" alt=""/><br /><sub><b>DrAg0n141</b></sub></a><br /><a href="https://github.com/doob187/Traefikv2/commits?author=DrAg0n141" title="Code">💻</a></td>
    <td align="center"><a href="https://github.com/townsmcp"><img src="https://avatars.githubusercontent.com/u/14061617?v=4?s=100" width="100px;" alt=""/><br /><sub><b>townsmcp</b></sub></a><br /><a href="https://github.com/doob187/Traefikv2/commits?author=townsmcp" title="Tests">⚠️</a> <a href="https://github.com/doob187/Traefikv2/issues?q=author%3Atownsmcp" title="Bug reports">🐛</a></td>
  </tr>
</table>

<!-- markdownlint-restore -->
<!-- prettier-ignore-end -->

<!-- ALL-CONTRIBUTORS-LIST:END -->
