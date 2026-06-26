import paramiko
import sys
import time

PHP_SCRIPT = """<?php
require_once("config.inc");
require_once("functions.inc");
require_once("filter.inc");
require_once("shaper.inc");
require_once("ipsec.inc");

global $config;

// 1. Rename interfaces
$config['interfaces']['lan']['descr'] = "SERVERS";
$config['interfaces']['opt1']['descr'] = "EMPLOYEES";
$config['interfaces']['opt2']['descr'] = "RD_ZONE";
$config['interfaces']['opt3']['descr'] = "MANAGEMENT";

// 2. Enable DHCP on opt1 (VLAN 20)
$config['dhcpd']['opt1']['enable'] = "";
$config['dhcpd']['opt1']['range']['from'] = "10.10.20.100";
$config['dhcpd']['opt1']['range']['to'] = "10.10.20.200";

// 3. Enable DHCP on opt2 (VLAN 30)
$config['dhcpd']['opt2']['enable'] = "";
$config['dhcpd']['opt2']['range']['from'] = "10.10.30.100";
$config['dhcpd']['opt2']['range']['to'] = "10.10.30.200";

// 4. Firewall Rules
// We preserve existing NAT rules and anti-lockout. We just clear the filter rules array.
if (!is_array($config['filter']['rule'])) {
    $config['filter']['rule'] = array();
}

$rules = array();

// Allow WebGUI on WAN (Anti-lockout via WAN pour la maquette)
$rules[] = array(
    "type" => "pass", "interface" => "wan", "ipprotocol" => "inet",
    "source" => array("any" => ""), "destination" => array("network" => "wanip"), "destinationport" => "80,443",
    "descr" => "Allow WAN WebGUI"
);

// SERVERS outbound
$rules[] = array(
    "type" => "pass", "interface" => "lan", "ipprotocol" => "inet",
    "source" => array("network" => "lan"), "destination" => array("any" => ""),
    "descr" => "SERVERS full outbound"
);
// EMPLOYEES: Block to RD_ZONE
$rules[] = array(
    "type" => "block", "interface" => "opt1", "ipprotocol" => "inet",
    "source" => array("network" => "opt1"), "destination" => array("network" => "opt2"),
    "descr" => "Block EMPLOYEES to RD_ZONE"
);
// EMPLOYEES: Pass to SERVERS
$rules[] = array(
    "type" => "pass", "interface" => "opt1", "ipprotocol" => "inet",
    "source" => array("network" => "opt1"), "destination" => array("network" => "lan"),
    "descr" => "Allow EMPLOYEES to SERVERS"
);
// EMPLOYEES: Pass to ANY
$rules[] = array(
    "type" => "pass", "interface" => "opt1", "ipprotocol" => "inet",
    "source" => array("network" => "opt1"), "destination" => array("any" => ""),
    "descr" => "Allow EMPLOYEES outbound"
);
// RD_ZONE: Pass to AD (SMB)
$rules[] = array(
    "type" => "pass", "interface" => "opt2", "ipprotocol" => "inet",
    "source" => array("network" => "opt2"), "destination" => array("address" => "10.10.10.10"),
    "target" => "445", "descr" => "Allow RD to AD SMB"
);
// RD_ZONE: Pass to AD (SQL)
$rules[] = array(
    "type" => "pass", "interface" => "opt2", "ipprotocol" => "inet",
    "source" => array("network" => "opt2"), "destination" => array("address" => "10.10.10.10"),
    "target" => "1433", "descr" => "Allow RD to AD SQL"
);
// RD_ZONE: Pass to Internet for setup (Optional but blocked as per spec, blocking all other)
$rules[] = array(
    "type" => "block", "interface" => "opt2", "ipprotocol" => "inet",
    "source" => array("network" => "opt2"), "destination" => array("any" => ""),
    "descr" => "Block RD outbound"
);
// MANAGEMENT: Allow all
$rules[] = array(
    "type" => "pass", "interface" => "opt3", "ipprotocol" => "inet",
    "source" => array("network" => "opt3"), "destination" => array("any" => ""),
    "descr" => "Allow ADMIN outbound"
);

// Allow IPsec Firewall
$rules[] = array(
    "type" => "pass", "interface" => "enc0", "ipprotocol" => "inet",
    "source" => array("network" => "10.100.0.0/16"), "destination" => array("network" => "10.10.0.0/16"),
    "descr" => "IPsec Allow Azure"
);

$config['filter']['rule'] = $rules;

// 5. IPsec VPN config
$config['ipsec'] = array();
$config['ipsec']['enable'] = true;
$config['ipsec']['client'] = array();
$config['ipsec']['phase1'] = array();
$config['ipsec']['phase2'] = array();

$p1_ikeid = 1;
$config['ipsec']['phase1'][] = array(
    "ikeid" => $p1_ikeid,
    "iketype" => "ikev2",
    "interface" => "wan",
    "remote-gateway" => "20.19.2.95",
    "protocol" => "inet",
    "myid_type" => "address",
    "myid_data" => "37.167.97.30",
    "peerid_type" => "address",
    "peerid_data" => "20.19.2.95",
    "encryption" => array(
        "item" => array(
            array(
                "encryption-algorithm" => array("name" => "aes", "keylen" => "256"),
                "hash-algorithm" => "sha256",
                "dhgroup" => "14"
            )
        )
    ),
    "lifetime" => "28800",
    "pre-shared-key" => "SmartOfficeVPN2026Secure",
    "private-key" => "",
    "certref" => "",
    "caref" => "",
    "authentication_method" => "pre_shared_key",
    "descr" => "Azure VPN P1",
    "nat_traversal" => "on"
);

$config['ipsec']['phase2'][] = array(
    "ikeid" => $p1_ikeid,
    "uniqid" => uniqid(),
    "mode" => "tunnel",
    "reqid" => "1",
    "localid" => array("type" => "network", "address" => "10.10.0.0", "netbits" => "16"),
    "remoteid" => array("type" => "network", "address" => "10.100.0.0", "netbits" => "16"),
    "protocol" => "esp",
    "encryption-algorithm-option" => array(array("name" => "aes", "keylen" => "256")),
    "hash-algorithm-option" => array("sha256"),
    "pfsgroup" => "14",
    "lifetime" => "3600",
    "pinghost" => "",
    "descr" => "Azure VPN P2"
);

write_config("Automated config by Antigravity");
filter_configure();
system_routing_configure();
setup_gateways_monitor();
ipsec_configure();
services_dhcpd_configure();

echo "CONFIG_APPLIED_SUCCESSFULLY\\n";
?>"""

def configure():
    try:
        client = paramiko.SSHClient()
        client.set_missing_host_key_policy(paramiko.AutoAddPolicy())
        print("Connecting to pfSense...")
        client.connect("192.168.2.145", username="root", password="pfsense", timeout=10)
        
        # Upload script
        sftp = client.open_sftp()
        with sftp.file('/root/apply_config.php', 'w') as f:
            f.write(PHP_SCRIPT)
        sftp.close()
        
        print("Executing configuration script on pfSense...")
        stdin, stdout, stderr = client.exec_command("php /root/apply_config.php")
        out = stdout.read().decode('utf-8')
        err = stderr.read().decode('utf-8')
        
        if "CONFIG_APPLIED_SUCCESSFULLY" in out:
            print("SUCCESS: Configuration applied completely.")
        else:
            print(f"FAILED. Output:\n{out}\nError:\n{err}")
            
        # Re-enable webgui just in case it crashes
        client.exec_command("/etc/rc.restart_webgui")
        client.close()
        
    except Exception as e:
        print(f"ERROR: {e}")

if __name__ == "__main__":
    configure()
