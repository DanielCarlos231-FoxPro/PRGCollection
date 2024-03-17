* Some parts of the code from foxpro community; I revised and added some parts!

= GetSQLDrivers()

FUNCTION GetSQLDrivers
	LOCAL lcBuffer, lnBufsize, lnii, lcch, lcName, laReturnVal(1), llRetVal As Boolean  
	m.lnBufsize = 16384
	m.lcBuffer = Repli(Chr(0), m.lnBufsize)
	 
*!*	You (Windows user) have to admin rights for installation -> Todo : if user is not admin; installation will be interrupted! Return FALSE -> check isAdmin .

	DECLARE INTEGER SQLGetInstalledDrivers IN odbccp32;
	    STRING @lpszBuf, INTEGER cbBufMax, INTEGER @pcbBufOut
	 
	IF SQLGetInstalledDrivers(@lcBuffer, m.lnBufsize, @lnBufsize) = 0
	    RETURN
	ENDIF
	 
	CREATE CURSOR csDriverResult (drvname C(150))
	m.lcBuffer = SUBSTR(m.lcBuffer,1,m.lnBufsize)
	m.lcName = ""
	 
	FOR m.lnii=1 TO m.lnBufsize
	    m.lcch = SUBSTR(m.lcBuffer, m.lnii,1)
	    IF m.lcch = Chr(0)
	        INSERT INTO csDriverResult VALUES (m.lcName)
	        m.lcName = ""
	    ELSE
	        m.lcName = m.lcName + m.lcch
	    ENDIF
	ENDFOR
	Browse 
	* Installed drivers in BROWSE no need runtime! 
	SELECT Distinct UPPER(drvname) FROM csDriverResult && You can remove this line safetly! WHERE UPPER(drvname) = "SQL SERVER NATIVE CLIENT 10.0" 
	
	* If you need a spesific driver! Here; Ineed check a spesicik driver : "SQL SERVER NATIVE CLIENT 10.0" ; you can check what you need!
	SELECT Distinct UPPER(drvname) FROM csDriverResult WHERE UPPER(drvname) = "SQL SERVER NATIVE CLIENT 10.0" INTO ARRAY laReturnVal
	
	IF _Tally > 0
		m.llRetVal = .T.
	ELSE
		m.llRetVal = .F.

		DECLARE INTEGER ShellExecute IN Shell32.DLL AS MyShellExecute ;
		   LONG nhWnd, STRING cAction, STRING cFile, ;
		   STRING cParam, STRING cDirectory, INTEGER nShow

		* Slient install of SQL Server Native Client drivers! 32 or 64 bit!
		IF isWindows64Bit() = .F. && 32 Bit windows
			IF FILE(ADDBS(oGu.PathofPrgStart)+"Setup\sqlncli_x86.msi")
				m.lcShellCmd = " /i  "+ADDBS(ogu.PathofPrgStart)+"sqlncli_x86.msi /qb ADDLOCAL=ALL APPGUID={0CC618CE-F36A-415E-84B4-FB1BFF6967E1} IACCEPTSQLNCLILICENSETERMS=YES"
			ENDIF 
		ELSE && 64 bit Windows
			IF FILE(ADDBS(oGu.PathofPrgStart)+"Setup\sqlncli_x64.msi")
				m.lcShellCmd = " /i  "+ADDBS(ogu.PathofPrgStart)+"sqlncli_x64.msi /qb ADDLOCAL=ALL APPGUID={0CC618CE-F36A-415E-84B4-FB1BFF6967E1} IACCEPTSQLNCLILICENSETERMS=YES"
			ENDIF 
		ENDIF

		MyShellExecute(0, NULL, "msiexec.exe", m.lcShellCmd, NULL, 0) && 
		CLEAR DLLS MyShellExecute

		MESSAGEBOX("sqlncli.msi installation started. You can run the software after installation.";
					+ADDBS(ogu.PathofPrgStart) + "SETUP\" + IIF(isWindows64Bit()=.T.,"sqlncli_x64.msi","sqlncli_x86.msi")+CHR(13)+" -> run the program!",0+64,"Attention!")
	
		DECLARE Sleep IN kernel32 INTEGER dwMilliseconds
		Sleep(500)

	ENDIF 

	CLEAR DLLS SQLGetInstalledDrivers 
	USE IN SELECT("csDriverResult") 

	RETURN (m.llRetVal)
ENDFUNC 


*!*	? IsAdmin()
************************************************************************
* wwUtils ::  IsAdmin
****************************************
***  Function: Determines whether user is an admin user by probing
***            access to HKLM registry key
***    Assume:
***      Pass:
***    Return:
************************************************************************
FUNCTION IsAdmin()
	LOCAL loAPI, lcVal

	DECLARE INTEGER IsUserAnAdmin IN Shell32
	TRY
	    lnResult = IsUserAnAdmin()
	CATCH
	    *** OLD OLD Version of Windows assume .T.
	    lnResult = 1
	ENDTRY
	IF lnResult = 0
	   RETURN .F.
	ENDIF

	RETURN .T.  
ENDFUNC

FUNCTION isWindows64bit && Author Sergey Berezniker
	* First determine if IsWow64Process function exists in the OS we're running under
	DECLARE Long GetModuleHandle IN WIN32API STRING lpModuleName
	DECLARE Long GetProcAddress IN WIN32API Long hModule, String lpProcName
	llIsWow64ProcessExists = (GetProcAddress(GetModuleHandle("kernel32"),"IsWow64Process") <> 0)
	 
	llIs64BitOS = .F.
	IF llIsWow64ProcessExists 
		DECLARE Long GetCurrentProcess IN WIN32API 
		DECLARE Long IsWow64Process IN WIN32API Long hProcess, Long @ Wow64Process
		lnIsWow64Process = 0
		* IsWow64Process function return value is nonzero if it succeeds 
		* The second output parameter value will be nonzero if VFP application is running under 64-bit OS 
		IF IsWow64Process( GetCurrentProcess(), @lnIsWow64Process) <> 0
			llIs64BitOS = (lnIsWow64Process <> 0)
		ENDIF	
	ENDIF	

	CLEAR DLLS GetModuleHandle 
	CLEAR DLLS GetProcAddress 
	CLEAR FIELDS 

	Return(m.llIs64BitOS)
ENDFUNC 
