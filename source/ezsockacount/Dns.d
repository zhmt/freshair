module ezsockacount.Dns;

import std.bitmanip;

union DnsHeaderFlags
{
	ubyte[2] flags;
	mixin(bitfields!(
			ubyte, "reqrsp",    	1,	//0 req, 1 rsp
			ubyte, "opcode",    	4,	//0 query,
			ubyte, "authAnswer", 	1,
			ubyte, "truncate", 		1,
			ubyte, "recursDesired", 1,
			ubyte, "recursAvail", 	1,
			ubyte, "reserved", 		3,	//0
			ubyte, "retCode", 		4));//0,suc,3 dns error
}

class Dns
{
	//========header 2 * 6 = 12
	/*
	ubyte[2] tid;
	Flags flags;
	ubyte[2] queryCount;
	ubyte[2] answerCount;
	ubyte[2] authCount;
	ubyte[2] extCount;
	*/
	//========query entries
	//========answer entries
	//========auth entries
	//========additional entries
	ubyte[] data;
	public ushort getTid()
	{
		return getUshort(data[0..2]);
	}

	public void setTid(ushort tid)
	{
		setUshort(data[0..2],tid);
	}

	public ushort getQueryCount()
	{
		return getUshort(data[4..6]);
	}

	public ubyte isSuc()
	{
		DnsHeaderFlags f;
		f.flags[0..2] = data[2..4];
		return f.retCode;
	}

	/**
	 * include name, type , class
	 */
	public ubyte[] getFirstQuery()
	{
		ubyte[] tmp = data[12..$];
		int end = 0;
		while(tmp[end]!=0)
		{
			end += tmp[end]+1;
		}
		end+=4;
		end++;
		if(end>tmp.length)
		{
			return null;
		}
		return tmp[0..end];
	}

	public static ushort getUshort(ubyte[] dt)
	{
		return bigEndianToNative!short(dt[0..2]);
	}

	public static void setUshort(ubyte[] dt,ushort value)
	{
		dt[0..$] = nativeToBigEndian(value);
	}
}

