module ezsockacount.ForwardingServer;

//import vibe.d;
import gamelibd.net.conn;
import std.bitmanip;
import thrift.protocol.compact;
import thrift.protocol.base;
import thrift.transport.memory;
import thrift.transport.base;
import std.stdio;
import ezsockacount.NetUtil;
import ezsockacount.Sock4;
import ezsockacount.Sock5;
import sock_types;

/**
 * Forwarding server
 */ 
class ForwardingServer
{
	void listen()
	{
		Acceptor acc = new Acceptor();
		acc.listen("0.0.0.0",NetUtil.serverPort,100);
		acc.accept((Ptr!Conn conn){
				handleConn(conn);
			});
	}

	void handleConn(Ptr!Conn client)
	{
		ubyte[] pack = NetUtil.readPacket(client);
		Cmd cmd = NetUtil.deserialObj!(Cmd)(pack);
		//debug NetUtil.printObj(cmd);
		if(cmd.cmdId==Cmds.Connect)
		{
			handleConnect(client,cmd);
		}
	}

	void handleConnect(Ptr!Conn client,ref Cmd cmd)
	{
		scope(exit) client.close();
		Ptr!Conn remote = connect(cmd.connect.ip,cast(ushort)cmd.connect.port);
		scope(exit) remote.close();
		NetUtil.forwardAndJoin(client,remote);
	}
	
	
}

