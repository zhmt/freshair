module ezsockacount.ForwardingClient;

//import vibe.d;
import std.bitmanip;
import thrift.protocol.compact;
import thrift.protocol.base;
import thrift.transport.memory;
import thrift.transport.base;
import std.stdio;
import ezsockacount.NetUtil;
import ezsockacount.Sock4;
import ezsockacount.Sock5;
import ezsockacount.SpeedLimitForwarder;

import gamelibd.net.conn;
import gamelibd.util;

/**
 * sock4/5 server
 */ 
class ForwardingClient
{
	private SpeedLimitForwarder limiter ;

	this()
	{
		limiter = new SpeedLimitForwarder;
	}

	void listen()
	{
		Acceptor acc = new Acceptor();
		acc.listen("0.0.0.0",NetUtil.clientPort,100);
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
			sock.tryForward(conn,limiter);
		}else if(buf[0]==5)
		{
			//debug writeFlush("sock5");
			Sock5 sock = new Sock5();
			sock.tryForward(conn,limiter);
		}else
		{
			conn.close();
		}
	}
}





