module ezsockacount.SpeedLimitForwarder;

import ezsockacount.NetUtil;
//import vibe.d;
import gamelibd.net.conn;;

class SpeedLimitForwarder
{
	private
	{
		int _speedLimit = 300000;
		long bytes = 0;
		long startTime;
	}

	this()
	{
		startTime = NetUtil.utcNow();
	}

	@property int speedLimit()
	{
		return _speedLimit;
	}

	@property void speedLimit(int limit)
	{
		this._speedLimit = limit;
	}

	public void tryForward(Ptr!Conn client,Ptr!Conn server)
	{
		auto wtask = spawn({
					forward(client,server);
			});
		auto wtask2 = spawn({
					forward(server,client);
			});
		
		// wait for the tasks to finish
		wtask.join();
		wtask2.join();
	}

	private void checkSpeedLimit()
	{
		import gamelibd.util;
		long speed = bytes/((NetUtil.utcNow()-startTime)/1000+1);

		bool blocked = false;

		//debug writeFlush("speed : ",speed);

		while(speed>_speedLimit)
		{
			if(!blocked)
			{
				debug writeFlush("blocked....................");
			}
			blocked = true;
			ExceptionSafeFiber.sleep(330);
			speed = bytes/((NetUtil.utcNow()-startTime)/1000+1);
		}

		if(blocked)
		{
			import gamelibd.util;
			debug writeFlush("deblocked.....");
		}

		if(bytes>1000*1000) //1M
		{
			bytes = 0;
			startTime = NetUtil.utcNow();
		}
	}

	private void forward(Ptr!Conn from,Ptr!Conn to)
	{
		scope(exit)
		{
			from.close();
			to.close();
		}

		ubyte[1400] buf;
		while(true)
		{
			int size = from.readSome(buf);
			if(size>0)
			{
				to.write(buf[0..size]);
				bytes+=size;
				checkSpeedLimit();
			}else if(from.isEof())
			{
				break;
			}else
			{
				ExceptionSafeFiber.sleep(300);
			}
		}
	}
}

