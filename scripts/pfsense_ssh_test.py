import paramiko
import sys

def get_config():
    try:
        client = paramiko.SSHClient()
        client.set_missing_host_key_policy(paramiko.AutoAddPolicy())
        client.connect("192.168.2.145", username="root", password="pfsense", timeout=10)
        
        stdin, stdout, stderr = client.exec_command("cat /conf/config.xml")
        config_xml = stdout.read().decode('utf-8')
        
        with open("config_backup.xml", "w") as f:
            f.write(config_xml)
            
        print(f"SUCCESS: config.xml downloaded, {len(config_xml)} bytes.")
        
        client.close()
    except Exception as e:
        print(f"ERROR: {e}")

if __name__ == "__main__":
    get_config()
