//module freshair.DnsForwardingClient;
//
//import gamelibd.net.conn;
//import gamelibd.util;
//
//import std.stdio;
//import freshair.Dns;
//import freshair.NetUtil;
//
//class DnsCache
//{
//	int cachePeriod = 60*2*1000; 				//cache dns result for 2 minutes
//	__gshared long[ubyte[]] cacheTime;
//	__gshared ubyte[][ubyte[]] resultCache;
//
//	public void cache(Dns rsp)
//	{
//		if(!rsp.isSuc() || rsp.getQueryCount()!=1)
//		{
//			return;
//		}
//
//		const ubyte[] key = rsp.getFirstQuery();
//		resultCache[key] = rsp.data;
//		cacheTime[key] = NetUtil.utcNow();
//	}
//
//	public ubyte[] getCache(Dns req)
//	{
//		if(req.getQueryCount()!=1)
//		{
//			return null;
//		}
//
//		ubyte[] key = req.getFirstQuery();
//		ubyte[] ret = resultCache.get(key,null);
//		if(ret is null)
//		{
//			return ret;
//		}
//
//		long time = cacheTime.get(key,0);
//		if(NetUtil.utcNow()-time>cachePeriod)
//		{
//			return null;
//		}
//		return ret;
//	}
//}
//
//class DnsForwardingClient
//{
//	private 
//	{
//		string remoteIp;
//		int remotePort;
//		string listenIp;
//		int listenPort;
//
//		long REQTIMEOUT = 10*1000;
//		long cleanTimeOutStamp ;					//清理无响应请求动作的时间戳
//
//		__gshared DnsCache cache;
//		__gshared ushort tidseq;
//		__gshared WaitingReq[ushort] waitingReqMap;
//	}
//
//	public this(string remoteIp,int remotePort,string listenIp,int listenPort)
//	{
//		this.remoteIp = remoteIp;
//		this.remotePort = remotePort;
//		this.listenIp = listenIp;
//		this.listenPort = listenPort;
//
//		cache = new DnsCache;
//
//		tidseq = cast(ushort)(NetUtil.utcNow()/1000%(ushort.max));
//		cleanTimeOutStamp = NetUtil.utcNow();
//	}
//
//	class WaitingReq
//	{
//		ushort serverTid;
//		ushort clientTid;
//		addrtransform clientAddr;
//		long timestamp;
//
//		this()
//		{
//			timestamp = NetUtil.utcNow();
//		}
//	}
//
//	public void start()
//	{
//		Ptr!UdpConn listener = createUdpServe(listenIp,cast(ushort)listenPort);
//		Ptr!UdpConn sender = createUdp();
//		//sender.connect(remoteIp,cast(ushort)remotePort);
//
//		runTask({
//				while(true)
//				{
//					try{
//						cleanUpTimeout();
//
//						WaitingReq req = new WaitingReq;
//						ubyte[] data = listener.recv(null,&req.clientAddr);
//						Dns dns = new Dns();
//						dns.data = data;
//						req.clientTid = dns.getTid();
//
//						//try get from cache
//						ubyte[] cached = cache.getCache(dns);
//						if(cached !is null)
//						{
//							dns.data = cached.dup();
//							dns.setTid(req.clientTid);
//							listener.send(dns.data,&req.clientAddr);
//							continue;
//						}
//						
//
//						req.serverTid = nextTid();
//						dns.setTid(req.serverTid);
//						waitingReqMap[req.serverTid] = req;
//						sender.send(dns.data);
//					}catch(Exception e)
//					{
//						sleep(200.msecs);
//						writeln(e.msg);
//					}
//				}
//			});
//
//		runTask(
//			{
//				while(true)
//				{
//					try{
//						ubyte[] data = sender.recv();
//						Dns dns = new Dns();
//						dns.data = data;
//						cache.cache(dns);
//
//						ushort serverTid = dns.getTid();
//						WaitingReq req = waitingReqMap.get(serverTid,null);
//						waitingReqMap.remove(serverTid);
//
//						if(req !is null)
//						{
//							dns.setTid(req.clientTid);
//							listener.send(dns.data,&req.clientAddr);
//						}
//					}catch(Exception e)
//					{
//						sleep(200.msecs);
//						writeln(e.msg);
//					}
//				}
//			}
//			);
//
//	}
//
//	private void cleanUpTimeout()
//	{
//		if(NetUtil.utcNow()-cleanTimeOutStamp<REQTIMEOUT)
//		{
//			return;
//		}
//
//		cleanTimeOutStamp = NetUtil.utcNow();
//		ushort[] todel;
//		foreach (key, value; waitingReqMap) {
//			if(cleanTimeOutStamp - value.timestamp>REQTIMEOUT)
//			{
//				todel ~= key;
//			}
//		}
//
//		writeln("clean timeout dns request : ",todel.length,
//			" . req set size : ",waitingReqMap.length);
//
//		foreach(key;todel)
//		{
//			waitingReqMap.remove(key);
//		}
//	}
//
//	private ushort nextTid()
//	{
//		return (tidseq++);
//	}
//}
//
