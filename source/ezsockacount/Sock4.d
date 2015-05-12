module ezsockacount.Sock4;

//import vibe.d;
import std.bitmanip;
import thrift.protocol.compact;
import thrift.protocol.base;
import thrift.transport.memory;
import thrift.transport.base;
import std.stdio;
import ezsockacount.NetUtil;
import sock_types;
import ezsockacount.SpeedLimitForwarder;

import gamelibd.net.conn;

class Sock4
{
	class CsPackHeader
	{
		ubyte 	vn;		//SOCK版本，应该是4；
		ubyte 	cd;		//1表示CONNECT请求，2表示BIND请求；
		ushort 	dstport;//目的主机的端口；
		ubyte[4]	dstip;	//目的主机的ip地址
		ubyte[] 	userid;	//包中以\0结束
		
		public void recvExceptVer(Ptr!Conn conn)
		{
			ubyte[2+2+4+256]buf;
			ubyte[] tmp = buf[0..7];
			conn.read(tmp);
			vn = 4;
			cd = tmp[0];
			dstport = bigEndianToNative!(ushort,2)(tmp[1..3]);
			dstip[0..4] = tmp[3..7]; 
			int n = conn.readUtil(tmp,"\0");
			if(n>0)
			{
				userid = tmp[0..n].dup();
			}else
			{
				throw new Exception("failed to recv sock4 head");
			}
		}
		
		public string ip()
		{
			import std.string;
			string ret = format("%s.%s.%s.%s",dstip[0],dstip[1],dstip[2],dstip[3]);
			return ret;
		}
	}
	
	class ScPackHeader
	{
		ubyte 	vn=0;	//回应码的版本，应该是0；
		ubyte 	cd;		//90，请求得到允许；91，请求被拒绝或失败；
		ushort 	dstport;//与请求发送的相同
		ubyte[4]	dstip;	//与请求发送的相同
		
		public void send(Ptr!Conn conn)
		{
			ubyte[2+2+4] buf;
			buf[0]=vn;
			buf[1]=cd;
			buf[2..4] = nativeToBigEndian!(ushort)(dstport)[0..2];
			buf[4..8] = dstip[0..4];
			conn.write(buf);
		}
	}
	
	public void tryForward(Ptr!Conn client,SpeedLimitForwarder limiter)
	{
		CsPackHeader cs = new CsPackHeader();
		cs.recvExceptVer(client);
		//debug NetUtil.printObj(cs);

		Ptr!Conn remote = null; 
		try{
			remote = connect(NetUtil.serverIp,NetUtil.serverPort);
		}catch(Exception e){
			NetUtil.closeTcpConn(client);
			return ;
		}
		
		Cmd cmd;
		cmd.set!("cmdId")(Cmds.Connect);
		Connect connect;
		cmd.set!("connect")(connect);
		cmd.connect.set!("ip")(cs.ip());
		cmd.connect.set!("port")(cs.dstport);
		ubyte[] data = NetUtil.serialObj(cmd);
		NetUtil.writePacket(remote,data);
		
		ScPackHeader sc = new ScPackHeader();
		sc.cd = 90;
		sc.dstport = cs.dstport;
		sc.dstip = cs.dstip;
		sc.send(client);

		limiter.tryForward(client,remote);
	}
}

