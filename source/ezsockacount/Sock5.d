module freshair.Sock5;

//import vibe.d;
import std.bitmanip;

import std.stdio;
import freshair.NetUtil;

import gamelibd.util;

import gamelibd.net.conn;

class Sock5
{
	class CsVer
	{
		public ubyte ver = 5;		//版本为5
		public ubyte nmethods;		//支持的认证个数
		public ubyte[] methods;
		
		public void fromBuffer(ubyte[] buf)
		{
			ver = buf[0];
			nmethods = buf[1];
			methods = methods[2..2+nmethods].dup();
		}
		
		public void recvExceptVer(Ptr!Conn conn)
		{
			ubyte [260]buf;
			ubyte[] head = buf[0..1];
			conn.read(head);
			nmethods = head[0];
			ubyte[] tmp = buf[0..nmethods];
			conn.read(tmp);
			this.methods = tmp.dup();
		}
	}
	
	class ScVer
	{
		ubyte ver=5;	//TODO 或许是5
		ubyte method; 	//0,无需认证
		
		public void send(Ptr!Conn conn)
		{
			ubyte[2] buf;
			buf[0] = ver;
			buf[1] = method;
			conn.write(buf);
		}
	}
	
	class CsForward
	{
		ubyte ver=5;	//5
		ubyte cmd;		//1 connect,2 bind,3 udp associate
		ubyte rsv=0;	//0
		ubyte atyp;		// dstaddr类型:1 ipv4地址, 3 全称域名，4 ipv6
		ubyte[] dstaddr;//若为ipv4，bigendian 4字节int；
						//若为域名 1字节长度+域名（没有\0）
						//若为ipv6，则是16字节
		ushort dstport;	//bigendian short.
		
		public void recv(Ptr!Conn conn)
		{
			ubyte[260] buf;
			ubyte[] tmp = buf[0..4];
			conn.read(tmp);
			ver = tmp[0];
			cmd = tmp[1];
			rsv = tmp[2];
			atyp = tmp[3];
			if(atyp==1)
			{
				tmp = buf[0..6];
				conn.read(tmp);
				dstaddr = tmp[0..4].dup();
				dstport = std.bitmanip.bigEndianToNative!(ushort,2)(tmp[4..6]);
			}else if(atyp==3)
			{
				tmp = buf[0..1];
				conn.read(tmp);
				ubyte n = tmp[0];
				tmp = buf[0..n+2];
				conn.read(tmp);
				dstaddr ~= n;
				dstaddr ~= tmp[0..n];
				ubyte[2] portarr = tmp[n..n+2];
				dstport = std.bitmanip.bigEndianToNative!(ushort,2)(portarr);
			}else if(atyp==4)
			{
				tmp = buf[0..18];
				conn.read(tmp);
				dstaddr = tmp[0..16].dup();
				dstport = std.bitmanip.bigEndianToNative!(ushort,2)(tmp[16..18]);
			}
		}
		
		public string ip()
		{
			if(atyp==1)
			{
				import std.string;
				string ret = format("%s.%s.%s.%s",dstaddr[0],dstaddr[1],dstaddr[2],dstaddr[3]);
				return ret;
			}else if(atyp==3)
			{
				return cast(string)(dstaddr[1..dstaddr.length]);
			}
			return null;
		}
	}
	
	class ScForward
	{
		ubyte ver=5;		
		ubyte rep;		//0 成功，1失败
		ubyte rsv =	0 ;
		ubyte atyp;
		ubyte[] bndaddr;	//proxyserver端地址
		ushort bndport;
		
		public void send(Ptr!Conn conn)
		{
			ubyte[4+4+2] buf;
			buf[0] = ver;
			buf[1] = rep;
			buf[2] = rsv;
			buf[3] = atyp;
			buf[4..8] = bndaddr[0..4];
			buf[8..10] = std.bitmanip.nativeToBigEndian(bndport);
			conn.write(buf);
		}
	}
	
	public void tryForward(Ptr!Conn client)
	{
		scope(exit) NetUtil.closeTcpConn(client);
		CsVer ver = new CsVer();
		ver.recvExceptVer(client);
		//debug NetUtil.printObj(ver);
		
		ScVer rspVer = new ScVer();
		rspVer.method = 0;
		rspVer.send(client);
		
		CsForward req = new CsForward();
		req.recv(client);
		//debug NetUtil.printObj(req);
		if(req.atyp==4)
		{// ignore ipv6
			return;
		}

		Ptr!Conn remote = connect(req.ip,req.dstport);
		if(remote is null) return;
		scope(exit) NetUtil.closeTcpConn(remote);

		ScForward rspForward = new ScForward();
		rspForward.rep = 0;
		rspForward.atyp = 1;
		ubyte[4] ip = remote.getLocalIpBytes();
		rspForward.bndaddr = ip.dup();
		rspForward.bndport = remote.getLocalPort();
		rspForward.send(client);

		NetUtil.forwardAndJoin(client,remote);
	}
}

