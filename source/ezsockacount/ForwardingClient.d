module freshair.ForwardingClient;

//import vibe.d;
import std.bitmanip;

import std.stdio;
import freshair.NetUtil;
import freshair.Sock4;
import freshair.Sock5;

import gamelibd.net.conn;
import gamelibd.util;

/**
 * sock4/5 server
 */ 
class ForwardingClient
{

	this()
	{

	}

	void listen()
	{
		Acceptor acc = new Acceptor();
		acc.listen("0.0.0.0",NetUtil.proxyPort,100);
		acc.accept((Ptr!Conn conn){
				handleConn(conn);
			});
	}

	void handleConn(Ptr!Conn conn)
	{
		ubyte[1] buf;
		conn.read(buf);
		
		if(buf[0]==4)
		{
			Sock4 sock = new Sock4();
			sock.tryForward(conn);
		}else if(buf[0]==5)
		{
			//debug writeFlush("sock5");
			Sock5 sock = new Sock5();
			sock.tryForward(conn);
		}else
		{
			conn.close();
		}
	}
}





