#include <cstdlib>
#include <fstream>
#include <iostream>
#include <sstream>
using namespace std;

// TODO: Parse other column from "/proc/net/tcp"
// sl  local_address rem_address   st tx_queue rx_queue tr tm->when retrnsmt   uid  timeout inode
// 0: 00000000:1F40 00000000:0000 0A 00000000:00000000 00:00000000 00000000     0        0 1394034504 1 ffff880436fcd7c0 99 0 0 10 -1

static const string PROC_TCP_FILE = "/proc/net/tcp";

// Get Ip address and port number from string XXXXXXXX:XXXX
static string GetIpAddress(char *str)
{
	int a, b, c, d, e;
	sscanf(str, "%02x%02x%02x%02x:%04x", &a, &b, &c, &d, &e);
	ostringstream oss;
	// return by order: d.c.b.a:e
	oss << d << "." << c << "." << b << "." << a << ":" << e ;
	return oss.str();
}

// Get tcp connection state
static string GetConnectionState(char *str)
{
	static const char *status[] = { "ERROR_STATUS", "TCP_ESTABLISHED", "TCP_SYN_SENT",
					"TCP_SYN_RECV", "TCP_FIN_WAIT1", "TCP_FIN_WAIT2",
					"TCP_TIME_WAIT", "TCP_CLOSE", "TCP_CLOSE_WAIT",
					"TCP_LAST_ACK", "TCP_LISTEN", "TCP_CLOSING"};

	if (str[0] == '0') {
		char ch = str[1];
		if (ch >= '0' && ch <= '9') {
			return status[static_cast<int>(ch-'0')];
		}
		if (ch == 'A' || ch == 'B') {
			return status[static_cast<int>(ch-'A'+10)];
		}
	}

	return "UNKNOWN_STATE";
}

int main()
{
	ifstream proc_tcp_file(PROC_TCP_FILE.c_str()); // FIXME: gcc-5 can't use ifstream proc_tcp_file(PROC_TCP_FILE);
	if (!proc_tcp_file) {
		cerr << "open ""<< error!" << endl;
		exit(1);
	}
	string line;
	char local_addr[20], remote_addr[20], state[20];
	getline(proc_tcp_file, line); // title: every column's name
	while (getline(proc_tcp_file, line)) {
		sscanf(line.c_str(), "%*s%s%s%s", local_addr, remote_addr, state);
		string ip_local = GetIpAddress(local_addr);
		string ip_remote = GetIpAddress(remote_addr);
		string conn_state = GetConnectionState(state);
		cout << ip_local << "\t" << ip_remote << "\t" << conn_state << endl;
	}
	return 0;
}
