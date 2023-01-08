# mqtt-broker
Config a secure MQTT broker

[Detail - Blog](https://mahdad.me/blog/2023-01-08-mqtt-broker)


* $ mkdir mosquitto-data
* $ cd mosquitto-data
* $ sudo curl -s https://raw.githubusercontent.com/MahdadGhasemian/mqtt-broker/main/install-mqtt-broker.sh | bash -s username password


### Recommended
$ sudo curl -s https://raw.githubusercontent.com/MahdadGhasemian/mqtt-broker/main/install-mqtt-broker.sh | bash -s username password


### Optional
$ sudo curl -s https://raw.githubusercontent.com/MahdadGhasemian/mqtt-broker/main/install-mqtt-broker.sh | bash -s username password host_name topic_name system_ip

### The scripts will show following log

![Script's log](https://user-images.githubusercontent.com/48379992/211197764-01993698-6bff-4ce9-9630-80b3472847c9.png)

* copy the last line of the log and run it on your local system like this:
    __$ sudo bash -c "echo \"x.x.x.x mqtt-host-tekp\" >> /etc/hosts"__
* copy __client__ folder to your local, it has three files (ca.crt  client.crt  client.key)


### How to configure the MQTTX client application

![How to configure the MQTTX client app](https://user-images.githubusercontent.com/48379992/211197547-da681c01-5797-49a5-a778-caf5237ddba4.png)
