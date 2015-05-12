
import std.stdio;

//import freshair.DnsForwardingClient;
import freshair.ForwardingClient;
import freshair.NetUtil;

import std.bitmanip;
import gamelibd.net.conn;
import gamelibd.net.exceptionsafefiber;
import std.container.rbtree;


void main(string[] args)
{
	int startCient = 1;
	NetUtil.serverDnsPort = 9992;
	NetUtil.proxyPort = 9990; 		//sock4/5 listen port

	//Task []tasks;

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



	startEventLoop();


}