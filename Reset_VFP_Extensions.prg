DECLARE INTEGER ShellExecute IN shell32.dll ; 
  INTEGER hndWin,		; && The handle of the program's parent window. In VFP, you will usually set this to 0.
  STRING cAction,		; && The action which is to be performed (see below).
  STRING cFileName,	; && The file (or other 'object') on which the action is to be performed (see below).
  STRING cParams,		; && If the file is an executable program, these are the parameters (if any) which are passed to it in the command line.
  STRING cDir,			; && If the file is an executable program, this is the program's default or start-up directory.
  INTEGER nShowWin	  && 	The program's initial window state (1 = normal, 2 = minimised, 3 = maximised).	

cAction = "runas" && "Open" 	-	Will open as the current user
						&& "runas" 	-	Will Open as the Administrator

LOCAL ARRAY prvaexelis(1)
ADir(prvaexelis, Home()+"\VFP*.exe")

*SET STEP ON 
PRVCHOMDIR = Home()
PRVCVFPEXE = IIF(ALEN(prvaexelis,1) = 2, prvaexelis[2,1], prvaexelis[1,1])		
prvctmpbat = GetEnv("TEMP")+"\Command.bat"
				
TEXT TO PRVCBATCMD NOSHOW TEXTMERGE
	"<<PRVCHOMDIR>><<PRVCVFPEXE>>" /regserver
ENDTEXT

StrToFile(PRVCBATCMD,prvctmpbat,.f.)

ShellExecute(0,cAction,prvctmpbat,"","",1)

*MODIFY FILE (prvctmpbat)
*ERASE (prvctmpbat)