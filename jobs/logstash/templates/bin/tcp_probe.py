import sys
import socket
import time
import argparse

parser = argparse.ArgumentParser(description='Check tcp connectivity')
parser.add_argument('--host', dest='host', type=str, help='target host')
parser.add_argument('--port', dest='port', type=int, help='target port')
parser.add_argument('--interval', dest='interval', type=int, default='3', help='interval to check')
parser.add_argument('--retries', dest='retries', type=int, default='3', help='number of retries')
args = parser.parse_args()

def check_tcp_connectivity(host, port, interval=0, retries=1):
    print('check tcp connectivity %s:%d (interval=%d,retries=%d)' % (host, port, interval, retries))
    s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    for x in range(retries):
        try:
            s.connect((host, port))
            s.close()
            return True
        except socket.error as e:
            time.sleep(interval)

    s.close()
    return False

if check_tcp_connectivity(args.host, args.port, args.interval, args.retries):
    print('OK')
    sys.exit(0)
else:
    print('Failed')
    sys.exit(1)