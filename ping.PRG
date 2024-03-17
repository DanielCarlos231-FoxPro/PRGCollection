LOCAL obj
obj = CREATEOBJECT("Ping")

clear
WITH obj
	? "["+CHR(13)+ nvl(.Ping("142.250.218.67"),"null")+"]"
	? "["+CHR(13)+ nvl(.Ping("142.250.218.67"),"null")+"]"
	? "["+CHR(13)+ nvl(.Ping("142.250.218.67"),"null")+"]"
	? "["+CHR(13)+ nvl(.Ping("142.250.218.67"),"null")+"]"

*	? .Ping("192.168.100.100")
*	? .Ping("192.168.100.100")
*	? .Ping("192.168.100.100")
*	? .Ping("192.168.100.100")
	
ENDWITH
* end of main

DEFINE CLASS Ping As Custom
#DEFINE CRLF CHR(13)+CHR(10)
PROTECTED ippacked
	errorcode=0
	host=""
	hostalias=""
	ipaddress=""
	ippacked=0
	timeout=5000
	rtt=0  && Round trip time, in milliseconds

PROCEDURE Init
	THIS.declare
	= WSAStartup(0x202, REPLICATE(CHR(0),512))

PROCEDURE Destroy
	= WSACleanup()

PROCEDURE ToString
	IF .errorcode=0
		RETURN "Pinging " + THIS.host +;
			" [" + THIS.ipaddress + "] " + CRLF +;
			"Reply from " + THIS.ipaddress +;
			" time=" + TRANSFORM(THIS.rtt) + CRLF
	ELSE
		RETURN "Ping failed with error code: " +;
			TRANSFORM(THIS.errorcode)
	ENDIF

PROCEDURE Ping(cHost)
#DEFINE INVALID_HANDLE_VALUE -1
	STORE 0 TO THIS.errorcode, THIS.rtt
	IF NOT THIS.ResolveHost(cHost)
		THIS.errorcode=-1
		RETURN THIS.ToString()
	ENDIF
	
	LOCAL hIcmpFile, nResult, cReplyBuffer

	hIcmpFile = IcmpCreateFile()
	IF hIcmpFile = INVALID_HANDLE_VALUE
		THIS.errorcode=-2
		RETURN THIS.ToString()
	ENDIF

	cReplyBuffer = REPLICATE(CHR(0), 1024)

	nResult = IcmpSendEcho(hIcmpFile, THIS.ippacked,;
		Null, 0, Null,;
		@cReplyBuffer, LEN(cReplyBuffer), THIS.timeout)

	THIS.errorcode = buf2dword(SUBSTR(cReplyBuffer,5,4))

	IF THIS.errorcode <> 0
		= IcmpCloseHandle(hIcmpFile)
		RETURN THIS.ToString()
	ENDIF

	THIS.rtt = buf2dword(SUBSTR(cReplyBuffer,9,4))
	= IcmpCloseHandle(hIcmpFile)
RETURN THIS.ToString()

FUNCTION ResolveHost(cHost)
	STORE "" TO THIS.host, THIS.hostalias, THIS.ipaddress
	THIS.ippacked = 0

	LOCAL hBuffer, nSize, cBuffer, nBufsize,;
		nOffset, cIP, ex As Exception
	
	TRY
		hBuffer = gethostbyname( m.cHost )
	CATCH TO ex
	ENDTRY

	IF VARTYPE(m.ex)="O" OR hBuffer = 0
		RETURN .F.
	ENDIF

	* parse HOSTENT structure
	nBufsize = GlobalSize(hBuffer)

	cBuffer = REPLICATE(Chr(0), nBufsize)
	cIP = REPLICATE(Chr(0), 4)

	IF NOT MemoryToString(@cBuffer, hBuffer, nBufsize)
		RETURN .F.
	ENDIF

	nOffset = buf2dword(SUBSTR(cBuffer,1,4)) - hBuffer + 1
	THIS.host = THIS.GetString(cBuffer, nOffset)

	nOffset = buf2dword(;
		SUBSTR(cBuffer,5,4)) - hBuffer + 1

	nOffset = buf2dword(;
		SUBSTR(cBuffer,nOffset,4)) - hBuffer + 1

	THIS.hostalias = THIS.GetString(cBuffer, nOffset)
	
	IF NOT MemoryToString(@cIP, buf2dword(SUBS(cBuffer,13,4)),4)
		RETURN .F.
	ENDIF
	
	IF NOT MemoryToString(@cIP, buf2dword(cIP),4)
		RETURN .F.
	ENDIF

	THIS.ippacked = buf2dword(m.cIP)
	THIS.ipaddress = inet_ntoa(THIS.ippacked)

RETURN (THIS.ippacked <> 0)

PROTECTED FUNCTION GetString(cBuffer, nOffset)
	LOCAL cResult, cChar
	cResult = ""
	DO WHILE BETWEEN(nOffset, 1, LEN(cBuffer))
		cChar = SUBSTR(cBuffer, nOffset, 1)
		IF m.cChar = CHR(0)
			EXIT
		ENDIF
		cResult = m.cResult + m.cChar
		nOffset = m.nOffset + 1
	ENDDO
RETURN m.cResult

PROTECTED PROCEDURE declare
	DECLARE INTEGER WSACleanup IN ws2_32
	DECLARE INTEGER IcmpCreateFile IN icmp

	DECLARE INTEGER gethostbyname IN ws2_32;
		STRING host

	DECLARE INTEGER GlobalSize IN kernel32;
		INTEGER hMem

	DECLARE STRING inet_ntoa IN ws2_32;
		INTEGER in_addr

	DECLARE INTEGER IcmpCloseHandle IN icmp;
		INTEGER IcmpHandle

	DECLARE INTEGER IcmpSendEcho IN icmp;
		INTEGER IcmpHandle, INTEGER DestAddr,;
		STRING @RequestData, LONG RequestSize,;
		STRING @RequestOptions, STRING @ReplyBuf,;
		LONG ReplySize, LONG tmout

	DECLARE INTEGER WSAStartup IN ws2_32;
		INTEGER wVerRq, STRING lpWSAData

	DECLARE RtlMoveMemory IN kernel32 As MemToStr;
		STRING @Dest, INTEGER Src, INTEGER nLength

ENDDEFINE

FUNCTION buf2dword(lcBuffer)
RETURN Asc(SUBSTR(lcBuffer, 1,1)) + ;
	BitLShift(Asc(SUBSTR(lcBuffer, 2,1)), 8) +;
	BitLShift(Asc(SUBSTR(lcBuffer, 3,1)), 16) +;
	BitLShift(Asc(SUBSTR(lcBuffer, 4,1)), 24)

FUNCTION MemoryToString( cDst, nAddr, nSize ) As Boolean
	IF m.nSize <= 0
		RETURN .F.
	ENDIF

	LOCAL ex As Exception
	TRY
		= MemToStr(@cDst, m.nAddr, m.nSize)
	CATCH TO ex
	ENDTRY
RETURN VARTYPE(m.ex) <> "O"  