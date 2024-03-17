

MessageBox(Getwinversion())
	


*** <summary>
*** procedure que pega a versão do Windows 
*** </summary>
*** <param name="tnType">Tipo de consulta</param>
*** <remarks></remarks>
FUNCTION GetWinVersion
Lparameters tnType
* Similar to VFP9 OS() function, returning the correct Win version for Windows 10
* 1 - Specifies that the name and version number of the operating system is returned.
* 3 - Identifies the major version number of the operating system. For example, for Windows 2000, the major number is 5.
*     For Windows 10, the major number is 10.
* 4 - Identifies the minor version number of the operating system. For example, for Windows 2000, the minor version number is 0.
* 5 - Identifies the build number of the operating system.


* OSVERSIONINFOA structure (winnt.h)
* https://docs.microsoft.com/en-us/windows/win32/api/winnt/ns-winnt-osversioninfoa
*!*	typedef struct _OSVERSIONINFOA {
*!*	  DWORD dwOSVersionInfoSize;
*!*	  DWORD dwMajorVersion;
*!*	  DWORD dwMinorVersion;
*!*	  DWORD dwBuildNumber;
*!*	  DWORD dwPlatformId;
*!*	  CHAR  szCSDVersion[128];
*!*	} OSVERSIONINFOA, *POSVERSIONINFOA, *LPOSVERSIONINFOA

*!*	The following table summarizes the values returned by supported versions of Windows. 
*!*	Use the information in the column labeled "Other" to distinguish between operating systems with identical version numbers.

*!*	Operating system	 Version dwMajorVersion	dwMinorVersion	Other
*!*	Windows 10	           10.0*		    10		0	
*!*	Windows Server 2016	   10.0*		    10		0	
*!*	Windows 8.1	            6.3*		     6		3	
*!*	Windows Server 2012 R2	6.3*		     6		3	
*!*	Windows 8	            6.2		         6		2	
*!*	Windows Server 2012	    6.2	    	     6		2	
*!*	Windows 7	            6.1	    	     6		1	
*!*	Windows Server 2008 R2	6.1	    	     6		1	
*!*	Windows Server 2008	    6.0	    	     6		0	
*!*	Windows Vista	        6.0	    	     6		0	
*!*	Windows Server 2003 R2	5.2	    	     5		2	
*!*	Windows Server 2003	    5.2	    	     5		2	
*!*	Windows XP	            5.1	    	     5		1	
*!*	Windows 2000	        5.0	    	     5		0	
*!*	* For applications that have been manifested for Windows 8.1 or Windows 10. Applications not manifested for Windows 8.1 or Windows 10 will return the Windows 8 OS version value (6.2). To manifest your applications for Windows 8.1 or Windows 10, refer to Targeting your application for Windows.

LOCAL lcOS, lcOsVersionInfo, lcReturn, lcVersion, lnBuild, lnMajor, lnMinor, lnPlatformId, lnRet, lnSize

* https://docs.microsoft.com/en-us/windows/win32/devnotes/rtlgetversion
DECLARE INTEGER RtlGetVersion IN NTDLL.DLL STRING @lcOsVersionInfo

m.lcOsVersionInfo = REPLICATE(CHR(0), 148) && Initialize osVersionInfo structure
m.lnRet = RtlGetVersion( @m.lcOsVersionInfo )

m.lnSize = CTOBIN(SUBSTR(m.lcOsVersionInfo, 1, 2), "2RS") && DWORD dwlcOsVersionInfoSize
m.lnMajor = CTOBIN(SUBSTR(m.lcOsVersionInfo, 5, 4), "4RS") && DWORD dwMajorVersion
m.lnMinor = CTOBIN(SUBSTR(m.lcOsVersionInfo, 9, 4), "4RS") && DWORD dwMinorVersion
m.lnBuild = CTOBIN(SUBSTR(m.lcOsVersionInfo, 13, 4), "4RS") && DWORD dwBuildNumber
m.lnPlatformId = CTOBIN(SUBSTR(m.lcOsVersionInfo, 17, 4), "4RS") && DWORD dwPlatformId
m.lcVersion = SUBSTR(m.lcOsVersionInfo, 21) && CHAR  szCSDVersion[128]

DO CASE

CASE EMPTY(m.tnType)
	DO CASE
	CASE m.lnMajor = 10 AND m.lnMinor = 0
		m.lcOS = "Windows 10"
	CASE m.lnMajor = 6 AND m.lnMinor = 3
		m.lcOS = "Windows 8.1 / Server 2012 R2"
	CASE m.lnMajor = 6 AND m.lnMinor = 2
		m.lcOS = "Windows 8 / Server 2012"
	CASE m.lnMajor = 6 AND m.lnMinor = 1
		m.lcOS = "Windows 7 / Server 2008 R2"
	CASE m.lnMajor = 6 AND m.lnMinor = 0
		m.lcOS = "Windows Vista / Server 2008"
	CASE m.lnMajor = 5 AND m.lnMinor = 2
		m.lcOS = "Windows Server 2003"
	CASE m.lnMajor = 5 AND m.lnMinor = 1
		m.lcOS = "Windows XP"
	CASE m.lnMajor = 5 AND m.lnMinor = 0
		m.lcOS = "Windows 2000"
	OTHERWISE
	ENDCASE
	m.lcReturn = m.lcOS + " " + TRANSFORM(m.lnMajor) + "." + TRANSFORM(m.lnMinor) + " build " + TRANSFORM(m.lnBuild)

CASE m.tnType = 1
	m.lcReturn = "Windows " + TRANSFORM(m.lnMajor) + "." + TRANSFORM(m.lnMinor)

CASE INLIST(m.tnType, 2, 6, 7, 8, 9, 10, 11)
	m.lcReturn = ""

CASE m.tnType = 3
	m.lcReturn = TRANSFORM(m.lnMajor)

CASE m.tnType = 4
	m.lcReturn = TRANSFORM(m.lnMinor)

CASE m.tnType = 5
	m.lcReturn = TRANSFORM(m.lnBuild)

OTHERWISE
	m.lcReturn = ""

ENDCASE
RETURN m.lcReturn