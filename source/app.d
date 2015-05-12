
import std.stdio;

//import vibe.d;
import ezsockacount.DnsForwardingClient;
import ezsockacount.ForwardingServer;
import ezsockacount.ForwardingClient;
import ezsockacount.NetUtil;
//import ezsockacount.Dns;
//import ezsockacount.DnsForwardingClient;
import std.bitmanip;
import gamelibd.net.conn;
import gamelibd.net.exceptionsafefiber;
import std.container.rbtree;


void main(string[] args)
{
	int startServer = 1;
	int startCient = 1;
	NetUtil.serverIp = "127.0.0.1";	//59.188.86.207 forwarding server remote address
	NetUtil.serverPort = 9991;		//forwarding server listenPort
	NetUtil.serverDnsPort = 9992;
	NetUtil.clientPort = 9990; 		//sock4/5 listen port

	//Task []tasks;

	if(startServer!=0)
	{
		auto wtask = spawn({
				ForwardingServer ss = new ForwardingServer();
				ss.listen();
			});
		//tasks ~= wtask;

//		DnsForwardingClient dns = new DnsForwardingClient("8.8.8.8",53,"0.0.0.0",NetUtil.serverDnsPort);
//		dns.start();
	}


	if(startCient!=0)
	{
		auto atask = spawn({
				ForwardingClient acc = new ForwardingClient();
				acc.listen();
			});
		//tasks ~= atask;

//		DnsForwardingClient dns = new DnsForwardingClient(NetUtil.serverIp,NetUtil.serverDnsPort,"0.0.0.0",53);
//		dns.start();
	}




//	foreach( oneTask ; tasks)
//	{
//		oneTask.join();
//	}



//	spawn({
//			Conn conn = connect("www.baidu.com",80);
//			string data = "GET / HTTP/1.1\r\n\r\n";
//			conn.write((cast(ubyte*)data.ptr)[0..data.length]);
//			ubyte[100] buf;
//			while(true)
//			{
//				import gamelibd.util;
//				int n = conn.readSome(buf);
//				writeFlush(cast(string)buf[0..n]);
//			}
//		});

	startEventLoop();


//	macmain();



}