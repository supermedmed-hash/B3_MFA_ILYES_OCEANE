import paramiko
import time

client = paramiko.SSHClient()
client.set_missing_host_key_policy(paramiko.AutoAddPolicy())
print("Connecting to pfSense...")
client.connect("192.168.2.145", username="root", password="pfsense", timeout=10)

# Check current config values
check_cmd = 'php -r \'require_once("config.inc"); global $config; echo "myid=" . $config["ipsec"]["phase1"][0]["myid_data"] . "\n"; echo "remote-gw=" . $config["ipsec"]["phase1"][0]["remote-gateway"] . "\n";\''
stdin, stdout, stderr = client.exec_command(check_cmd)
print("Current config:")
print(stdout.read().decode("utf-8"))

# Force restart IPsec service to reload config
print("Restarting IPsec service...")
client.exec_command("/usr/local/sbin/ipsec restart")
time.sleep(5)

# Check status after restart
stdin, stdout, stderr = client.exec_command("ipsec statusall 2>&1")
output = stdout.read().decode("utf-8")
print("IPsec status after restart:")
print(output)

# Try to initiate the connection
print("Initiating connection...")
client.exec_command("ipsec up con1")
time.sleep(5)
stdin, stdout, stderr = client.exec_command("ipsec statusall 2>&1")
output = stdout.read().decode("utf-8")
print("IPsec status after initiate:")
print(output)

client.close()
print("Done")
