module ezsockacount.NetUtil;

//import vibe.d;
import std.bitmanip;
import thrift.protocol.compact;
import thrift.protocol.base;
import thrift.transport.memory;
import thrift.transport.base;
import std.stdio;

import std.math;

import gamelibd.net.conn;
import gamelibd.util;


class NetUtil
{
	public static __gshared string serverIp;
	public static __gshared ushort serverPort;
	public static __gshared ushort serverDnsPort;

	public static __gshared ushort clientPort;


	static void printObj(SRC)(ref SRC src)
	{

		write(SRC.stringof,"{");
		foreach (i, type; typeof(SRC.tupleof)) {
			enum name =  SRC.tupleof[i].stringof;
			writeFlush(name,":",__traits(getMember, src, name), ",");
		}
		writeFlush("}");

	}

	/**
	 * will block current task until forwarding of both directions ends. 
	 */
	static void forwardAndJoin(Ptr!Conn client,Ptr!Conn remote)
	{
		auto wtask = spawn({
				scope(exit)
				{
					client.close();
					remote.close();
				}
				NetUtil.sendTo(client,remote);
			});
		auto wtask2 = spawn({
				scope(exit)
				{
					client.close();
					remote.close();
				}
				NetUtil.sendTo(remote,client);
			});
		
		// wait for the tasks to finish
		wtask.join();
		wtask2.join();
	}

	static void sendTo(Ptr!Conn from,Ptr!Conn to)
	{
		ubyte[512] buf;
		while(true)
		{
			int n = from.readSome(buf);
			if(n>0)
			{
				to.write(buf[0..n]);
			}
			if(from.isEof())
			{
				break;
			}
		}
	}

	static ubyte[] readPacket(Ptr!Conn conn)
	{
		ubyte[4] lendata;
		conn.read(lendata);
		int len = std.bitmanip.littleEndianToNative!int(lendata);
		ubyte[] data = new ubyte[len];
		conn.read(data);
		return data;
	}
	
	static T deserialObj(T)(const (ubyte)[] data) 
	{
		T obj;
		auto trans = new TMemoryBuffer(data);
		auto prot = new TCompactProtocol!TMemoryBuffer(trans);
		obj.read(prot);
		return obj;
	}

	static void writePacket(Ptr!Conn conn,ubyte[] data)
	{
		ubyte[] lendata = std.bitmanip.nativeToLittleEndian!(int)(cast(int)data.length); 
		conn.write(lendata);
		conn.write(data);
	}
	
	static ubyte[] serialObj(T) (ref T obj)
	{
		auto trans = new TMemoryBuffer();
		auto prot = new TCompactProtocol!TMemoryBuffer(trans);
		obj.write(prot);
		auto ret = trans.getContents().dup();
		return ret;
	}

	static void closeTcpConn(Ptr!Conn conn)
	{
		conn.close();
	}

	/**
	 * std time in milliseconds
	 */
	public static long utcNow()
	{
		import std.datetime;
		long stdtime = Clock.currStdTime();

		import core.time;
		auto ret = convert!("hnsecs", "msecs")(stdtime - 621_355_968_000_000_000L);

		return ret;
	}
}

