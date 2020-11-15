## Expansion Ideas and Sources

Other tools for the future:
* <a href="https://github.com/iagox86/dnscat2">DNScat</a>
* <a href="">Heyoka</a> (uses source ip spoofing)
* <a href="https://github.com/mdornseif/DeNiSe">DeNiSe</a>
* <a href="https://github.com/FedericoCeratto/dnscapy">dnscappy</a>
* <a href="https://github.com/alex-sector/dns2tcp">dns2tcp</a>
* <a href="https://github.com/M66B/element53">Element53</a>
* <a href="https://github.com/lnussbaum/tuns">tuns</a>

Other DNS servers for the future:
* BIND9
* Windows?

Detection notes:
* Look at domain-length, num of bytes, content encoding/compresison/entropy of request/response (unprintable requests?)
* Uncommon request types (TXT NULL EDNS)
* Volume of traffic / number of hostnames per domain / volume of DNS traffic per domain / volume of DNS traffic per IP. (exclude .arpa for reverse lookups false positives)
* Geo location
* Domain history (when A or NS record was added / when was this domain acquired?) 

### Some Sources:
* <a href="https://davidhamann.de/2019/05/12/tunnel-traffic-over-dns-ssh/">Tunneling network traffic over DNS with Iodine and a SSH SOCKS proxy </a>
* <a href="https://stackoverflow.com/questions/39362730/how-to-capture-packets-for-single-docker-container">How to capture packets for single docker container</a>
* <a href="https://www.doyler.net/security-not-included/iodine-dns-tunneling">Iodine DNS Tunneling – Not Just for Exfiltration!</a>
* <a href="https://trustfoundry.net/using-iodine-for-dns-tunneling-c2-to-bypass-egress-filtering/">Using Iodine for DNS Tunneling C2 to Bypass Egress Filtering</a>
* <a href="https://www.sans.org/reading-room/whitepapers/dns/detecting-dns-tunneling-34152">SANS - Detecting DNS Tunneling</a>
* <a href="https://github.com/jpillora/docker-dnsmasq">dnsmasq in Docker</a>
* <a href="https://github.com/yarrick/iodine">Iodine</a>
* <a href="https://blog.stalkr.net/2010/10/hacklu-ctf-challenge-9-bottle-writeup.html">Great CTF writeup</a>
* <a href="https://unit42.paloaltonetworks.com/dns-tunneling-in-the-wild-overview-of-oilrigs-dns-tunneling/">DNS Tunneling in the Wild: Overview of OilRig’s DNS Tunneling</a>
* <a href="https://unit42.paloaltonetworks.com/dns-tunneling-how-dns-can-be-abused-by-malicious-actors/">DNS Tunneling: how DNS can be (ab)used by malicious actors</a>
