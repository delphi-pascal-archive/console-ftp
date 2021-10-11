// pftp : petit ftp en mode console
// OBJECTIVE : an console FTP  with command lines compatible "psftp" (from Putty)
// WHY ? because Putty include Telnet, SSH and SFTP but no FTP
// FINAL OBJECTIVE : to be used from VBS/JS/VBA with CMDOLE.exe interface
// CMDOLE is an interface OLE <=> console soft with input/output redirection
// => from VBS/JS/VBA we will have acces to Telnet, SSH, FTP and SFTP buy OLE links

program pftp;

{$I ICSDEFS.INC}
{$IFDEF VER80}
    Bomb('Sorry, Delphi 1 does not support console mode programs');
{$ENDIF}
{$APPTYPE CONSOLE}
{$IFNDEF NOFORMS}
   // Bomb('Please add NOFORMS to your project defines');
{$ENDIF}
{$R pftp.res}
uses
  Classes,
  SysUtils,
  strutils,
  IdFTP, IdGlobal, IdFTPCommon;

const
  pftpVersion  = 100;
  CopyRight    = 'Console FTP V1.00 - Open Source built with Delphi7 and ICS v5.';

var
   CurrentDir : string;

type
    { We use TConApplication class (actually a component) to encapsulate all }
    { the work to be done. This is easier because TFtpCli is event driven    }
    { and need methods (that is procedure of object) to handle events.       }
    TConApplication = class(TComponent)
    protected
         IdFTP1: TIdFTP;
   public
        constructor Create(AOwner: TComponent); override;
        destructor  Destroy; override;
        procedure   Execute;
        procedure   printout(txt:string);
        procedure   Connect(Cmdln:string);
        procedure   listdir(param1:string);
        procedure   ChangeDir(DirName: String);
        procedure   UploadF(cmdln1: string);
        procedure   DownloadF(cmdln1,param3: string);
        procedure   RenameF(cmdln1: string);
        procedure   DeleteF(param1: string);
        procedure   CreateDir(param1: string);
        procedure   RemoveDir(param1: string);
        procedure   chmod(cmdln:string);
        procedure   getcurrentD;
        procedure   setcurrentD(cmdln:string);
        procedure   gethostcurrentD;
        procedure   createLocdir(cmdln:string);
        procedure   RmLocdir(cmdln:string);
        procedure   LsLocdir(cmdln:string);
        procedure   RenameLF(cmdln:string);
        procedure   DeleteLF(cmdln:string);
        procedure   help(cmdln:string);
    end;

    {* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
constructor TConApplication.Create(AOwner: TComponent);
begin
    inherited Create(AOwner);
 IdFTP1:= TIdFTP.Create(Self);
 IdFTP1.Passive := False;
 IdFtp1.Intercept := nil;
end;

{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
destructor TConApplication.Destroy;
begin
    if Assigned(IdFTP1) then begin
       IdFTP1.Destroy;
       IdFTP1 := nil;
    end;
    inherited Destroy;
end;

{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
procedure TConApplication.Execute;
var
  cmd, cmdln : string;
  i : byte;
begin

// first step : analyser la ligne de paramêtre
  if ParamCount <> 0 then
  begin
    for i := 1 to paramcount do
    begin
      Cmdln := Cmdln + ' '+ ParamStr(i);
    end ;
    Cmdln := trim(Cmdln)+ ' ';
    connect(CmdLn);
  end
  else
    printout('pftp: no hostname specified; use "open [user@]host [port] [-pw password]" to connect');

// second step : command line received analysis and execution
  repeat
    write('pftp>');
    flush(output);
    readln(Cmdln);
    sleep(50);
    Cmdln := trim(Cmdln)+ ' ';
    Cmd := (leftstr(Cmdln,pos(' ',Cmdln)-1 ));
    Cmdln := trimleft(midstr(Cmdln,pos(' ',Cmdln),100));
    if Cmd = '!dir'   then lsLocdir(Cmdln)            else
    if Cmd = '!mkdir' then createLocdir(Cmdln)        else
    if Cmd = '!rmdir' then RmLocdir(Cmdln)            else
    if Cmd = '!ren'    then RenameLF(Cmdln)           else
    if Cmd = '!del'    then deleteLF(Cmdln)           else

    if Cmd = 'cd'     then changedir(Cmdln)           else
    if Cmd = 'chmod'  then chmod(cmdln)               else //modif attributs
    if Cmd = 'del'    then deleteF(Cmdln)             else
    if Cmd = 'dir'    then listdir(cmdln)             else
    if Cmd = 'get'    then downloadF(cmdln,'Replace') else
    if Cmd = 'help'   then help(Cmd)                  else
    if Cmd = 'lcd'    then SetCurrentD(Cmdln)         else
    if Cmd = 'lpwd'   then GetCurrentD                else
    if Cmd = 'ls'     then listdir(cmdln)             else
    if Cmd = 'mkdir'  then CreateDir(Cmdln)           else
    if Cmd = 'mv'     then RenameF(Cmdln)             else
    if Cmd = 'open'   then connect(Cmdln)             else
    if Cmd = 'put'    then UploadF(cmdln)             else
    if Cmd = 'pwd'    then gethostcurrentD            else
    if Cmd = 'reget'  then downloadF(cmdln,'Resume')  else
    if Cmd = 'ren'    then RenameF(Cmdln)             else
    if Cmd = 'reput'  then UploadF(cmdln)             else
    if Cmd = 'rm'     then DeleteF(Cmdln)             else
    if Cmd = 'rmdir'  then RemoveDir(Cmdln)           else
    if Cmd = 'quit'   then break                      else
    if Cmd = 'exit'   then break                      else
    if Cmd = 'Bye'    then break                      else
      printout('pftp: unknown command "'+cmdln+'"') ;

  until false;
  writeln('end of pftp session');
  flush(output);
  sleep(1000);

end;

{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
procedure  TConApplication.gethostcurrentD;
begin
  if IdFTP1.Connected then
  begin
    try try
      currentdir := idftp1.RetrieveCurrentDir ;
      printout('Remote directory is now '+currentdir);
    except on E : Exception do begin
      printout(ansireplaceText('pftp:  '+E.Message,#13+#10,'   '));
    end; end;
    finally
    end;
  end
  else printout('pftp: not connected to a host; use "open user@host"');
 end;

{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
procedure TConApplication.RenameLF(cmdln:string);
var param1, param2:string;
begin
  param1 := trim(leftstr(Cmdln,pos(' ',Cmdln)-1 ));
  param2 := trim(midstr(Cmdln,pos(' ',Cmdln),100));
    try try
      if not sysutils.renamefile(param1,param2)then
      printout('pftp: wrong file names : '+ param1 + ' '+ param2);
    except on E : Exception do begin
      printout(ansireplaceText('pftp:  '+E.Message,#13+#10,'   '));
    end; end;
    finally
    end;
end;

{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
procedure TConApplication.DeleteLF(cmdln:string);
begin
  try try
    if not sysutils.deletefile(trim(cmdln))then
    printout('pftp: wrong file name : '+ cmdln);
  except on E : Exception do begin
    printout(ansireplaceText('pftp:  '+E.Message,#13+#10,'   '));
  end; end;
  finally
  end;
end;

{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
procedure TConApplication.LsLocdir(cmdln:string);
var Info   : TSearchRec;
  ligne,tmp : string;
begin
  if trim(cmdln)= '' then cmdln := '*.*'
  else cmdln := trim(cmdln);
  If FindFirst(getcurrentdir+'\'+cmdln,faAnyFile,Info)=0 Then
  Begin
    Repeat
      ligne := leftstr(datetimetostr(FileDateToDateTime(info.Time)),16)+'    ';
      tmp := rightstr('                '+inttostr(info.Size),12);
      tmp := leftstr(tmp,6)+' '+midstr(tmp,7,3)+' '+rightstr(tmp,3);
      if ((info.FindData.dwFileAttributes or 16) = 16) then ligne := ligne + '<DIR>         '
      else
      ligne := ligne + tmp;
      printout(ligne+' ' +info.Name);
    Until FindNext(Info)<>0;
    FindClose(Info);
  end;
end;

{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
procedure TConApplication.RmLocdir(cmdln:string);
begin
  try try
    if not sysutils.removedir(trim(cmdln))then
    printout('pftp: wrong file name : '+ cmdln);
  except on E : Exception do begin
    printout(ansireplaceText('pftp: '+E.Message,#13+#10,'   '));
  end; end;
  finally
  end;
end;

{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
procedure TConApplication.createLocdir(cmdln:string);
begin
  if pos(':\',cmdln) = 0 then cmdln := getcurrentdir + '\'+ cmdln;
  try try
    if not sysutils.createdir(trim(cmdln))then
    printout('pftp: wrong file name : '+ cmdln);
  except on E : Exception do begin
    printout(ansireplaceText('pftp: '+E.Message,#13+#10,'   '));
  end; end;
  finally
  end;
end;

{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
procedure TConApplication.setcurrentD(cmdln:string);
begin
    try try
      if not SetCurrentDir(trim(cmdln))then
      printout('pftp: wrong file name : '+ cmdln);
      printout('Current local directory : '+ getcurrentdir);
    except on E : Exception do begin
      printout(ansireplaceText('pftp: '+E.Message,#13+#10,'   '));
    end; end;
    finally
    end;
end;

{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
procedure TConApplication.getcurrentD;
var txt:string;
begin
  txt := GetCurrentDir;
  printout('Current local directory : '+ txt);
end;

{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
procedure TConApplication.chmod(cmdln:string);
var param1, param2:string;
begin
  param1 := trim(leftstr(Cmdln,pos(' ',Cmdln)-1 ));
  param2 := trim(midstr(Cmdln,pos(' ',Cmdln),100));
  if IdFTP1.Connected then
  begin
    try try
      IdFTP1.Site('chmod '+ param1 + ' '+ param2);
    except on E : Exception do begin
      printout(ansireplaceText('pftp: '+E.Message,#13+#10,'   '));
    end; end;
    finally
    end;
  end
  else printout('pftp: not connected to a host; use "open user@host"');
end;

{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
procedure TConApplication.Connect(cmdln:string);
var cmd:string;
begin
  IdFTP1.port := 21;
  IdFTP1.Username := 'anonymous';
  IdFTP1.Password := 'anonymous';
  IdFTP1.host := 'localhost';
  IdFTP1.port := 21;

  Cmd := (leftstr(Cmdln,pos(' ',Cmdln)-1 ));
  Cmdln := trimleft(midstr(Cmdln,pos(' ',Cmdln),100));
  if pos('@',Cmd) <>0 then  // case user@host [21] [-pw password]
  begin
    IdFTP1.username := leftstr(Cmd,pos('@',Cmd)-1);
    IdFTP1.host := midstr(Cmd,pos('@',Cmd)+1,100);
    Cmd := (leftstr(Cmdln,pos(' ',Cmdln)-1 ));
    Cmdln := trimleft(midstr(Cmdln,pos(' ',Cmdln),100));
    if Cmd = '-pw' then IdFTP1.password := (leftstr(Cmdln,pos(' ',Cmdln)-1 ))
    else
    begin
      if Cmd <> '' then IdFTP1.port := strtoint(Cmd);
      Cmd := (leftstr(Cmdln,pos(' ',Cmdln)-1 ));
      Cmdln := trimleft(midstr(Cmdln,pos(' ',Cmdln),100));
      if Cmd = '-pw' then IdFTP1.password := (leftstr(Cmdln,pos(' ',Cmdln)-1 ));
    end;
  end
  else
  begin
    if (trim(Cmd) <> '') then    // case host + [port]
    begin
      IdFTP1.Host := Cmd;
      if (trim(Cmdln) <> '') then IdFTP1.Port := strtoint(Cmdln);
      IdFTP1.Username := 'anonymous';
      IdFTP1.Password := 'anonymous';
    end;
  end;
  printout('user : '+IdFTP1.username+' |host : '+IdFTP1.host+' |port : '+inttostr(IdFTP1.port)+' |pass : '+IdFTP1.password);
  if IdFTP1.Connected then
  begin
    try try
//      if TransferrignData then IdFTP1.Abort;
      currentdir := '';
      IdFTP1.Quit;
    except on E : Exception do  begin
      printout(ansireplacetext('pftp:++ '+E.Message,#13+#10,'   '));
    end; end;
    finally
    end;
  end
  else with IdFTP1 do
  begin
    try try
      IdFTP1.Connect(true);
      currentdir := idftp1.RetrieveCurrentDir ;
    except on E : Exception do  begin
      printout(ansireplaceText('pftp: '+E.Message,#13+#10,'   '));
    end; end;
    finally
    end;
    if IdFTP1.Connected then printout('Remote worling directory is '+ CurrentDir  );
  end;
end;

 {* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
procedure TConApplication.listdir(param1:string);
Var
  LS: TStringList;
  i : integer;
begin
  param1 := trim(param1);
  if IdFTP1.Connected then
  begin
    LS := TStringList.Create;
    try try
      IdFTP1.TransferType := ftASCII;
      IdFTP1.List(LS);
      IdFTP1.List(LS,param1);
      if ((rightstr(currentdir,1) <> '/') and (leftstr(param1,1) <> '/')) then param1 := '/'+param1;
      printout('Listing directory '+currentdir+param1);
      for i := 0 to   ls.Count -1 do
        printout(LS[i]);
    except on E : Exception do begin
      printout(ansireplaceText('pftp: '+E.Message,#13+#10,'   '));
    end; end;
    finally
    end;
    LS.Free;
  end
  else printout('pftp: not connected to a host; use "open user@host"');
end;

 {* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
procedure TConApplication.ChangeDir(DirName: String);
begin
  if IdFTP1.Connected then
  begin
    try try
      IdFTP1.ChangeDir(trim(DirName));
      currentdir := idftp1.RetrieveCurrentDir ;
      printout('Remote directory is now '+currentdir);
    except on E : Exception do begin
      printout(ansireplaceText('pftp: '+E.Message,#13+#10,'   '));
    end; end;
    finally
    end;
  end
  else printout('pftp: not connected to a host; use "open user@host"');
end;

{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
procedure TConApplication.RenameF(cmdln1: string);
var param1,param2 : string;
begin
  Param1 := trim(leftstr(Cmdln1,pos(' ',Cmdln1)-1 ));
  Param2 := trim(midstr(Cmdln1,pos(' ',Cmdln1),100));
  if IdFTP1.Connected then
  begin
    try try
      if ((param1 <> '') and (param2 <> '')) then idftp1.Rename(param1, param2);
    except on E : Exception do begin
      printout(ansireplaceText('pftp: '+E.Message,#13+#10,'   '));
    end; end;
    finally
    end;
  end
  else printout('pftp: not connected to a host; use "open user@host"');
end;

{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
procedure TConApplication.UploadF(cmdln1: string);
var Param1, Param2 : string;
begin
// put filename, host-filename
  Param1 := trim(leftstr(Cmdln1,pos(' ',Cmdln1)-1 ));
  Param2 := trim(midstr(Cmdln1,pos(' ',Cmdln1),100));
  if param2 = '' then param2 := param1;
  printout('local: '+Param1+' => remote: '+param2);
  if IdFTP1.Connected then begin
    if param1 <> '' then
    begin
      try try
        IdFTP1.TransferType := ftBinary;
        IdFTP1.Put(param1,ExtractFileName(param2));
      except on E : Exception do begin
        printout( ansireplaceText('pftp: '+E.Message,#13+#10,'   '));
      end; end;
      finally
      end;
    end;
  end
  else printout('pftp: not connected to a host; use "open user@host"');
end;

{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
procedure TConApplication.DownloadF(cmdln1,param3: string);
var Param1, Param2 : string;
begin
// get filename, local-filename
  Param1 := trim(leftstr(Cmdln1,pos(' ',Cmdln1)-1 ));
  Param2 := trim(midstr(Cmdln1,pos(' ',Cmdln1),100));
  if param2 = '' then param2 := param1;
  printout('remote: '+Param1+' => local: '+param2);
  if IdFTP1.Connected then
  begin
    try try
      IdFTP1.TransferType := ftBinary;
//    BytesToTransfer := IdFTP1.Size(param1);
//    bytestotransfer :=idFTP1.DirectoryListing.items[i].size ;
      if FileExists(param2) then
      begin
        if param3 = 'Resume'  then
        begin
//      BytesToTransfer := BytesToTransfer - FileSizeByName(Param2);
          IdFTP1.Get(param1,param2, false, true);
        end
        else
        begin
          if param3 = 'Replace' then
            IdFTP1.Get(param1,param2, true)
          else
            if param3 = 'Cancel' then
            begin
              printout('Transfert Canceled');
              exit;
            end;
        end;
      end
      else
        idFTP1.Get(param1, param2, false);
    except on E : Exception do  begin
      printout(ansireplaceText('pftp: '+E.Message,#13+#10,'   '));
    end;  end;
    finally
    end;
  end
  else printout('pftp: not connected to a host; use "open user@host"');
end;

{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
procedure TConApplication.DeleteF(param1: string);
begin
  if IdFTP1.Connected then
  begin
    try  try
      idftp1.Delete(trim(param1));
    except on E : Exception do  begin
    printout(ansireplaceText('pftp: '+E.Message,#13+#10,'   '));
    end; end;
    finally
    end;
  end
  else printout('pftp: not connected to a host; use "open user@host"');
end;

{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
procedure TConApplication.RemoveDir(param1: string);
begin
  if IdFTP1.Connected then
  begin
    try  try
      idftp1.RemoveDir(trim(param1));
//      ChangeDir(idftp1.RetrieveCurrentDir);
    except on E : Exception do  begin
    printout(ansireplaceText('pftp: '+E.Message,#13+#10,'   '));
    end; end;
    finally
    end;
  end
  else printout('pftp: not connected to a host; use "open user@host"');
end;

{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
procedure TConApplication.CreateDir(param1: string);
begin
  if trim(param1) <> '' then
  begin
    if IdFTP1.Connected then
    begin
      try try
         IdFTP1.MakeDir(trim(param1));
      except on E : Exception do begin
      printout(ansireplaceText('pftp: '+E.Message,#13+#10,'   '));
      end; end;
      finally
      end;
    end
    else printout('pftp: not connected to a host; use "open user@host"');
  end
  else printout('pftp: no Directory name');
end;

{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
procedure TConApplication.printout(txt:string);
begin
  writeln(txt);
  flush(output);
end;

{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
procedure TConApplication.help(cmdln:string);
begin
printout('');
printout('to launch pftp :');
printout(' pftp [user@]host [21] [-pw password]');
printout(' pftp host [port]');
printout('');
printout('all pftp commands :');
printout(' !dir   list contents of current directory in local client');
printout(' !dir  [selection-criteria]');
printout('');
printout(' !mkdir create a directory in local client');
printout(' !mkdir New-Directory');
printout('');
printout(' !rmdir remove a directory in local client');
printout(' !rmdir Directory');
printout('');
printout(' !ren   rename a file in local client');
printout(' !ren   Old-file New-file');
printout('');
printout(' !del   remove a file in local client');
printout(' !del   File');
printout('');
printout(' bye    finish your FTP session');
printout('');
printout(' cd     change your remote working directory');
printout(' cd     Sub-directory');
printout('');
printout(' chmod  change file permissions and modes');
printout(' chmod  Attrib file');
printout('');
printout(' del    delete a file');
printout(' del    File');
printout('');
printout(' dir    list contents of a remote directory');
printout(' dir    [Sub-directory]');
printout('');
printout(' exit   finish your FTP session');
printout('');
printout(' get    download a file from the server to your local machine');
printout(' get    Host-file [local-file]');
printout('');
printout(' help   print this help');
printout('');
printout(' lcd    change local working directory');
printout(' lcd    Sub-directory');
printout('');
printout(' lpwd   print current local working directory');
printout(' lpwd   ');
printout('');
printout(' ls     list contents of a remote directory');
printout(' ls     [Sub-directory] ');
printout('');
printout(' mkdir  create a directory on the remote server');
printout(' mkdir  New-directory');
printout('');
printout(' mv     move or rename a file on the remote server');
printout(' mv     Old-file new-file');
printout('');
printout(' open   connect to a host');
printout(' open   [User@]host [port] [-pw password]');
printout('');
printout(' put    upload a file from your local machine to the server');
printout(' put    Local-file [host-file]');
printout('');
printout(' pwd    print your remote working directory');
printout(' pwd    ');
printout('');
printout(' quit   finish your FTP session');
printout('');
printout(' reget  continue downloading a file');
printout(' reget  Host-file [local-file]');
printout('');
printout(' ren    move or rename a file on the remote server');
printout(' ren    Old-file New-file ');
printout('');
printout(' reput  continue uploading a file');
printout(' reput  Local-file [host-file]');
printout('');
printout(' rm     delete a file on remote server');
printout(' rm     Host-file');
printout('');
printout(' rmdir  remove a directory on the remote server');
printout(' rmdir  Host-directory');
end;
{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}

var
    ConApp : TConApplication;
begin
    WriteLn(CopyRight);
    WriteLn;
    ConApp := TConApplication.Create(nil);
    try
        ConApp.Execute;
    finally
        ConApp.Destroy;
    end;
 {
 procedure TMainForm.IdFTP1Disconnected(Sender: TObject);
begin
  StatusBar1.Panels[1].Text := 'Disconnected.';
end;

procedure TMainForm.AbortButtonClick(Sender: TObject);
begin
  AbortTransfer := true;
end;



procedure TMainForm.IdFTP1Status(axSender: TObject; const axStatus: TIdStatus;
  const asStatusText: String);
begin
  DebugListBox.ItemIndex := DebugListBox.Items.Add(asStatusText);
  StatusBar1.Panels[1].Text := asStatusText;
  checkWaitStatus(asStatusText);
end;


procedure TMainForm.IdFTP1Work(Sender: TObject; AWorkMode: TWorkMode;
  const AWorkCount: Integer);
Var
  S: String;
  TotalTime: TDateTime;
  H, M, Sec, MS: Word;
  DLTime: Double;
begin
  TotalTime :=  Now - STime;
  DecodeTime(TotalTime, H, M, Sec, MS);
  Sec := Sec + M * 60 + H * 3600;
  DLTime := Sec + MS / 1000;
  if DLTime > 0 then
 //   AverageSpeed := }{(AverageSpeed + }{(AWorkCount / 1024) / DLTime}{) / 2}{;

  if AverageSpeed > 0 then begin
    Sec := Trunc(((ProgressBar1.Max - AWorkCount) / 1024) / AverageSpeed);

    S := Format('%2d:%2d:%2d', [Sec div 3600, (Sec div 60) mod 60, Sec mod 60]);

    S := 'Time remaining ' + S;
  end
  else S := '';

  S := FormatFloat('0.00 KB/s', AverageSpeed) + '; ' + S;
  case AWorkMode of
    wmRead: StatusBar1.Panels[1].Text := 'Download speed ' + S;
    wmWrite: StatusBar1.Panels[1].Text := 'Uploade speed ' + S;
  end;

  if AbortTransfer then IdFTP1.Abort;
  ProgressBar1.Position := AWorkCount;
  AbortTransfer := false;
end;

procedure TMainForm.IdFTP1WorkBegin(Sender: TObject; AWorkMode: TWorkMode;
  const AWorkCountMax: Integer);
begin
  TransferrignData := true;
  AbortButton.Enabled := true;
  AbortTransfer := false;
  STime := Now;
  if AWorkCountMax > 0 then ProgressBar1.Max := AWorkCountMax
  else ProgressBar1.Max := BytesToTransfer;
  AverageSpeed := 0;
end;

procedure TMainForm.IdFTP1WorkEnd(Sender: TObject; AWorkMode: TWorkMode);
begin
  AbortButton.Enabled := false;
  StatusBar1.Panels[1].Text := 'Transfer complete.';
  BytesToTransfer := 0;
  TransferrignData := false;
  ProgressBar1.Position := 0;
  AverageSpeed := 0;
end;
}

end.

